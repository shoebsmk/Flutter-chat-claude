import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing typing indicators in real-time conversations.
///
/// Handles setting, tracking, and streaming typing status between users.
/// Uses polling to ensure reliable updates even when Supabase streams
/// don't emit on UPDATE operations.
class TypingService {
  final SupabaseClient _client;
  Timer? _typingTimeout;

  /// Duration after which typing indicator automatically stops if not refreshed.
  static const Duration _typingTimeoutDuration = Duration(seconds: 3);

  /// Polling interval for checking typing status updates.
  static const Duration _pollingInterval = Duration(seconds: 1);

  /// Maximum age (in seconds) for a typing status to be considered valid.
  static const int _maxTypingAgeSeconds = 5;

  TypingService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Returns the current authenticated user's ID.
  String? get currentUserId => _client.auth.currentUser?.id;

  /// Sets typing status for a conversation.
  ///
  /// [conversationUserId] is the ID of the user you're typing to.
  /// [isTyping] indicates whether the user is currently typing.
  Future<void> setTyping({
    required String conversationUserId,
    required bool isTyping,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      debugPrint('Cannot set typing status: user not authenticated');
      return;
    }

    try {
      await _client.from('typing_indicators').upsert(
        {
          'user_id': userId,
          'conversation_user_id': conversationUserId,
          'is_typing': isTyping,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'user_id,conversation_user_id',
      ).select();
    } catch (e) {
      debugPrint('Error setting typing status: $e');
    }
  }

  /// Starts typing indicator (sets to true).
  ///
  /// Automatically stops after [_typingTimeoutDuration] if [stopTyping] is not called.
  Future<void> startTyping(String conversationUserId) async {
    await setTyping(conversationUserId: conversationUserId, isTyping: true);
    _typingTimeout?.cancel();
    _typingTimeout = Timer(_typingTimeoutDuration, () {
      stopTyping(conversationUserId);
    });
  }

  /// Stops typing indicator (sets to false).
  Future<void> stopTyping(String conversationUserId) async {
    _typingTimeout?.cancel();
    await setTyping(conversationUserId: conversationUserId, isTyping: false);
  }

  /// Returns a stream of typing status for a specific conversation.
  ///
  /// Uses polling to ensure reliable updates. Returns true if the other user
  /// is typing, false otherwise.
  ///
  /// [conversationUserId] is the ID of the user whose typing status to monitor.
  Stream<bool> getTypingStream(String conversationUserId) {
    final userId = currentUserId;
    if (userId == null) {
      return Stream.value(false);
    }

    return Stream.value(null).asyncExpand((_) async* {
      // Emit initial state immediately
      try {
        final initialValue = await _fetchTypingState(userId, conversationUserId);
        yield initialValue;
      } catch (e) {
        debugPrint('Error fetching initial typing state: $e');
        yield false;
      }

      // Poll periodically to catch updates
      // Supabase streams may not always emit on UPDATE operations
      yield* Stream.periodic(_pollingInterval)
          .asyncMap((_) => _fetchTypingState(userId, conversationUserId))
          .distinct(); // Only emit when value changes
    });
  }

  /// Fetches the current typing state from the database.
  ///
  /// Returns true if the other user is typing and the status is recent,
  /// false otherwise.
  Future<bool> _fetchTypingState(String userId, String conversationUserId) async {
    try {
      final response = await _client
          .from('typing_indicators')
          .select()
          .eq('conversation_user_id', userId)
          .eq('user_id', conversationUserId)
          .maybeSingle();

      if (response == null) {
        return false;
      }

      final isTyping = response['is_typing'] as bool? ?? false;
      if (!isTyping) {
        return false;
      }

      final updatedAt = response['updated_at'] as String?;
      if (updatedAt == null) {
        return false;
      }

      final updated = DateTime.tryParse(updatedAt);
      if (updated == null) {
        return false;
      }

      // Check if typing status is recent enough to be valid
      final age = DateTime.now().difference(updated);
      return age.inSeconds < _maxTypingAgeSeconds;
    } catch (e) {
      debugPrint('Error fetching typing state: $e');
      return false;
    }
  }

  /// Disposes resources and cancels any active timers.
  void dispose() {
    _typingTimeout?.cancel();
    _typingTimeout = null;
  }
}

