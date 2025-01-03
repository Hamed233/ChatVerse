import 'package:flutter/material.dart';
import 'package:chatverse/chatverse.dart';
import 'package:provider/provider.dart';

class ChatDetailsScreen extends StatelessWidget {
  final Map<String, ChatUser> users;
  final String currentUserId;
  final ChatController controller;

  const ChatDetailsScreen({
    Key? key,
    required this.users,
    required this.currentUserId,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: controller,
      child: _ChatDetailsContent(
        users: users,
        currentUserId: currentUserId,
      ),
    );
  }
}

class _ChatDetailsContent extends StatefulWidget {
  final Map<String, ChatUser> users;
  final String currentUserId;

  const _ChatDetailsContent({
    Key? key,
    required this.users,
    required this.currentUserId,
  }) : super(key: key);

  @override
  _ChatDetailsContentState createState() => _ChatDetailsContentState();
}

class _ChatDetailsContentState extends State<_ChatDetailsContent> {
  bool _isEditing = false;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _showAddMembersDialog(BuildContext context, ChatController controller, List<ChatUser> currentMembers) async {
    final availableUsers = widget.users.entries
        .where((entry) => !currentMembers.any((member) => member.id == entry.key))
        .map((e) => e.value)
        .toList();

    if (availableUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No more users available to add')),
      );
      return;
    }

    final selectedUsers = <ChatUser>{};

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Members'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableUsers.length,
              itemBuilder: (context, index) {
                final user = availableUsers[index];
                return CheckboxListTile(
                  value: selectedUsers.contains(user),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        selectedUsers.add(user);
                      } else {
                        selectedUsers.remove(user);
                      }
                    });
                  },
                  title: Text(user.name),
                  secondary: CircleAvatar(
                    backgroundImage: user.photoUrl!.isNotEmpty ? NetworkImage(user.photoUrl ?? '') : null,
                    child: user.photoUrl!.isEmpty ? Text(user.name[0].toUpperCase()) : null,
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedUsers.isEmpty
                  ? null
                  : () {
                      final newMemberIds = selectedUsers.map((u) => u.id).toList();
                      controller.addMembers(newMemberIds);
                      Navigator.pop(context);
                    },
              child: const Text('Add Selected'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatController>(
      builder: (context, controller, _) {
        final room = controller.currentRoom;
        if (room == null) return const SizedBox();

        final isGroup = room.type == ChatRoomType.group;
        final members = room.memberIds
            .map((id) => widget.users[id])
            .where((user) => user != null)
            .cast<ChatUser>()
            .toList();
        final admins = room.adminIds
            .map((id) => widget.users[id])
            .whereType<ChatUser>()
            .toList();
        final isAdmin = admins.any((admin) => admin.id == widget.currentUserId);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Chat Details'),
            actions: [
              if (isGroup && isAdmin && !_isEditing)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                      _nameController.text = room.name;
                    });
                  },
                ),
            ],
          ),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Hero(
                        tag: 'chat_${room.id}',
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: isGroup ? Colors.blue : Colors.grey[300],
                          child: isGroup
                              ? const Icon(Icons.group, size: 50, color: Colors.white)
                              : (members.length > 1 && members[1].photoUrl!.isNotEmpty
                                  ? Image.network(members[1].photoUrl!)
                                  : Text(
                                      members.length > 1
                                          ? members[1].name[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(fontSize: 32),
                                    )),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_isEditing) ...[
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Group Name',
                            border: OutlineInputBorder(),
                          ),
                          autofocus: true,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isEditing = false;
                                });
                              },
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: () {
                                final newName = _nameController.text.trim();
                                if (newName.isNotEmpty) {
                                  controller.updateRoom(
                                    room.copyWith(name: newName),
                                  );
                                  setState(() {
                                    _isEditing = false;
                                  });
                                }
                              },
                              child: const Text('Save'),
                            ),
                          ],
                        ),
                      ] else ...[
                        Text(
                          isGroup ? room.name : members[1].name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        '${members.length} ${isGroup ? 'members' : 'participant'}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.photo_library),
                        title: const Text('Media, Links, and Files'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          // TODO: Implement media gallery
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Media gallery coming soon')),
                          );
                        },
                      ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          isGroup ? 'Members' : 'Participant',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final user = members[index];
                    final isCurrentUser = user.id == widget.currentUserId;
                    final isMemberAdmin = admins.any((admin) => admin.id == user.id);

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            user.photoUrl!.isNotEmpty ? NetworkImage(user.photoUrl ?? '') : null,
                        child: user.photoUrl!.isEmpty
                            ? Text(user.name[0].toUpperCase())
                            : null,
                      ),
                      title: Text(
                        isCurrentUser ? '${user.name} (You)' : user.name,
                      ),
                      subtitle: isMemberAdmin
                          ? const Text(
                              'Admin',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            )
                          : null,
                      trailing: isGroup &&
                              isAdmin &&
                              !isCurrentUser &&
                              user.id != widget.currentUserId
                          ? PopupMenuButton(
                              itemBuilder: (context) => [
                                if (!isMemberAdmin)
                                  const PopupMenuItem(
                                    value: 'make_admin',
                                    child: Text('Make Admin'),
                                  ),
                                const PopupMenuItem(
                                  value: 'remove',
                                  child: Text(
                                    'Remove',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                              onSelected: (value) async {
                                if (value == 'make_admin') {
                                  controller.updateRoom(
                                    room.copyWith(
                                      adminIds: [...room.adminIds, user.id],
                                    ),
                                  );
                                } else if (value == 'remove') {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Remove Member'),
                                      content: Text(
                                        'Are you sure you want to remove ${user.name} from the group?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text(
                                            'Remove',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    controller.removeMembers([user.id]);
                                  }
                                }
                              },
                            )
                          : null,
                    );
                  },
                  childCount: members.length,
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const Divider(),
                    if (isGroup && isAdmin)
                      ListTile(
                        leading: const Icon(Icons.person_add),
                        title: const Text('Add Members'),
                        onTap: () => _showAddMembersDialog(context, controller, members),
                      ),
                    ListTile(
                      leading: Icon(
                        isGroup ? Icons.exit_to_app : Icons.delete,
                        color: Colors.red,
                      ),
                      title: Text(
                        isGroup ? 'Leave Group' : 'Delete Chat',
                        style: const TextStyle(color: Colors.red),
                      ),
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(isGroup ? 'Leave Group' : 'Delete Chat'),
                            content: Text(
                              isGroup
                                  ? 'Are you sure you want to leave this group?'
                                  : 'Are you sure you want to delete this chat? This action cannot be undone.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(
                                  isGroup ? 'Leave' : 'Delete',
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true && context.mounted) {
                          if (isGroup) {
                            await controller.removeMembers([widget.currentUserId]);
                          } else {
                            await controller.deleteRoom();
                          }
                          if (context.mounted) {
                            Navigator.of(context)
                              ..pop() // Close details screen
                              ..pop(); // Close chat screen
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
