import 'dart:io';
import 'package:chatverse/chatverse.dart';
import 'package:flutter/material.dart';
import '../models/chat_user.dart';
import 'chat_image_uploader.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';

class UserDetailsWidget extends StatefulWidget {
  final ChatUser user;
  final Function(ChatUser)? onUserUpdated;
  final bool isEditable;

  const UserDetailsWidget({
    Key? key,
    required this.user,
    this.onUserUpdated,
    this.isEditable = true,
  }) : super(key: key);

  @override
  State<UserDetailsWidget> createState() => _UserDetailsWidgetState();
}

class _UserDetailsWidgetState extends State<UserDetailsWidget> {
  late TextEditingController _nameController;
  bool _isLoading = false;
  File? _selectedImage;
  String? _currentPhotoUrl;
  final _formKey = GlobalKey<FormState>();
  final theme = ChatTheme();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _currentPhotoUrl = widget.user.photoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<String?> _uploadImage(String userId, File imageFile) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('user_images')
          .child('$userId.jpg');
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String? photoUrl = _currentPhotoUrl;

      if (_selectedImage != null) {
        photoUrl = await _uploadImage(widget.user.id, _selectedImage!);
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updateProfile(
          displayName: _nameController.text.trim(),
          photoURL: photoUrl,
        );
      }

      final userDoc = {
        'name': _nameController.text.trim(),
        'photoUrl': photoUrl,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.id)
          .update(userDoc);

      final updatedUser = ChatUser(
        id: widget.user.id,
        name: _nameController.text.trim(),
        email: widget.user.email,
        photoUrl: photoUrl,
        isOnline: widget.user.isOnline,
        lastSeen: widget.user.lastSeen,
        createdAt: widget.user.createdAt,
      );

      widget.onUserUpdated?.call(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: theme.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to update profile'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: theme.primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 8),
                 Icon(
                  Icons.edit,
                  size: 20,
                  color: theme.primaryColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor,
                  theme.primaryColor.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        image: _selectedImage != null
                            ? DecorationImage(
                                image: FileImage(_selectedImage!),
                                fit: BoxFit.cover,
                              )
                            : _currentPhotoUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(_currentPhotoUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                      ),
                      child:
                          (_selectedImage == null && _currentPhotoUrl == null)
                              ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.white,
                                )
                              : null,
                    ),
                    if (widget.isEditable)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: ChatImageUploader(
                          size: 40,
                          icon: Icons.camera_alt,
                          backgroundColor: Colors.white,
                          iconColor: theme.primaryColor,
                          onImageSelected: (File image) {
                            setState(() {
                              _selectedImage = image;
                            });
                          },
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  widget.user.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.user.email ?? '',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (widget.isEditable) ...[
            _buildInfoCard(
              title: 'Display Name',
              value: _nameController.text,
              icon: Icons.person_outline,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Edit Name'),
                    content: TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel',
                            style: TextStyle(color: theme.primaryColor)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            Navigator.pop(context);
                            _updateProfile();
                          }
                        },
                        child: Text('Save',
                            style: TextStyle(color: theme.primaryColor)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ] else ...[
            _buildInfoCard(
              title: 'Display Name',
              value: widget.user.name,
              icon: Icons.person_outline,
            ),
          ],
          const SizedBox(height: 12),
          _buildInfoCard(
            title: 'Email',
            value: widget.user.email ?? '',
            icon: Icons.email_outlined,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            title: 'Status',
            value: widget.user.isOnline ? 'Online' : 'Offline',
            icon: Icons.circle,
          ),
          const SizedBox(height: 12),
          if (widget.user.createdAt != null)
            _buildInfoCard(
              title: 'Member Since',
              value: DateFormat.yMMMd().format(widget.user.createdAt!),
              icon: Icons.calendar_today_outlined,
            ),
          if (widget.isEditable) ...[
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _updateProfile,
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  foregroundColor: theme.primaryColor),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
