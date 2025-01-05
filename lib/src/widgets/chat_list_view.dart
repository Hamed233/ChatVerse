import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../models/chat_room.dart';
import '../models/chat_user.dart';
import '../chat_controller.dart';
import '../utils/chat_theme.dart';
import 'chat_room_tile.dart';

class ChatListView extends StatefulWidget {
  final Map<String, ChatUser> users;
  final String currentUserId;
  final ChatController controller;
  final void Function(ChatRoom)? onRoomTap;
  final void Function(ChatRoom)? onRoomDelete;
  final Widget Function(BuildContext, ChatRoomType)? emptyBuilder;
  final ChatTheme theme;

  const ChatListView({
    super.key,
    required this.users,
    required this.currentUserId,
    required this.controller,
    this.onRoomTap,
    this.onRoomDelete,
    this.emptyBuilder,
    required this.theme,
  });

  @override
  State<ChatListView> createState() => _ChatListViewState();
}

class _ChatListViewState extends State<ChatListView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showFloatingButton = true;
  bool _isSearching = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  void _onScroll() {
    final ScrollDirection direction =
        _scrollController.position.userScrollDirection;
    final bool shouldShowButton =
        direction == ScrollDirection.idle || direction == ScrollDirection.forward;

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
    super.dispose();
  }

  List<ChatRoom> _filterRooms(List<ChatRoom> rooms, bool isGroup) {
    return rooms
        .where((room) =>
            room.type == (isGroup ? ChatRoomType.group : ChatRoomType.individual))
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
        final otherUser = widget.users[otherUserId];
        return otherUser?.name.toLowerCase().contains(_searchQuery) ?? false;
      }
    }).toList()
      ..sort((a, b) => b.lastMessage!.createdAt.compareTo(a.lastMessage!.createdAt));
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
            type == ChatRoomType.group ? Icons.group : Icons.chat_bubble_outline,
            size: 64,
            color: widget.theme.textColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            type == ChatRoomType.group ? 'No group chats yet' : 'No chats yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: widget.theme.textColor.withOpacity(0.7),
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
          color: widget.theme.backgroundColor,
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
              fillColor: widget.theme.backgroundColor.withOpacity(0.06),
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
        color: widget.theme.backgroundColor,
        border: Border(
          bottom: BorderSide(
            color: widget.theme.textColor.withOpacity(0.1),
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
        labelColor: widget.theme.primaryColor,
        unselectedLabelColor: widget.theme.textColor.withOpacity(0.7),
        indicatorColor: widget.theme.primaryColor,
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
                color: widget.theme.primaryColor,
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

  @override
  Widget build(BuildContext context) {
    final individualChats = _filterRooms(widget.controller.rooms, false);
    final groupChats = _filterRooms(widget.controller.rooms, true);

    return Column(
      children: [
        _buildSearchBar(),
        if (_searchQuery.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: widget.theme.backgroundColor,
            child: Text(
              'Found ${individualChats.length + groupChats.length} results',
              style: TextStyle(
                color: widget.theme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        _buildTabBar(individualChats.length, groupChats.length),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildChatList(individualChats, false),
              _buildChatList(groupChats, true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatList(List<ChatRoom> rooms, bool isGroup) {
    if (rooms.isEmpty) {
      return _buildEmptyState(isGroup ? ChatRoomType.group : ChatRoomType.individual);
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
          users: widget.users,
          theme: widget.theme,
          onTap: () => widget.onRoomTap?.call(room),
          onDelete: () => widget.onRoomDelete?.call(room),
        );
      },
    );
  }
}
