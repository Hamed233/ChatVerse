import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chatverse/chatverse.dart';
import 'package:network_image_mock/network_image_mock.dart';

void main() {
  group('ChatBubble', () {
    testWidgets('should render text message correctly',
        (WidgetTester tester) async {
      final message = Message(
        id: 'test_id',
        senderId: 'sender_id',
        roomId: 'room_id',
        senderName: 'sender_name',

        content: 'Hello, world!',
        type: MessageType.text,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatBubble(
              message: message,
              isCurrentUser: true,
              theme: const ChatTheme(),
            ),
          ),
        ),
      );

      expect(find.text('Hello, world!'), findsOneWidget);
    });

    testWidgets('should render sender name when provided',
        (WidgetTester tester) async {
      final message = Message(
        id: 'test_id',
        senderId: 'sender_id',
        roomId: 'room_id',
        senderName: 'sender_name',

        content: 'Hello, world!',
        type: MessageType.text,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatBubble(
              message: message,
              isCurrentUser: false,
              theme: const ChatTheme(),
              
            ),
          ),
        ),
      );

      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Hello, world!'), findsOneWidget);
    });

    testWidgets('should render image message correctly',
        (WidgetTester tester) async {
      await mockNetworkImagesFor(() async {
        final message = Message(
          id: 'test_id',
          senderId: 'sender_id',
        senderName: 'sender_name',
          roomId: 'room_id',
          content: 'https://via.placeholder.com/150',
          type: MessageType.image,
          createdAt: DateTime.now(),
          attachments: {'caption': 'Test image'},
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChatBubble(
                message: message,
                isCurrentUser: true,
                theme: const ChatTheme(),
              ),
            ),
          ),
        );

        await tester.pump();

        expect(find.byType(Image), findsOneWidget);
        expect(find.text('Test image'), findsOneWidget);
      });
    });

    testWidgets('should handle long press', (WidgetTester tester) async {
      bool longPressed = false;
      final message = Message(
        id: 'test_id',
        senderName: 'sender_name',
        senderId: 'sender_id',
        roomId: 'room_id',
        content: 'Hello, world!',
        type: MessageType.text,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatBubble(
              message: message,
              isCurrentUser: true,
              theme: const ChatTheme(),
              onLongPress: () => longPressed = true,
            ),
          ),
        ),
      );

      await tester.longPress(find.text('Hello, world!'));
      expect(longPressed, true);
    });

    testWidgets('should show message status for current user',
        (WidgetTester tester) async {
      final message = Message(
        id: 'test_id',
        senderId: 'sender_id',
        senderName: 'sender_name',

        roomId: 'room_id',
        content: 'Hello, world!',
        type: MessageType.text,
        createdAt: DateTime.now(),
     
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatBubble(
              message: message,
              isCurrentUser: true,
              theme: const ChatTheme(),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.done_all), findsOneWidget);
    });

    testWidgets('should apply different styles for sent and received messages',
        (WidgetTester tester) async {
      final message = Message(
        id: 'test_id',
        senderId: 'sender_id',
        senderName: 'sender_name',
        roomId: 'room_id',
        content: 'Hello, world!',
        type: MessageType.text,
        createdAt: DateTime.now(),
      );

      // Test sent message
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatBubble(
              message: message,
              isCurrentUser: true,
              theme: const ChatTheme(),
            ),
          ),
        ),
      );

      final sentBubble = find.byType(Container).evaluate().first.widget as Container;
      final sentDecoration = sentBubble.decoration as BoxDecoration;
      expect(sentDecoration.color, const ChatTheme().sentMessageColor);

      // Test received message
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatBubble(
              message: message,
              isCurrentUser: false,
              theme: const ChatTheme(),
            ),
          ),
        ),
      );

      final receivedBubble = find.byType(Container).evaluate().first.widget as Container;
      final receivedDecoration = receivedBubble.decoration as BoxDecoration;
      expect(receivedDecoration.color, const ChatTheme().receivedMessageColor);
    });
  });
}
