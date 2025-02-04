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
  final String senderName;
  final String content;
  final MessageType type;
  final DateTime createdAt;
  final String? replyTo;
  final String? replyToMessageId;
  final bool isRead;
  final bool isDelivered;
  final Map<String, dynamic>? metadata;
  final Map<String, dynamic>? attachments;

  const Message({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.type,
    required this.createdAt,
    this.replyTo,
    this.replyToMessageId,
    this.isRead = false,
    this.isDelivered = false,
    this.metadata,
    this.attachments,
  });

  Message copyWith({
    String? id,
    String? roomId,
    String? senderId,
    String? senderName,
    String? content,
    MessageType? type,
    DateTime? createdAt,
    String? replyTo,
    String? replyToMessageId,
    bool? isRead,
    bool? isDelivered,
    Map<String, dynamic>? metadata,
    Map<String, dynamic>? attachments,
  }) {
    return Message(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      replyTo: replyTo ?? this.replyTo,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      isRead: isRead ?? this.isRead,
      isDelivered: isDelivered ?? this.isDelivered,
      metadata: metadata ?? this.metadata,
      attachments: attachments ?? this.attachments,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'roomId': roomId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'type': type.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      if (replyTo != null) 'replyTo': replyTo,
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
      'isRead': isRead,
      'isDelivered': isDelivered,
      if (metadata != null) 'metadata': metadata,
      if (attachments != null) 'attachments': attachments,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    final createdAtValue = map['createdAt'];
    final DateTime createdAt;
    
    if (createdAtValue is Timestamp) {
      createdAt = createdAtValue.toDate();
    } else if (createdAtValue is String) {
      createdAt = DateTime.parse(createdAtValue);
    } else {
      createdAt = DateTime.now(); // Fallback
    }

    return Message(
      id: map['id']?.toString() ?? '',
      roomId: map['roomId']?.toString() ?? '',
      senderId: map['senderId']?.toString() ?? '',
      senderName: map['senderName']?.toString() ?? 'Unknown User',
      content: map['content']?.toString() ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type']?.toString(),
        orElse: () => MessageType.text,
      ),
      createdAt: createdAt,
      replyTo: map['replyTo']?.toString(),
      replyToMessageId: map['replyToMessageId']?.toString(),
      isRead: map['isRead'] as bool? ?? false,
      isDelivered: map['isDelivered'] as bool? ?? false,
      metadata: map['metadata'] is Map ? Map<String, dynamic>.from(map['metadata']) : null,
      attachments: map['attachments'] is Map ? Map<String, dynamic>.from(map['attachments']) : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message &&
        other.id == id &&
        other.roomId == roomId &&
        other.senderId == senderId &&
        other.senderName == senderName &&
        other.content == content &&
        other.type == type &&
        other.createdAt == createdAt &&
        other.replyTo == replyTo &&
        other.replyToMessageId == replyToMessageId &&
        other.isRead == isRead &&
        other.isDelivered == isDelivered &&
        mapEquals(other.metadata, metadata) &&
        mapEquals(other.attachments, attachments);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      roomId,
      senderId,
      senderName,
      content,
      type,
      createdAt,
      replyTo,
      replyToMessageId,
      isRead,
      isDelivered,
      metadata,
      attachments,
    );
  }
}
