import 'package:flutter/material.dart';
import '../models/message.dart';
import '../utils/chat_theme.dart';
import 'chat_bubble.dart';
import 'chat_input.dart';

class ChatView extends StatefulWidget {
  final String roomId;
  final String currentUserId;
  final List<Message> messages;
  final Function(String) onSendMessage;
  final Function(Message)? onMessageTap;
  final Function(Message)? onMessageLongPress;
  final Function(bool)? onTypingStatusChanged;
  final ChatTheme theme;
  final Widget Function(BuildContext, Message, bool)? bubbleBuilder;
  final Widget Function(BuildContext)? headerBuilder;
  final Widget Function(BuildContext)? footerBuilder;
  final Widget? loadingWidget;
  final Widget? emptyWidget;
  final Widget? errorWidget;
  final bool showTypingIndicator;
  final bool showUserAvatar;
  final bool showUserName;
  final bool showTimestamp;
  final bool showReadStatus;
  final bool showDeliveryStatus;
  final ScrollController? scrollController;
  final bool reverse;
  final EdgeInsets padding;

  const ChatView({
    super.key,
    required this.roomId,
    required this.currentUserId,
    required this.messages,
    required this.onSendMessage,
    this.onMessageTap,
    this.onMessageLongPress,
    this.onTypingStatusChanged,
    this.theme = const ChatTheme(),
    this.bubbleBuilder,
    this.headerBuilder,
    this.footerBuilder,
    this.loadingWidget,
    this.emptyWidget,
    this.errorWidget,
    this.showTypingIndicator = true,
    this.showUserAvatar = true,
    this.showUserName = true,
    this.showTimestamp = true,
    this.showReadStatus = true,
    this.showDeliveryStatus = true,
    this.scrollController,
    this.reverse = true,
    this.padding = const EdgeInsets.all(8.0),
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.headerBuilder != null) widget.headerBuilder!(context),
        Expanded(
          child: _buildMessageList(),
        ),
        if (widget.footerBuilder != null) widget.footerBuilder!(context),
        ChatInput(
          onSendMessage: widget.onSendMessage,
          onTypingStatusChanged: widget.onTypingStatusChanged,
          theme: widget.theme,
        ),
      ],
    );
  }

  Widget _buildMessageList() {
    if (widget.messages.isEmpty) {
      return widget.emptyWidget ?? const Center(child: Text('No messages yet'));
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: widget.reverse,
      padding: widget.padding,
      itemCount: widget.messages.length,
      itemBuilder: (context, index) {
        final message = widget.messages[index];
        final isCurrentUser = message.senderId == widget.currentUserId;

        return widget.bubbleBuilder?.call(context, message, isCurrentUser) ??
            ChatBubble(
              message: message,
              isCurrentUser: isCurrentUser,
              theme: widget.theme,
              showUserAvatar: widget.showUserAvatar,
              showUserName: widget.showUserName,
              showTimestamp: widget.showTimestamp,
              showReadStatus: widget.showReadStatus,
              showDeliveryStatus: widget.showDeliveryStatus,
              onTap: () => widget.onMessageTap?.call(message),
              onLongPress: () => widget.onMessageLongPress?.call(message),
            );
      },
    );
  }
}
