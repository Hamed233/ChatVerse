import 'package:flutter/material.dart';
import '../models/message.dart';
import '../models/chat_user.dart';
import '../utils/chat_theme.dart';
import 'chat_bubble.dart';
import 'chat_input.dart';

class ChatView extends StatefulWidget {
  final List<Message> messages;
  final ChatUser currentUser;
  final Map<String, ChatUser> users;
  final Function(String) onSendMessage;
  final Function(String, String?)? onSendImage;
  final Function(String, String)? onSendFile;
  final Function()? onStartTyping;
  final Function()? onStopTyping;
  final Function(Message)? onMessageLongPress;
  final Widget Function(Message)? replyWidgetBuilder;
  final ChatTheme theme;
  final Widget? loadingWidget;
  final Widget? emptyWidget;
  final Widget? headerWidget;
  final bool showUserNames;
  final bool showTypingIndicator;
  final List<String> typingUsers;

  const ChatView({
    Key? key,
    required this.messages,
    required this.currentUser,
    required this.users,
    required this.onSendMessage,
    this.onSendImage,
    this.onSendFile,
    this.onStartTyping,
    this.onStopTyping,
    this.onMessageLongPress,
    this.replyWidgetBuilder,
    this.theme = const ChatTheme(),
    this.loadingWidget,
    this.emptyWidget,
    this.headerWidget,
    this.showUserNames = true,
    this.showTypingIndicator = true,
    this.typingUsers = const [],
  }) : super(key: key);

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final ScrollController _scrollController = ScrollController();
  bool _isAtBottom = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      setState(() => _isAtBottom = true);
    } else {
      setState(() => _isAtBottom = false);
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.headerWidget != null) widget.headerWidget!,
        Expanded(
          child: Stack(
            children: [
              if (widget.messages.isEmpty && widget.emptyWidget != null)
                widget.emptyWidget!
              else
                ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: widget.messages.length +
                      (widget.showTypingIndicator && widget.typingUsers.isNotEmpty
                          ? 1
                          : 0),
                  itemBuilder: (context, index) {
                    if (index == widget.messages.length) {
                      return _buildTypingIndicator();
                    }

                    final message = widget.messages[index];
                    final isCurrentUser =
                        message.senderId == widget.currentUser.id;
                    final showName = widget.showUserNames &&
                        !isCurrentUser &&
                        (index == 0 ||
                            widget.messages[index - 1].senderId !=
                                message.senderId);

                    return ChatBubble(
                      message: message,
                      isCurrentUser: isCurrentUser,
                      theme: widget.theme,
                      onLongPress: widget.onMessageLongPress != null
                          ? () => widget.onMessageLongPress!(message)
                          : null,
                      replyWidget: message.replyTo != null &&
                              widget.replyWidgetBuilder != null
                          ? widget.replyWidgetBuilder!(message)
                          : null,
                      senderName: showName
                          ? widget.users[message.senderId]?.name
                          : null,
                    );
                  },
                ),
              if (!_isAtBottom)
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: widget.theme.primaryColor,
                    child: const Icon(Icons.keyboard_arrow_down),
                    onPressed: _scrollToBottom,
                  ),
                ),
            ],
          ),
        ),
        ChatInput(
          onSendText: widget.onSendMessage,
          onSendImage: widget.onSendImage,
          onSendFile: widget.onSendFile,
          onStartTyping: widget.onStartTyping,
          onStopTyping: widget.onStopTyping,
          theme: widget.theme,
        ),
      ],
    );
  }

  Widget _buildTypingIndicator() {
    if (!widget.showTypingIndicator || widget.typingUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: widget.theme.receivedMessageColor.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(1),
                _buildDot(2),
                _buildDot(3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 * index),
      builder: (context, value, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          height: 6 + (value * 3),
          width: 6 + (value * 3),
          decoration: BoxDecoration(
            color: widget.theme.receivedMessageTextColor.withOpacity(0.7),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
