import 'package:chatverse_example/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:chatverse/chatverse.dart';

class ChatListScreen extends StatefulWidget {
  final String userId;

  const ChatListScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChatListView(
      onSignOutGoTo: LoginScreen(),
      currentUserId: widget.userId,
    );
  }
}
