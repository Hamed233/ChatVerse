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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'photoUrl': photoUrl,
      'type': type.toString().split('.').last,
      'memberIds': memberIds,
      'adminIds': adminIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'lastMessage': lastMessage?.toJson(),
      'metadata': metadata,
      'typingUsers': typingUsers?.map(
        (key, value) => MapEntry(key, value.toIso8601String()),
      ),
      'isArchived': isArchived,
      'isMuted': isMuted,
    };
  }

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] as String,
      name: json['name'] as String,
      photoUrl: json['photoUrl'] as String?,
      type: ChatRoomType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => ChatRoomType.individual,
      ),
      memberIds: List<String>.from(json['memberIds'] as List),
      adminIds: List<String>.from(json['adminIds'] as List),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'] as String)
          : null,
      lastMessage: json['lastMessage'] != null
          ? Message.fromJson(json['lastMessage'] as Map<String, dynamic>)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
      typingUsers: json['typingUsers'] != null
          ? Map<String, DateTime>.from(json['typingUsers'] as Map<String, dynamic>).map(
              (key, value) => MapEntry(key, DateTime.parse(value as String)))
          : null,
      isArchived: json['isArchived'] as bool? ?? false,
      isMuted: json['isMuted'] as bool? ?? false,
    );
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
