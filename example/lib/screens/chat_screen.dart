import 'package:flutter/material.dart';
import 'package:chatverse/chatverse.dart';

class ChatScreen extends StatelessWidget {
  final ChatRoom room;
  final Map<String, ChatUser> users;
  final String currentUserId;
  final ChatController controller;
  final ChatTheme theme;

  const ChatScreen({
    Key? key,
    required this.room,
    required this.users,
    required this.currentUserId,
    required this.controller,
    required this.theme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.backgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          room.name,
          style: TextStyle(color: theme.textColor),
        ),
        actions: [
          if (room.type == ChatRoomType.group)
            IconButton(
              icon: Icon(Icons.group, color: theme.textColor),
              onPressed: () {
                // TODO: Show group info
              },
            ),
          IconButton(
            icon: Icon(Icons.more_vert, color: theme.textColor),
            onPressed: () {
              // TODO: Show chat options
            },
          ),
        ],
      ),
      body: ChatView(
        room: room,
        users: users,
        currentUserId: currentUserId,
        controller: controller,
        theme: theme,
      ),
    );
  }
}
