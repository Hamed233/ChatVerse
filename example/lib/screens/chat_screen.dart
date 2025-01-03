import 'package:flutter/material.dart';
import 'package:chatverse/chatverse.dart';
import 'package:provider/provider.dart';
import 'chat_details_screen.dart';

class ChatScreen extends StatelessWidget {
  final Map<String, ChatUser> users;
  final String currentUserId;

  const ChatScreen({
    Key? key,
    required this.users,
    required this.currentUserId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatController>(
      builder: (context, controller, _) {
        final room = controller.currentRoom;
        if (room == null) return const SizedBox();

        final isGroup = room.type == ChatRoomType.group;
        final otherUserId = isGroup
            ? null
            : room.memberIds.firstWhere((id) => id != currentUserId);
        final otherUser = otherUserId != null ? users[otherUserId] : null;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                controller.currentRoom = null;
                Navigator.pop(context);
              },
            ),
            title: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatDetailsScreen(
                      users: users,
                      currentUserId: currentUserId,
                    ),
                  ),
                );
              },
              child: Column(
                children: [
                  Text(
                    isGroup ? room.name : (otherUser?.name ?? 'Unknown User'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!isGroup && otherUser != null)
                    Text(
                      'Online', // TODO: Implement online status
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[400],
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatDetailsScreen(
                        users: users,
                        currentUserId: currentUserId,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ChatView(
                  messages: controller.messages,
                  currentUser: users[currentUserId]!,
                  users: users,
                  onSendMessage: (message) {
                    controller.sendMessage(content: message);
                  },
                  onSendImage: (path, caption) {
                    controller.sendMessage(
                      content: path,
                      type: MessageType.image,
                      metadata: {'caption': caption},
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
