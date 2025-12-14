/// Application-wide constants.
class AppConstants {
  AppConstants._();

  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 200);
  static const Duration animationSlow = Duration(milliseconds: 300);

  // UI constants
  static const int shimmerItemCount = 8;
  static const int maxSearchResults = 20;

  // Validation
  static const int minPasswordLength = 6;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 50;
  static const int maxBioLength = 500;
  
  // Profile image validation
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5MB
  static const int maxImageDimension = 2000;

  // Database table names
  static const String usersTable = 'users';
  static const String messagesTable = 'messages';

  // Database column names
  static const String columnId = 'id';
  static const String columnUsername = 'username';
  static const String columnEmail = 'email';
  static const String columnCreatedAt = 'created_at';
  static const String columnSenderId = 'sender_id';
  static const String columnReceiverId = 'receiver_id';
  static const String columnContent = 'content';
  static const String columnIsRead = 'is_read';
}

/// Regular expressions for validation.
class AppRegex {
  AppRegex._();

  static final RegExp email = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  
  /// Username pattern: alphanumeric, underscore, hyphen, 3-50 characters
  static final RegExp username = RegExp(r'^[a-zA-Z0-9_-]{3,50}$');
}
