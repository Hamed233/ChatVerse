import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ChatImageUploader extends StatefulWidget {
  final Function(File image)? onImageSelected;
  final double? size;
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;

  const ChatImageUploader({
    Key? key,
    this.onImageSelected,
    this.size = 40,
    this.icon = Icons.image,
    this.iconColor,
    this.backgroundColor,
  }) : super(key: key);

  @override
  State<ChatImageUploader> createState() => _ChatImageUploaderState();
}

class _ChatImageUploaderState extends State<ChatImageUploader> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        widget.onImageSelected?.call(File(image.path));
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _pickImage,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? Theme.of(context).primaryColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          widget.icon,
          color: widget.iconColor ?? Theme.of(context).primaryColor,
          size: widget.size! * 0.6,
        ),
      ),
    );
  }
}
