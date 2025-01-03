import 'package:flutter/material.dart';
import 'package:chatverse/chatverse.dart';
import 'package:provider/provider.dart';
import 'chat_screen.dart';
import 'create_group_screen.dart';

class ChatListScreen extends StatelessWidget {
  final Map<String, ChatUser> users;
  final String currentUserId;

  const ChatListScreen({
    Key? key,
    required this.users,
    required this.currentUserId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<ChatController>(
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

          return ListView.builder(
            itemCount: controller.rooms.length,
            itemBuilder: (context, index) {
              final room = controller.rooms[index];
              final otherUserId = room.memberIds
                  .firstWhere((id) => id != currentUserId, orElse: () => '');
              final otherUser = users[otherUserId];
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
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Chat?'),
                      content: const Text(
                        'Are you sure you want to delete this chat? This action cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) {
                  controller.deleteRoom();
                },
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: room.type == ChatRoomType.individual
                        ? NetworkImage(otherUser?.photoUrl ?? '')
                        : null,
                    child: room.type == ChatRoomType.group
                        ? const Icon(Icons.group)
                        : (otherUser?.photoUrl == null
                            ? Text(
                                otherUser?.name.substring(0, 1).toUpperCase() ??
                                    '?',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null),
                  ),
                  title: Text(
                    room.type == ChatRoomType.individual
                        ? otherUser?.name ?? 'Unknown User'
                        : room.name,
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
                              _formatMessageTime(lastMessage.createdAt),
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
                        ),
                      ),
                    );
                  },
                ),
              );
            },
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
              ),
            ),
          );
        },
        child: const Icon(Icons.message),
      ),
    );
  }

  String _formatMessageTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 7) {
      return '${time.day}/${time.month}/${time.year}';
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
}
