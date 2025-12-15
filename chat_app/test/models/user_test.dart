import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/models/user.dart';

void main() {
  group('User Model', () {
    test('creates a user with all required fields', () {
      final user = User(
        id: 'user-123',
        username: 'testuser',
        email: 'test@example.com',
        createdAt: DateTime(2024, 1, 1),
        lastSeen: DateTime(2024, 1, 2),
        avatarUrl: 'https://example.com/avatar.jpg',
        bio: 'Test bio',
        updatedAt: DateTime(2024, 1, 3),
      );

      expect(user.id, 'user-123');
      expect(user.username, 'testuser');
      expect(user.email, 'test@example.com');
      expect(user.avatarUrl, 'https://example.com/avatar.jpg');
      expect(user.bio, 'Test bio');
    });

    test('creates a user from JSON', () {
      final json = {
        'id': 'user-123',
        'username': 'testuser',
        'email': 'test@example.com',
        'created_at': '2024-01-01T12:00:00Z',
        'last_seen': '2024-01-02T12:00:00Z',
        'avatar_url': 'https://example.com/avatar.jpg',
        'bio': 'Test bio',
        'updated_at': '2024-01-03T12:00:00Z',
      };

      final user = User.fromJson(json);

      expect(user.id, 'user-123');
      expect(user.username, 'testuser');
      expect(user.email, 'test@example.com');
      expect(user.avatarUrl, 'https://example.com/avatar.jpg');
      expect(user.bio, 'Test bio');
    });

    test('creates a user from JSON with missing optional fields', () {
      final json = {
        'id': 'user-123',
        'username': 'testuser',
      };

      final user = User.fromJson(json);

      expect(user.id, 'user-123');
      expect(user.username, 'testuser');
      expect(user.email, isNull);
      expect(user.avatarUrl, isNull);
      expect(user.bio, isNull);
      expect(user.lastSeen, isNull);
    });

    test('converts user to JSON', () {
      final user = User(
        id: 'user-123',
        username: 'testuser',
        email: 'test@example.com',
        createdAt: DateTime(2024, 1, 1, 12, 0),
        lastSeen: DateTime(2024, 1, 2, 12, 0),
        avatarUrl: 'https://example.com/avatar.jpg',
        bio: 'Test bio',
        updatedAt: DateTime(2024, 1, 3, 12, 0),
      );

      final json = user.toJson();

      expect(json['id'], 'user-123');
      expect(json['username'], 'testuser');
      expect(json['email'], 'test@example.com');
      expect(json['avatar_url'], 'https://example.com/avatar.jpg');
      expect(json['bio'], 'Test bio');
    });

    test('toJson excludes null fields', () {
      final user = User(
        id: 'user-123',
        username: 'testuser',
      );

      final json = user.toJson();

      expect(json.containsKey('email'), false);
      expect(json.containsKey('avatar_url'), false);
      expect(json.containsKey('bio'), false);
    });

    test('copyWith creates a new user with updated fields', () {
      final original = User(
        id: 'user-123',
        username: 'original',
        email: 'original@example.com',
      );

      final updated = original.copyWith(
        username: 'updated',
        bio: 'New bio',
      );

      expect(updated.id, 'user-123');
      expect(updated.username, 'updated');
      expect(updated.email, 'original@example.com');
      expect(updated.bio, 'New bio');
    });

    test('isOnline returns true when lastSeen is within 1 minute', () {
      final now = DateTime.now();
      final user = User(
        id: 'user-123',
        username: 'testuser',
        lastSeen: now.subtract(const Duration(seconds: 30)),
      );

      expect(user.isOnline, true);
    });

    test('isOnline returns false when lastSeen is more than 1 minute ago', () {
      final now = DateTime.now();
      final user = User(
        id: 'user-123',
        username: 'testuser',
        lastSeen: now.subtract(const Duration(minutes: 2)),
      );

      expect(user.isOnline, false);
    });

    test('isOnline returns false when lastSeen is null', () {
      final user = User(
        id: 'user-123',
        username: 'testuser',
      );

      expect(user.isOnline, false);
    });

    test('equality is based on user id', () {
      final user1 = User(
        id: 'user-123',
        username: 'user1',
      );

      final user2 = User(
        id: 'user-123',
        username: 'user2',
      );

      final user3 = User(
        id: 'user-456',
        username: 'user1',
      );

      expect(user1 == user2, true);
      expect(user1 == user3, false);
    });

    test('toString returns formatted string', () {
      final user = User(
        id: 'user-123',
        username: 'testuser',
        email: 'test@example.com',
      );

      final str = user.toString();
      expect(str, contains('user-123'));
      expect(str, contains('testuser'));
      expect(str, contains('test@example.com'));
    });

    test('handles unknown username in JSON', () {
      final json = {
        'id': 'user-123',
      };

      final user = User.fromJson(json);

      expect(user.username, 'Unknown');
    });
  });
}

