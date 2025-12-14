import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../exceptions/app_exceptions.dart' as exceptions;
import '../models/user.dart' as models;

/// Service for handling authentication operations.
class AuthService {
  final SupabaseClient _client;

  AuthService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  /// Returns the current authenticated user's ID, or null if not authenticated.
  String? get currentUserId => _client.auth.currentUser?.id;

  /// Returns the current authenticated user's email, or null if not authenticated.
  String? get currentUserEmail => _client.auth.currentUser?.email;

  /// Returns true if there is a current session.
  bool get isAuthenticated => _client.auth.currentSession != null;

  /// Signs up a new user with email and password.
  ///
  /// Creates both an auth user and a corresponding entry in the users table.
  /// Returns the created user model.
  /// Throws [exceptions.AuthException] if sign up fails.
  Future<models.User?> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'username': username.trim()},
      );

      final userId = response.user?.id;
      if (userId == null) {
        throw exceptions.AuthException('Sign up failed. Please try again.');
      }

      // Create user in public.users table
      await _client.from('users').insert({
        'id': userId,
        'username': username.trim(),
      });

      return models.User(
        id: userId,
        username: username.trim(),
        email: email.trim(),
      );
    } on AuthApiException catch (e) {
      debugPrint('Auth API error during sign up: ${e.message}');
      throw exceptions.AuthException(
        exceptions.ExceptionHandler.getMessage(e),
        e,
      );
    } on PostgrestException catch (e) {
      debugPrint('Database error during sign up: ${e.message}');
      throw exceptions.DatabaseException(
        exceptions.ExceptionHandler.getMessage(e),
        e,
      );
    }
  }

  /// Signs in a user with email and password.
  ///
  /// Also ensures the user exists in the users table.
  /// Returns the user model.
  /// Throws [exceptions.AuthException] if sign in fails.
  Future<models.User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw exceptions.AuthException('Sign in failed. Please try again.');
      }

      // Ensure user exists in public.users table
      final existing = await _client
          .from('users')
          .select('id, username')
          .eq('id', userId)
          .limit(1);

      if (existing.isEmpty) {
        // Create user entry if missing
        final username = email.trim().split('@').first;
        await _client.from('users').insert({
          'id': userId,
          'username': username,
        });
        return models.User(id: userId, username: username, email: email.trim());
      }

      // Return existing user
      final userData = existing.first;
      return models.User(
        id: userId,
        username: userData['username']?.toString() ?? 'User',
        email: email.trim(),
      );
    } on AuthApiException catch (e) {
      debugPrint('Auth API error during sign in: ${e.message}');
      throw exceptions.AuthException(
        exceptions.ExceptionHandler.getMessage(e),
        e,
      );
    } on PostgrestException catch (e) {
      debugPrint('Database error during sign in: ${e.message}');
      throw exceptions.DatabaseException(
        exceptions.ExceptionHandler.getMessage(e),
        e,
      );
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Gets the current user's profile from the users table.
  Future<models.User?> getCurrentUserProfile() async {
    final userId = currentUserId;
    if (userId == null) return null;

    final response = await _client
        .from('users')
        .select()
        .eq('id', userId)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return models.User.fromJson(response);
  }
}
