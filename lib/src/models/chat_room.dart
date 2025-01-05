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
  final int unreadCount;

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
    this.unreadCount = 0,
  });

  factory ChatRoom.empty() {
    return ChatRoom(
      id: '',
      name: '',
      type: ChatRoomType.individual,
      memberIds: const [],
      adminIds: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

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
    int? unreadCount,
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
      unreadCount: unreadCount ?? this.unreadCount,
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
      'unreadCount': unreadCount,
    };
  }

  factory ChatRoom.fromMap(Map<String, dynamic> map) {
    return ChatRoom(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      type: ChatRoomType.values.firstWhere(
        (e) => e.toString().split('.').last == (map['type'] as String? ?? 'individual'),
        orElse: () => ChatRoomType.individual,
      ),
      memberIds: List<String>.from(map['memberIds'] ?? []),
      adminIds: List<String>.from(map['adminIds'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessageAt: (map['lastMessageAt'] as Timestamp?)?.toDate(),
      lastMessage: map['lastMessage'] != null
          ? Message.fromMap(map['lastMessage'] as Map<String, dynamic>)
          : null,
      metadata: map['metadata'] as Map<String, dynamic>?,
      typingUsers: (map['typingUsers'] as Map<String, dynamic>?)?.map(
        (key, value) => MapEntry(key, (value as Timestamp).toDate()),
      ),
      isArchived: map['isArchived'] as bool? ?? false,
      isMuted: map['isMuted'] as bool? ?? false,
      unreadCount: map['unreadCount'] as int? ?? 0,
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
        other.isMuted == isMuted &&
        other.unreadCount == unreadCount;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      photoUrl,
      type,
      Object.hashAll(memberIds),
      Object.hashAll(adminIds),
      createdAt,
      updatedAt,
      lastMessageAt,
      lastMessage,
      metadata,
      typingUsers,
      isArchived,
      isMuted,
      unreadCount,
    );
  }

  bool isGroup() => type == ChatRoomType.group;
  bool isChannel() => type == ChatRoomType.channel;
  bool isIndividual() => type == ChatRoomType.individual;

  bool isAdmin(String userId) => adminIds.contains(userId);
  bool isMember(String userId) => memberIds.contains(userId);
}
