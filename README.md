# ChatVerse 🚀

[![pub package](https://img.shields.io/pub/v/chatverse.svg)](https://pub.dev/packages/chatverse)
[![likes](https://img.shields.io/pub/likes/chatverse?logo=dart)](https://pub.dev/packages/chatverse/score)
[![popularity](https://img.shields.io/pub/popularity/chatverse?logo=dart)](https://pub.dev/packages/chatverse/score)
[![Flutter Platform](https://img.shields.io/badge/Flutter-Platform-yellow.svg)](https://flutter.dev)

A powerful and customizable Flutter chat library with Firebase integration, featuring a beautiful UI, group chat support, and real-time messaging capabilities.

## Demo Video 🎥

<div align="center">
  <video width="400" controls>
    <source src="https://github.com/Hamed233/ChatVerse/raw/main/assets/chatverse_demo.mp4" type="video/mp4">
    Your browser does not support the video tag.
  </video>
</div>

## Features 🌟

- 🔥 **Firebase Integration**: 
  - Built-in support for Firebase Authentication
  - Cloud Firestore for messages and data
  - Firebase Storage for media files
- 💬 **Real-time Messaging**: 
  - Instant message delivery
  - Typing indicators
  - Online/offline status
  - Last seen information
- 👥 **Advanced Group Chat**: 
  - Create and manage group conversations
  - Add/remove members
  - Group avatar support
  - Admin controls
- 📱 **Modern UI/UX**: 
  - Beautiful chat interface
  - Smooth animations
  - Intuitive navigation
  - Date separators
- 📸 **Rich Media Support**: 
  - Send and receive images
  - File sharing capabilities
  - Media preview
- 🎨 **Customization**:
  - Themes (Light/Dark)
  - Custom colors and styles
  - Flexible layout options
- ⚡ **Performance**: 
  - Efficient message loading
  - Optimized media handling
  - Smooth scrolling
- 🌐 **Cross-Platform**: 
  - iOS
  - Android

## Getting Started 🚀

### Prerequisites

1. Set up Firebase in your Flutter project
2. Add the required Firebase dependencies
3. Initialize Firebase in your app

### Installation

Add ChatVerse to your `pubspec.yaml`:

```yaml
dependencies:
  chatverse: ^0.0.4
```

### Basic Usage

1. **Initialize ChatVerse**

```dart
import 'package:chatverse/chatverse.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  runApp(MyApp());
}
```

2. **Set up the Chat Controller**

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ChatController(userId: 'current_user_id'),
        ),
      ],
      child: MaterialApp(
        theme: ChatVerseTheme.light(), // or ChatVerseTheme.dark()
        home: HomeScreen(),
      ),
    );
  }
}
```

3. **Display the Chat View**

```dart
class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ChatView(
        room: chatRoom,
        currentUserId: 'current_user_id',
        theme: ChatVerseTheme.light(),
      ),
    );
  }
}
```

## Advanced Features 🔥

### Group Chat Management

```dart
// Create a new group chat
final group = await chatController.createRoom(
  name: 'Group Name',
  description: 'Group Description', // Optional
  members: selectedUsers,
  type: RoomType.group,
  avatar: selectedImage, // Optional: File object for group avatar
);

// Update group details
await chatController.updateRoom(
  roomId: room.id,
  name: newName,
  description: newDescription,
  avatar: newAvatarFile,
);

// Manage group members
await chatController.addMembers(
  room: currentRoom,
  members: selectedMembers,
  notify: true, // Send system message about new members
);

await chatController.removeMembers(
  room: currentRoom,
  members: membersToRemove,
  notify: true, // Send system message about removed members
);

// Update member roles
await chatController.updateMemberRole(
  room: currentRoom,
  memberId: userId,
  role: MemberRole.admin,
);

// Leave group
await chatController.leaveRoom(
  room: currentRoom,
  notify: true, // Send system message about member leaving
);
```

### Media Handling

```dart
// Send an image message
await chatController.sendMessage(
  room: currentRoom,
  type: MessageType.image,
  file: imageFile, // File object from image picker
  metadata: {
    'width': 800,
    'height': 600,
    'thumbnail': thumbnailUrl, // Optional
  },
  onProgress: (progress) {
    // Handle upload progress
    print('Upload progress: ${progress * 100}%');
  },
);

// Send a file message
await chatController.sendMessage(
  room: currentRoom,
  type: MessageType.file,
  file: pickedFile,
  metadata: {
    'fileName': pickedFile.name,
    'fileSize': await pickedFile.length(),
    'mimeType': lookupMimeType(pickedFile.path),
  },
  onProgress: (progress) {
    // Handle upload progress
    print('Upload progress: ${progress * 100}%');
  },
);

// Handle file downloads
void onFileMessageTap(Message message) async {
  if (message.type == MessageType.file || message.type == MessageType.image) {
    final file = await chatController.downloadFile(
      message.content,
      onProgress: (progress) {
        // Handle download progress
        print('Download progress: ${progress * 100}%');
      },
    );
    
    if (message.type == MessageType.image) {
      // Show image preview
      showImagePreview(context, file);
    } else {
      // Open file using platform-specific method
      OpenFile.open(file.path);
    }
  }
}

// Image/File picker integration
Future<void> pickAndSendImage() async {
  final ImagePicker picker = ImagePicker();
  final XFile? image = await picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: 1920,
    maxHeight: 1080,
    imageQuality: 80,
  );
  
  if (image != null) {
    await chatController.sendMessage(
      room: currentRoom,
      type: MessageType.image,
      file: File(image.path),
    );
  }
}

Future<void> pickAndSendFile() async {
  final result = await FilePicker.platform.pickFiles(
    allowMultiple: false,
    type: FileType.any,
  );
  
  if (result != null && result.files.isNotEmpty) {
    final file = File(result.files.first.path!);
    await chatController.sendMessage(
      room: currentRoom,
      type: MessageType.file,
      file: file,
    );
  }
}
```

## Customization 🎨

ChatVerse provides extensive customization options through themes and style overrides:

```dart
final theme = ChatVerseTheme(
  primaryColor: Colors.blue,
  backgroundColor: Colors.white,
  textColor: Colors.black87,
  // ... other theme properties
);

ChatView(
  theme: theme,
  messageBuilder: (context, message) {
    // Custom message builder
    return CustomMessageBubble(message: message);
  },
  // ... other customization options
)
```

## Contributing 🤝

Contributions are welcome! Please feel free to submit a Pull Request.

## License 📄

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Connect with Me 🌐

- Twitter: [@hamedesam_dev](https://twitter.com/hamedesam_dev)
- GitHub: [hamedessam](https://github.com/Hamed233)

## Acknowledgments 🙏

- Thanks to all contributors who have helped make ChatVerse better
- Special thanks to the Flutter and Firebase teams for their amazing platforms
