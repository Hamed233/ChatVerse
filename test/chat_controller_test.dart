import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:chatverse/src/chat_controller.dart';
import 'package:chatverse/src/services/chat_service.dart';
import 'package:chatverse/src/services/auth_service.dart';
import 'package:chatverse/src/models/chat_room.dart';
import 'package:chatverse/src/models/message.dart';
import 'package:chatverse/src/models/chat_user.dart';
import 'dart:async';

@GenerateNiceMocks([
  MockSpec<ChatService>(),
  MockSpec<AuthService>(),
])
import 'chat_controller_test.mocks.dart';

void main() {
  late ChatController controller;
  late MockChatService mockChatService;
  late MockAuthService mockAuthService;
  const String testUserId = 'test-user-id';
  final now = DateTime.now();

  final testUser = ChatUser(
    id: testUserId,
    name: 'Test User',
    photoUrl: 'https://example.com/photo.jpg',
  );

  final testRoom = ChatRoom(
    id: 'test-room-id',
    name: 'Test Room',
    type: ChatRoomType.individual,
    memberIds: [testUserId, 'other-user-id'],
    adminIds: [testUserId],
    createdAt: now,
    updatedAt: now,
  );

  final testMessage = Message(
    id: 'test-message-id',
    roomId: testRoom.id,
    senderId: testUserId,
        senderName: 'sender_name',
    content: 'Hello, World!',
    type: MessageType.text,
    createdAt: now,
  );

  setUp(() {
    mockChatService = MockChatService();
    mockAuthService = MockAuthService();

    // Setup default stubs
    when(mockAuthService.getCurrentUser())
        .thenAnswer((_) async => testUser);
    
    when(mockChatService.getRooms())
        .thenAnswer((_) => Stream.value([testRoom]));
    
    when(mockChatService.getMessages(any))
        .thenAnswer((_) => Stream.value([testMessage]));

    // Setup createRoom mock
    when(mockChatService.createRoom(
      name: anyNamed('name'),
      memberIds: anyNamed('memberIds'),
      type: anyNamed('type'),
      adminIds: anyNamed('adminIds'),
      createdAt: anyNamed('createdAt'),
      updatedAt: anyNamed('updatedAt'),
    )).thenAnswer((_) async => testRoom);

    controller = ChatController(
      userId: testUserId,
      chatService: mockChatService,
      authService: mockAuthService,
    );
  });

  test('initializes with correct values', () {
    expect(controller.currentRoom, isNull);
    expect(controller.messages, isEmpty);
    expect(controller.rooms, isEmpty);
    expect(controller.isLoading, false);
  });

  test('init fetches current user and rooms', () async {
    // Wait for initialization
    await Future.delayed(Duration.zero);
    
    verify(mockAuthService.getCurrentUser()).called(1);
    verify(mockChatService.getRooms()).called(1);
    
    expect(controller.currentUser, equals(testUser));
    expect(controller.rooms, equals([testRoom]));
  });

  test('setting currentRoom updates messages subscription', () async {
    controller.currentRoom = testRoom;
    
    verify(mockChatService.getMessages(testRoom.id)).called(1);
    await Future.delayed(Duration.zero);
    
    expect(controller.messages, equals([testMessage]));
  });

  test('setting currentRoom to null clears messages', () async {
    // First set a room
    controller.currentRoom = testRoom;
    await Future.delayed(Duration.zero);
    expect(controller.messages, isNotEmpty);
    
    // Then clear it
    controller.currentRoom = null;
    expect(controller.messages, isEmpty);
  });

  test('sendMessage calls chat service with correct parameters', () async {
    controller.currentRoom = testRoom;
    
    await controller.sendMessage(
      content: 'Test message',
      type: MessageType.text,
    );

    verify(mockChatService.sendMessage(
      roomId: testRoom.id,
      content: 'Test message',
      type: MessageType.text,
      metadata: null,
      replyTo: null,
      attachments: null,
    )).called(1);
  });

  test('createRoom creates room and sets it as current', () async {
    final newRoom = testRoom.copyWith(
      name: 'New Room',
      type: ChatRoomType.group,
      memberIds: ['user1', 'user2'],
    );

    when(mockChatService.createRoom(
      name: 'New Room',
      memberIds: ['user1', 'user2'],
      type: ChatRoomType.group,
      adminIds: [testUserId],
      createdAt: anyNamed('createdAt'),
      updatedAt: anyNamed('updatedAt'),
    )).thenAnswer((_) async => newRoom);

    // await controller.createRoom(
    //   name: 'New Room',
    //   memberIds: ['user1', 'user2'],
    //   type: ChatRoomType.group,
    // );

    verify(mockChatService.createRoom(
      name: 'New Room',
      memberIds: ['user1', 'user2'],
      type: ChatRoomType.group,
      adminIds: [testUserId],
      createdAt: anyNamed('createdAt'),
      updatedAt: anyNamed('updatedAt'),
    )).called(1);

    expect(controller.currentRoom, equals(newRoom));
  });

  test('typing indicators work correctly', () async {
    controller.currentRoom = testRoom;
    
    controller.startTyping();
    verify(mockChatService.setTyping(testRoom.id, true)).called(1);
    
    // controller.stopTyping();
    verify(mockChatService.setTyping(testRoom.id, false)).called(1);
  });

  test('room operations require current room', () async {
    // Test with no current room
    // await controller.muteRoom(true);
    // await controller.archiveRoom(true);
    await controller.addMembers(['user1']);
    await controller.removeMembers(['user1']);
    await controller.deleteRoom();

    verifyNever(mockChatService.muteRoom(any, any));
    verifyNever(mockChatService.archiveRoom(any, any));
    verifyNever(mockChatService.addMembersToRoom(any, any));
    verifyNever(mockChatService.removeMembersFromRoom(any, any));
    verifyNever(mockChatService.deleteRoom(any));
  });

  test('room operations work with current room', () async {
    controller.currentRoom = testRoom;

    // await controller.muteRoom(true);
    verify(mockChatService.muteRoom(testRoom.id, true)).called(1);

    // await controller.archiveRoom(true);
    verify(mockChatService.archiveRoom(testRoom.id, true)).called(1);

    await controller.addMembers(['user1']);
    verify(mockChatService.addMembersToRoom(testRoom.id, ['user1'])).called(1);

    await controller.removeMembers(['user1']);
    verify(mockChatService.removeMembersFromRoom(testRoom.id, ['user1'])).called(1);

    await controller.deleteRoom();
    verify(mockChatService.deleteRoom(testRoom.id)).called(1);
    expect(controller.currentRoom, isNull);
  });

  test('dispose cancels subscriptions', () {
    controller.dispose();
    // No explicit verification needed as we're testing that no exceptions are thrown
  });
}
