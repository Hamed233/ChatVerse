import 'package:flutter/material.dart';
import 'package:chatverse/chatverse.dart';
import 'package:provider/provider.dart';
import 'chat_details_screen.dart';

class ChatScreen extends StatelessWidget {
  final Map<String, ChatUser> users;
  final String currentUserId;
  final ChatController controller;

  const ChatScreen({
    super.key,
    required this.users,
    required this.currentUserId,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: controller,
      child: _ChatScreenContent(
        users: users,
        currentUserId: currentUserId,
      ),
    );
  }
}

class _ChatScreenContent extends StatelessWidget {
  final Map<String, ChatUser> users;
  final String currentUserId;

  const _ChatScreenContent({
    super.key,
    required this.users,
    required this.currentUserId,
  });

  void _navigateToChatDetails(BuildContext context, ChatController controller) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailsScreen(
          users: users,
          currentUserId: currentUserId,
          controller: controller,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatController>(
      builder: (context, controller, _) {
        final room = controller.currentRoom;
        if (room == null) {
          return const Center(child: Text('No chat room selected'));
        }

        final isGroup = room.type == ChatRoomType.group;
        final otherUserId = isGroup
            ? null
            : room.memberIds.firstWhere(
                (id) => id != currentUserId,
                orElse: () => '',
              );
        final otherUser = otherUserId?.isNotEmpty == true ? users[otherUserId] : null;

        return Scaffold(
          appBar: AppBar(
            centerTitle: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                controller.currentRoom = null;
                Navigator.pop(context);
              },
            ),
            title: GestureDetector(
              onTap: () => _navigateToChatDetails(context, controller),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
                onPressed: () => _navigateToChatDetails(context, controller),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ChatView(
                  roomId: room.id,
                  currentUserId: currentUserId,
                  messages: controller.messages,
                  onSendMessage: (message) {
                    if (message.trim().isNotEmpty) {
                      controller.sendMessage(
                        content: message,
                        type: MessageType.text,
                      );
                    }
                  },
                  onMessageTap: (message) {
                    // Handle message tap
                  },
                  onTypingStatusChanged: (isTyping) {
                    // Handle typing status
                    // controller.setTypingStatus(isTyping);
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
