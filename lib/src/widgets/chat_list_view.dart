import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../chatverse.dart';
import '../models/chat_room.dart';
import '../models/chat_user.dart';
import '../chat_controller.dart';
import '../utils/chat_theme.dart';
import 'chat_room_tile.dart';

class ChatListView extends StatefulWidget {
  final String currentUserId;
  final void Function(ChatRoom)? onRoomTap;
  final void Function(ChatRoom)? onRoomDelete;
  final Widget? onSignOutGoTo;
  final Widget Function(BuildContext, ChatRoomType)? emptyBuilder;
  final ChatTheme? theme;

  const ChatListView({
    super.key,
    required this.currentUserId,
    this.onRoomTap,
    this.onRoomDelete,
    this.onSignOutGoTo,
    this.emptyBuilder,
    this.theme,
  });

  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView>
    with SingleTickerProviderStateMixin {
  late ChatController _chatController;
  ChatTheme _theme = ChatTheme();
  late AuthService _authService;
  Map<String, ChatUser> _usersMap = {};

  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showFloatingButton = true;
  bool _isSearching = false;
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    _authService = AuthService();
    _chatController = ChatController(
      userId: widget.currentUserId,
      chatService: ChatService(userId: widget.currentUserId),
      authService: _authService,
    );
    if (widget.theme != null) {
      _theme = widget.theme!;
    }

    // Convert users list to map when controller updates
    _chatController.addListener(_updateUsersMap);
  }

void _onSearchChanged() {
  if (_searchDebounce?.isActive ?? false) _searchDebounce?.cancel();
  _searchDebounce = Timer(const Duration(milliseconds: 300), () {
    // Schedule the state update after the current build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  });
}

  void _onScroll() {
    final ScrollDirection direction =
        _scrollController.position.userScrollDirection;
    final bool shouldShowButton = direction == ScrollDirection.idle ||
        direction == ScrollDirection.forward;

    if (shouldShowButton != _showFloatingButton) {
      setState(() {
        _showFloatingButton = shouldShowButton;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _chatController.removeListener(_updateUsersMap);
    _chatController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _updateUsersMap() {
    setState(() {
      _usersMap = {
        for (var user in _chatController.users) user.id: user,
      };
    });
  }

  List<ChatRoom> _filterRooms(List<ChatRoom> rooms, bool isGroup) {
    return rooms
        .where((room) =>
            room.type ==
            (isGroup ? ChatRoomType.group : ChatRoomType.individual))
        .where((room) => room.lastMessage != null)
        .where((room) {
      if (_searchQuery.isEmpty) return true;

      if (room.type == ChatRoomType.group) {
        return room.name.toLowerCase().contains(_searchQuery);
      } else {
        final otherUserId = room.memberIds.firstWhere(
          (id) => id != widget.currentUserId,
          orElse: () => '',
        );
        final otherUser = _usersMap[otherUserId];
        return otherUser?.name.toLowerCase().contains(_searchQuery) ?? false;
      }
    }).toList()
      ..sort((a, b) =>
          b.lastMessage!.createdAt.compareTo(a.lastMessage!.createdAt));
  }

  Widget _buildEmptyState(ChatRoomType type) {
    if (widget.emptyBuilder != null) {
      return widget.emptyBuilder!(context, type);
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            type == ChatRoomType.group
                ? Icons.group
                : Icons.chat_bubble_outline,
            size: 64,
            color: _theme.textColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            type == ChatRoomType.group ? 'No group chats yet' : 'No chats yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: _theme.textColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildSearchBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 60,
        decoration: BoxDecoration(
          color: _theme.backgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchController,
            onTap: () => setState(() => _isSearching = true),
            decoration: InputDecoration(
              hintText: 'Search chats...',
              prefixIcon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _isSearching
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () {
                          _searchController.clear();
                          FocusScope.of(context).unfocus();
                          setState(() => _isSearching = false);
                        },
                      )
                    : const Icon(Icons.search),
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: _theme.backgroundColor.withOpacity(0.06),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(int individualCount, int groupCount) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: _theme.backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: _theme.textColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        tabs: [
          _buildTab(Icons.chat_bubble_outline, 'Chats', individualCount),
          _buildTab(Icons.group_outlined, 'Groups', groupCount),
        ],
        labelColor: _theme.primaryColor,
        unselectedLabelColor: _theme.textColor.withOpacity(0.7),
        indicatorColor: _theme.primaryColor,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
      ),
    );
  }

  Widget _buildTab(IconData icon, String text, int count) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(text),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _theme.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _navigateToChatScreen(BuildContext context, ChatRoom room) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatView(
          room: room,
          users: _usersMap,
          currentUserId: widget.currentUserId,
          controller: _chatController,
          theme: _theme,
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    try {
      // First try to update online status
      try {
        await _authService.updateOnlineStatus(false);
      } catch (e) {
        // Ignore errors when updating online status
        debugPrint('Warning: Could not update online status: $e');
      }

      // Then sign out
      await _authService.signOut();

      // Navigate to login screen
      if (mounted) {
        if (widget.onSignOutGoTo != null) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => widget.onSignOutGoTo!),
            (route) => false, // Remove all previous routes
          );
        }
      }
    } catch (e) {
      debugPrint('Error signing out: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
    }
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.white,
              radius: 24,
            ),
            title: Container(
              width: double.infinity,
              height: 16,
              color: Colors.white,
            ),
            subtitle: Container(
              width: double.infinity,
              height: 12,
              color: Colors.white,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final individualChats = _filterRooms(_chatController.rooms, false);
    final groupChats = _filterRooms(_chatController.rooms, true);

    return ChangeNotifierProvider.value(
      value: _chatController,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Chats'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _signOut,
            ),
          ],
        ),
        body: Column(
          children: [
            _buildSearchBar(),
            if (_searchQuery.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: _theme.backgroundColor,
                child: Text(
                  'Found ${individualChats.length + groupChats.length} results',
                  style: TextStyle(
                    color: _theme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            _buildTabBar(individualChats.length, groupChats.length),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _chatController.isLoading
                      ? _buildShimmerLoading()
                      : _buildChatList(individualChats, false),
                  _chatController.isLoading
                      ? _buildShimmerLoading()
                      : _buildChatList(groupChats, true),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: NewChatFAB(
          controller: _chatController,
          theme: _theme,
          onChatCreated: (roomId) {
            debugPrint('Chat created with ID: $roomId');
          },
        ),
      ),
    );
  }

  Widget _buildChatList(List<ChatRoom> rooms, bool isGroup) {
    if (rooms.isEmpty) {
      return _buildEmptyState(
          isGroup ? ChatRoomType.group : ChatRoomType.individual);
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: rooms.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final room = rooms[index];
        return ChatRoomTile(
          room: room,
          currentUserId: widget.currentUserId,
          users: _usersMap,
          theme: _theme,
          onTap: () => widget.onRoomTap != null
              ? widget.onRoomTap?.call(room)
              : _navigateToChatScreen(context, room),
          onDelete: () => widget.onRoomDelete?.call(room),
        );
      },
    );
  }
}