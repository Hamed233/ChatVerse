import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/chat_user.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<ChatUser?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    return ChatUser.fromJson(doc.data()!);
  }

  Future<void> createUser(Map<String, dynamic> userData) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user signed in');

    final docRef = _firestore.collection('users').doc(user.uid);
    await docRef.set({
      ...userData,
      'lastSeen': Timestamp.fromDate(userData['lastSeen'] as DateTime),
      'createdAt': Timestamp.fromDate(userData['createdAt'] as DateTime),
    });
  }

  Future<void> updateUserProfile({
    String? name,
    String? photoUrl,
    Map<String, dynamic>? metadata,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No user signed in');

    final updates = <String, dynamic>{
      'lastSeen': Timestamp.now(),
    };
    if (name != null) updates['name'] = name;
    if (photoUrl != null) updates['photoUrl'] = photoUrl;
    if (metadata != null) updates['metadata'] = metadata;

    await _firestore.collection('users').doc(user.uid).update(updates);

    // Also update Firebase Auth profile if needed
    if (name != null || photoUrl != null) {
      await user.updateProfile(
        displayName: name,
        photoURL: photoUrl,
      );
    }
  }

  Future<void> updateOnlineStatus(bool isOnline) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'isOnline': isOnline,
      'lastSeen': Timestamp.now(),
    });
  }

  Stream<List<ChatUser>> getAllUsers() {
    return _firestore
        .collection('users')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              try {
                final data = doc.data();
                data['id'] = doc.id;
                return ChatUser.fromJson(data);
              } catch (e) {
                debugPrint('Error parsing user data: $e');
                return null;
              }
            })
            .where((user) => user != null)
            .cast<ChatUser>()
            .toList());
  }

  Future<void> createOrUpdateUser(User firebaseUser) async {
    final userDoc = _firestore.collection('users').doc(firebaseUser.uid);
    final userData = {
      'id': firebaseUser.uid,
      'name': firebaseUser.displayName ?? 'User',
      'email': firebaseUser.email,
      'photoUrl': firebaseUser.photoURL,
      'isOnline': true,
      'lastSeen': Timestamp.now(),
      'createdAt': FieldValue.serverTimestamp(),
    };

    await userDoc.set(userData, SetOptions(merge: true));
  }

  Future<List<ChatUser>> searchUsers(String query) async {
    final snapshot = await _firestore
        .collection('users')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: query + '\uf8ff')
        .get();

    return snapshot.docs.map((doc) => ChatUser.fromJson(doc.data())).toList();
  }

  // Authentication methods
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      debugPrint('Error signing in: $e');
      rethrow;
    }
  }

  Future<User?> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
  ) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (result.user != null) {
        // Update display name
        await result.user!.updateProfile(displayName: name);
        
        // Create user document
        await createUser({
          'id': result.user!.uid,
          'name': name,
          'email': email,
          'isOnline': true,
          'lastSeen': DateTime.now(),
          'createdAt': DateTime.now(),
        });
      }
      
      return result.user;
    } catch (e) {
      debugPrint('Error registering: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await updateOnlineStatus(false);
      debugPrint('User signed out successfully');
    } catch (e) {
      debugPrint('Error signing out: $e');
      throw Exception('Failed to sign out');
    }
  }
}
