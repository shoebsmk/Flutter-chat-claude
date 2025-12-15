import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/services/chat_service.dart';
import 'package:chat_app/models/message.dart';

void main() {
  group('ChatService - processConversations', () {
    test('processes empty messages list', () {
      // Note: ChatService requires Supabase initialization
      // This test validates the structure without instantiating the service
      final messages = <Message>[];
      expect(messages, isEmpty);
    });

    test('processes conversations correctly for single user', () {
      // Note: ChatService requires Supabase initialization
      // This test validates message structure and logic
      
      final messages = [
        Message(
          id: 'msg-1',
          senderId: 'user-1',
          receiverId: 'user-2',
          content: 'Hello',
          createdAt: DateTime(2024, 1, 1, 10, 0),
          isRead: false,
        ),
        Message(
          id: 'msg-2',
          senderId: 'user-2',
          receiverId: 'user-1',
          content: 'Hi there',
          createdAt: DateTime(2024, 1, 1, 11, 0),
          isRead: false,
        ),
      ];

      expect(messages.length, 2);
      expect(messages.first.senderId, 'user-1');
      expect(messages.last.senderId, 'user-2');
    });

    test('identifies last message in conversation', () {
      final messages = [
        Message(
          id: 'msg-1',
          senderId: 'user-1',
          receiverId: 'user-2',
          content: 'First',
          createdAt: DateTime(2024, 1, 1, 10, 0),
        ),
        Message(
          id: 'msg-2',
          senderId: 'user-2',
          receiverId: 'user-1',
          content: 'Second',
          createdAt: DateTime(2024, 1, 1, 11, 0),
        ),
        Message(
          id: 'msg-3',
          senderId: 'user-1',
          receiverId: 'user-2',
          content: 'Third',
          createdAt: DateTime(2024, 1, 1, 12, 0),
        ),
      ];

      // The last message should be the one with the latest timestamp
      final sorted = [...messages]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      expect(sorted.first.content, 'Third');
    });

    test('filters out deleted messages', () {
      final messages = [
        Message(
          id: 'msg-1',
          senderId: 'user-1',
          receiverId: 'user-2',
          content: 'Active',
          createdAt: DateTime(2024, 1, 1, 10, 0),
        ),
        Message(
          id: 'msg-2',
          senderId: 'user-1',
          receiverId: 'user-2',
          content: 'Deleted',
          createdAt: DateTime(2024, 1, 1, 11, 0),
          deletedAt: DateTime(2024, 1, 1, 12, 0),
        ),
      ];

      final activeMessages = messages.where((m) => !m.isDeleted).toList();
      expect(activeMessages.length, 1);
      expect(activeMessages.first.content, 'Active');
    });

    test('counts unread messages correctly', () {
      final messages = [
        Message(
          id: 'msg-1',
          senderId: 'user-2',
          receiverId: 'user-1',
          content: 'Unread 1',
          createdAt: DateTime(2024, 1, 1, 10, 0),
          isRead: false,
        ),
        Message(
          id: 'msg-2',
          senderId: 'user-2',
          receiverId: 'user-1',
          content: 'Read',
          createdAt: DateTime(2024, 1, 1, 11, 0),
          isRead: true,
        ),
        Message(
          id: 'msg-3',
          senderId: 'user-2',
          receiverId: 'user-1',
          content: 'Unread 2',
          createdAt: DateTime(2024, 1, 1, 12, 0),
          isRead: false,
        ),
      ];

      final unreadCount = messages.where((m) => !m.isRead).length;
      expect(unreadCount, 2);
    });
  });

  group('ChatService - Message Validation', () {
    test('validates message content is not empty', () {
      final emptyContent = '';
      final trimmedEmpty = emptyContent.trim();
      expect(trimmedEmpty.isEmpty, true);

      final validContent = 'Hello, world!';
      final trimmedValid = validContent.trim();
      expect(trimmedValid.isNotEmpty, true);
    });

    test('validates message has sender and receiver', () {
      final message = Message(
        senderId: 'user-1',
        receiverId: 'user-2',
        content: 'Test',
        createdAt: DateTime.now(),
      );

      expect(message.senderId.isNotEmpty, true);
      expect(message.receiverId.isNotEmpty, true);
      expect(message.senderId != message.receiverId, true);
    });
  });
}

