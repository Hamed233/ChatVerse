import 'dart:async';
import 'package:flutter/foundation.dart';
import 'services/chat_service.dart';
import 'services/auth_service.dart';
import 'models/message.dart';
import 'models/chat_room.dart';
import 'models/chat_user.dart';

class ChatController extends ChangeNotifier {
  final ChatService _chatService;
  final AuthService _authService;
  final String userId;

  ChatRoom? _currentRoom;
  List<Message> _messages = [];
  List<ChatRoom> _rooms = [];
  List<ChatUser> _users = [];
  ChatUser? _currentUser;
  bool _isLoading = false;
  Timer? _typingTimer;
  StreamSubscription? _messagesSubscription;
  StreamSubscription? _roomsSubscription;
  StreamSubscription? _usersSubscription;

  ChatController({
    required this.userId,
    ChatService? chatService,
    AuthService? authService,
  })  : _chatService = chatService ?? ChatService(userId: userId),
        _authService = authService ?? AuthService() {
    _init();
  }

  // Getters
  ChatRoom? get currentRoom => _currentRoom;
  List<Message> get messages => _messages;
  List<ChatRoom> get rooms => _rooms;
  List<ChatUser> get users => _users;
  ChatUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  void _init() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Get current user
      _currentUser = await _authService.getCurrentUser();

      // Listen to rooms
      _roomsSubscription?.cancel();
      _roomsSubscription = _chatService.getRooms().listen((updatedRooms) {
        _rooms = updatedRooms;
        notifyListeners();
      });

      // Listen to users
      _usersSubscription?.cancel();
      _usersSubscription = _authService.getAllUsers().listen((updatedUsers) {
        _users = updatedUsers;
        notifyListeners();
      });

      // Listen to messages if there's a current room
      if (_currentRoom != null) {
        _messagesSubscription?.cancel();
        _messagesSubscription = _chatService
            .getMessages(_currentRoom!.id)
            .listen((updatedMessages) {
          _messages = updatedMessages;
          notifyListeners();
        });
      }
    } catch (e) {
      debugPrint('Error initializing ChatController: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Setter for currentRoom
  set currentRoom(ChatRoom? room) {
    if (_currentRoom?.id != room?.id) {
      _currentRoom = room;
      _messages = []; // Clear messages when changing rooms
      notifyListeners(); // Notify immediately to clear UI

      if (room != null) {
        _messagesSubscription?.cancel();
        _messagesSubscription =
            _chatService.getMessages(room.id).listen((msgs) {
          _messages = msgs;
          notifyListeners();
        });
      }
    }
  }

  Future<void> sendMessage({
    required String content,
    MessageType type = MessageType.text,
    Map<String, dynamic>? metadata,
  }) async {
    if (_currentRoom == null) return;

    final newMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      roomId: _currentRoom!.id,
      senderId: userId,
      senderName: _currentUser?.name ?? 'Unknown User',
      content: content,
      type: type,
      createdAt: DateTime.now(),
      metadata: metadata,
    );

    try {
      // Add message to local list immediately for UI responsiveness
      _messages = [..._messages, newMessage];
      notifyListeners();

      // Send message to service
      await _chatService.sendMessage(newMessage);
    } catch (e) {
      // Remove message from local list if sending failed
      _messages = _messages.where((m) => m.id != newMessage.id).toList();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> sendMediaMessage({
    required String url,
    required MessageType type,
    required Map<String, dynamic> metadata,
  }) async {
    if (_currentRoom == null) return;

    final newMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      roomId: _currentRoom!.id,
      senderId: userId,
      senderName: _currentUser?.name ?? 'Unknown User',
      content: url,
      type: type,
      createdAt: DateTime.now(),
      metadata: metadata,
    );

    try {
      // Add message to local list immediately for UI responsiveness
      _messages = [..._messages, newMessage];
      notifyListeners();

      // Send message to service
      await _chatService.sendMessage(newMessage);
    } catch (e) {
      // Remove message from local list if sending failed
      _messages = _messages.where((m) => m.id != newMessage.id).toList();
      notifyListeners();
      rethrow;
    }
  }

  Future<ChatRoom> createRoom({
    required String name,
    required List<String> memberIds,
    required ChatRoomType type,
    required List<String> adminIds,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) async {
    try {
      final room = await _chatService.createRoom(
        name: name,
        memberIds: memberIds,
        type: type,
        adminIds: adminIds,
      );
      return room;
    } catch (e) {
      debugPrint('Error creating room: $e');
      rethrow;
    }
  }

  Future<void> deleteRoom() async {
    if (_currentRoom == null) return;

    try {
      await _chatService.deleteRoom(_currentRoom!.id);
      _currentRoom = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting room: $e');
      rethrow;
    }
  }

  Future<void> updateRoom(ChatRoom room) async {
    try {
      await _chatService.updateRoom(room);
      if (_currentRoom?.id == room.id) {
        _currentRoom = room;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating room: $e');
      rethrow;
    }
  }

  Future<void> addMembers(List<String> memberIds) async {
    try {
      if (_currentRoom == null) {
        throw Exception('No room selected');
      }
      await _chatService.addMembers(_currentRoom!.id, memberIds);
    } catch (e) {
      debugPrint('Error adding members: $e');
      rethrow;
    }
  }

  Future<void> removeMembers(List<String> memberIds) async {
    try {
      if (_currentRoom == null) {
        throw Exception('No room selected');
      }
      await _chatService.removeMembers(_currentRoom!.id, memberIds);

      // If the current user is being removed, close the chat
      if (memberIds.contains(userId)) {
        _currentRoom = null;
      }
    } catch (e) {
      debugPrint('Error removing members: $e');
      rethrow;
    }
  }

  void startTyping() {
    if (_currentRoom == null) return;

    _typingTimer?.cancel();
    _chatService.updateTypingStatus(_currentRoom!.id, true);

    _typingTimer = Timer(const Duration(seconds: 5), () {
      _chatService.updateTypingStatus(_currentRoom!.id, false);
    });
  }

  // User registration and management
  Future<void> registerUser({
    required String id,
    required String name,
    String? email,
    String? photoUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final userDoc = await _authService.getCurrentUser();
      
      // If user already exists, just update their data
      if (userDoc != null) {
        await _authService.updateUserProfile(
          name: name,
          photoUrl: photoUrl,
          metadata: metadata,
        );
        return;
      }

      // Create a new user document in Firestore
      final userData = {
        'id': id,
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
        'isOnline': true,
        'lastSeen': DateTime.now(),
        'createdAt': DateTime.now(),
        if (metadata != null) 'metadata': metadata,
      };

      await _authService.createUser(userData);

      // Update current user
      _currentUser = ChatUser.fromJson(userData);
      notifyListeners();
    } catch (e) {
      print('Error registering user: $e');
      rethrow;
    }
  }

  // Update user's online status
  Future<void> updateOnlineStatus(bool isOnline) async {
    try {
      await _authService.updateOnlineStatus(isOnline);
    } catch (e) {
      print('Error updating online status: $e');
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? name,
    String? photoUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _authService.updateUserProfile(
        name: name,
        photoUrl: photoUrl,
        metadata: metadata,
      );
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _messagesSubscription?.cancel();
    _roomsSubscription?.cancel();
    _usersSubscription?.cancel();
    super.dispose();
  }
}
