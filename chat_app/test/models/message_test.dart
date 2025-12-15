import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/models/message.dart';

void main() {
  group('Message Model', () {
    test('creates a message with all required fields', () {
      final message = Message(
        id: 'msg-123',
        senderId: 'user-1',
        receiverId: 'user-2',
        content: 'Hello, world!',
        isRead: false,
        createdAt: DateTime(2024, 1, 1, 12, 0),
      );

      expect(message.id, 'msg-123');
      expect(message.senderId, 'user-1');
      expect(message.receiverId, 'user-2');
      expect(message.content, 'Hello, world!');
      expect(message.isRead, false);
      expect(message.deletedAt, isNull);
    });

    test('creates a message from JSON', () {
      final json = {
        'id': 'msg-123',
        'sender_id': 'user-1',
        'receiver_id': 'user-2',
        'content': 'Test message',
        'is_read': true,
        'created_at': '2024-01-01T12:00:00Z',
        'deleted_at': null,
      };

      final message = Message.fromJson(json);

      expect(message.id, 'msg-123');
      expect(message.senderId, 'user-1');
      expect(message.receiverId, 'user-2');
      expect(message.content, 'Test message');
      expect(message.isRead, true);
      expect(message.deletedAt, isNull);
    });

    test('creates a message from JSON with deleted_at', () {
      final json = {
        'id': 'msg-123',
        'sender_id': 'user-1',
        'receiver_id': 'user-2',
        'content': 'Deleted message',
        'is_read': false,
        'created_at': '2024-01-01T12:00:00Z',
        'deleted_at': '2024-01-01T13:00:00Z',
      };

      final message = Message.fromJson(json);

      expect(message.deletedAt, isNotNull);
      expect(message.isDeleted, true);
    });

    test('converts message to JSON', () {
      final message = Message(
        id: 'msg-123',
        senderId: 'user-1',
        receiverId: 'user-2',
        content: 'Test message',
        isRead: true,
        createdAt: DateTime(2024, 1, 1, 12, 0),
      );

      final json = message.toJson();

      expect(json['id'], 'msg-123');
      expect(json['sender_id'], 'user-1');
      expect(json['receiver_id'], 'user-2');
      expect(json['content'], 'Test message');
      expect(json['is_read'], true);
    });

    test('copyWith creates a new message with updated fields', () {
      final original = Message(
        id: 'msg-123',
        senderId: 'user-1',
        receiverId: 'user-2',
        content: 'Original',
        isRead: false,
        createdAt: DateTime(2024, 1, 1, 12, 0),
      );

      final updated = original.copyWith(
        content: 'Updated',
        isRead: true,
      );

      expect(updated.id, 'msg-123');
      expect(updated.senderId, 'user-1');
      expect(updated.receiverId, 'user-2');
      expect(updated.content, 'Updated');
      expect(updated.isRead, true);
      expect(updated.createdAt, original.createdAt);
    });

    test('isSentBy returns true when message is sent by user', () {
      final message = Message(
        senderId: 'user-1',
        receiverId: 'user-2',
        content: 'Test',
        createdAt: DateTime.now(),
      );

      expect(message.isSentBy('user-1'), true);
      expect(message.isSentBy('user-2'), false);
    });

    test('isReceivedBy returns true when message is received by user', () {
      final message = Message(
        senderId: 'user-1',
        receiverId: 'user-2',
        content: 'Test',
        createdAt: DateTime.now(),
      );

      expect(message.isReceivedBy('user-2'), true);
      expect(message.isReceivedBy('user-1'), false);
    });

    test('getOtherUserId returns receiver when current user is sender', () {
      final message = Message(
        senderId: 'user-1',
        receiverId: 'user-2',
        content: 'Test',
        createdAt: DateTime.now(),
      );

      expect(message.getOtherUserId('user-1'), 'user-2');
    });

    test('getOtherUserId returns sender when current user is receiver', () {
      final message = Message(
        senderId: 'user-1',
        receiverId: 'user-2',
        content: 'Test',
        createdAt: DateTime.now(),
      );

      expect(message.getOtherUserId('user-2'), 'user-1');
    });

    test('isDeleted returns true when deletedAt is not null', () {
      final deletedMessage = Message(
        senderId: 'user-1',
        receiverId: 'user-2',
        content: 'Test',
        createdAt: DateTime.now(),
        deletedAt: DateTime.now(),
      );

      final activeMessage = Message(
        senderId: 'user-1',
        receiverId: 'user-2',
        content: 'Test',
        createdAt: DateTime.now(),
      );

      expect(deletedMessage.isDeleted, true);
      expect(activeMessage.isDeleted, false);
    });

    test('equality is based on message id', () {
      final message1 = Message(
        id: 'msg-123',
        senderId: 'user-1',
        receiverId: 'user-2',
        content: 'Test 1',
        createdAt: DateTime.now(),
      );

      final message2 = Message(
        id: 'msg-123',
        senderId: 'user-3',
        receiverId: 'user-4',
        content: 'Test 2',
        createdAt: DateTime.now(),
      );

      final message3 = Message(
        id: 'msg-456',
        senderId: 'user-1',
        receiverId: 'user-2',
        content: 'Test 1',
        createdAt: DateTime.now(),
      );

      expect(message1 == message2, true);
      expect(message1 == message3, false);
    });

    test('toString returns formatted string', () {
      final message = Message(
        id: 'msg-123',
        senderId: 'user-1',
        receiverId: 'user-2',
        content: 'This is a test message',
        createdAt: DateTime.now(),
      );

      final str = message.toString();
      expect(str, contains('msg-123'));
      expect(str, contains('user-1'));
      expect(str, contains('user-2'));
    });

    test('handles missing optional fields in JSON', () {
      final json = {
        'sender_id': 'user-1',
        'receiver_id': 'user-2',
        'content': 'Test',
      };

      final message = Message.fromJson(json);

      expect(message.id, isNull);
      expect(message.isRead, false);
      expect(message.deletedAt, isNull);
    });
  });
}

