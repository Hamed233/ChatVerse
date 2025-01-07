import 'package:cloud_firestore/cloud_firestore.dart';

class ChatUser {
  final String id;
  final String name;
  final String? email;
  final String? photoUrl;
  final bool? isOnline;
  final DateTime? lastSeen;
  final DateTime? createdAt;
  final Map<String, dynamic>? metadata;

  ChatUser({
    required this.id,
    required this.name,
    this.email,
    this.photoUrl,
    this.isOnline,
    this.lastSeen,
    this.createdAt,
    this.metadata,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String?,
      photoUrl: json['photoUrl'] as String?,
      isOnline: json['isOnline'] as bool?,
      lastSeen: json['lastSeen'] != null
          ? (json['lastSeen'] as Timestamp).toDate()
          : null,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (email != null) 'email': email,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (isOnline != null) 'isOnline': isOnline,
      if (lastSeen != null) 'lastSeen': Timestamp.fromDate(lastSeen!),
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (metadata != null) 'metadata': metadata,
    };
  }

  ChatUser copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    bool? isOnline,
    DateTime? lastSeen,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
  }) {
    return ChatUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
    );
  }
}
