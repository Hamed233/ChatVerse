import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';
import '../models/chat_room.dart';
import '../models/chat_user.dart';

class ChatService {
  final FirebaseFirestore _firestore;
  final String userId;

  ChatService({
    required this.userId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  // Room Operations
  Stream<List<ChatRoom>> getRooms() {
    return _firestore
        .collection('rooms')
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ChatRoom.fromJson(data);
      }).toList();
    });
  }

  Future<ChatRoom> createRoom({
    required String name,
    required List<String> memberIds,
    required ChatRoomType type,
    required List<String> adminIds,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) async {
    final roomData = {
      'name': name,
      'memberIds': memberIds,
      'type': type.toString(),
      'adminIds': adminIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };

    final docRef = await _firestore.collection('rooms').add(roomData);
    roomData['id'] = docRef.id;
    
    return ChatRoom.fromJson(roomData);
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
        return Message.fromJson(data);
      }).toList();
    });
  }

  Future<void> sendMessage(Message message) async {
    final roomRef = _firestore.collection('rooms').doc(message.roomId);
    final batch = _firestore.batch();

    // Add message to messages subcollection
    final messageRef = roomRef.collection('messages').doc(message.id);
    batch.set(messageRef, message.toJson());

    // Update room's lastMessage and lastMessageAt
    batch.update(roomRef, {
      'lastMessage': message.toJson(),
      'lastMessageAt': Timestamp.fromDate(message.createdAt),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });

    await batch.commit();
  }

  // Room Member Operations
  Future<void> addMembersToRoom(String roomId, List<String> userIds) async {
    await _firestore.collection('rooms').doc(roomId).update({
      'memberIds': FieldValue.arrayUnion(userIds),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> removeMembersFromRoom(String roomId, List<String> userIds) async {
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
    await _firestore.collection('rooms').doc(room.id).update(room.toJson());
  }
}
