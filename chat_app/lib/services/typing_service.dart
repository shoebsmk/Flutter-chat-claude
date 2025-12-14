import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing typing indicators.
class TypingService {
  final SupabaseClient _client;
  Timer? _typingTimeout;
  static const _typingTimeoutDuration = Duration(seconds: 3);

  TypingService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Returns the current user's ID.
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
    if (userId == null) return;

    try {
      await _client.from('typing_indicators').upsert(
        {
          'user_id': userId,
          'conversation_user_id': conversationUserId,
          'is_typing': isTyping,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id,conversation_user_id',
      );
    } catch (e) {
      debugPrint('Error setting typing status: $e');
    }
  }

  /// Starts typing indicator (sets to true).
  ///
  /// Automatically stops after timeout if [stopTyping] is not called.
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
  /// Returns true if the other user is typing, false otherwise.
  Stream<bool> getTypingStream(String conversationUserId) {
    final userId = currentUserId;
    if (userId == null) return Stream.value(false);

    // Note: SupabaseStreamBuilder doesn't support .eq() chaining,
    // so we filter in the map callback instead
    return _client
        .from('typing_indicators')
        .stream(primaryKey: ['id'])
        .map((data) {
          // Filter for the specific conversation
          final filtered = data.where((row) =>
              row['conversation_user_id'] == userId &&
              row['user_id'] == conversationUserId);
          
          if (filtered.isEmpty) return false;
          
          final indicator = filtered.first;
          final isTyping = indicator['is_typing'] as bool? ?? false;
          final updatedAt = indicator['updated_at'] as String?;
          
          // Check if typing status is recent (within 5 seconds)
          if (isTyping && updatedAt != null) {
            final updated = DateTime.tryParse(updatedAt);
            if (updated != null) {
              final difference = DateTime.now().difference(updated);
              return difference.inSeconds < 5;
            }
          }
          
          return false;
        });
  }

  /// Disposes resources.
  void dispose() {
    _typingTimeout?.cancel();
  }
}
