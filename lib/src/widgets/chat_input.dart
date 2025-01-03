import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';
import '../utils/chat_theme.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSendText;
  final Function(String, String?)? onSendImage;
  final Function(String, String)? onSendFile;
  final Function()? onStartTyping;
  final Function()? onStopTyping;
  final ChatTheme theme;

  const ChatInput({
    Key? key,
    required this.onSendText,
    this.onSendImage,
    this.onSendFile,
    this.onStartTyping,
    this.onStopTyping,
    required this.theme,
  }) : super(key: key);

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  bool _showEmoji = false;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (_controller.text.isNotEmpty && !_isTyping) {
      setState(() => _isTyping = true);
      widget.onStartTyping?.call();
    } else if (_controller.text.isEmpty && _isTyping) {
      setState(() => _isTyping = false);
      widget.onStopTyping?.call();
    }
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    widget.onSendText(_controller.text.trim());
    _controller.clear();
    setState(() => _isTyping = false);
    widget.onStopTyping?.call();
  }

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && widget.onSendImage != null) {
      String path = result.files.single.path!;
      widget.onSendImage!(path, _controller.text.trim());
      _controller.clear();
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
    );

    if (result != null && widget.onSendFile != null) {
      String path = result.files.single.path!;
      String name = result.files.single.name;
      widget.onSendFile!(path, name);
    }
  }

  void _insertText(String text) {
    _controller.text = _controller.text + text;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: widget.theme.backgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _showEmoji ? Icons.keyboard : Icons.emoji_emotions_outlined,
                    color: widget.theme.primaryColor,
                  ),
                  onPressed: () {
                    setState(() => _showEmoji = !_showEmoji);
                    if (_showEmoji) {
                      FocusScope.of(context).unfocus();
                    }
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.attach_file,
                    color: widget.theme.primaryColor,
                  ),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.image),
                            title: const Text('Image'),
                            onTap: () {
                              Navigator.pop(context);
                              _pickImage();
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.insert_drive_file),
                            title: const Text('File'),
                            onTap: () {
                              Navigator.pop(context);
                              _pickFile();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Type a message',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: widget.theme.receivedMessageColor.withOpacity(0.3),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.send,
                    color: _controller.text.trim().isEmpty
                        ? Colors.grey
                        : widget.theme.primaryColor,
                  ),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ),
        _showEmoji
          ? SizedBox(
              height: 250,
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  _insertText(emoji.emoji);
                },
                config: Config(
                  columns: 7,
                  emojiSizeMax: 32,
                  verticalSpacing: 0,
                  horizontalSpacing: 0,
                  initCategory: Category.RECENT,
                  bgColor: widget.theme.backgroundColor,
                  indicatorColor: widget.theme.primaryColor,
                  iconColor: widget.theme.iconColor,
                  iconColorSelected: widget.theme.primaryColor,
                  backspaceColor: widget.theme.primaryColor,
                  skinToneDialogBgColor: widget.theme.backgroundColor,
                  skinToneIndicatorColor: widget.theme.primaryColor,
                  enableSkinTones: true,
                  recentsLimit: 28,
                  noRecents: const Text('No Recents'),
                  loadingIndicator: const SizedBox.shrink(),
                  tabIndicatorAnimDuration: kTabScrollDuration,
                  categoryIcons: const CategoryIcons(),
                  buttonMode: ButtonMode.MATERIAL,
                ),
              ),
            )
          : const SizedBox.shrink(),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
