import 'package:flutter/material.dart';
import 'package:chatverse/chatverse.dart';
import 'package:provider/provider.dart';
import 'chat_screen.dart';
import 'create_group_screen.dart';

class ChatListScreen extends StatelessWidget {
  final Map<String, ChatUser> users;
  final String currentUserId;
  final ChatController controller;
  final ChatTheme theme;

  const ChatListScreen({
    super.key,
    required this.users,
    required this.currentUserId,
    required this.controller,
    required this.theme,
  });

  void _navigateToChatScreen(BuildContext context, ChatRoom room) {
    // Set the current room before navigation
    controller.currentRoom = room;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          room: room,
          users: users,
          currentUserId: currentUserId,
          controller: controller,
          theme: theme,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: controller,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Chats',
            style: TextStyle(color: theme.textColor),
          ),
          backgroundColor: theme.backgroundColor,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(Icons.search, color: theme.textColor),
              onPressed: () {
                // TODO: Implement global search
              },
            ),
            IconButton(
              icon: Icon(Icons.more_vert, color: theme.textColor),
              onPressed: () {
                // TODO: Implement menu options
              },
            ),
          ],
        ),
        body: Consumer<ChatController>(
          builder: (context, controller, _) {
            if (controller.isLoading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            return ChatListView(
              users: users,
              currentUserId: currentUserId,
              controller: controller,
              theme: theme,
              onRoomTap: (room) => _navigateToChatScreen(context, room),
              onRoomDelete: (room) async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text(
                        'Delete ${room.type == ChatRoomType.group ? 'Group' : 'Chat'}?',
                      ),
                      content: Text(
                        'Are you sure you want to delete this ${room.type == ChatRoomType.group ? 'group' : 'chat'}? '
                        'This action cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text(
                            'Delete',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error),
                          ),
                        ),
                      ],
                    );
                  },
                );

                if (confirmed == true) {
                  controller.deleteRoom();
                }
              },
              emptyBuilder: (context, type) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      type == ChatRoomType.group
                          ? Icons.group
                          : Icons.chat_bubble_outline,
                      size: 64,
                      color: Theme.of(context).disabledColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      type == ChatRoomType.group
                          ? 'No group chats yet'
                          : 'No chats yet',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).disabledColor,
                          ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () =>
                          _navigateToCreateGroup(context, controller),
                      icon: const Icon(Icons.add),
                      label: Text(
                        type == ChatRoomType.group
                            ? 'Create a group'
                            : 'Start a chat',
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _navigateToCreateGroup(context, controller),
          backgroundColor: theme.primaryColor,
          child: const Icon(Icons.message),
        ),
      ),
    );
  }

  void _navigateToCreateGroup(BuildContext context, ChatController controller) {
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
  }
}
