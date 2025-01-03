import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/message.dart';
import '../utils/chat_theme.dart';

class ChatBubble extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;
  final ChatTheme theme;
  final VoidCallback? onLongPress;
  final Widget? replyWidget;
  final String? senderName;

  const ChatBubble({
    Key? key,
    required this.message,
    required this.isCurrentUser,
    required this.theme,
    this.onLongPress,
    this.replyWidget,
    this.senderName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: theme.maxMessageWidth,
        ),
        margin: EdgeInsets.only(
          left: isCurrentUser ? 64 : 16,
          right: isCurrentUser ? 16 : 64,
          top: 4,
          bottom: 4,
        ),
        child: Column(
          crossAxisAlignment:
              isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (senderName != null && !isCurrentUser)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 4),
                child: Text(
                  senderName!,
                  style: theme.userNameStyle,
                ),
              ),
            GestureDetector(
              onLongPress: onLongPress,
              child: Container(
                decoration: BoxDecoration(
                  color: isCurrentUser
                      ? theme.sentMessageColor
                      : theme.receivedMessageColor,
                  borderRadius: theme.messageBorderRadius,
                ),
                padding: theme.messagePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (replyWidget != null) replyWidget!,
                    _buildMessageContent(),
                    const SizedBox(height: 4),
                    Text(
                      timeago.format(message.createdAt),
                      style: theme.timeTextStyle,
                    ),
                    if (isCurrentUser) _buildMessageStatus(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent() {
    switch (message.type) {
      case MessageType.text:
        return Linkify(
          onOpen: (link) async {
            if (await canLaunchUrl(Uri.parse(link.url))) {
              await launchUrl(Uri.parse(link.url));
            }
          },
          text: message.content,
          style: theme.messageTextStyle.copyWith(
            color: isCurrentUser
                ? theme.sentMessageTextColor
                : theme.receivedMessageTextColor,
          ),
          linkStyle: theme.messageTextStyle.copyWith(
            color: Colors.blue,
            decoration: TextDecoration.underline,
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
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
              ),
            ),
            if (message.attachments?['caption'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  message.attachments!['caption'],
                  style: theme.messageTextStyle.copyWith(
                    color: isCurrentUser
                        ? theme.sentMessageTextColor
                        : theme.receivedMessageTextColor,
                  ),
                ),
              ),
          ],
        );
      case MessageType.video:
      case MessageType.audio:
      case MessageType.file:
      case MessageType.custom:
      default:
        return Text(
          message.content,
          style: theme.messageTextStyle.copyWith(
            color: isCurrentUser
                ? theme.sentMessageTextColor
                : theme.receivedMessageTextColor,
          ),
        );
    }
  }

  Widget _buildMessageStatus() {
    // Get message status from metadata if available
    final status = message.metadata?['status'] as String?;
    IconData icon = Icons.check;
    Color color = Colors.grey;

    if (status != null) {
      switch (status) {
        case 'sending':
          icon = Icons.access_time;
          break;
        case 'sent':
          icon = Icons.check;
          break;
        case 'delivered':
          icon = Icons.done_all;
          break;
        case 'read':
          icon = Icons.done_all;
          color = Colors.blue;
          break;
        case 'failed':
          icon = Icons.error_outline;
          color = Colors.red;
          break;
        default:
          icon = Icons.check;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Icon(
        icon,
        size: 16,
        color: color,
      ),
    );
  }
}
