# ChatVerse 🚀

[![pub package](https://img.shields.io/pub/v/chatverse.svg)](https://pub.dev/packages/chatverse)
[![likes](https://img.shields.io/pub/likes/chatverse?logo=dart)](https://pub.dev/packages/chatverse/score)
[![popularity](https://img.shields.io/pub/popularity/chatverse?logo=dart)](https://pub.dev/packages/chatverse/score)
[![Flutter Platform](https://img.shields.io/badge/Flutter-Platform-yellow.svg)](https://flutter.dev)

A powerful and customizable Flutter chat library with Firebase integration, featuring a beautiful UI, group chat support, and real-time messaging capabilities.

## Features 🌟

- 🔥 **Firebase Integration**: Built-in support for Firebase Authentication and Cloud Firestore
- 💬 **Real-time Messaging**: Instant message delivery and updates
- 👥 **Group Chat Support**: Create and manage group conversations
- 📱 **Modern UI**: Beautiful and customizable chat interface
- 📸 **Media Support**: Send images, videos, and files
- 🔍 **Message Search**: Search through chat history
- 👤 **User Profiles**: Customizable user profiles with avatars
- ⚡ **Performance Optimized**: Efficient message loading and caching
- 🎨 **Themes**: Support for light and dark themes
- 🌐 **Cross-Platform**: Works on iOS, Android, Web, and Desktop

## Getting Started 🚀

### Prerequisites

1. Set up Firebase in your Flutter project
2. Add the required Firebase dependencies
3. Initialize Firebase in your app

### Installation

Add ChatVerse to your `pubspec.yaml`:

```yaml
dependencies:
  chatverse: ^0.0.1
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

2. **Set up the Chat Provider**

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
        // Your app configuration
      ),
    );
  }
}
```

3. **Display the Chat Screen**

```dart
class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ChatView(
        roomId: 'room_id',
        currentUserId: 'current_user_id',
      ),
    );
  }
}
```

## Advanced Features 🔥

### Group Chat Management

```dart
// Create a new group
final group = await chatController.createRoom(
  name: 'Group Name',
  memberIds: ['user1', 'user2', 'user3'],
  type: ChatRoomType.group,
  adminIds: ['user1'],
);

// Add members to group
await chatController.addMembers(['user4', 'user5']);

// Remove members from group
await chatController.removeMembers(['user2']);
```

### Media Messages

```dart
// Send image message
await chatController.sendMessage(
  content: 'image_url',
  type: MessageType.image,
);

// Send file message
await chatController.sendMessage(
  content: 'file_url',
  type: MessageType.file,
  metadata: {'fileName': 'document.pdf', 'size': '2.5MB'},
);
```

### Message Features

```dart
// Reply to message
await chatController.sendMessage(
  content: 'Reply message',
  replyTo: 'original_message_id',
);

// Delete message
await chatController.deleteMessage('message_id');

// Update message
await chatController.updateMessage(
  messageId: 'message_id',
  content: 'Updated content',
);
```

## Customization 🎨

### Theme Customization

```dart
ChatView(
  theme: ChatTheme(
    primaryColor: Colors.blue,
    secondaryColor: Colors.grey[200],
    userBubbleColor: Colors.blue,
    otherBubbleColor: Colors.grey[300],
    inputBackgroundColor: Colors.white,
    // ... more theme options
  ),
)
```

### Custom Bubble Builder

```dart
ChatView(
  bubbleBuilder: (context, message, isUser) {
    return CustomBubble(
      message: message,
      isUser: isUser,
      // ... your custom bubble implementation
    );
  },
)
```

## Example App 📱

Check out our [example app](example/) for a complete implementation of ChatVerse features.

## Contributing 🤝

Contributions are welcome! Feel free to submit issues and pull requests.

## Connect with Me 🌐

- Twitter: [@hamedesam_dev](https://twitter.com/hamedesam_dev)
- GitHub: [hamedessam](https://github.com/Hamed233)

## License 📄

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments 🙏

- Thanks to all contributors who have helped make ChatVerse better
- Special thanks to the Flutter and Firebase teams for their amazing platforms
