import 'dart:async';
import 'dart:io';
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
  StreamSubscription? _typingSubscription;
  final Map<String, bool> _typingUsers = {};
  bool _isTyping = false;

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

  set currentRoom(ChatRoom? room) {
    if (_currentRoom?.id == room?.id) {
      debugPrint('ChatController: Room ID unchanged, skipping update');
      return;
    }

    debugPrint('ChatController: Switching room from ${_currentRoom?.id} to ${room?.id}');

    // Cancel existing subscriptions
    _messagesSubscription?.cancel();
    _typingSubscription?.cancel();
    _messagesSubscription = null;
    _typingSubscription = null;

    // Clear messages and typing status when changing rooms
    _messages = const [];
    _typingUsers.clear();
    _currentRoom = room;

    if (room != null) {
      debugPrint('ChatController: Subscribing to messages for room ${room.id}');
      // Subscribe to messages for the new room
      _messagesSubscription = _chatService
          .getMessages(room.id)
          .listen(
            (messages) {
              if (_currentRoom?.id != room.id) {
                debugPrint('ChatController: Skipping message update - room changed');
                return;
              }

              try {
                debugPrint('ChatController: Updating messages for room ${room.id}');
                _messages = List.unmodifiable(messages);
                notifyListeners();
              } catch (e, stackTrace) {
                debugPrint('ChatController: Error updating messages: $e');
                debugPrint('ChatController: Stack trace: $stackTrace');
              }
            },
            onError: (error) {
              debugPrint('ChatController: Error in message subscription: $error');
            },
            cancelOnError: false,
          );
          
      // Listen to typing status
      _listenToTypingStatus();
    }
  }

  void _handleNewMessages(List<Message> messages) {
    final currentRoomId = _currentRoom?.id;
    if (currentRoomId == null) return;

    // Only update messages if we're still in the same room
    if (messages.isNotEmpty && messages.first.roomId == currentRoomId) {
      debugPrint('ChatController: Updating messages for room $currentRoomId');
      _messages = List.unmodifiable(messages);
      notifyListeners();
    }
  }

  List<Message> get messages => List.unmodifiable(_messages);
  List<ChatRoom> get rooms => _rooms;
  List<ChatUser> get users => _users;
  ChatUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  List<String> get typingUsers {
    if (_currentRoom == null) return [];
    return _typingUsers.entries
        .where((entry) => entry.value && entry.key != userId)
        .map((entry) => entry.key)
        .toList();
  }

  void startTyping() {
    if (_currentRoom == null) return;
    
    debugPrint('ChatController: Starting typing in room ${_currentRoom!.id}');
    
    _isTyping = true;
    _typingTimer?.cancel();
    
    // Update typing status in the room
    _chatService.updateTypingStatusForUser(_currentRoom!.id, userId, true);
    
    // Set timer to stop typing after 1 second of inactivity
    _typingTimer = Timer(const Duration(seconds: 1), () {
      stopTyping();
    });
  }
  
  void stopTyping() {
    if (_currentRoom == null || !_isTyping) return;
    
    debugPrint('ChatController: Stopping typing in room ${_currentRoom!.id}');
    
    _isTyping = false;
    _typingTimer?.cancel();
    _typingTimer = null;
    
    // Update typing status in the room
    _chatService.updateTypingStatusForUser(_currentRoom!.id, userId, false);
  }

  void updateOnlineStatus(bool isOnline) {
    _chatService.updateUserOnlineStatus(userId, isOnline);
  }

  void _init() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Set user as online
      updateOnlineStatus(true);

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
            .listen(_handleNewMessages, onError: (error) {
          debugPrint('Error in message subscription: $error');
        });
      }

      // Listen to typing status if there's a current room
      if (_currentRoom != null) {
        _listenToTypingStatus();
      }
    } catch (e) {
      debugPrint('Error initializing ChatController: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _listenToTypingStatus() {
    _typingSubscription?.cancel();
    if (_currentRoom == null) return;
    
    debugPrint('ChatController: Starting typing status listener for room ${_currentRoom!.id}');
    
    _typingSubscription = _chatService.getTypingUsers(_currentRoom!.id).listen((typingStatus) {
      if (_currentRoom == null) return;
      
      debugPrint('ChatController: Received typing status update: $typingStatus');
      
      _typingUsers.clear();
      _typingUsers.addAll(typingStatus);
      notifyListeners();
    }, onError: (error) {
      debugPrint('Error in typing status subscription: $error');
    });
  }

  Future<void> sendMessage({
    required String content,
    MessageType type = MessageType.text,
    Map<String, dynamic>? metadata,
  }) async {
    if (_currentRoom == null) return;

    try {
      debugPrint('Adding message to local list...');
      final message = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        roomId: _currentRoom!.id,
        senderId: userId,
        senderName: _currentUser?.name ?? 'Unknown User',
        content: content,
        type: type,
        createdAt: DateTime.now(),
        metadata: metadata,
      );

      // Add message to Firestore
      await _chatService.sendMessage(message);
      debugPrint('Message sent successfully!');
    } catch (e, stackTrace) {
      debugPrint('ChatController: Error sending message: $e');
      debugPrint('ChatController: Stack trace: $stackTrace');
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

  Future<String> uploadGroupPhoto(File file) async {
    try {
      debugPrint('ChatController: Uploading group photo');
      return await _chatService.uploadFile(
        file: file,
        path: 'group_photos/${_currentRoom!.id}/${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      debugPrint('Error uploading group photo: $e');
      rethrow;
    }
  }

  Future<ChatRoom> createRoom(ChatRoom room) async {
    try {
      debugPrint('ChatController: Creating room...');
      debugPrint('ChatController: Room data: ${room.toMap()}');

      // Create the room in Firestore
      final createdRoom = await _chatService.createRoom(room);
      debugPrint('ChatController: Room created in Firestore: ${createdRoom.id}');

      // Add the room to the local list if we're still mounted
      _rooms = [createdRoom, ..._rooms];
      notifyListeners();

      debugPrint('ChatController: Room created successfully!');
      return createdRoom;
    } catch (e, stackTrace) {
      debugPrint('ChatController: Error creating room: $e');
      debugPrint('ChatController: Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<ChatRoom> findOrCreateRoom({
    required String otherUserId,
    required ChatRoomType type,
    String? name,
    String? photoUrl,
  }) async {
    try {
      debugPrint('ChatController: Finding or creating room...');
      // For individual chats, check if room exists
      if (type == ChatRoomType.individual) {
        final existingRoom = _rooms.firstWhere(
          (room) =>
              room.type == ChatRoomType.individual &&
              room.memberIds.length == 2 &&
              room.memberIds.contains(otherUserId) &&
              room.memberIds.contains(userId),
          orElse: () => throw StateError('Room not found'),
        );
        return existingRoom;
      }

      // For group chats, always create a new room
      final room = ChatRoom(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name ?? 'New Group',
        photoUrl: photoUrl,
        type: type,
        memberIds: [userId, otherUserId],
        adminIds: [userId],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return await createRoom(room);
    } catch (e) {
      if (e is StateError) {
        // Create new individual chat room
        final otherUser = users.firstWhere((u) => u.id == otherUserId);
        final room = ChatRoom(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: otherUser.name,
          photoUrl: otherUser.photoUrl,
          type: ChatRoomType.individual,
          memberIds: [userId, otherUserId],
          adminIds: [userId],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        return await createRoom(room);
      }
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

  void registerUser({
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

  Stream<ChatRoom?> getRoomStream(String roomId) {
    return _chatService.getRoomStream(roomId);
  }

  @override
  void dispose() {
    // Set user as offline
    updateOnlineStatus(false);
    
    // Cancel typing timer and clear status
    _typingTimer?.cancel();
    if (_currentRoom != null) {
      _chatService.updateTypingStatusForUser(_currentRoom!.id, userId, false);
    }
    
    // Cancel all subscriptions
    _messagesSubscription?.cancel();
    _roomsSubscription?.cancel();
    _usersSubscription?.cancel();
    _typingSubscription?.cancel();
    
    super.dispose();
  }
}
