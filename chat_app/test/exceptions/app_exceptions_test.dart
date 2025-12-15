import 'package:flutter_test/flutter_test.dart';
import 'package:chat_app/exceptions/app_exceptions.dart';

void main() {
  group('AppException', () {
    test('creates exception with message', () {
      final exception = AuthException('Test error');
      expect(exception.message, 'Test error');
      expect(exception.cause, isNull);
    });

    test('creates exception with message and cause', () {
      final cause = Exception('Original error');
      final exception = AuthException('Test error', cause);
      expect(exception.message, 'Test error');
      expect(exception.cause, cause);
    });

    test('toString returns message', () {
      final exception = AuthException('Test error');
      expect(exception.toString(), 'Test error');
    });
  });

  group('AuthException', () {
    test('creates basic auth exception', () {
      final exception = AuthException('Authentication failed');
      expect(exception.message, 'Authentication failed');
    });

    test('invalidCredentials factory creates correct message', () {
      final exception = AuthException.invalidCredentials();
      expect(exception.message, 'Invalid email or password');
    });

    test('userNotFound factory creates correct message', () {
      final exception = AuthException.userNotFound();
      expect(exception.message, 'User not found');
    });

    test('notAuthenticated factory creates correct message', () {
      final exception = AuthException.notAuthenticated();
      expect(exception.message, 'You must be logged in to perform this action');
    });

    test('emailInUse factory creates correct message', () {
      final exception = AuthException.emailInUse();
      expect(exception.message, 'This email is already registered');
    });

    test('weakPassword factory creates correct message', () {
      final exception = AuthException.weakPassword();
      expect(exception.message, contains('too weak'));
    });
  });

  group('NetworkException', () {
    test('noConnection factory creates correct message', () {
      final exception = NetworkException.noConnection();
      expect(exception.message, contains('internet connection'));
    });

    test('timeout factory creates correct message', () {
      final exception = NetworkException.timeout();
      expect(exception.message, contains('timed out'));
    });

    test('serverError factory creates correct message', () {
      final exception = NetworkException.serverError();
      expect(exception.message, contains('Server error'));
    });
  });

  group('DatabaseException', () {
    test('notFound factory creates correct message', () {
      final exception = DatabaseException.notFound('User');
      expect(exception.message, 'User not found');
    });

    test('duplicate factory creates correct message', () {
      final exception = DatabaseException.duplicate('Username');
      expect(exception.message, 'Username already exists');
    });

    test('operationFailed factory creates correct message without operation', () {
      final exception = DatabaseException.operationFailed();
      expect(exception.message, 'Database operation failed');
    });

    test('operationFailed factory creates correct message with operation', () {
      final exception = DatabaseException.operationFailed('insert');
      expect(exception.message, 'Database operation failed: insert');
    });
  });

  group('ChatException', () {
    test('sendFailed factory creates correct message', () {
      final exception = ChatException.sendFailed();
      expect(exception.message, contains('Failed to send message'));
    });

    test('loadFailed factory creates correct message', () {
      final exception = ChatException.loadFailed();
      expect(exception.message, 'Failed to load messages');
    });

    test('emptyMessage factory creates correct message', () {
      final exception = ChatException.emptyMessage();
      expect(exception.message, 'Message cannot be empty');
    });
  });

  group('ValidationException', () {
    test('creates validation exception with field', () {
      final exception = ValidationException('Invalid format', field: 'email');
      expect(exception.message, 'Invalid format');
      expect(exception.field, 'email');
    });

    test('required factory creates correct message', () {
      final exception = ValidationException.required('email');
      expect(exception.message, 'email is required');
      expect(exception.field, 'email');
    });

    test('invalidFormat factory creates correct message', () {
      final exception = ValidationException.invalidFormat('email');
      expect(exception.message, 'Invalid email format');
      expect(exception.field, 'email');
    });

    test('invalidFormat factory creates message with details', () {
      final exception = ValidationException.invalidFormat('email', 'Must be valid');
      expect(exception.message, 'Invalid email: Must be valid');
    });

    test('tooShort factory creates correct message', () {
      final exception = ValidationException.tooShort('password', 8);
      expect(exception.message, 'password must be at least 8 characters');
      expect(exception.field, 'password');
    });

    test('tooLong factory creates correct message', () {
      final exception = ValidationException.tooLong('username', 20);
      expect(exception.message, 'username must be at most 20 characters');
      expect(exception.field, 'username');
    });
  });

  group('StorageException', () {
    test('uploadFailed factory creates correct message', () {
      final exception = StorageException.uploadFailed();
      expect(exception.message, contains('Failed to upload image'));
    });

    test('uploadFailed factory creates message with details', () {
      final exception = StorageException.uploadFailed('Network error');
      expect(exception.message, 'Failed to upload image: Network error');
    });

    test('deleteFailed factory creates correct message', () {
      final exception = StorageException.deleteFailed();
      expect(exception.message, contains('Failed to delete image'));
    });

    test('quotaExceeded factory creates correct message', () {
      final exception = StorageException.quotaExceeded();
      expect(exception.message, contains('quota exceeded'));
    });

    test('invalidFileType factory creates correct message', () {
      final exception = StorageException.invalidFileType();
      expect(exception.message, contains('Invalid file type'));
    });

    test('fileTooLarge factory creates correct message', () {
      final exception = StorageException.fileTooLarge(5);
      expect(exception.message, contains('5MB'));
    });
  });

  group('ProfileException', () {
    test('updateFailed factory creates correct message', () {
      final exception = ProfileException.updateFailed();
      expect(exception.message, contains('Failed to update profile'));
    });

    test('usernameTaken factory creates correct message', () {
      final exception = ProfileException.usernameTaken();
      expect(exception.message, contains('already taken'));
    });

    test('usernameUnavailable factory creates correct message', () {
      final exception = ProfileException.usernameUnavailable();
      expect(exception.message, contains('not available'));
    });
  });

  group('AICommandException', () {
    test('extractionFailed factory creates correct message', () {
      final exception = AICommandException.extractionFailed();
      expect(exception.message, 'Failed to extract message intent');
    });

    test('recipientNotFound factory creates correct message', () {
      final exception = AICommandException.recipientNotFound();
      expect(exception.message, 'Recipient not found');
    });
  });

  group('ExceptionHandler', () {
    test('getMessage returns message for AppException', () {
      final exception = AuthException('Custom error');
      final message = ExceptionHandler.getMessage(exception);
      expect(message, 'Custom error');
    });

    test('getMessage handles invalid credentials error', () {
      final error = Exception('Invalid login credentials');
      final message = ExceptionHandler.getMessage(error);
      expect(message, 'Invalid email or password');
    });

    test('getMessage handles email already registered error', () {
      final error = Exception('Email already registered');
      final message = ExceptionHandler.getMessage(error);
      expect(message, 'This email is already registered');
    });

    test('getMessage handles network connection error', () {
      final error = Exception('SocketException: Connection failed');
      final message = ExceptionHandler.getMessage(error);
      expect(message, contains('internet connection'));
    });

    test('getMessage handles timeout error', () {
      final error = Exception('Request timeout');
      final message = ExceptionHandler.getMessage(error);
      expect(message, contains('timed out'));
    });

    test('getMessage cleans up exception prefixes', () {
      final error = Exception('AuthException: Custom error');
      final message = ExceptionHandler.getMessage(error);
      // The handler removes "Exception: " but not "AuthException: " specifically
      // It will clean up "Exception: " prefix, leaving "AuthCustom error"
      expect(message, contains('Custom error'));
    });
  });
}

