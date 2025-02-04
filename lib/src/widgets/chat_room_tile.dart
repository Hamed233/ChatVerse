import 'dart:math';

import 'package:flutter/material.dart';
import '../models/chat_room.dart';
import '../models/chat_user.dart';
import '../models/message.dart';
import '../utils/chat_theme.dart';

class ChatRoomTile extends StatelessWidget {
  final ChatRoom room;
  final String currentUserId;
  final Map<String, ChatUser> users;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final ChatTheme theme;

  const ChatRoomTile({
    super.key,
    required this.room,
    required this.currentUserId,
    required this.users,
    required this.theme,
    this.onTap,
    this.onDelete,
  });

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, min(name.length, 2)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isGroup = room.type == ChatRoomType.group;
    final otherUserId = isGroup
        ? null
        : room.memberIds.firstWhere(
            (id) => id != currentUserId,
            orElse: () => '',
          );
    final otherUser = otherUserId?.isNotEmpty == true ? users[otherUserId] : null;
    final lastMessage = room.lastMessage;
    final hasUnreadMessages = room.unreadCount > 0;

    return Dismissible(
      key: Key(room.id),
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.delete_outline, color: Colors.white, size: 28),
            const SizedBox(height: 4),
            const Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                'Delete ${isGroup ? 'Group' : 'Chat'}?',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Text(
                'Are you sure you want to delete this ${isGroup ? 'group' : 'chat'}? '
                'This action cannot be undone.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: theme.textColor),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        ) ?? false;
      },
      onDismissed: (direction) => onDelete?.call(),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: hasUnreadMessages
              ? BorderSide(color: theme.primaryColor.withOpacity(0.3), width: 1)
              : BorderSide.none,
        ),
        elevation: hasUnreadMessages ? 2 : 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: isGroup ? theme.primaryColor : theme.secondaryColor,
                      backgroundImage: !isGroup && otherUser?.photoUrl?.isNotEmpty == true
                          ? NetworkImage(otherUser!.photoUrl!)
                          : null,
                      child: (!isGroup && otherUser?.photoUrl?.isNotEmpty == true)
                          ? null
                          : Text(
                              isGroup
                                  ? room.name.substring(0, 1).toUpperCase()
                                  : _getInitials(otherUser?.name ?? 'Unknown'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    if (isGroup)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: theme.backgroundColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.backgroundColor,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.group,
                            size: 14,
                            color: theme.primaryColor,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isGroup ? room.name : (otherUser?.name ?? 'Unknown User'),
                              style: TextStyle(
                                fontWeight: hasUnreadMessages ? FontWeight.bold : FontWeight.w500,
                                fontSize: 16,
                                color: theme.textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (lastMessage != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              _formatTimestamp(lastMessage.createdAt),
                              style: TextStyle(
                                color: hasUnreadMessages
                                    ? theme.primaryColor
                                    : theme.textColor.withOpacity(0.5),
                                fontSize: 12,
                                fontWeight: hasUnreadMessages ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (lastMessage != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                lastMessage.type == MessageType.text
                                    ? lastMessage.content
                                    : '📷 Photo',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: hasUnreadMessages
                                      ? theme.textColor
                                      : theme.textColor.withOpacity(0.7),
                                  fontSize: 14,
                                  fontWeight: hasUnreadMessages ? FontWeight.w500 : FontWeight.normal,
                                ),
                              ),
                            ),
                            if (hasUnreadMessages) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  room.unreadCount > 9 ? '9+' : room.unreadCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
