import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chatverse/chatverse.dart';

class ChatScreen extends StatelessWidget {
  final ChatRoom room;
  final Map<String, ChatUser> users;
  final String currentUserId;
  final ChatController controller;
  final ChatTheme theme;

  const ChatScreen({
    super.key,
    required this.room,
    required this.users,
    required this.currentUserId,
    required this.controller,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: controller,
      child: Consumer<ChatController>(
        builder: (context, controller, _) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: theme.backgroundColor,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: theme.textColor),
                onPressed: () => Navigator.pop(context),
              ),
              title: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.primaryColor.withOpacity(0.1),
                    child: Text(
                      room.name[0].toUpperCase(),
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.name,
                          style: TextStyle(
                            color: theme.textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (room.type == ChatRoomType.group)
                          Text(
                            '${room.memberIds.length} members',
                            style: TextStyle(
                              color: theme.textColor.withOpacity(0.6),
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
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
        },
      ),
    );
  }
}
