import 'package:flutter/material.dart';
import 'package:chatverse/chatverse.dart';
import 'package:provider/provider.dart';

class ChatDetailsScreen extends StatelessWidget {
  final Map<String, ChatUser> users;
  final String currentUserId;

  const ChatDetailsScreen({
    Key? key,
    required this.users,
    required this.currentUserId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatController>(
      builder: (context, controller, _) {
        final room = controller.currentRoom;
        if (room == null) return const SizedBox();

        final isGroup = room.type == ChatRoomType.group;
        final members = room.memberIds
            .map((id) => users[id])
            .where((user) => user != null)
            .cast<ChatUser>()
            .toList();
        final admins =
            room.adminIds.map((id) => users[id]).whereType<ChatUser>().toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Chat Details'),
          ),
          body: ListView(
            children: [
              // Chat Info Section
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (isGroup) ...[
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: const Icon(
                          Icons.group,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        room.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        '${members.length} members',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),

              // Media, Links, and Files Section
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Media, Links, and Files'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // TODO: Implement media gallery
                },
              ),

              const Divider(),

              // Members Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  isGroup ? 'Members' : 'Participant',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              ...members.map((user) => ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(user.photoUrl ?? ''),
                      child: user.photoUrl!.isEmpty
                          ? Text(user.name[0].toUpperCase())
                          : null,
                    ),
                    title: Text(user.name),
                    subtitle: admins.any((admin) => admin.id == user.id)
                        ? const Text(
                            'Admin',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          )
                        : null,
                    trailing: user.id == currentUserId
                        ? const Text('You')
                        : (isGroup && admins.any((admin) => admin.id == currentUserId)
                            ? PopupMenuButton(
                                itemBuilder: (context) => [
                                  if (!admins.any((admin) => admin.id == user.id))
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
                                    // TODO: Implement make admin functionality
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
                                      // TODO: Implement remove member functionality
                                    }
                                  }
                                },
                              )
                            : null),
                  )),

              const Divider(),

              // Actions Section
              if (isGroup && admins.any((admin) => admin.id == currentUserId)) ...[
                ListTile(
                  leading: const Icon(Icons.person_add),
                  title: const Text('Add Members'),
                  onTap: () {
                    // TODO: Implement add members functionality
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Edit Group Name'),
                  onTap: () {
                    // TODO: Implement edit group name functionality
                  },
                ),
              ],

              // Leave/Delete Group
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
                    await controller.deleteRoom();
                    if (context.mounted) {
                      Navigator.of(context)
                        ..pop() // Close details screen
                        ..pop(); // Close chat screen
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
