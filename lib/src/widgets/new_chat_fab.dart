import 'package:flutter/material.dart';
import '../chat_controller.dart';
import '../utils/chat_theme.dart';
import 'new_chat_view.dart';

class NewChatFAB extends StatelessWidget {
  final ChatController controller;
  final ChatTheme theme;
  final Function(String chatId)? onChatCreated;
  final String? label;
  final IconData? icon;
  final double? elevation;

  const NewChatFAB({
    Key? key,
    required this.controller,
    required this.theme,
    this.onChatCreated,
    this.label = 'New Chat',
    this.icon = Icons.chat_bubble_outline,
    this.elevation = 4,
  }) : super(key: key);

  void _navigateToNewChat(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => NewChatView(
          controller: controller,
          theme: theme,
          onChatCreated: (chatId) {
            // Navigator.pop(context);
            onChatCreated?.call(chatId);
          },
          // scrollController: scrollController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _navigateToNewChat(context),
      backgroundColor: theme.primaryColor,
      icon: Icon(icon),
      label: Text(label!),
      elevation: elevation,
    );
  }
}
