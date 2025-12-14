/// Base exception class for all app-specific exceptions.
abstract class AppException implements Exception {
  /// A user-friendly message describing the error.
  final String message;

  /// Optional underlying error that caused this exception.
  final Object? cause;

  const AppException(this.message, [this.cause]);

  @override
  String toString() => message;
}

/// Exception thrown when authentication fails.
class AuthException extends AppException {
  const AuthException(super.message, [super.cause]);

  /// Creates an exception for invalid credentials.
  factory AuthException.invalidCredentials() {
    return const AuthException('Invalid email or password');
  }

  /// Creates an exception for when a user is not found.
  factory AuthException.userNotFound() {
    return const AuthException('User not found');
  }

  /// Creates an exception for when a user is not authenticated.
  factory AuthException.notAuthenticated() {
    return const AuthException('You must be logged in to perform this action');
  }

  /// Creates an exception for when email is already in use.
  factory AuthException.emailInUse() {
    return const AuthException('This email is already registered');
  }

  /// Creates an exception for weak password.
  factory AuthException.weakPassword() {
    return const AuthException(
      'Password is too weak. Please use a stronger password',
    );
  }
}

/// Exception thrown when a network operation fails.
class NetworkException extends AppException {
  const NetworkException(super.message, [super.cause]);

  /// Creates an exception for no internet connection.
  factory NetworkException.noConnection() {
    return const NetworkException(
      'No internet connection. Please check your network settings',
    );
  }

  /// Creates an exception for a timeout.
  factory NetworkException.timeout() {
    return const NetworkException('Request timed out. Please try again');
  }

  /// Creates an exception for server errors.
  factory NetworkException.serverError() {
    return const NetworkException('Server error. Please try again later');
  }
}

/// Exception thrown when a database operation fails.
class DatabaseException extends AppException {
  const DatabaseException(super.message, [super.cause]);

  /// Creates an exception for when a record is not found.
  factory DatabaseException.notFound(String entity) {
    return DatabaseException('$entity not found');
  }

  /// Creates an exception for duplicate records.
  factory DatabaseException.duplicate(String entity) {
    return DatabaseException('$entity already exists');
  }

  /// Creates an exception for general database errors.
  factory DatabaseException.operationFailed([String? operation]) {
    final msg = operation != null
        ? 'Database operation failed: $operation'
        : 'Database operation failed';
    return DatabaseException(msg);
  }
}

/// Exception thrown when a chat/message operation fails.
class ChatException extends AppException {
  const ChatException(super.message, [super.cause]);

  /// Creates an exception for when sending a message fails.
  factory ChatException.sendFailed() {
    return const ChatException('Failed to send message. Please try again');
  }

  /// Creates an exception for when loading messages fails.
  factory ChatException.loadFailed() {
    return const ChatException('Failed to load messages');
  }

  /// Creates an exception for empty message content.
  factory ChatException.emptyMessage() {
    return const ChatException('Message cannot be empty');
  }
}

/// Exception thrown for validation errors.
class ValidationException extends AppException {
  /// The field that failed validation.
  final String? field;

  const ValidationException(String message, {this.field, Object? cause})
    : super(message, cause);

  /// Creates an exception for a required field.
  factory ValidationException.required(String field) {
    return ValidationException('$field is required', field: field);
  }

  /// Creates an exception for an invalid format.
  factory ValidationException.invalidFormat(String field, [String? details]) {
    final msg = details != null
        ? 'Invalid $field: $details'
        : 'Invalid $field format';
    return ValidationException(msg, field: field);
  }

  /// Creates an exception for value too short.
  factory ValidationException.tooShort(String field, int minLength) {
    return ValidationException(
      '$field must be at least $minLength characters',
      field: field,
    );
  }
  
  /// Creates an exception for value too long.
  factory ValidationException.tooLong(String field, int maxLength) {
    return ValidationException(
      '$field must be at most $maxLength characters',
      field: field,
    );
  }
}

/// Exception thrown when a storage operation fails.
class StorageException extends AppException {
  const StorageException(super.message, [super.cause]);

  /// Creates an exception for upload failures.
  factory StorageException.uploadFailed([String? details]) {
    final msg = details != null
        ? 'Failed to upload image: $details'
        : 'Failed to upload image. Please try again';
    return StorageException(msg);
  }

  /// Creates an exception for deletion failures.
  factory StorageException.deleteFailed([String? details]) {
    final msg = details != null
        ? 'Failed to delete image: $details'
        : 'Failed to delete image';
    return StorageException(msg);
  }

  /// Creates an exception for quota exceeded.
  factory StorageException.quotaExceeded() {
    return const StorageException(
      'Storage quota exceeded. Please contact support',
    );
  }

  /// Creates an exception for invalid file type.
  factory StorageException.invalidFileType() {
    return const StorageException(
      'Invalid file type. Please select a JPEG, PNG, or WebP image',
    );
  }

  /// Creates an exception for file too large.
  factory StorageException.fileTooLarge(int maxSizeMB) {
    return StorageException(
      'File is too large. Maximum size is ${maxSizeMB}MB',
    );
  }
}

/// Exception thrown when a profile operation fails.
class ProfileException extends AppException {
  const ProfileException(super.message, [super.cause]);

  /// Creates an exception for update failures.
  factory ProfileException.updateFailed([String? details]) {
    final msg = details != null
        ? 'Failed to update profile: $details'
        : 'Failed to update profile. Please try again';
    return ProfileException(msg);
  }

  /// Creates an exception for username already taken.
  factory ProfileException.usernameTaken() {
    return const ProfileException(
      'Username is already taken. Please choose another',
    );
  }

  /// Creates an exception for username unavailable.
  factory ProfileException.usernameUnavailable() {
    return const ProfileException(
      'Username is not available. Please choose another',
    );
  }
}

/// Utility class for parsing and handling exceptions.
class ExceptionHandler {
  ExceptionHandler._();

  /// Parses an exception and returns a user-friendly message.
  static String getMessage(Object error) {
    if (error is AppException) {
      return error.message;
    }

    final errorStr = error.toString().toLowerCase();

    // Auth-related errors
    if (errorStr.contains('invalid login credentials') ||
        errorStr.contains('invalid_credentials')) {
      return AuthException.invalidCredentials().message;
    }
    if (errorStr.contains('email already registered') ||
        errorStr.contains('user_already_exists')) {
      return AuthException.emailInUse().message;
    }
    if (errorStr.contains('password') && errorStr.contains('weak')) {
      return AuthException.weakPassword().message;
    }

    // Network-related errors
    if (errorStr.contains('socketexception') ||
        errorStr.contains('network') ||
        errorStr.contains('connection')) {
      return NetworkException.noConnection().message;
    }
    if (errorStr.contains('timeout')) {
      return NetworkException.timeout().message;
    }

    // Storage-related errors
    if (errorStr.contains('storage') || errorStr.contains('bucket')) {
      return StorageException.uploadFailed().message;
    }
    if (errorStr.contains('quota') || errorStr.contains('storage limit')) {
      return StorageException.quotaExceeded().message;
    }

    // Profile-related errors
    if (errorStr.contains('username') && 
        (errorStr.contains('unique') || errorStr.contains('duplicate'))) {
      return ProfileException.usernameTaken().message;
    }

    // Clean up common prefixes
    return error
        .toString()
        .replaceAll('Exception: ', '')
        .replaceAll('AuthException: ', '')
        .replaceAll('PostgrestException: ', '')
        .replaceAll('StorageException: ', '')
        .replaceAll('ProfileException: ', '');
  }
}
