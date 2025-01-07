import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_user.dart';
import '../models/chat_room.dart';
import '../chat_controller.dart';
import '../utils/chat_theme.dart';

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

class _NewChatViewState extends State<NewChatView> {
  final TextEditingController _searchController = TextEditingController();
  List<ChatUser> _searchResults = [];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInitialUsers();
  }

  Future<void> _loadInitialUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('id', isNotEqualTo: widget.controller.userId)
          .limit(20)
          .get();

      setState(() {
        _searchResults = querySnapshot.docs
            .map((doc) => ChatUser.fromJson(doc.data()))
            .toList()
          ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      });
    } catch (e) {
      debugPrint('Error loading users: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchUsers(String query) async {
    if (query == _searchQuery) return;

    setState(() {
      _isLoading = true;
      _searchQuery = query;
    });

    try {
      if (query.isEmpty) {
        await _loadInitialUsers();
        return;
      }

      // Simple query without complex indexing requirements
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('id', isNotEqualTo: widget.controller.userId)
          .get();

      final lowercaseQuery = query.toLowerCase();
      final results = querySnapshot.docs
          .map((doc) => ChatUser.fromJson(doc.data()))
          .where((user) =>
              user.name.toLowerCase().contains(lowercaseQuery) ||
              user.email!.toLowerCase().contains(lowercaseQuery))
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      debugPrint('Error searching users: $e');
      setState(() {
        _searchResults = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createChat(ChatUser user) async {
    try {
      // Create a new chat room
      final room = await widget.controller.createRoom(
        name: user.name,
        memberIds: [user.id, widget.controller.userId],
        type: ChatRoomType.individual,
        adminIds: [widget.controller.userId],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      widget.onChatCreated?.call(room.id);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating chat: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Chat'),
        backgroundColor: widget.theme.backgroundColor,
        elevation: 0,
      ),
      body: Container(
        color: widget.theme.backgroundColor,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
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
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search users...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _searchUsers('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: _searchUsers,
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _searchQuery.isEmpty
                                    ? Icons.people_outline
                                    : Icons.search_off,
                                size: 64,
                                color: Theme.of(context).disabledColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'No users available'
                                    : 'No users found',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: Theme.of(context).disabledColor,
                                    ),
                              ),
                              if (_searchQuery.isEmpty) ...[
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                  ),
                                  child: Text(
                                    'Users will appear here once they register',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .disabledColor
                                              .withOpacity(0.7),
                                        ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final user = _searchResults[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _createChat(user),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Stack(
                                        children: [
                                          CircleAvatar(
                                            radius: 24,
                                            backgroundColor: widget
                                                .theme.primaryColor
                                                .withOpacity(0.1),
                                            backgroundImage: user.photoUrl !=
                                                    null
                                                ? NetworkImage(user.photoUrl!)
                                                : null,
                                            child: user.photoUrl == null
                                                ? Text(
                                                    user.name[0].toUpperCase(),
                                                    style: TextStyle(
                                                      color: widget
                                                          .theme.primaryColor,
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  )
                                                : null,
                                          ),
                                          if (user.isOnline ?? false)
                                            Positioned(
                                              right: 0,
                                              bottom: 0,
                                              child: Container(
                                                width: 12,
                                                height: 12,
                                                decoration: BoxDecoration(
                                                  color: Colors.green,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: widget
                                                        .theme.backgroundColor,
                                                    width: 2,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              user.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              user.email ?? '',
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.color,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.chat_bubble_outline,
                                        color: widget.theme.primaryColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
