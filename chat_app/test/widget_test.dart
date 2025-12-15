import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/models/message.dart';
import 'package:chat_app/models/user.dart';

void main() {
  group('Critical Functionality Smoke Tests', () {
    test('Message model can be created and serialized', () {
      final message = Message(
        id: 'test-msg',
        senderId: 'user-1',
        receiverId: 'user-2',
        content: 'Test message',
        createdAt: DateTime.now(),
      );

      expect(message.id, 'test-msg');
      expect(message.content, 'Test message');
      
      final json = message.toJson();
      expect(json['sender_id'], 'user-1');
      expect(json['receiver_id'], 'user-2');
    });

    test('User model can be created and serialized', () {
      final user = User(
        id: 'test-user',
        username: 'testuser',
        email: 'test@example.com',
      );

      expect(user.id, 'test-user');
      expect(user.username, 'testuser');
      
      final json = user.toJson();
      expect(json['id'], 'test-user');
      expect(json['username'], 'testuser');
    });

    test('Message equality works correctly', () {
      final msg1 = Message(
        id: 'same-id',
        senderId: 'user-1',
        receiverId: 'user-2',
        content: 'Message 1',
        createdAt: DateTime.now(),
      );

      final msg2 = Message(
        id: 'same-id',
        senderId: 'user-3',
        receiverId: 'user-4',
        content: 'Message 2',
        createdAt: DateTime.now(),
      );

      expect(msg1 == msg2, true);
    });

    test('User online status calculation works', () {
      final onlineUser = User(
        id: 'user-1',
        username: 'test',
        lastSeen: DateTime.now().subtract(const Duration(seconds: 30)),
      );

      final offlineUser = User(
        id: 'user-2',
        username: 'test',
        lastSeen: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      expect(onlineUser.isOnline, true);
      expect(offlineUser.isOnline, false);
    });
  });
}
