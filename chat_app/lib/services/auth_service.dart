import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../exceptions/app_exceptions.dart' as exceptions;
import '../models/user.dart' as models;

/// Result of a sign-up operation.
class SignUpResult {
  /// The created user model, or null if email verification is required.
  final models.User? user;
  
  /// Whether email verification is required before the user can sign in.
  final bool requiresEmailVerification;
  
  /// The email address used for sign-up.
  final String email;
  
  SignUpResult({
    this.user,
    required this.requiresEmailVerification,
    required this.email,
  });
}

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
  /// Returns a [SignUpResult] that indicates whether email verification is required.
  /// Throws [exceptions.AuthException] if sign up fails.
  Future<SignUpResult> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final trimmedEmail = email.trim();
      final response = await _client.auth.signUp(
        email: trimmedEmail,
        password: password,
        data: {'username': username.trim()},
      );

      final userId = response.user?.id;
      if (userId == null) {
        throw exceptions.AuthException('Sign up failed. Please try again.');
      }

      // Check if email verification is required (session is null when verification is needed)
      final requiresEmailVerification = response.session == null;

      // Create user in public.users table
      // This should work even without a session since we have the userId
      try {
        await _client.from('users').insert({
          'id': userId,
          'username': username.trim(),
        });
      } on PostgrestException catch (e) {
        // Critical error: auth user created but database insert failed
        debugPrint('Critical error: Database insert failed after auth user creation. UserId: $userId, Error: ${e.message}');
        throw exceptions.DatabaseException(
          'Account created but profile setup failed. Please contact support.',
          e,
        );
      }

      // If email verification is required, return result without user (user not authenticated)
      if (requiresEmailVerification) {
        return SignUpResult(
          user: null,
          requiresEmailVerification: true,
          email: trimmedEmail,
        );
      }

      // User is authenticated (no email verification required)
      return SignUpResult(
        user: models.User(
          id: userId,
          username: username.trim(),
          email: trimmedEmail,
        ),
        requiresEmailVerification: false,
        email: trimmedEmail,
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
