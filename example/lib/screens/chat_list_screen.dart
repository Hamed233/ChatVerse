import 'package:flutter/material.dart';
import 'package:chatverse/chatverse.dart';
import 'package:provider/provider.dart';
import 'chat_screen.dart';
import 'create_group_screen.dart';

class ChatListScreen extends StatelessWidget {
  final Map<String, ChatUser> users;
  final String currentUserId;
  final ChatController controller;

  const ChatListScreen({
    Key? key,
    required this.users,
    required this.currentUserId,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: controller,
      child: _ChatListContent(
        users: users,
        currentUserId: currentUserId,
      ),
    );
  }
}

class _ChatListContent extends StatelessWidget {
  final Map<String, ChatUser> users;
  final String currentUserId;

  const _ChatListContent({
    Key? key,
    required this.users,
    required this.currentUserId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatController>(
      builder: (context, controller, _) {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.rooms.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  'No chats yet',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateGroupScreen(
                          users: users,
                          currentUserId: currentUserId,
                          controller: controller,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Start a chat'),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Chats',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.group_add),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateGroupScreen(
                        users: users,
                        currentUserId: currentUserId,
                        controller: controller,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          body: ListView.builder(
            itemCount: controller.rooms.length,
            itemBuilder: (context, index) {
              final room = controller.rooms[index];
              final isGroup = room.type == ChatRoomType.group;
              final otherUserId = isGroup
                  ? null
                  : room.memberIds.firstWhere((id) => id != currentUserId);
              final otherUser = otherUserId != null ? users[otherUserId] : null;
              final lastMessage = room.lastMessage;

              return Dismissible(
                key: Key(room.id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                  ),
                ),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(
                            'Delete ${isGroup ? 'Group' : 'Chat'}?'),
                        content: Text(
                            'Are you sure you want to delete this ${isGroup ? 'group' : 'chat'}? This action cannot be undone.'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
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
                  );
                },
                onDismissed: (direction) {
                  controller.deleteRoom();
                },
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isGroup ? Colors.blue : Colors.grey[300],
                    backgroundImage: isGroup
                        ? null
                        : (otherUser?.photoUrl?.isNotEmpty == true
                            ? NetworkImage(otherUser!.photoUrl ?? '')
                            : null),
                    child: isGroup
                        ? const Icon(Icons.group, color: Colors.white)
                        : (otherUser?.photoUrl?.isNotEmpty == true
                            ? null
                            : Text(
                                otherUser?.name.substring(0, 1).toUpperCase() ??
                                    '?',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              )),
                  ),
                  title: Text(
                    isGroup ? room.name : (otherUser?.name ?? 'Unknown User'),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: lastMessage != null
                      ? Row(
                          children: [
                            Expanded(
                              child: Text(
                                lastMessage.type == MessageType.text
                                    ? lastMessage.content
                                    : '📷 Photo',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatTimestamp(lastMessage.createdAt),
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )
                      : null,
                  onTap: () {
                    controller.currentRoom = room;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          users: users,
                          currentUserId: currentUserId,
                          controller: controller,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateGroupScreen(
                    users: users,
                    currentUserId: currentUserId,
                    controller: controller,
                  ),
                ),
              );
            },
            child: const Icon(Icons.message),
          ),
        );
      },
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
