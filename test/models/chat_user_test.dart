import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatverse/chatverse.dart';

void main() {
  group('ChatUser', () {
    test('should create ChatUser instance with required fields', () {
      final user = ChatUser(
        id: 'test_id',
        name: 'Test User',
      );

      expect(user.id, 'test_id');
      expect(user.name, 'Test User');
      expect(user.isOnline, false);
      expect(user.photoUrl, null);
      expect(user.email, null);
      expect(user.lastSeen, null);
      expect(user.metadata, null);
    });

    test('should create ChatUser instance with all fields', () {
      final now = DateTime.now();
      final user = ChatUser(
        id: 'test_id',
        name: 'Test User',
        photoUrl: 'https://example.com/photo.jpg',
        email: 'test@example.com',
        isOnline: true,
        lastSeen: now,
        metadata: {'key': 'value'},
      );

      expect(user.id, 'test_id');
      expect(user.name, 'Test User');
      expect(user.photoUrl, 'https://example.com/photo.jpg');
      expect(user.email, 'test@example.com');
      expect(user.isOnline, true);
      expect(user.lastSeen, now);
      expect(user.metadata, {'key': 'value'});
    });

    test('should create ChatUser from json', () {
      final now = DateTime.now();
      final json = {
        'id': 'test_id',
        'name': 'Test User',
        'photoUrl': 'https://example.com/photo.jpg',
        'email': 'test@example.com',
        'isOnline': true,
        'lastSeen': Timestamp.fromDate(now),
        'metadata': {'key': 'value'},
      };

      final user = ChatUser.fromJson(json);

      expect(user.id, 'test_id');
      expect(user.name, 'Test User');
      expect(user.photoUrl, 'https://example.com/photo.jpg');
      expect(user.email, 'test@example.com');
      expect(user.isOnline, true);
      expect(user.lastSeen?.millisecondsSinceEpoch, 
             now.millisecondsSinceEpoch);
      expect(user.metadata, {'key': 'value'});
    });

    test('should convert ChatUser to json', () {
      final now = DateTime.now();
      final user = ChatUser(
        id: 'test_id',
        name: 'Test User',
        photoUrl: 'https://example.com/photo.jpg',
        email: 'test@example.com',
        isOnline: true,
        lastSeen: now,
        metadata: {'key': 'value'},
      );

      final json = user.toJson();

      expect(json['id'], 'test_id');
      expect(json['name'], 'Test User');
      expect(json['photoUrl'], 'https://example.com/photo.jpg');
      expect(json['email'], 'test@example.com');
      expect(json['isOnline'], true);
      expect((json['lastSeen'] as Timestamp).toDate().millisecondsSinceEpoch,
             now.millisecondsSinceEpoch);
      expect(json['metadata'], {'key': 'value'});
    });

    test('should create copy with updated fields', () {
      final user = ChatUser(
        id: 'test_id',
        name: 'Test User',
      );

      final updatedUser = user.copyWith(
        name: 'Updated User',
        isOnline: true,
      );

      expect(updatedUser.id, 'test_id');
      expect(updatedUser.name, 'Updated User');
      expect(updatedUser.isOnline, true);
      expect(updatedUser.photoUrl, null);
    });
  });
}
