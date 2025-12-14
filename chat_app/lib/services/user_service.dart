import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as models;

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
}
