import 'package:flutter/material.dart';
import 'package:chatverse/chatverse.dart';
import 'package:provider/provider.dart';

class CreateGroupScreen extends StatelessWidget {
  final Map<String, ChatUser> users;
  final String currentUserId;
  final ChatController controller;

  const CreateGroupScreen({
    Key? key,
    required this.users,
    required this.currentUserId,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: controller,
      child: _CreateGroupContent(
        users: users,
        currentUserId: currentUserId,
      ),
    );
  }
}

class _CreateGroupContent extends StatefulWidget {
  final Map<String, ChatUser> users;
  final String currentUserId;

  const _CreateGroupContent({
    Key? key,
    required this.users,
    required this.currentUserId,
  }) : super(key: key);

  @override
  _CreateGroupContentState createState() => _CreateGroupContentState();
}

class _CreateGroupContentState extends State<_CreateGroupContent> {
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
        .map((entry) => entry.value)
        .toList();

    return Consumer<ChatController>(
      builder: (context, controller, _) {
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
                if (_isGroup)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Group Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a group name';
                        }
                        return null;
                      },
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: availableUsers.length,
                    itemBuilder: (context, index) {
                      final user = availableUsers[index];
                      final isSelected = _selectedUsers.contains(user.id);

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(user.photoUrl ?? 'https://i.pravatar.cc/150?img=1'),
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
                            // Create individual chat
                            controller
                                .createRoom(
                                  name: user.name,
                                  memberIds: [widget.currentUserId, user.id],
                                  type: ChatRoomType.individual,
                                  adminIds: [widget.currentUserId],
                                  createdAt: DateTime.now(),
                                  updatedAt: DateTime.now()
                                )
                                .then((_) {
                              Navigator.pop(context);
                            });
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: _isGroup
              ? FloatingActionButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate() &&
                        _selectedUsers.isNotEmpty) {
                      final members = [..._selectedUsers, widget.currentUserId];
                      controller
                          .createRoom(
                            name: _nameController.text.trim(),
                            memberIds: members,
                            type: ChatRoomType.group,
                            adminIds: [widget.currentUserId],
                             createdAt: DateTime.now(),
                                  updatedAt: DateTime.now()
                          )
                          .then((_) {
                        Navigator.pop(context);
                      });
                    } else if (_selectedUsers.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select at least one member'),
                        ),
                      );
                    }
                  },
                  child: const Icon(Icons.check),
                )
              : null,
        );
      },
    );
  }
}
