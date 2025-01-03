import 'package:flutter/material.dart';
import 'package:chatverse/chatverse.dart';
import 'package:provider/provider.dart';

class CreateGroupScreen extends StatefulWidget {
  final Map<String, ChatUser> users;
  final String currentUserId;

  const CreateGroupScreen({
    Key? key,
    required this.users,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final Set<String> _selectedUsers = {};
  bool _isGroup = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availableUsers = widget.users.entries
        .where((entry) => entry.key != widget.currentUserId)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isGroup ? 'Create Group' : 'New Chat'),
        actions: [
          Switch(
            value: _isGroup,
            onChanged: (value) {
              setState(() {
                _isGroup = value;
                if (!value) {
                  _selectedUsers.clear();
                  _nameController.clear();
                }
              });
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            if (_isGroup) ...[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Group Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.group),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a group name';
                    }
                    return null;
                  },
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Select ${_isGroup ? "Members" : "User"}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: availableUsers.length,
                itemBuilder: (context, index) {
                  final user = availableUsers[index].value;
                  final isSelected = _selectedUsers.contains(user.id);

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(user.photoUrl ?? ''),
                      child: user.photoUrl!.isEmpty
                          ? Text(user.name[0].toUpperCase())
                          : null,
                    ),
                    title: Text(user.name),
                    trailing: _isGroup
                        ? Checkbox(
                            value: isSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedUsers.add(user.id);
                                } else {
                                  _selectedUsers.remove(user.id);
                                }
                              });
                            },
                          )
                        : null,
                    onTap: () {
                      if (_isGroup) {
                        setState(() {
                          if (isSelected) {
                            _selectedUsers.remove(user.id);
                          } else {
                            _selectedUsers.add(user.id);
                          }
                        });
                      } else {
                        _createChat([user.id]);
                      }
                    },
                  );
                },
              ),
            ),
            if (_isGroup)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _selectedUsers.isEmpty
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            _createChat(_selectedUsers.toList());
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Create Group'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _createChat(List<String> memberIds) async {
    final controller = context.read<ChatController>();
    final now = DateTime.now();

    try {
      await controller.createRoom(
        name: _isGroup ? _nameController.text : '',
        memberIds: [widget.currentUserId, ...memberIds],
        type: _isGroup ? ChatRoomType.group : ChatRoomType.individual,
        adminIds: [widget.currentUserId],
        createdAt: now,
        updatedAt: now,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create chat: $e')),
        );
      }
    }
  }
}
