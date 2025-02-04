import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String userId;

  StorageService({required this.userId});

  Future<String?> uploadFile(File file, String chatRoomId) async {
    try {
      final fileName = path.basename(file.path);
      final extension = path.extension(fileName);
      final uniqueId = const Uuid().v4();
      final storagePath = 'chats/$chatRoomId/$uniqueId$extension';

      debugPrint('Uploading file: $fileName to $storagePath');

      final ref = _storage.ref().child(storagePath);
      final uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: _getContentType(extension),
          customMetadata: {
            'uploadedBy': userId,
            'originalName': fileName,
          },
        ),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('File uploaded successfully. URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading file: $e');
      return null;
    }
  }

  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.pdf':
        return 'application/pdf';
      case '.doc':
      case '.docx':
        return 'application/msword';
      case '.xls':
      case '.xlsx':
        return 'application/vnd.ms-excel';
      default:
        return 'application/octet-stream';
    }
  }
}
