import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  image,
  video,
  audio,
  file,
  custom,
}

@immutable
class Message {
  final String id;
  final String roomId;
  final String senderId;
  final String content;
  final MessageType type;
  final DateTime createdAt;
  final String? replyTo;
  final Map<String, dynamic>? metadata;
  final Map<String, dynamic>? attachments;

  const Message({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    required this.type,
    required this.createdAt,
    this.replyTo,
    this.metadata,
    this.attachments,
  });

  Message copyWith({
    String? id,
    String? roomId,
    String? senderId,
    String? content,
    MessageType? type,
    DateTime? createdAt,
    String? replyTo,
    Map<String, dynamic>? metadata,
    Map<String, dynamic>? attachments,
  }) {
    return Message(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      replyTo: replyTo ?? this.replyTo,
      metadata: metadata ?? this.metadata,
      attachments: attachments ?? this.attachments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomId': roomId,
      'senderId': senderId,
      'content': content,
      'type': type.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      if (replyTo != null) 'replyTo': replyTo,
      if (metadata != null) 'metadata': metadata,
      if (attachments != null) 'attachments': attachments,
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      roomId: json['roomId'] as String,
      senderId: json['senderId'] as String,
      content: json['content'] as String,
      type: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      replyTo: json['replyTo'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      attachments: json['attachments'] as Map<String, dynamic>?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message &&
        other.id == id &&
        other.roomId == roomId &&
        other.senderId == senderId &&
        other.content == content &&
        other.type == type &&
        other.createdAt == createdAt &&
        other.replyTo == replyTo &&
        mapEquals(other.metadata, metadata) &&
        mapEquals(other.attachments, attachments);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      roomId,
      senderId,
      content,
      type,
      createdAt,
      replyTo,
      metadata,
      attachments,
    );
  }
}
