import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as models;
import '../exceptions/app_exceptions.dart' as exceptions;

/// Service for handling user-related operations.
class UserService {
  final SupabaseClient _client;

  UserService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  /// Returns the current user's ID.
  String? get currentUserId => _client.auth.currentUser?.id;

  /// Returns a stream of all users in the system.
  ///
  /// The stream updates in real-time when users are added or modified.
  Stream<List<models.User>> getUsersStream() {
    return _client
        .from('users')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .map((data) => data.map((json) => models.User.fromJson(json)).toList());
  }

  /// Returns a stream of all users except the current user.
  Stream<List<models.User>> getOtherUsersStream() {
    final userId = currentUserId;
    return getUsersStream().map((users) {
      if (userId == null) return users;
      return users.where((user) => user.id != userId).toList();
    });
  }

  /// Gets a single user by ID.
  Future<models.User?> getUserById(String userId) async {
    final response = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return models.User.fromJson(response);
  }

  /// Gets the current user's profile.
  Future<models.User?> getCurrentUser() async {
    final userId = currentUserId;
    if (userId == null) return null;
    return getUserById(userId);
  }

  /// Searches users by username.
  ///
  /// Returns users whose username contains the search query (case-insensitive).
  Future<List<models.User>> searchUsers(String query) async {
    if (query.isEmpty) return [];

    final response = await _client
        .from('users')
        .select()
        .ilike('username', '%$query%')
        .neq('id', currentUserId ?? '')
        .limit(20);

    return response.map((json) => models.User.fromJson(json)).toList();
  }

  /// Filters a list of users by username search query.
  List<models.User> filterUsers(List<models.User> users, String query) {
    if (query.isEmpty) return users;
    final lowerQuery = query.toLowerCase();
    return users
        .where((user) => user.username.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Checks if a username is available.
  ///
  /// Returns true if the username is available, false if it's already taken.
  /// If the username belongs to the current user, returns true.
  Future<bool> checkUsernameAvailability(String username) async {
    final userId = currentUserId;
    if (userId == null) {
      throw exceptions.AuthException.notAuthenticated();
    }

    try {
      final response = await _client
          .from('users')
          .select('id, username')
          .eq('username', username.trim())
          .limit(1)
          .maybeSingle();

      // If no user found, username is available
      if (response == null) return true;

      // If the username belongs to current user, it's available
      final existingUserId = response['id']?.toString();
      return existingUserId == userId;
    } on PostgrestException catch (e) {
      debugPrint('Error checking username availability: ${e.message}');
      throw exceptions.DatabaseException.operationFailed('check username availability');
    }
  }

  /// Updates the current user's profile.
  ///
  /// Updates username, bio, and/or avatar_url.
  /// Throws [ProfileException] if update fails.
  /// Throws [exceptions.ValidationException] if validation fails.
  Future<models.User> updateProfile({
    String? username,
    String? bio,
    String? avatarUrl,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw exceptions.AuthException.notAuthenticated();
    }

    try {
      // Build update map
      final updateData = <String, dynamic>{};

      if (username != null) {
        final trimmed = username.trim();
        if (trimmed.isEmpty) {
          throw exceptions.ValidationException.required('username');
        }
        updateData['username'] = trimmed;
      }

      if (bio != null) {
        final trimmed = bio.trim();
        // Convert empty string to null
        updateData['bio'] = trimmed.isEmpty ? null : trimmed;
      }

      if (avatarUrl != null) {
        updateData['avatar_url'] = avatarUrl;
      }

      if (updateData.isEmpty) {
        // No changes to make, return current user
        final currentUser = await getCurrentUser();
        if (currentUser == null) {
          throw exceptions.DatabaseException.notFound('user');
        }
        return currentUser;
      }

      // Update database
      final response = await _client
          .from('users')
          .update(updateData)
          .eq('id', userId)
          .select()
          .single();

      return models.User.fromJson(response);
    } on PostgrestException catch (e) {
      debugPrint('Error updating profile: ${e.message}');
      
      // Check for unique constraint violation (username taken)
      if (e.message.contains('unique') || 
          e.message.contains('duplicate') ||
          e.message.contains('username')) {
        throw exceptions.ProfileException.usernameTaken();
      }
      
      throw exceptions.ProfileException.updateFailed(e.message);
    }
  }

  /// Updates only the avatar URL in the database.
  ///
  /// Used after successful image upload.
  Future<void> updateAvatarUrl(String avatarUrl) async {
    final userId = currentUserId;
    if (userId == null) {
      throw exceptions.AuthException.notAuthenticated();
    }

    try {
      await _client
          .from('users')
          .update({'avatar_url': avatarUrl})
          .eq('id', userId);
    } on PostgrestException catch (e) {
      debugPrint('Error updating avatar URL: ${e.message}');
      throw exceptions.DatabaseException.operationFailed('update avatar URL');
    }
  }
}
