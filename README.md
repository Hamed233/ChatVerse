# ChatVerse

A powerful and flexible Flutter chat library that seamlessly integrates with Firebase, providing a complete solution for adding chat functionality to your Flutter applications.

## Features

- 🔥 Firebase Integration
- 💬 Individual & Group Chats
- 🎨 Customizable UI
- 📱 Modern Material Design
- 🔔 Real-time Updates
- 📸 Media Sharing
- 😊 Emoji Support
- 🔗 Link Preview
- ⌨️ Typing Indicators
- ✅ Read Receipts
- 🔄 Online/Offline Status
- 📍 Reply to Messages
- 🗑️ Message Deletion
- 📱 Responsive Design

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  chatverse: ^0.0.1
```

## Firebase Setup

1. Create a new Firebase project
2. Add your Flutter app to the Firebase project
3. Download and add the `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
4. Initialize Firebase in your app:

```dart
await Firebase.initializeApp();
```

## Usage

### Basic Implementation

```dart
import 'package:chatverse/chatverse.dart';

// Initialize ChatController
final chatController = ChatController(userId: 'current_user_id');

// Use ChatView widget
ChatView(
  messages: chatController.messages,
  currentUser: chatController.currentUser!,
  users: users, // Map<String, ChatUser>
  onSendMessage: (String message) {
    chatController.sendMessage(content: message);
  },
  theme: ChatTheme(), // Optional custom theme
);
```

### Creating a Chat Room

```dart
await chatController.createRoom(
  name: 'Group Name',
  memberIds: ['user1', 'user2', 'user3'],
  type: ChatRoomType.group,
);
```

### Sending Messages

```dart
// Send text message
await chatController.sendMessage(content: 'Hello!');

// Send image
await chatController.sendMessage(
  content: imageUrl,
  type: MessageType.image,
  attachments: {'caption': 'Check this out!'},
);
```

### Customizing Theme

```dart
final customTheme = ChatTheme(
  primaryColor: Colors.blue,
  backgroundColor: Colors.white,
  sentMessageColor: Colors.blue,
  receivedMessageColor: Colors.grey[200],
  // ... more customization options
);
```

## Advanced Features

### Group Management

```dart
// Add members
await chatController.addMembers(['user4', 'user5']);

// Remove members
await chatController.removeMembers(['user4']);

// Make admin
await chatController.makeAdmin('user2');
```

### Message Features

```dart
// Delete message
await chatController.deleteMessage('messageId');

// Reply to message
await chatController.sendMessage(
  content: 'Reply message',
  replyTo: 'originalMessageId',
);
```

## Contributing

We welcome contributions! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
