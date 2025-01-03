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
  final bool showUserAvatar;
  final bool showUserName;
  final bool showTimestamp;
  final bool showReadStatus;
  final bool showDeliveryStatus;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    required this.theme,
    this.showUserAvatar = true,
    this.showUserName = true,
    this.showTimestamp = true,
    this.showReadStatus = true,
    this.showDeliveryStatus = true,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isCurrentUser ? 64 : 16,
          right: isCurrentUser ? 16 : 64,
          top: 4,
          bottom: 4,
        ),
        child: GestureDetector(
          onTap: onTap,
          onLongPress: onLongPress,
          child: Column(
            crossAxisAlignment:
                isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (showUserName && !isCurrentUser)
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 4),
                  child: Text(
                    message.senderName,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.timestampColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isCurrentUser ? theme.sentMessageColor : theme.receivedMessageColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMessageContent(),
                    if (showTimestamp)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              timeago.format(message.createdAt),
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.timestampColor,
                              ),
                            ),
                            if (showDeliveryStatus && isCurrentUser) ...[
                              const SizedBox(width: 4),
                              Icon(
                                message.isDelivered
                                    ? Icons.done_all
                                    : Icons.done,
                                size: 12,
                                color: message.isRead && showReadStatus
                                    ? theme.primaryColor
                                    : theme.timestampColor,
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
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
}
