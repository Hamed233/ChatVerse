import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chatverse/chatverse.dart';

void main() {
  group('Message', () {
    test('should create Message instance with required fields', () {
      final now = DateTime.now();
      final message = Message(
        id: 'test_id',
        senderId: 'sender_id',
        roomId: 'room_id',
        content: 'Hello, world!',
        type: MessageType.text,
        createdAt: now,
      );

      expect(message.id, 'test_id');
      expect(message.senderId, 'sender_id');
      expect(message.roomId, 'room_id');
      expect(message.content, 'Hello, world!');
      expect(message.type, MessageType.text);
      expect(message.createdAt, now);
      expect(message.metadata, null);
      expect(message.replyTo, null);
      expect(message.attachments, null);
    });

    test('should create Message instance with all fields', () {
      final now = DateTime.now();
      final message = Message(
        id: 'test_id',
        senderId: 'sender_id',
        roomId: 'room_id',
        content: 'Hello, world!',
        type: MessageType.text,
        createdAt: now,
        metadata: {'key': 'value', 'status': 'delivered'},
        replyTo: 'original_message_id',
        attachments: {'type': 'image'},
      );

      expect(message.id, 'test_id');
      expect(message.senderId, 'sender_id');
      expect(message.roomId, 'room_id');
      expect(message.content, 'Hello, world!');
      expect(message.type, MessageType.text);
      expect(message.createdAt, now);
      expect(message.metadata, {'key': 'value', 'status': 'delivered'});
      expect(message.replyTo, 'original_message_id');
      expect(message.attachments, {'type': 'image'});
    });

    test('should create Message from json', () {
      final now = DateTime.now();
      final json = {
        'id': 'test_id',
        'senderId': 'sender_id',
        'roomId': 'room_id',
        'content': 'Hello, world!',
        'type': 'text',
        'createdAt': Timestamp.fromDate(now),
        'metadata': {'key': 'value', 'status': 'delivered'},
        'replyTo': 'original_message_id',
        'attachments': {'type': 'image'},
      };

      final message = Message.fromJson(json);

      expect(message.id, 'test_id');
      expect(message.senderId, 'sender_id');
      expect(message.roomId, 'room_id');
      expect(message.content, 'Hello, world!');
      expect(message.type, MessageType.text);
      expect(message.createdAt.millisecondsSinceEpoch,
             now.millisecondsSinceEpoch);
      expect(message.metadata, {'key': 'value', 'status': 'delivered'});
      expect(message.replyTo, 'original_message_id');
      expect(message.attachments, {'type': 'image'});
    });

    test('should convert Message to json', () {
      final now = DateTime.now();
      final message = Message(
        id: 'test_id',
        senderId: 'sender_id',
        roomId: 'room_id',
        content: 'Hello, world!',
        type: MessageType.text,
        createdAt: now,
        metadata: {'key': 'value', 'status': 'delivered'},
        replyTo: 'original_message_id',
        attachments: {'type': 'image'},
      );

      final json = message.toJson();

      expect(json['id'], 'test_id');
      expect(json['senderId'], 'sender_id');
      expect(json['roomId'], 'room_id');
      expect(json['content'], 'Hello, world!');
      expect(json['type'], 'text');
      expect(json['createdAt'], now.toIso8601String());
      expect(json['metadata'], {'key': 'value', 'status': 'delivered'});
      expect(json['replyTo'], 'original_message_id');
      expect(json['attachments'], {'type': 'image'});
    });

    test('should create copy with updated fields', () {
      final now = DateTime.now();
      final message = Message(
        id: 'test_id',
        senderId: 'sender_id',
        roomId: 'room_id',
        content: 'Hello, world!',
        type: MessageType.text,
        createdAt: now,
      );

      final updatedMessage = message.copyWith(
        content: 'Updated content',
        metadata: {'status': 'read'},
      );

      expect(updatedMessage.id, 'test_id');
      expect(updatedMessage.content, 'Updated content');
      expect(updatedMessage.metadata, {'status': 'read'});
      expect(updatedMessage.createdAt, now);
    });

    test('should handle different message types', () {
      final now = DateTime.now();
      final message = Message(
        id: 'test_id',
        senderId: 'sender_id',
        roomId: 'room_id',
        content: 'image_url',
        type: MessageType.image,
        createdAt: now,
        attachments: {'caption': 'Image caption'},
      );

      expect(message.type, MessageType.image);
      expect(message.attachments?['caption'], 'Image caption');
    });
  });
}
