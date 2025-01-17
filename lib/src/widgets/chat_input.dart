import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import '../utils/chat_theme.dart';
import '../services/storage_service.dart';
import '../models/message.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final Function(String, MessageType, Map<String, dynamic>?) onSendMedia;
  final VoidCallback? onTypingStarted;
  final ChatTheme theme;
  final String currentUserId;
  final String roomId;

  const ChatInput({
    super.key,
    required this.onSendMessage,
    required this.onSendMedia,
    this.onTypingStarted,
    required this.theme,
    required this.currentUserId,
    required this.roomId,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  late final StorageService _storageService;
  bool _canSend = false;
  bool _isUploading = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _storageService = StorageService(userId: widget.currentUserId);
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final canSend = _controller.text.trim().isNotEmpty;
    if (canSend != _canSend) {
      setState(() => _canSend = canSend);
    }
    _handleTextChanged(_controller.text);
  }

  void _handleTextChanged(String text) {
    _updateCanSend(text.isNotEmpty);
    if (text.isNotEmpty && widget.onTypingStarted != null) {
      debugPrint('ChatInput: Triggering typing event');
      widget.onTypingStarted!();
    }
  }

  void _handleSend() {
    final message = _controller.text.trim();
    if (message.isNotEmpty) {
      widget.onSendMessage(message);
      _controller.clear();
    }
  }

  Future<void> _showAttachmentOptions() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: widget.theme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  Icon(Icons.photo_library, color: widget.theme.primaryColor),
              title: Text(
                'Photo Gallery',
                style: TextStyle(color: widget.theme.textColor),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading:
                  Icon(Icons.attach_file, color: widget.theme.primaryColor),
              title: Text(
                'Upload File',
                style: TextStyle(color: widget.theme.textColor),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickFile();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (image != null) {
        await _uploadFile(File(image.path), MessageType.image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx'],
      );

      if (result != null && result.files.single.path != null) {
        await _uploadFile(File(result.files.single.path!), MessageType.file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  Future<void> _uploadFile(File file, MessageType type) async {
    setState(() => _isUploading = true);

    try {
      final url = await _storageService.uploadFile(file, widget.roomId);

      if (url != null && mounted) {
        widget.onSendMedia.call(
          url,
          type,
          {
            'fileName': path.basename(file.path),
            'fileSize': await file.length(),
          },
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload file')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _updateCanSend(bool canSend) {
    if (canSend != _canSend) {
      setState(() => _canSend = canSend);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: widget.theme.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: _isUploading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          widget.theme.primaryColor,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.attach_file,
                      color: widget.theme.textColor.withOpacity(0.6),
                    ),
              onPressed: _isUploading ? null : _showAttachmentOptions,
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(
                  color: widget.theme.textColor,
                  fontSize: 16,
                ),
                onChanged: _handleTextChanged,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                    color: widget.theme.textColor.withOpacity(0.5),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: widget.theme.backgroundColor.withOpacity(0.06),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              child: IconButton(
                icon: Icon(
                  Icons.send,
                  color: _canSend
                      ? widget.theme.primaryColor
                      : widget.theme.textColor.withOpacity(0.3),
                ),
                onPressed: _canSend ? _handleSend : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
