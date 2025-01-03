import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:file_picker/file_picker.dart';
import '../utils/chat_theme.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final Function(bool)? onTypingStatusChanged;
  final ChatTheme theme;

  const ChatInput({
    super.key,
    required this.onSendMessage,
    this.onTypingStatusChanged,
    this.theme = const ChatTheme(),
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  bool _isComposing = false;
  bool _showEmoji = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final isComposing = _controller.text.isNotEmpty;
    if (isComposing != _isComposing) {
      setState(() => _isComposing = isComposing);
      widget.onTypingStatusChanged?.call(isComposing);
    }
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;
    widget.onSendMessage(text.trim());
    _controller.clear();
    setState(() => _isComposing = false);
    widget.onTypingStatusChanged?.call(false);
  }

  void _insertText(String text) {
    _controller.text = _controller.text + text;
  }

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null) {
      String path = result.files.single.path!;
      widget.onSendMessage(path);
      _controller.clear();
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
    );

    if (result != null) {
      String path = result.files.single.path!;
      widget.onSendMessage(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: widget.theme.inputBackgroundColor,
            border: Border(
              top: BorderSide(
                color: widget.theme.inputBorderColor,
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
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
                      decoration: InputDecoration(
                        hintText: 'Type a message',
                        hintStyle: TextStyle(
                          color: widget.theme.inputHintColor,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: widget.theme.inputFillColor,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      style: TextStyle(
                        color: widget.theme.inputTextColor,
                      ),
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.send,
                      color: _isComposing
                          ? widget.theme.primaryColor
                          : widget.theme.inputIconColor,
                    ),
                    onPressed:
                        _isComposing ? () => _handleSubmitted(_controller.text) : null,
                  ),
                ],
              ),
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
                  bgColor: widget.theme.inputBackgroundColor,
                  indicatorColor: widget.theme.primaryColor,
                  iconColor: widget.theme.iconColor,
                  iconColorSelected: widget.theme.primaryColor,
                  backspaceColor: widget.theme.primaryColor,
                  skinToneDialogBgColor: widget.theme.inputBackgroundColor,
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
