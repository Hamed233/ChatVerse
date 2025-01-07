import 'package:chatverse_example/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:chatverse/chatverse.dart';
import 'chat_screen.dart';

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
  late ChatController _chatController;
  late ChatTheme _theme;
  late AuthService _authService;
  Map<String, ChatUser> _usersMap = {};

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _chatController = ChatController(
      userId: widget.userId,
      chatService: ChatService(userId: widget.userId),
      authService: _authService,
    );
    _theme = ChatTheme();

    // Convert users list to map when controller updates
    _chatController.addListener(_updateUsersMap);
  }

  void _updateUsersMap() {
    setState(() {
      _usersMap = {
        for (var user in _chatController.users) user.id: user,
      };
    });
  }

  @override
  void dispose() {
    _chatController.removeListener(_updateUsersMap);
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    try {
      // First try to update online status
      try {
        await _authService.updateOnlineStatus(false);
      } catch (e) {
        // Ignore errors when updating online status
        debugPrint('Warning: Could not update online status: $e');
      }

      // Then sign out
      await _authService.signOut();
      
      // Navigate to login screen
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false, // Remove all previous routes
        );
      }
    } catch (e) {
      debugPrint('Error signing out: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
    }
  }

  void _navigateToChatScreen(BuildContext context, ChatRoom room) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          room: room,
          users: _usersMap,
          currentUserId: widget.userId,
          controller: _chatController,
          theme: _theme,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: ChatListView(
        controller: _chatController,
        theme: _theme,
        onRoomTap: (room) => _navigateToChatScreen(context, room),
        users: _usersMap,
        currentUserId: widget.userId,
      ),
      floatingActionButton: NewChatFAB(
        controller: _chatController,
        theme: _theme,
        onChatCreated: (chatId) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Chat created successfully!')),
            );
          }
        },
      ),
    );
  }
}
