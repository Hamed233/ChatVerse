import 'dart:math';

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
import 'package:intl/intl.dart';
import '../mixins/lifecycle_mixin.dart';
import 'profile_view.dart';

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

class _ChatViewState extends State<ChatView> with ChatLifecycleMixin {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToBottom = false;
  bool _isAtBottom = true;
  late final ChatController _chatController = widget.controller;
  bool _isSearching = false;
  String? _highlightedMessageId;
  bool _isUserBlocked = false;
  bool _isBlockedByUser = false;

  @override
  ChatController get chatController => _chatController;

  bool get isGroup => widget.room.type == ChatRoomType.group;

  bool get _isBlockedEither => _isUserBlocked || _isBlockedByUser;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _checkBlockStatus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        debugPrint('ChatView: Setting current room to ${widget.room.id}');
        _chatController.currentRoom = widget.room;
        _scrollToBottom();
      }
    });
  }

  @override
  void dispose() {
    if (mounted && _chatController.currentRoom?.id == widget.room.id) {
      _chatController.currentRoom = null;
    }
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkBlockStatus() async {
    if (!isGroup) {
      final otherUserId =
          widget.room.memberIds.firstWhere((id) => id != widget.currentUserId);
      final isBlocked = await widget.controller.isUserBlocked(otherUserId);
      final isBlockedBy = await widget.controller.isBlockedByUser(otherUserId);
      if (mounted) {
        setState(() {
          _isUserBlocked = isBlocked;
          _isBlockedByUser = isBlockedBy;
        });
      }
    }
  }

  Future<void> _handleBlockUser() async {
    if (!isGroup) {
      final otherUserId =
          widget.room.memberIds.firstWhere((id) => id != widget.currentUserId);
      if (_isUserBlocked) {
        await widget.controller.unblockUser(otherUserId);
      } else {
        await widget.controller.blockUser(otherUserId);
      }
      await _checkBlockStatus();
    }
  }

  Widget _buildInput() {
    if (_isBlockedEither) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: widget.theme.backgroundColor,
          border: Border(
            top: BorderSide(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _isUserBlocked
                    ? 'You have blocked this user'
                    : 'You have been blocked by this user',
                style: TextStyle(
                  color: widget.theme.textColor.withOpacity(0.6),
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (_isUserBlocked) // Only show unblock button if we blocked them
              TextButton(
                onPressed: _handleBlockUser,
                child: Text(
                  'Unblock',
                  style: TextStyle(
                    color: widget.theme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return ChatInput(
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
              SnackBar(
                content: Text('Error sending message: $e'),
                backgroundColor: Colors.red,
              ),
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
              SnackBar(
                content: Text('Error sending media: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      onTypingStarted: () => _chatController.startTyping(),
      theme: widget.theme,
      currentUserId: widget.currentUserId,
      roomId: widget.room.id,
    );
  }

  void _searchMessages() {
    showDialog(
      context: context,
      builder: (context) => _SearchDialog(
        users: widget.users,
        controller: widget.controller,
        theme: widget.theme,
        onMessageSelected: _scrollToMessage,
        roomId: widget.room.id,
      ),
    );
  }

  void _scrollToMessage(int messageIndex) {
    if (_scrollController.hasClients) {
      // Since we're using reverse: true, we need to adjust the scroll position
      final totalMessages = widget.controller.messages.length;
      final itemHeight = 70.0; // Approximate height of each message
      final offset = (totalMessages - messageIndex - 1) * itemHeight;

      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );

      // Highlight the message temporarily
      setState(() {
        _highlightedMessageId = widget.controller.messages[messageIndex].id;
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _highlightedMessageId = null;
          });
        }
      });
    }
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

  Future<void> _blockUser() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: Text(
            'Are you sure you want to block ${widget.users[widget.room.memberIds.firstWhere((id) => id != widget.currentUserId)]?.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: widget.theme.primaryColor),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'Block',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _handleBlockUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isUserBlocked
                ? 'User blocked successfully'
                : 'User unblocked successfully'),
          ),
        );
      }
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    // Since we're using reverse: true, minScrollExtent is the bottom (newest messages)
    final isAtBottom = _scrollController.position.pixels <=
        _scrollController.position.minScrollExtent + 50;

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
        _scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildMessage(Message message, bool isMe, ChatUser sender) {
    if (widget.messageBuilder != null) {
      return widget.messageBuilder!(context, message);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: widget.theme.primaryColor.withOpacity(0.2),
                  backgroundImage: sender.photoUrl != null
                      ? NetworkImage(sender.photoUrl!)
                      : null,
                  child: sender.photoUrl == null
                      ? Text(
                          sender.name[0].toUpperCase(),
                          style: TextStyle(
                            color: widget.theme.primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  decoration: BoxDecoration(
                    color: _highlightedMessageId == message.id
                        ? widget.theme.primaryColor.withOpacity(0.3)
                        : isMe
                            ? widget.theme.primaryColor
                            : widget.theme.backgroundColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isMe ? 20 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: isMe
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      if (!isMe && widget.room.type == ChatRoomType.group)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            sender.name,
                            style: TextStyle(
                              color: widget.theme.primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      _buildMessageContent(message),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(message.createdAt),
                            style: TextStyle(
                              color: isMe
                                  ? Colors.white.withOpacity(0.7)
                                  : Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.done_all,
                              size: 14,
                              color: message.isRead
                                  ? Colors.blue
                                  : Colors.white.withOpacity(0.7),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (isMe) const SizedBox(width: 8),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(Message message) {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content,
          style: TextStyle(
            color: message.senderId == widget.currentUserId
                ? Colors.white
                : widget.theme.textColor,
            fontSize: 16,
          ),
        );
      case MessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  message.content,
                  fit: BoxFit.cover,
                  width: 200,
                  height: 200,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: widget.theme.backgroundColor.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 32,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Failed to load image',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
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
            color: message.senderId == widget.currentUserId
                ? Colors.white.withOpacity(0.1)
                : widget.theme.backgroundColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: message.senderId == widget.currentUserId
                  ? Colors.white.withOpacity(0.2)
                  : widget.theme.primaryColor.withOpacity(0.2),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getFileIcon(fileName),
                  color: widget.theme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: TextStyle(
                        color: message.senderId == widget.currentUserId
                            ? Colors.white
                            : widget.theme.textColor,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      fileSizeStr,
                      style: TextStyle(
                        color: message.senderId == widget.currentUserId
                            ? Colors.white.withOpacity(0.7)
                            : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: widget.theme.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.download,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => _downloadFile(message.content, fileName),
                ),
              ),
            ],
          ),
        );
      default:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.grey,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Unsupported message type',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        );
    }
  }

  String _formatTime(DateTime time) {
    return DateFormat('HH:mm').format(time);
  }

  String _formatDate(DateTime date) {
    final referenceDate = DateTime(2025, 1, 13);
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedReference =
        DateTime(referenceDate.year, referenceDate.month, referenceDate.day);
    final difference = normalizedReference.difference(normalizedDate).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return DateFormat('EEEE').format(date);
    } else if (date.year == referenceDate.year) {
      return DateFormat('MMM d').format(date);
    } else {
      return DateFormat('MMM d, y').format(date);
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: Colors.grey.withOpacity(0.2),
              thickness: 1,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _formatDate(date),
              style: TextStyle(
                color: widget.theme.primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: Colors.grey.withOpacity(0.2),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Widget _buildTypingIndicator() {
    final typingUsers = _chatController.typingUsers;
    debugPrint(
        'ChatView: Building typing indicator, typing users: $typingUsers');

    if (typingUsers.isEmpty) return const SizedBox.shrink();

    String typingText;
    if (typingUsers.length == 1) {
      final user = widget.users[typingUsers.first];
      typingText = '${user?.name ?? 'Someone'} is typing...';
    } else if (typingUsers.length == 2) {
      final user1 = widget.users[typingUsers[0]];
      final user2 = widget.users[typingUsers[1]];
      typingText =
          '${user1?.name ?? 'Someone'} and ${user2?.name ?? 'someone'} are typing...';
    } else {
      typingText = 'Several people are typing...';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 35,
            child: Stack(
              children: [
                Positioned(
                  child: _buildTypingDot(0),
                ),
                Positioned(
                  left: 12,
                  child: _buildTypingDot(150),
                ),
                Positioned(
                  left: 24,
                  child: _buildTypingDot(300),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            typingText,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int delay) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, -3 * sin(value * math.pi)),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: widget.theme.primaryColor.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserStatus(ChatUser user) {
    debugPrint(
        'Building status for user ${user.id}: online=${user.isOnline}, lastSeen=${user.lastSeen}');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: user.isOnline ? Colors.green : Colors.grey,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          user.isOnline
              ? 'Online'
              : user.lastSeen != null
                  ? 'Last seen ${_formatLastSeen(user.lastSeen!)}'
                  : 'Offline',
          style: TextStyle(
            color: user.isOnline ? Colors.green : Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inHours < 1) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inDays < 1) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else {
      return DateFormat('MMM d, h:mm a').format(lastSeen);
    }
  }

  AppBar _buildAppBar() {
    final otherUser = widget.room.type == ChatRoomType.individual
        ? widget.users.values.firstWhere((u) => u.id != widget.currentUserId)
        : null;
    final isGroup = widget.room.type == ChatRoomType.group;

    return AppBar(
      backgroundColor: widget.theme.backgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        color: widget.theme.textColor,
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: GestureDetector(
        onTap: isGroup ? _showGroupDetails : _showUserDetails,
        child: Row(
          children: [
            Hero(
              tag: 'avatar_${widget.room.id}',
              child: CircleAvatar(
                radius: 20,
                backgroundColor: widget.theme.primaryColor.withOpacity(0.2),
                backgroundImage: widget.room.photoUrl != null
                    ? NetworkImage(widget.room.photoUrl!)
                    : null,
                child: widget.room.photoUrl == null
                    ? Text(
                        isGroup
                            ? widget.room.name[0].toUpperCase()
                            : (otherUser?.name[0].toUpperCase() ?? 'U'),
                        style: TextStyle(
                          color: widget.theme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isGroup
                        ? widget.room.name
                        : (otherUser?.name ?? 'Unknown User'),
                    style: TextStyle(
                      color: widget.theme.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isGroup)
                    Text(
                      '${widget.room.memberIds.length} members',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    )
                  else if (otherUser != null)
                    _buildUserStatus(otherUser),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert),
          color: widget.theme.textColor,
          onPressed: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (context) => Container(
                decoration: BoxDecoration(
                  color: widget.theme.backgroundColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.search),
                        title: const Text('Search Messages'),
                        onTap: () {
                          Navigator.pop(context);
                          _searchMessages();
                        },
                      ),
                      if (isGroup)
                        ListTile(
                          leading: const Icon(Icons.group),
                          title: const Text('Group Info'),
                          onTap: () {
                            Navigator.pop(context);
                            _showGroupDetails();
                          },
                        ),
                      if (!isGroup)
                        ListTile(
                          leading: const Icon(Icons.block, color: Colors.red),
                          title: const Text(
                            'Block User',
                            style: TextStyle(color: Colors.red),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _blockUser();
                          },
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _showUserDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => ProfileView(
              isCurrentUser: false,
              userId: widget.room.memberIds
                  .firstWhere((element) => element != widget.currentUserId))),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('_isUserBlocked');
    print(_isUserBlocked);
    print('_isBlockedByUser');
    print(_isBlockedByUser);

    return Scaffold(
      backgroundColor: widget.theme.backgroundColor,
      appBar: widget.appBar ?? _buildAppBar(),
      body: SafeArea(
        child: ChangeNotifierProvider.value(
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
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: widget.theme.primaryColor
                                        .withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.chat_bubble_outline,
                                    size: 48,
                                    color: widget.theme.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No messages yet',
                                  style: TextStyle(
                                    color: widget.theme.textColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Start a conversation!',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
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

                            // Check if we need to show a date separator
                            final messageDate = DateTime(
                              message.createdAt.year,
                              message.createdAt.month,
                              message.createdAt.day,
                            );

                            // For reverse order, check with the next message (which is actually previous in time)
                            Widget? dateSeparator;
                            if (index == messages.length - 1) {
                              // First message (oldest)
                              dateSeparator = _buildDateSeparator(messageDate);
                            } else {
                              final nextMessage = messages[index + 1];
                              final nextDate = DateTime(
                                nextMessage.createdAt.year,
                                nextMessage.createdAt.month,
                                nextMessage.createdAt.day,
                              );

                              if (!_isSameDay(messageDate, nextDate)) {
                                dateSeparator =
                                    _buildDateSeparator(messageDate);
                              }
                            }

                            return Column(
                              children: [
                                _buildMessage(message, isMe, sender),
                                if (dateSeparator != null) dateSeparator,
                              ],
                            );
                          },
                        );
                      },
                    ),
                    if (_showScrollToBottom)
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: FloatingActionButton.small(
                          backgroundColor: widget.theme.backgroundColor,
                          elevation: 4,
                          onPressed: _scrollToBottom,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(),
                            child: Icon(
                              Icons.keyboard_arrow_down,
                              color: widget.theme.primaryColor,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Consumer<ChatController>(
                builder: (context, controller, _) => _buildTypingIndicator(),
              ),
              _buildInput(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchDialog extends StatefulWidget {
  final Map<String, ChatUser> users;
  final ChatController controller;
  final ChatTheme theme;
  final Function(int) onMessageSelected;
  final String roomId;

  const _SearchDialog({
    required this.users,
    required this.controller,
    required this.theme,
    required this.onMessageSelected,
    required this.roomId,
  });

  @override
  _SearchDialogState createState() => _SearchDialogState();
}

class _SearchDialogState extends State<_SearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Message> _searchResults = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String value) {
    setState(() {
      if (value.isEmpty) {
        _searchResults = [];
      } else {
        _searchResults = widget.controller.messages
            .where((msg) =>
                msg.roomId == widget.roomId &&
                msg.content.toLowerCase().contains(value.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Search Messages',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: widget.theme.textColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    color: widget.theme.textColor,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Enter search term',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: _performSearch,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _searchResults.isEmpty && _searchController.text.isEmpty
                  ? Center(
                      child: Text(
                        'Enter text to search messages',
                        style: TextStyle(
                          color: widget.theme.textColor.withOpacity(0.6),
                        ),
                      ),
                    )
                  : _searchResults.isEmpty
                      ? Center(
                          child: Text(
                            'No messages found',
                            style: TextStyle(
                              color: widget.theme.textColor.withOpacity(0.6),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final message = _searchResults[index];
                            final sender = widget.users[message.senderId];
                            return ListTile(
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor:
                                    widget.theme.primaryColor.withOpacity(0.2),
                                backgroundImage: sender?.photoUrl != null
                                    ? NetworkImage(sender!.photoUrl!)
                                    : null,
                                child: sender?.photoUrl == null
                                    ? Text(
                                        sender?.name[0].toUpperCase() ?? '?',
                                        style: TextStyle(
                                          color: widget.theme.primaryColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      )
                                    : null,
                              ),
                              title: Text(
                                sender?.name ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message.content,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    DateFormat.yMMMd()
                                        .add_jm()
                                        .format(message.createdAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: widget.theme.textColor
                                          .withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                final messageIndex = widget.controller.messages
                                    .indexWhere((m) => m.id == message.id);
                                if (messageIndex != -1) {
                                  Navigator.pop(context);
                                  widget.onMessageSelected(messageIndex);
                                }
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
