import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import '../../chatverse.dart';
import '../models/chat_user.dart';
import '../models/chat_room.dart';
import '../chat_controller.dart';
import '../utils/chat_theme.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class NewChatView extends StatefulWidget {
  final ChatController controller;
  final ChatTheme theme;
  final Function(String)? onChatCreated;

  const NewChatView({
    Key? key,
    required this.controller,
    required this.theme,
    this.onChatCreated,
  }) : super(key: key);

  @override
  State<NewChatView> createState() => _NewChatViewState();
}

class _NewChatViewState extends State<NewChatView> with SingleTickerProviderStateMixin {
  late TextEditingController _searchController;
  late TabController _tabController;
  Timer? _searchDebounce;
  String _searchQuery = '';
  List<ChatUser> _selectedUsers = [];
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _groupBioController = TextEditingController();
  String? _groupImageUrl;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _searchDebounce?.cancel();
    _groupNameController.dispose();
    _groupBioController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchDebounce?.isActive ?? false) _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  void _toggleUserSelection(ChatUser user) {
    setState(() {
      if (_selectedUsers.contains(user)) {
        _selectedUsers.remove(user);
      } else {
        _selectedUsers.add(user);
      }
    });
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        // Upload image to Firebase Storage
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('group_images')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

        final file = File(pickedFile.path);
        await storageRef.putFile(file);
        final url = await storageRef.getDownloadURL();

        setState(() {
          _groupImageUrl = url;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _createGroupChat() async {
    if (_selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one user')),
      );
      return;
    }

    if (_groupNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }

    try {
      // Create member IDs list including the current user
      final memberIds = [
        widget.controller.userId,
        ..._selectedUsers.map((user) => user.id),
      ];

      // Create metadata with bio
      final metadata = {
        'bio': _groupBioController.text.trim(),
        'createdBy': widget.controller.userId,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };

      // Create the group room
      final room = ChatRoom(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _groupNameController.text.trim(),
        photoUrl: _groupImageUrl,
        type: ChatRoomType.group,
        memberIds: memberIds,
        adminIds: [widget.controller.userId], // Current user is the admin
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        metadata: metadata,
      );

      // Create the room in Firestore
      await widget.controller.createRoom(room);

      // Call the callback if provided
      widget.onChatCreated?.call(room.id);

      if (!mounted) return;

      // Pop the current screen and push the new one
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Provider(
            create: (_) => widget.controller,
            child: ChatView(
              controller: widget.controller,
              room: room,
              currentUserId: widget.controller.userId,
              users: {
                ...Map.fromEntries(_selectedUsers.map((user) => MapEntry(user.id, user))),
                widget.controller.userId: widget.controller.currentUser ?? ChatUser(
                  id: widget.controller.userId,
                  name: 'Me',
                  email: '',
                ),
              },
              theme: widget.theme,
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error creating group: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.theme.backgroundColor,
        title: Text(
          'New Chat',
          style: TextStyle(color: widget.theme.textColor),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: widget.theme.primaryColor,
          unselectedLabelColor: widget.theme.textColor.withOpacity(0.5),
          tabs: const [
            Tab(text: 'Users'),
            Tab(text: 'Group'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUsersList(),
                _buildGroupView(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 1 && _selectedUsers.isNotEmpty
          ? FloatingActionButton(
              onPressed: _createGroupChat,
              backgroundColor: widget.theme.primaryColor,
              child: const Icon(Icons.check),
            )
          : null,
    );
  }

  Widget _buildUsersList() {
    final users = widget.controller.users.where((user) {
      final searchLower = _searchQuery.toLowerCase();
      return user.id != widget.controller.userId &&
          (user.name.toLowerCase().contains(searchLower) ||
              user.email!.toLowerCase().contains(searchLower));
    }).toList();

    if (users.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty ? 'No users found' : 'No matching users',
          style: TextStyle(color: widget.theme.textColor.withOpacity(0.7)),
        ),
      );
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final isSelected = _selectedUsers.contains(user);

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: widget.theme.primaryColor,
            child: Text(
              user.name[0].toUpperCase(),
              style: TextStyle(color: widget.theme.backgroundColor),
            ),
          ),
          title: Text(user.name),
          subtitle: Text(user.email ?? ''),
          trailing: _tabController.index == 1
              ? Checkbox(
                  value: isSelected,
                  onChanged: (_) => _toggleUserSelection(user),
                )
              : null,
          onTap: () {
            if (_tabController.index == 1) {
              _toggleUserSelection(user);
            } else {
              _handleUserTap(user);
            }
          },
        );
      },
    );
  }

  Widget _buildGroupView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: widget.theme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                    image: _groupImageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(_groupImageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _groupImageUrl == null
                      ? Icon(
                          Icons.camera_alt,
                          size: 40,
                          color: widget.theme.primaryColor,
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _groupNameController,
                decoration: InputDecoration(
                  hintText: 'Enter group name',
                  prefixIcon: const Icon(Icons.group),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _groupBioController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter group bio (optional)',
                  prefixIcon: const Icon(Icons.info_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_selectedUsers.isNotEmpty)
          Container(
            height: 90,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedUsers.length,
              itemBuilder: (context, index) {
                final user = _selectedUsers[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: widget.theme.primaryColor,
                            backgroundImage: user.photoUrl != null
                                ? NetworkImage(user.photoUrl!)
                                : null,
                            child: user.photoUrl == null
                                ? Text(
                                    user.name[0].toUpperCase(),
                                    style: TextStyle(
                                      color: widget.theme.backgroundColor,
                                      fontSize: 20,
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            right: -5,
                            top: -5,
                            child: IconButton(
                              icon: const Icon(Icons.remove_circle),
                              color: Colors.red,
                              onPressed: () => _toggleUserSelection(user),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.name.length > 10
                            ? '${user.name.substring(0, 8)}...'
                            : user.name,
                        style: TextStyle(
                          color: widget.theme.textColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        Expanded(
          child: _buildUsersList(),
        ),
      ],
    );
  }

  Future<void> _handleUserTap(ChatUser user) async {
    try {
      // Check if a chat room already exists with this user
      final existingRoom = await widget.controller.findOrCreateRoom(
        otherUserId: user.id,
        type: ChatRoomType.individual,
      );

      if (!mounted) return;

      // Navigate to the chat room
      _navigateToChatRoom(context, existingRoom, user);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _navigateToChatRoom(BuildContext context, ChatRoom room, [ChatUser? otherUser]) async {
    try {
      // Use the controller from props
      final controller = widget.controller;

      // Call the callback if provided
      widget.onChatCreated?.call(room.id);

      if (!mounted) return;

      // Pop the current screen and push the new one
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Provider(
            create: (_) => controller,
            child: ChatView(
              controller: controller,
              room: room,
              currentUserId: controller.userId,
              users: {
                if (otherUser != null) otherUser.id: otherUser,
                controller.userId: controller.currentUser ?? ChatUser(
                  id: controller.userId,
                  name: 'Me',
                  email: '',
                ),
              },
              theme: widget.theme,
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error navigating to chat room: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
