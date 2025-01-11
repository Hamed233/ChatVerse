import 'package:flutter/material.dart';
import '../models/chat_room.dart';
import '../models/chat_user.dart';
import '../chat_controller.dart';
import '../utils/chat_theme.dart';

class GroupDetailsView extends StatefulWidget {
  final ChatRoom room;
  final Map<String, ChatUser> users;
  final String currentUserId;
  final ChatController controller;
  final ChatTheme theme;

  const GroupDetailsView({
    Key? key,
    required this.room,
    required this.users,
    required this.currentUserId,
    required this.controller,
    required this.theme,
  }) : super(key: key);

  @override
  State<GroupDetailsView> createState() => _GroupDetailsViewState();
}

class _GroupDetailsViewState extends State<GroupDetailsView> {
  bool get isAdmin => widget.room.adminIds.contains(widget.currentUserId);

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
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        // Delete the room
        await widget.controller.deleteRoom();
        
        if (!mounted) return;
        
        // Pop to root and show success message
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
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        // Remove current user from the room
        final updatedRoom = ChatRoom(
          id: widget.room.id,
          name: widget.room.name,
          type: widget.room.type,
          photoUrl: widget.room.photoUrl,
          memberIds: widget.room.memberIds.where((id) => id != widget.currentUserId).toList(),
          adminIds: widget.room.adminIds,
          createdAt: widget.room.createdAt,
          updatedAt: DateTime.now(),
          metadata: widget.room.metadata,
        );
        
        await widget.controller.updateRoom(updatedRoom);
        
        if (!mounted) return;
        
        // Pop to root and show success message
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

  Widget _buildMemberTile(String userId) {
    final user = widget.users[userId];
    final isAdmin = widget.room.adminIds.contains(userId);
    
    if (user == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: widget.theme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.theme.primaryColor.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: CircleAvatar(
          backgroundColor: widget.theme.primaryColor.withOpacity(0.1),
          backgroundImage: user.photoUrl != null
              ? NetworkImage(user.photoUrl!)
              : null,
          child: user.photoUrl == null
              ? Text(
                  user.name[0].toUpperCase(),
                  style: TextStyle(
                    color: widget.theme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          user.name,
          style: TextStyle(
            fontWeight: isAdmin ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(user.email ?? ''),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isAdmin)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
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
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final metadata = widget.room.metadata ?? {};
    final bio = metadata['bio'] as String? ?? 'No bio available';
    final createdBy = metadata['createdBy'] as String?;
    final createdAt = metadata['createdAt'] as int?;
    final creator = createdBy != null ? widget.users[createdBy] : null;
    final creationDate = createdAt != null 
        ? DateTime.fromMillisecondsSinceEpoch(createdAt)
        : null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.theme.backgroundColor,
        elevation: 0,
        title: const Text('Group Details'),
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // TODO: Implement edit functionality
              },
            ),
        ],
      ),
      body: ListView(
        children: [
          // Group Image
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: widget.theme.primaryColor.withOpacity(0.1),
                  image: widget.room.photoUrl != null
                      ? DecorationImage(
                          image: NetworkImage(widget.room.photoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: widget.room.photoUrl == null
                    ? Icon(
                        Icons.group,
                        size: 80,
                        color: widget.theme.primaryColor,
                      )
                    : null,
              ),
              if (isAdmin)
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.theme.primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt),
                      color: widget.theme.backgroundColor,
                      onPressed: () {
                        // TODO: Implement image change
                      },
                    ),
                  ),
                ),
            ],
          ),

          // Group Info
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.room.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  bio,
                  style: TextStyle(
                    fontSize: 16,
                    color: widget.theme.textColor.withOpacity(0.7),
                  ),
                ),
                if (creator != null && creationDate != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Created by ${creator.name} on ${_formatDate(creationDate)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.theme.textColor.withOpacity(0.5),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const Divider(),

          // Members Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Members',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: widget.theme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.room.memberIds.length.toString(),
                    style: TextStyle(
                      color: widget.theme.backgroundColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Members List
          ...widget.room.memberIds.map(_buildMemberTile),

          const SizedBox(height: 24),

          // Action Buttons
          if (!isAdmin)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                onPressed: () => _leaveGroup(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Leave Group',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

          if (isAdmin)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                onPressed: () => _deleteGroup(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Delete Group',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
