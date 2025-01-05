import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:chatverse/chatverse.dart';
import 'screens/chat_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    runApp(const MyApp());
  } catch (e) {
    debugPrint('Failed to initialize Firebase: $e');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Failed to initialize app: $e'),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatVerse Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
      home: const ChatApp(),
    );
  }
}

class ChatApp extends StatefulWidget {
  const ChatApp({Key? key}) : super(key: key);

  @override
  State<ChatApp> createState() => _ChatAppState();
}

class _ChatAppState extends State<ChatApp> {
  late ChatController _chatController;
  final String _userId = 'user1';
  final Map<String, ChatUser> _users = {
    'user1': ChatUser(
      id: 'user1',
      name: 'Noor Ahmed',
      photoUrl: 'https://i.pravatar.cc/150?img=1',
    ),
    'user2': ChatUser(
      id: 'user2',
      name: 'Nono Nimo',
      photoUrl: 'https://i.pravatar.cc/150?img=2',
    ),
    'user3': ChatUser(
      id: 'user3',
      name: 'Salah Ahmed',
      photoUrl: 'https://i.pravatar.cc/150?img=3',
    ),
    'user4': ChatUser(
      id: 'user4',
      name: 'Hamed Essam',
      photoUrl: 'https://i.pravatar.cc/150?img=4',
    ),
  };

  @override
  void initState() {
    super.initState();
    _chatController = ChatController(
      userId: _userId,
      chatService: ChatService(userId: _userId),
      // authService: AuthService(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _chatController,
      child: ChatListScreen(
        users: _users,
        currentUserId: _userId,
        controller: _chatController,
        theme: ChatTheme(),
      ),
    );
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }
}
