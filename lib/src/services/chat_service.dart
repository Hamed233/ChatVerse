import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/message.dart';
import '../models/chat_room.dart';
import '../models/chat_user.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ChatService {
  final String userId;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  
  ChatService({
    required this.userId,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  // Room Operations
  Stream<List<ChatRoom>> getRooms() {
    return _firestore
        .collection('rooms')
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          return ChatRoom.fromMap(Map<String, dynamic>.from(data));
        } catch (e) {
          print('Error parsing room data: $e');
          // Return a default room in case of parsing error
          return ChatRoom(
            id: doc.id,
            name: 'Unnamed Room',
            memberIds: [userId],
            adminIds: [userId],
            type: ChatRoomType.individual,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }
      }).toList();
    });
  }

  Future<ChatRoom> createRoom(ChatRoom room,
  ) async {
    try {
      debugPrint('ChatService: Creating room with ID: ${room.id}');
      
      // For individual chats, check if a room already exists
      if (room.type == ChatRoomType.individual && room.memberIds.length == 2) {
        final existingRooms = await _firestore
            .collection('rooms')
            .where('memberIds', arrayContainsAny: room.memberIds)
            .where('type', isEqualTo: room.type.toString().split('.').last)
            .get();

        for (final doc in existingRooms.docs) {
          final roomData = doc.data();
          final roomMemberIds = List<String>.from(roomData['memberIds'] ?? []);
          
          // Check if the room has exactly these two members
          if (roomMemberIds.length == 2 &&
              roomMemberIds.contains(room.memberIds[0]) &&
              roomMemberIds.contains(room.memberIds[1])) {
            roomData['id'] = doc.id;
            return ChatRoom.fromMap(Map<String, dynamic>.from(roomData));
          }
        }
      }

      // If no existing room found or it's a group chat, create a new room
      final roomData = {
        'name': room.name,
        'photoUrl': room.photoUrl,
        'memberIds': room.memberIds,
        'type': room.type.toString().split('.').last,
        'adminIds': room.adminIds,
        'createdAt': Timestamp.fromDate(room.createdAt),
        'updatedAt': Timestamp.fromDate(room.updatedAt),
        'isArchived': room.isArchived,
        'isMuted': room.isMuted,
        'metadata': room.metadata,
      };

      // Use the provided room ID instead of auto-generating one
      await _firestore.collection('rooms').doc(room.id).set(roomData);
      roomData['id'] = room.id;
      
      debugPrint('ChatService: Room created successfully with ID: ${room.id}');
      return ChatRoom.fromMap(Map<String, dynamic>.from(roomData));
    } catch (e, stackTrace) {
      debugPrint('ChatService: Error creating room: $e');
      debugPrint('ChatService: Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> deleteRoom(String roomId) async {
    final batch = _firestore.batch();
    final roomRef = _firestore.collection('rooms').doc(roomId);

    // Delete all messages in the room
    final messages = await roomRef.collection('messages').get();
    for (final message in messages.docs) {
      batch.delete(message.reference);
    }

    // Delete the room document
    batch.delete(roomRef);

    await batch.commit();
  }

  // Message Operations
  Stream<List<Message>> getMessages(String roomId) {
    return _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Message.fromMap(Map<String, dynamic>.from(data));
      }).toList();
    });
  }

  Future<void> sendMessage(Message message) async {
    try {
      debugPrint('ChatService: Starting to send message...');
      debugPrint('ChatService: Message data: ${message.toMap()}');
      
      final roomRef = _firestore.collection('rooms').doc(message.roomId);
      
      // First verify if room exists
      final roomDoc = await roomRef.get();
      if (!roomDoc.exists) {
        debugPrint('ChatService: Error - Room ${message.roomId} does not exist');
        throw Exception('Room does not exist');
      }
      
      debugPrint('ChatService: Room exists, creating batch write...');
      final batch = _firestore.batch();

      // Add message to messages subcollection
      final messageRef = roomRef.collection('messages').doc(message.id);
      final messageData = message.toMap();
      debugPrint('ChatService: Adding message to batch: $messageData');
      batch.set(messageRef, messageData);

      // Update room's lastMessage and lastMessageAt
      final roomUpdate = {
        'lastMessage': messageData,
        'lastMessageAt': Timestamp.fromDate(message.createdAt),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };
      debugPrint('ChatService: Adding room update to batch: $roomUpdate');
      batch.update(roomRef, roomUpdate);

      debugPrint('ChatService: Committing batch write...');
      await batch.commit();
      debugPrint('ChatService: Message sent successfully!');
    } catch (e, stackTrace) {
      debugPrint('ChatService: Error sending message: $e');
      debugPrint('ChatService: Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Room Member Operations
  Future<void> addMembers(String roomId, List<String> userIds) async {
    await _firestore.collection('rooms').doc(roomId).update({
      'memberIds': FieldValue.arrayUnion(userIds),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> removeMembers(String roomId, List<String> userIds) async {
    await _firestore.collection('rooms').doc(roomId).update({
      'memberIds': FieldValue.arrayRemove(userIds),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Room Settings
  Future<void> muteRoom(String roomId, bool muted) async {
    await _firestore.collection('rooms').doc(roomId).update({
      'isMuted': muted,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> archiveRoom(String roomId, bool archived) async {
    await _firestore.collection('rooms').doc(roomId).update({
      'isArchived': archived,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // Typing Indicator
  Future<void> updateTypingStatus(String roomId, bool isTyping) async {
    final data = {
      'typingUsers': {
        userId: isTyping ? Timestamp.fromDate(DateTime.now()) : FieldValue.delete(),
      }
    };

    await _firestore.collection('rooms').doc(roomId).update(data);
  }

  Future<void> updateRoom(ChatRoom room) async {
    await _firestore.collection('rooms').doc(room.id).update(room.toMap());
  }

  Stream<ChatRoom?> getRoomStream(String roomId) {
    return _firestore
        .collection('rooms')
        .doc(roomId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return null;
          
          try {
            final data = snapshot.data()!;
            data['id'] = snapshot.id;
            return ChatRoom.fromMap(Map<String, dynamic>.from(data));
          } catch (e) {
            debugPrint('Error parsing room data: $e');
            return null;
          }
        });
  }

  // User Operations
  Stream<List<ChatUser>> getUsers() {
    return _firestore
        .collection('users')
        .snapshots()
        .map((snapshot) {
          debugPrint('Received users update: ${snapshot.docs.length} users');
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            debugPrint('User ${doc.id} status: ${data['isOnline']}');
            return ChatUser.fromJson(data);
          }).toList();
        });
  }

  // Update typing status for a user in a room
  Future<void> updateTypingStatusForUser(String roomId, String userId, bool isTyping) async {
    try {
      await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('typing')
          .doc(userId)
          .set({
        'isTyping': isTyping,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating typing status: $e');
      rethrow;
    }
  }

  // Update user's online status
  Future<void> updateUserOnlineStatus(String userId, bool isOnline) async {
    try {
      debugPrint('Updating online status for user $userId to $isOnline');
      await _firestore.collection('users').doc(userId).update({
        'isOnline': isOnline,
        'lastSeen': isOnline ? null : FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating online status: $e');
      rethrow;
    }
  }

  // Stream of typing users in a room
  Stream<Map<String, bool>> getTypingUsers(String roomId) {
    return _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('typing')
        .snapshots()
        .map((snapshot) {
      final Map<String, bool> typingUsers = {};
      for (var doc in snapshot.docs) {
        typingUsers[doc.id] = doc.data()['isTyping'] as bool;
      }
      return typingUsers;
    });
  }

  Future<String> uploadFile({
    required File file,
    required String path,
  }) async {
    try {
      debugPrint('ChatService: Uploading file to $path');
      
      final ref = _storage.ref().child(path);
      final uploadTask = await ref.putFile(file);
      final url = await uploadTask.ref.getDownloadURL();
      
      debugPrint('ChatService: File uploaded successfully. URL: $url');
      return url;
    } catch (e) {
      debugPrint('Error uploading file: $e');
      rethrow;
    }
  }

  // Block user functionality
  Future<void> blockUser(String userId) async {
    try {
      // Add user to blocked users collection
      await _firestore.collection('users').doc(this.userId).collection('blocked').doc(userId).set({
        'blockedAt': FieldValue.serverTimestamp(),
      });
      
      // Find and archive all individual chat rooms with this user
      final rooms = await _firestore
          .collection('rooms')
          .where('memberIds', arrayContains: this.userId)
          .where('type', isEqualTo: ChatRoomType.individual.toString().split('.').last)
          .get();
      
      for (final room in rooms.docs) {
        final memberIds = List<String>.from(room.data()['memberIds'] ?? []);
        if (memberIds.contains(userId)) {
          await room.reference.update({
            'isArchived': true,
            'blockedBy': this.userId,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      debugPrint('Error blocking user: $e');
      rethrow;
    }
  }

  // Check if a user is blocked
  Future<bool> isUserBlocked(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(this.userId)
          .collection('blocked')
          .doc(userId)
          .get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking blocked status: $e');
      return false;
    }
  }

  // Unblock user
  Future<void> unblockUser(String userId) async {
    try {
      // Remove user from blocked collection
      await _firestore
          .collection('users')
          .doc(this.userId)
          .collection('blocked')
          .doc(userId)
          .delete();
      
      // Find and unarchive all individual chat rooms with this user
      final rooms = await _firestore
          .collection('rooms')
          .where('memberIds', arrayContains: this.userId)
          .where('type', isEqualTo: ChatRoomType.individual.toString().split('.').last)
          .where('blockedBy', isEqualTo: this.userId)
          .get();
      
      for (final room in rooms.docs) {
        await room.reference.update({
          'isArchived': false,
          'blockedBy': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error unblocking user: $e');
      rethrow;
    }
  }
}
