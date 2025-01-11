import 'package:chatverse/src/widgets/group_details_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_room.dart';
import '../models/chat_user.dart';
import '../models/message.dart';
import '../chat_controller.dart';
import '../utils/chat_theme.dart';
import 'chat_input.dart';
import 'dart:math' as math;

class ChatView extends StatefulWidget {
  final ChatRoom room;
  final Map<String, ChatUser> users;
  final String currentUserId;
  final ChatController controller;
  final ChatTheme theme;
  final Widget Function(BuildContext, Message)? messageBuilder;
  final Widget Function(BuildContext, ChatUser)? userBuilder;
  final Widget Function(BuildContext, DateTime)? dateBuilder;
  final PreferredSizeWidget? appBar;

  const ChatView({
    super.key,
    required this.room,
    required this.users,
    required this.currentUserId,
    required this.controller,
    required this.theme,
    this.messageBuilder,
    this.userBuilder,
    this.dateBuilder,
    this.appBar,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToBottom = false;
  bool _isAtBottom = true;
  DateTime? _lastMessageDate;
  late ChatController _chatController;

  @override
  void initState() {
    super.initState();
    _chatController = widget.controller;
    _scrollController.addListener(_onScroll);

    // Set the current room after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        debugPrint('ChatView: Setting current room to ${widget.room.id}');
        _chatController.currentRoom = widget.room;
        _scrollToBottom();
      }
    });
  }

  @override
  void didUpdateWidget(ChatView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller || oldWidget.room.id != widget.room.id) {
      _chatController = widget.controller;
      // Update the current room after the frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          debugPrint('ChatView: Updating current room to ${widget.room.id}');
          _chatController.currentRoom = widget.room;
        }
      });
    }
  }

  @override
  void dispose() {
    debugPrint('ChatView: Disposing view for room ${widget.room.id}');
    // Only clear the current room if we're still showing this room
    if (mounted && _chatController.currentRoom?.id == widget.room.id) {
      _chatController.currentRoom = null;
    }
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final isAtBottom = _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100;
    if (_isAtBottom != isAtBottom) {
      setState(() {
        _isAtBottom = isAtBottom;
        _showScrollToBottom = !isAtBottom;
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildMessage(Message message, bool isMe, ChatUser sender) {
    if (widget.messageBuilder != null) {
      return widget.messageBuilder!(context, message);
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Card(
          color:
              isMe ? widget.theme.primaryColor : widget.theme.backgroundColor,
          margin: EdgeInsets.only(
            left: isMe ? 64 : 8,
            right: isMe ? 8 : 64,
            bottom: 4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe && widget.room.type == ChatRoomType.group)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      sender.name,
                      style: TextStyle(
                        color: widget.theme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                _buildMessageContent(message),
                const SizedBox(height: 2),
                Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(
                    color: isMe
                        ? Colors.white.withOpacity(0.7)
                        : widget.theme.textColor.withOpacity(0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageContent(Message message) {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content,
          style: TextStyle(
            color: widget.theme.textColor,
            fontSize: 16,
          ),
        );
      case MessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                message.content,
                fit: BoxFit.cover,
                width: 200,
                height: 200,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return SizedBox(
                    width: 200,
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          widget.theme.primaryColor,
                        ),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 200,
                    height: 200,
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 32,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      case MessageType.file:
        final fileName = message.metadata?['fileName'] as String? ?? 'File';
        final fileSize = message.metadata?['fileSize'] as int? ?? 0;
        final fileSizeStr = _formatFileSize(fileSize);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.theme.backgroundColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getFileIcon(fileName),
                color: widget.theme.primaryColor,
                size: 32,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: TextStyle(
                        color: widget.theme.textColor,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      fileSizeStr,
                      style: TextStyle(
                        color: widget.theme.textColor.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: Icon(
                  Icons.download,
                  color: widget.theme.primaryColor,
                ),
                onPressed: () => _downloadFile(message.content, fileName),
              ),
            ],
          ),
        );
      default:
        return Text(
          'Unsupported message type',
          style: TextStyle(
            color: widget.theme.textColor.withOpacity(0.7),
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
        );
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      final weekday = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ][date.weekday - 1];
      return weekday;
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      default:
        return Icons.insert_drive_file;
    }
  }

  Future<void> _downloadFile(String url, String fileName) async {
    try {
      // Implement file download logic here
      // You can use url_launcher or other packages to handle file downloads
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Downloading $fileName...')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading file: $e')),
      );
    }
  }

  Widget _buildDateSeparator(DateTime date) {
    if (widget.dateBuilder != null) {
      return widget.dateBuilder!(context, date);
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: widget.theme.backgroundColor.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _formatDate(date),
          style: TextStyle(
            color: widget.theme.textColor.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: widget.theme.backgroundColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      title: widget.room.type == ChatRoomType.group
          ? GestureDetector(
              onTap: () => _showGroupDetails(),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: widget.theme.primaryColor,
                    backgroundImage: widget.room.photoUrl != null
                        ? NetworkImage(widget.room.photoUrl!)
                        : null,
                    child: widget.room.photoUrl == null
                        ? Text(
                            widget.room.name[0].toUpperCase(),
                            style: TextStyle(
                              color: widget.theme.backgroundColor,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.room.name,
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          '${widget.room.memberIds.length} members',
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.theme.textColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : Text(widget.room.name),
      actions: [
        if (widget.room.type == ChatRoomType.group)
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showGroupDetails,
          ),
      ],
    );
  }

  void _showGroupDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupDetailsView(
          room: widget.room,
          users: widget.users,
          currentUserId: widget.currentUserId,
          controller: widget.controller,
          theme: widget.theme,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: widget.appBar ?? _buildAppBar(),
        body: ChangeNotifierProvider.value(
            value: widget.controller,
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Consumer<ChatController>(
                        builder: (context, chatController, _) {
                          final messages = chatController.messages;

                          if (messages.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    size: 48,
                                    color:
                                        widget.theme.textColor.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No messages yet',
                                    style: TextStyle(
                                      color: widget.theme.textColor
                                          .withOpacity(0.7),
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            controller: _scrollController,
                            reverse: true,
                            padding: const EdgeInsets.all(16),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[index];
                              final isMe =
                                  message.senderId == widget.currentUserId;
                              final sender = widget.users[message.senderId] ??
                                  ChatUser(
                                    id: message.senderId,
                                    name: message.senderName,
                                    email: '',
                                  );

                              return _buildMessage(message, isMe, sender);
                            },
                          );
                        },
                      ),
                      if (_showScrollToBottom)
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: FloatingActionButton(
                            mini: true,
                            backgroundColor: widget.theme.backgroundColor,
                            onPressed: _scrollToBottom,
                            child: Icon(
                              Icons.arrow_downward,
                              color: widget.theme.primaryColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                ChatInput(
                  onSendMessage: (content) async {
                    try {
                      await _chatController.sendMessage(
                        content: content,
                        type: MessageType.text,
                      );
                      if (_isAtBottom) {
                        _scrollToBottom();
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error sending message: $e')),
                        );
                      }
                    }
                  },
                  onSendMedia: (url, type, metadata) async {
                    try {
                      await _chatController.sendMessage(
                        content: url,
                        type: type,
                        metadata: metadata,
                      );
                      if (_isAtBottom) {
                        _scrollToBottom();
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error sending media: $e')),
                        );
                      }
                    }
                  },
                  theme: widget.theme,
                  currentUserId: widget.currentUserId,
                  roomId: widget.room.id,
                ),
              ],
            )));
  }
}
