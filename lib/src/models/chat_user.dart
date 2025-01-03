import 'package:cloud_firestore/cloud_firestore.dart';

class ChatUser {
  final String id;
  final String name;
  final String? photoUrl;
  final String? email;
  final bool isOnline;
  final DateTime? lastSeen;
  final Map<String, dynamic>? metadata;

  ChatUser({
    required this.id,
    required this.name,
    this.photoUrl,
    this.email,
    this.isOnline = false,
    this.lastSeen,
    this.metadata,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id'] as String,
      name: json['name'] as String,
      photoUrl: json['photoUrl'] as String?,
      email: json['email'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeen: json['lastSeen'] != null
          ? (json['lastSeen'] as Timestamp).toDate()
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'photoUrl': photoUrl,
      'email': email,
      'isOnline': isOnline,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'metadata': metadata,
    };
  }

  ChatUser copyWith({
    String? id,
    String? name,
    String? photoUrl,
    String? email,
    bool? isOnline,
    DateTime? lastSeen,
    Map<String, dynamic>? metadata,
  }) {
    return ChatUser(
      id: id ?? this.id,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      email: email ?? this.email,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      metadata: metadata ?? this.metadata,
    );
  }
}
