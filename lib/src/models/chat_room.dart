import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'message.dart';

enum ChatRoomType {
  individual,
  group,
  channel
}

@immutable
class ChatRoom {
  final String id;
  final String name;
  final String? photoUrl;
  final ChatRoomType type;
  final List<String> memberIds;
  final List<String> adminIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastMessageAt;
  final Message? lastMessage;
  final Map<String, dynamic>? metadata;
  final Map<String, DateTime>? typingUsers;
  final bool isArchived;
  final bool isMuted;

  const ChatRoom({
    required this.id,
    required this.name,
    this.photoUrl,
    required this.type,
    required this.memberIds,
    required this.adminIds,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessageAt,
    this.lastMessage,
    this.metadata,
    this.typingUsers,
    this.isArchived = false,
    this.isMuted = false,
  });

  ChatRoom copyWith({
    String? id,
    String? name,
    String? photoUrl,
    ChatRoomType? type,
    List<String>? memberIds,
    List<String>? adminIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastMessageAt,
    Message? lastMessage,
    Map<String, dynamic>? metadata,
    Map<String, DateTime>? typingUsers,
    bool? isArchived,
    bool? isMuted,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      type: type ?? this.type,
      memberIds: memberIds ?? this.memberIds,
      adminIds: adminIds ?? this.adminIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessage: lastMessage ?? this.lastMessage,
      metadata: metadata ?? this.metadata,
      typingUsers: typingUsers ?? this.typingUsers,
      isArchived: isArchived ?? this.isArchived,
      isMuted: isMuted ?? this.isMuted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'photoUrl': photoUrl,
      'type': type.toString().split('.').last,
      'memberIds': memberIds,
      'adminIds': adminIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (lastMessageAt != null) 'lastMessageAt': Timestamp.fromDate(lastMessageAt!),
      if (lastMessage != null) 'lastMessage': lastMessage!.toMap(),
      if (metadata != null) 'metadata': metadata,
      if (typingUsers != null)
        'typingUsers': typingUsers!.map(
          (key, value) => MapEntry(key, Timestamp.fromDate(value)),
        ),
      'isArchived': isArchived,
      'isMuted': isMuted,
    };
  }

  factory ChatRoom.fromMap(Map<String, dynamic> map) {
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed;
      }
      return DateTime.now();
    }

    Map<String, DateTime>? parseTypingUsers(dynamic value) {
      if (value == null) return null;
      if (value is! Map) return null;

      return Map<String, DateTime>.from(
        value.map((key, value) => MapEntry(key.toString(), parseDateTime(value))),
      );
    }

    return ChatRoom(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      photoUrl: map['photoUrl'],
      type: ChatRoomType.values.firstWhere(
        (e) => e.toString().split('.').last == map['type']?.toString(),
        orElse: () => ChatRoomType.individual,
      ),
      memberIds: List<String>.from(map['memberIds']?.map((e) => e.toString()) ?? []),
      adminIds: List<String>.from(map['adminIds']?.map((e) => e.toString()) ?? []),
      createdAt: parseDateTime(map['createdAt']),
      updatedAt: parseDateTime(map['updatedAt']),
      lastMessageAt: map['lastMessageAt'] != null ? parseDateTime(map['lastMessageAt']) : null,
      lastMessage: map['lastMessage'] != null
          ? Message.fromMap(Map<String, dynamic>.from(map['lastMessage']))
          : null,
      metadata: map['metadata'],
      typingUsers: parseTypingUsers(map['typingUsers']),
      isArchived: map['isArchived'] as bool? ?? false,
      isMuted: map['isMuted'] as bool? ?? false,
    );
  }

  static ChatRoomType parseRoomType(String? type) {
    switch (type?.toLowerCase()) {
      case 'group':
        return ChatRoomType.group;
      case 'channel':
        return ChatRoomType.channel;
      case 'individual':
      default:
        return ChatRoomType.individual;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ChatRoom &&
        other.id == id &&
        other.name == name &&
        other.photoUrl == photoUrl &&
        other.type == type &&
        listEquals(other.memberIds, memberIds) &&
        listEquals(other.adminIds, adminIds) &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.lastMessageAt == lastMessageAt &&
        other.lastMessage == lastMessage &&
        mapEquals(other.metadata, metadata) &&
        mapEquals(other.typingUsers, typingUsers) &&
        other.isArchived == isArchived &&
        other.isMuted == isMuted;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      photoUrl,
      type,
      memberIds,
      adminIds,
      createdAt,
      updatedAt,
      lastMessageAt,
      lastMessage,
      metadata,
      typingUsers,
      isArchived,
      isMuted,
    );
  }

  bool isGroup() => type == ChatRoomType.group;
  bool isChannel() => type == ChatRoomType.channel;
  bool isIndividual() => type == ChatRoomType.individual;

  bool isAdmin(String userId) => adminIds.contains(userId);
  bool isMember(String userId) => memberIds.contains(userId);
}
