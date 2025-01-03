import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatverse/chatverse.dart';

void main() {
  group('ChatRoom', () {
    test('should create ChatRoom instance with required fields', () {
      final now = DateTime.now();
      final room = ChatRoom(
        id: 'test_id',
        name: 'Test Room',
        type: ChatRoomType.individual,
        memberIds: ['user1', 'user2'],
        adminIds: ['user1'],
        createdAt: now,
        updatedAt: now,
      );

      expect(room.id, 'test_id');
      expect(room.name, 'Test Room');
      expect(room.type, ChatRoomType.individual);
      expect(room.memberIds, ['user1', 'user2']);
      expect(room.adminIds, ['user1']);
      expect(room.createdAt, now);
      expect(room.photoUrl, null);
      expect(room.lastMessageAt, null);
      expect(room.metadata, null);
      expect(room.typingUsers, null);
      expect(room.isArchived, false);
      expect(room.isMuted, false);
    });

    test('should create ChatRoom instance with all fields', () {
      final now = DateTime.now();
      final typingUsers = {'user1': now};
      final room = ChatRoom(
        id: 'test_id',
        name: 'Test Room',
        photoUrl: 'https://example.com/photo.jpg',
        type: ChatRoomType.group,
        memberIds: ['user1', 'user2', 'user3'],
        adminIds: ['user1', 'user2'],
        createdAt: now,
        lastMessageAt: now,
        metadata: {'key': 'value'},
        typingUsers: typingUsers,
        isArchived: true,
        isMuted: true,
        updatedAt: now,
      );

      expect(room.id, 'test_id');
      expect(room.name, 'Test Room');
      expect(room.photoUrl, 'https://example.com/photo.jpg');
      expect(room.type, ChatRoomType.group);
      expect(room.memberIds, ['user1', 'user2', 'user3']);
      expect(room.adminIds, ['user1', 'user2']);
      expect(room.createdAt, now);
      expect(room.lastMessageAt, now);
      expect(room.metadata, {'key': 'value'});
      expect(room.typingUsers, typingUsers);
      expect(room.isArchived, true);
      expect(room.isMuted, true);
    });

    test('should create ChatRoom from json', () {
      final now = DateTime.now();
      final json = {
        'id': 'test_id',
        'name': 'Test Room',
        'photoUrl': 'https://example.com/photo.jpg',
        'type': 'ChatRoomType.group',
        'memberIds': ['user1', 'user2', 'user3'],
        'adminIds': ['user1', 'user2'],
        'createdAt': Timestamp.fromDate(now),
        'lastMessageAt': Timestamp.fromDate(now),
        'metadata': {'key': 'value'},
        'typingUsers': {
          'user1': Timestamp.fromDate(now),
        },
        'isArchived': true,
        'isMuted': true,
      };

      final room = ChatRoom.fromJson(json);

      expect(room.id, 'test_id');
      expect(room.name, 'Test Room');
      expect(room.photoUrl, 'https://example.com/photo.jpg');
      expect(room.type, ChatRoomType.group);
      expect(room.memberIds, ['user1', 'user2', 'user3']);
      expect(room.adminIds, ['user1', 'user2']);
      expect(room.createdAt.millisecondsSinceEpoch,
             now.millisecondsSinceEpoch);
      expect(room.lastMessageAt?.millisecondsSinceEpoch,
             now.millisecondsSinceEpoch);
      expect(room.metadata, {'key': 'value'});
      expect(room.typingUsers?['user1']?.millisecondsSinceEpoch,
             now.millisecondsSinceEpoch);
      expect(room.isArchived, true);
      expect(room.isMuted, true);
    });

    test('should convert ChatRoom to json', () {
      final now = DateTime.now();
      final room = ChatRoom(
        id: 'test_id',
        name: 'Test Room',
        photoUrl: 'https://example.com/photo.jpg',
        type: ChatRoomType.group,
        memberIds: ['user1', 'user2', 'user3'],
        adminIds: ['user1', 'user2'],
        createdAt: now,
        lastMessageAt: now,
        metadata: {'key': 'value'},
        typingUsers: {'user1': now},
        isArchived: true,
        updatedAt:  DateTime.now(),
        isMuted: true,
      );

      final json = room.toJson();

      expect(json['id'], 'test_id');
      expect(json['name'], 'Test Room');
      expect(json['photoUrl'], 'https://example.com/photo.jpg');
      expect(json['type'], 'ChatRoomType.group');
      expect(json['memberIds'], ['user1', 'user2', 'user3']);
      expect(json['adminIds'], ['user1', 'user2']);
      expect((json['createdAt'] as Timestamp).toDate().millisecondsSinceEpoch,
             now.millisecondsSinceEpoch);
      expect((json['lastMessageAt'] as Timestamp).toDate().millisecondsSinceEpoch,
             now.millisecondsSinceEpoch);
      expect(json['metadata'], {'key': 'value'});
      expect((json['typingUsers']?['user1'] as Timestamp)
             .toDate()
             .millisecondsSinceEpoch,
             now.millisecondsSinceEpoch);
      expect(json['isArchived'], true);
      expect(json['isMuted'], true);
    });

    test('should create copy with updated fields', () {
      final room = ChatRoom(
        id: 'test_id',
        name: 'Test Room',
        type: ChatRoomType.individual,
        memberIds: ['user1', 'user2'],
        adminIds: ['user1'],
        createdAt: DateTime.now(),
        updatedAt:  DateTime.now(),

      );

      final updatedRoom = room.copyWith(
        name: 'Updated Room',
        type: ChatRoomType.group,
        memberIds: ['user1', 'user2', 'user3'],
      );

      expect(updatedRoom.id, 'test_id');
      expect(updatedRoom.name, 'Updated Room');
      expect(updatedRoom.type, ChatRoomType.group);
      expect(updatedRoom.memberIds, ['user1', 'user2', 'user3']);
    });

    test('should check room type correctly', () {
      final groupRoom = ChatRoom(
        id: 'group_id',
        name: 'Group Room',
        type: ChatRoomType.group,
        memberIds: ['user1', 'user2', 'user3'],
        adminIds: ['user1'],
        createdAt: DateTime.now(),
        updatedAt:  DateTime.now(),

      );

      final individualRoom = ChatRoom(
        id: 'individual_id',
        name: 'Individual Room',
        type: ChatRoomType.individual,
        memberIds: ['user1', 'user2'],
        adminIds: ['user1'],
        createdAt: DateTime.now(),
        updatedAt:  DateTime.now(),

      );

      final channelRoom = ChatRoom(
        id: 'channel_id',
        name: 'Channel Room',
        type: ChatRoomType.channel,
        memberIds: ['user1', 'user2', 'user3'],
        adminIds: ['user1'],
        createdAt: DateTime.now(),
        updatedAt:  DateTime.now(),

      );

      expect(groupRoom.isGroup(), true);
      expect(groupRoom.isIndividual(), false);
      expect(groupRoom.isChannel(), false);

      expect(individualRoom.isGroup(), false);
      expect(individualRoom.isIndividual(), true);
      expect(individualRoom.isChannel(), false);

      expect(channelRoom.isGroup(), false);
      expect(channelRoom.isIndividual(), false);
      expect(channelRoom.isChannel(), true);
    });

    test('should check admin and member status correctly', () {
      final room = ChatRoom(
        id: 'test_id',
        name: 'Test Room',
        type: ChatRoomType.group,
        memberIds: ['user1', 'user2', 'user3'],
        adminIds: ['user1', 'user2'],
        createdAt: DateTime.now(),
        updatedAt:  DateTime.now(),
      );

      expect(room.isAdmin('user1'), true);
      expect(room.isAdmin('user3'), false);
      expect(room.isMember('user2'), true);
      expect(room.isMember('user4'), false);
    });
  });
}
