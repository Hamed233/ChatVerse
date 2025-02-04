import 'dart:async';

import 'package:flutter/material.dart';
import '../models/chat_room.dart';
import '../models/chat_user.dart';
import '../chat_controller.dart';
import '../utils/chat_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class GroupDetailsView extends StatefulWidget {
  final ChatRoom room;
  final Map<String, ChatUser> users;
  final ChatController controller;
  final String currentUserId;
  final ChatTheme theme;

  const GroupDetailsView({
    Key? key,
    required this.room,
    required this.users,
    required this.controller,
    required this.currentUserId,
    required this.theme,
  }) : super(key: key);

  @override
  State<GroupDetailsView> createState() => _GroupDetailsViewState();
}

class _GroupDetailsViewState extends State<GroupDetailsView> with SingleTickerProviderStateMixin {
  bool get isAdmin => widget.room.adminIds.contains(widget.currentUserId);
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  bool _isEditing = false;
  bool _isEditingBio = false;
  bool _isSaving = false;
  late TabController _tabController;
  StreamSubscription? _roomSubscription;
  late ChatRoom _currentRoom;

  @override
  void initState() {
    super.initState();
    _currentRoom = widget.room;
    _nameController.text = _currentRoom.name;
    _bioController.text = _currentRoom.bio ?? '';
    _tabController = TabController(length: 2, vsync: this);
    _subscribeToRoomUpdates();
  }

  void _subscribeToRoomUpdates() {
    _roomSubscription?.cancel();
    _roomSubscription = widget.controller.getRoomStream(_currentRoom.id).listen((updatedRoom) {
      if (mounted && updatedRoom != null && updatedRoom.id == _currentRoom.id) {
        setState(() {
          _currentRoom = updatedRoom;
          if (!_isEditing) {
            _nameController.text = updatedRoom.name;
          }
          if (!_isEditingBio) {
            _bioController.text = updatedRoom.bio ?? '';
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _tabController.dispose();
    _roomSubscription?.cancel();
    super.dispose();
  }

  Future<void> _updateGroupPhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image == null) return;

    setState(() => _isSaving = true);
    
    try {
      final file = File(image.path);
      final photoUrl = await widget.controller.uploadGroupPhoto(file);
      
      final updatedRoom = _currentRoom.copyWith(
        photoUrl: photoUrl,
        updatedAt: DateTime.now(),
      );
      
      await widget.controller.updateRoom(updatedRoom);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group photo updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating group photo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _updateGroupName() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group name cannot be empty')),
      );
      return;
    }

    setState(() => _isSaving = true);
    
    try {
      final updatedRoom = _currentRoom.copyWith(
        name: _nameController.text.trim(),
        updatedAt: DateTime.now(),
      );
      
      await widget.controller.updateRoom(updatedRoom);
      
      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group name updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating group name: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _updateGroupBio() async {
    setState(() => _isSaving = true);
    
    try {
      final updatedRoom = _currentRoom.copyWith(
        bio: _bioController.text.trim(),
        updatedAt: DateTime.now(),
      );
      
      await widget.controller.updateRoom(updatedRoom);
      
      if (mounted) {
        setState(() => _isEditingBio = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group bio updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating group bio: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _toggleAdmin(String userId, bool makeAdmin) async {
    try {
      final updatedRoom = _currentRoom.copyWith(
        adminIds: makeAdmin 
            ? [..._currentRoom.adminIds, userId]
            : _currentRoom.adminIds.where((id) => id != userId).toList(),
        updatedAt: DateTime.now(),
      );
      
      await widget.controller.updateRoom(updatedRoom);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              makeAdmin ? 'Admin rights granted' : 'Admin rights removed'
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating admin status: $e')),
        );
      }
    }
  }

  Future<void> _removeMember(String userId) async {
    final user = widget.users[userId];
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Are you sure you want to remove ${user.name} from the group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final updatedRoom = _currentRoom.copyWith(
          memberIds: _currentRoom.memberIds.where((id) => id != userId).toList(),
          adminIds: _currentRoom.adminIds.where((id) => id != userId).toList(),
          updatedAt: DateTime.now(),
        );
        
        await widget.controller.updateRoom(updatedRoom);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${user.name} removed from group')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error removing member: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteGroup(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: const Text(
          'Are you sure you want to delete this group? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await widget.controller.deleteRoom();
        
        if (!mounted) return;
        
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group deleted successfully')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting group: $e')),
        );
      }
    }
  }

  Future<void> _leaveGroup(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text(
          'Are you sure you want to leave this group?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final updatedRoom = _currentRoom.copyWith(
          memberIds: _currentRoom.memberIds.where((id) => id != widget.currentUserId).toList(),
          adminIds: _currentRoom.adminIds.where((id) => id != widget.currentUserId).toList(),
          updatedAt: DateTime.now(),
        );
        
        await widget.controller.updateRoom(updatedRoom);
        
        if (!mounted) return;
        
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Left group successfully')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error leaving group: $e')),
        );
      }
    }
  }

  Future<void> _addMembers() async {
    final List<ChatUser> selectedUsers = await showDialog(
      context: context,
      builder: (context) => AddMembersDialog(
        currentMembers: _currentRoom.memberIds,
        users: widget.users,
        theme: widget.theme,
      ),
    ) ?? [];

    if (selectedUsers.isNotEmpty) {
      try {
        // Get the list of user IDs
        final userIds = selectedUsers.map((u) => u.id).toList();
        
        // Add members using the controller's addMembers method
        await widget.controller.addMembers(userIds);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added ${selectedUsers.length} member(s) to the group'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding members: $e')),
          );
        }
      }
    }
  }

  Widget _buildHeader() {
    print(_currentRoom.photoUrl);
    return Container(
      padding: const EdgeInsets.only(top: 32, bottom: 24),
      decoration: BoxDecoration(
        color: widget.theme.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Hero(
                tag: 'group_photo_${_currentRoom.id}',
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.theme.primaryColor.withOpacity(0.1),
                    border: Border.all(
                      color: widget.theme.primaryColor.withOpacity(0.2),
                      width: 2,
                    ),
                    image: _currentRoom.photoUrl != null
                        ? DecorationImage(
                            image: NetworkImage(_currentRoom.photoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _currentRoom.photoUrl == null
                      ? Icon(
                          Icons.group,
                          size: 60,
                          color: widget.theme.primaryColor,
                        )
                      : null,
                ),
              ),
              if (isAdmin)
                Positioned(
                  right: MediaQuery.of(context).size.width * 0.20,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: _updateGroupPhoto,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.theme.primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: widget.theme.primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: 20,
                        color: widget.theme.backgroundColor,
                      ),
                    ),
                  ),
                ),
          
            ],
          ),
          const SizedBox(height: 20),
          if (_isEditing)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'Enter group name',
                        filled: true,
                        fillColor: widget.theme.primaryColor.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: _isSaving ? null : _updateGroupName,
                    icon: _isSaving
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                widget.theme.primaryColor,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.check_circle,
                            color: widget.theme.primaryColor,
                            size: 28,
                          ),
                  ),
                  IconButton(
                    onPressed: _isSaving
                        ? null
                        : () => setState(() => _isEditing = false),
                    icon: Icon(
                      Icons.cancel,
                      color: Colors.grey,
                      size: 28,
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GestureDetector(
                onTap: isAdmin ? () => setState(() => _isEditing = true) : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        _currentRoom.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (isAdmin)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(
                          Icons.edit,
                          size: 20,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: widget.theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.people,
                      size: 16,
                      color: widget.theme.primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_currentRoom.memberIds.length} members',
                      style: TextStyle(
                        color: widget.theme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBioSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: widget.theme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'About',
                style: TextStyle(
                  color: widget.theme.textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (isAdmin && !_isEditingBio)
                IconButton(
                  onPressed: () => setState(() => _isEditingBio = true),
                  icon: Icon(
                    Icons.edit,
                    color: Colors.grey,
                    size: 20,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isEditingBio)
            Column(
              children: [
                TextField(
                  controller: _bioController,
                  maxLines: 5,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: 'Enter group description...',
                    filled: true,
                    fillColor: widget.theme.primaryColor.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  style: TextStyle(
                    color: widget.theme.textColor,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: _isSaving
                          ? null
                          : () => setState(() => _isEditingBio = false),
                      icon: const Icon(Icons.close),
                      label: const Text('Cancel'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _updateGroupBio,
                      icon: _isSaving
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  widget.theme.backgroundColor,
                                ),
                              ),
                            )
                          : const Icon(Icons.check),
                      label: const Text('Save'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.theme.primaryColor,
                        foregroundColor: widget.theme.backgroundColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.theme.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _currentRoom.bio?.isNotEmpty == true
                    ? _currentRoom.bio!
                    : 'No description available',
                style: TextStyle(
                  color: _currentRoom.bio?.isNotEmpty == true
                      ? widget.theme.textColor
                      : Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(String userId) {
    final user = widget.users[userId];
    final isUserAdmin = _currentRoom.adminIds.contains(userId);
    
    if (user == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: widget.theme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.theme.primaryColor.withOpacity(0.1),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Hero(
          tag: 'avatar_${user.id}',
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.theme.primaryColor.withOpacity(0.1),
              border: Border.all(
                color: widget.theme.primaryColor.withOpacity(0.2),
                width: 2,
              ),
              image: user.photoUrl != null
                  ? DecorationImage(
                      image: NetworkImage(user.photoUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: user.photoUrl == null
                ? Center(
                    child: Text(
                      user.name[0].toUpperCase(),
                      style: TextStyle(
                        color: widget.theme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  )
                : null,
          ),
        ),
        title: Text(
          user.name,
          style: TextStyle(
            fontWeight: isUserAdmin ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user.email != null)
              Text(
                user.email!,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            if (isUserAdmin)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: widget.theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Admin',
                  style: TextStyle(
                    color: widget.theme.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        trailing: isAdmin && userId != widget.currentUserId
            ? PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: Colors.grey,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: isUserAdmin ? 'remove_admin' : 'make_admin',
                    child: Row(
                      children: [
                        Icon(
                          isUserAdmin ? Icons.person_remove : Icons.person_add,
                          size: 20,
                          color: widget.theme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(isUserAdmin ? 'Remove admin' : 'Make admin'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.remove_circle_outline,
                          size: 20,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Remove from group',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'make_admin':
                      _toggleAdmin(userId, true);
                      break;
                    case 'remove_admin':
                      _toggleAdmin(userId, false);
                      break;
                    case 'remove':
                      _removeMember(userId);
                      break;
                  }
                },
              )
            : null,
      ),
    );
  }

  Widget _buildInfoTab() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildBioSection(),
        const Divider(),
        ListTile(
          leading: Icon(
            Icons.calendar_today,
            color: widget.theme.primaryColor,
          ),
          title: const Text('Created'),
          subtitle: Text(
            DateFormat('MMMM d, y').format(_currentRoom.createdAt),
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ),
        if (_currentRoom.updatedAt != _currentRoom.createdAt)
          ListTile(
            leading: Icon(
              Icons.update,
              color: widget.theme.primaryColor,
            ),
            title: const Text('Last Updated'),
            subtitle: Text(
              DateFormat('MMMM d, y').format(_currentRoom.updatedAt),
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMembersTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: widget.theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.people,
                      size: 16,
                      color: widget.theme.primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_currentRoom.memberIds.length} members',
                      style: TextStyle(
                        color: widget.theme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (isAdmin)
                IconButton(
                  onPressed: _addMembers,
                  icon: Icon(
                    Icons.person_add,
                    color: widget.theme.primaryColor,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ..._currentRoom.memberIds.map(_buildMemberTile),
      ],
    );
  }

  Widget _buildActionButtons() {
    if (isAdmin) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildActionButton(
              icon: Icons.delete_forever,
              label: 'Delete Group',
              onPressed: () => _deleteGroup(context),
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            Text(
              'Only group admins can delete the group',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildActionButton(
            icon: Icons.exit_to_app,
            label: 'Leave Group',
            onPressed: () => _leaveGroup(context),
            color: Colors.red,
          ),
        
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: color ?? widget.theme.primaryColor),
      label: Text(
        label,
        style: TextStyle(color: color ?? widget.theme.primaryColor),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: (color ?? widget.theme.primaryColor).withOpacity(0.2),
          ),
        ),
        backgroundColor: (color ?? widget.theme.primaryColor).withOpacity(0.1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Details'),
        backgroundColor: widget.theme.backgroundColor,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(onPressed: () {
          Navigator.pop(context);
        }, icon: Icon(Icons.arrow_back_ios)),
      ),
      body: Column(
        children: [
          _buildHeader(),
          TabBar(
            controller: _tabController,
            labelColor: widget.theme.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: widget.theme.primaryColor,
            tabs: const [
              Tab(text: 'INFO'),
              Tab(text: 'MEMBERS'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInfoTab(),
                _buildMembersTab(),
              ],
            ),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }
}

class AddMembersDialog extends StatefulWidget {
  final List<String> currentMembers;
  final Map<String, ChatUser> users;
  final ChatTheme theme;

  const AddMembersDialog({
    Key? key,
    required this.currentMembers,
    required this.users,
    required this.theme,
  }) : super(key: key);

  @override
  State<AddMembersDialog> createState() => _AddMembersDialogState();
}

class _AddMembersDialogState extends State<AddMembersDialog> {
  final _searchController = TextEditingController();
  final _selectedUsers = <ChatUser>{};
  List<ChatUser> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _updateFilteredUsers('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateFilteredUsers(String query) {
    _filteredUsers = widget.users.values
        .where((user) => 
          !widget.currentMembers.contains(user.id) &&
          (user.name.toLowerCase().contains(query.toLowerCase()) ||
           (user.email?.toLowerCase().contains(query.toLowerCase()) ?? false)))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Add Members',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: widget.theme.textColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search users...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: _updateFilteredUsers,
              ),
            ),
            if (_selectedUsers.isNotEmpty)
              Container(
                height: 60,
                margin: const EdgeInsets.only(top: 16),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: _selectedUsers.map((user) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      avatar: CircleAvatar(
                        backgroundImage: user.photoUrl != null
                            ? NetworkImage(user.photoUrl!)
                            : null,
                        child: user.photoUrl == null
                            ? Text(user.name[0].toUpperCase())
                            : null,
                      ),
                      label: Text(user.name),
                      onDeleted: () => setState(() => _selectedUsers.remove(user)),
                    ),
                  )).toList(),
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: _filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = _filteredUsers[index];
                  final isSelected = _selectedUsers.contains(user);
                  
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: user.photoUrl != null
                          ? NetworkImage(user.photoUrl!)
                          : null,
                      child: user.photoUrl == null
                          ? Text(user.name[0].toUpperCase())
                          : null,
                    ),
                    title: Text(user.name),
                    subtitle: user.email != null ? Text(user.email!) : null,
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle,
                            color: widget.theme.primaryColor,
                          )
                        : Icon(
                            Icons.check_circle_outline,
                            color: Colors.grey,
                          ),
                    onTap: () => setState(() {
                      if (isSelected) {
                        _selectedUsers.remove(user);
                      } else {
                        _selectedUsers.add(user);
                      }
                    }),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _selectedUsers.isEmpty
                        ? null
                        : () => Navigator.of(context).pop(_selectedUsers.toList()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.theme.primaryColor,
                      foregroundColor: widget.theme.backgroundColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text('Add ${_selectedUsers.length} Member${_selectedUsers.length == 1 ? '' : 's'}'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
