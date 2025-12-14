import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../exceptions/app_exceptions.dart' as exceptions;
import '../models/message.dart';

/// Data class for conversation summary information.
class ConversationInfo {
  /// The ID of the other user in the conversation.
  final String otherUserId;

  /// The most recent message in the conversation.
  final Message? lastMessage;

  /// Number of unread messages from this user.
  final int unreadCount;

  const ConversationInfo({
    required this.otherUserId,
    this.lastMessage,
    this.unreadCount = 0,
  });
}

/// Service for handling chat and message operations.
class ChatService {
  final SupabaseClient _client;

  ChatService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  /// Returns the current user's ID.
  String? get currentUserId => _client.auth.currentUser?.id;

  /// Returns a stream of messages between the current user and another user.
  ///
  /// Messages are ordered by creation time (newest first for reverse ListView).
  Stream<List<Message>> getConversationStream(String otherUserId) {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map(
          (data) => data
              .where(
                (msg) =>
                    (msg['sender_id'] == userId &&
                        msg['receiver_id'] == otherUserId) ||
                    (msg['sender_id'] == otherUserId &&
                        msg['receiver_id'] == userId),
              )
              .map((json) => Message.fromJson(json))
              .toList(),
        );
  }

  /// Returns a stream of all messages involving the current user.
  Stream<List<Message>> getCurrentUserMessagesStream() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map(
          (data) => data
              .where(
                (msg) =>
                    msg['sender_id'] == userId || msg['receiver_id'] == userId,
              )
              .map((json) => Message.fromJson(json))
              .toList(),
        );
  }

  /// Sends a message to another user.
  ///
  /// Throws [exceptions.AuthException] if not authenticated.
  /// Throws [exceptions.ChatException] if the message is empty or sending fails.
  Future<Message> sendMessage({
    required String receiverId,
    required String content,
  }) async {
    final userId = currentUserId;
    if (userId == null) {
      throw exceptions.AuthException.notAuthenticated();
    }

    final trimmedContent = content.trim();
    if (trimmedContent.isEmpty) {
      throw exceptions.ChatException.emptyMessage();
    }

    try {
      final response = await _client
          .from('messages')
          .insert({
            'sender_id': userId,
            'receiver_id': receiverId,
            'content': trimmedContent,
            'is_read': false,
          })
          .select()
          .single();

      return Message.fromJson(response);
    } on PostgrestException catch (e) {
      debugPrint('Database error sending message: ${e.message}');
      throw exceptions.ChatException.sendFailed();
    }
  }

  /// Marks all unread messages from a specific sender as read.
  Future<int> markMessagesAsRead(String senderId) async {
    final userId = currentUserId;
    if (userId == null) return 0;

    try {
      final response = await _client
          .from('messages')
          .update({'is_read': true})
          .eq('sender_id', senderId)
          .eq('receiver_id', userId)
          .eq('is_read', false)
          .select();

      final count = (response as List).length;
      if (count > 0) {
        debugPrint('Marked $count messages as read');
      }
      return count;
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
      return 0;
    }
  }

  /// Processes messages to extract conversation summaries for each user.
  ///
  /// Returns a map of user IDs to their conversation info (last message and unread count).
  Map<String, ConversationInfo> processConversations(
    List<Message> messages,
    List<String> userIds,
  ) {
    final userId = currentUserId;
    if (userId == null || userIds.isEmpty) return {};

    final result = <String, ConversationInfo>{};
    final lastMessagesByUser = <String, Message>{};
    final unreadCountsByUser = <String, int>{};

    for (final msg in messages) {
      // Determine the other user in this conversation
      String? otherUserId;
      if (msg.senderId == userId) {
        otherUserId = msg.receiverId;
      } else if (msg.receiverId == userId) {
        otherUserId = msg.senderId;
        // Count unread messages (only for messages received by current user)
        if (!msg.isRead && userIds.contains(otherUserId)) {
          unreadCountsByUser[otherUserId] =
              (unreadCountsByUser[otherUserId] ?? 0) + 1;
        }
      }

      if (otherUserId == null || !userIds.contains(otherUserId)) continue;

      // Store the latest message for this conversation
      final existingLastMessage = lastMessagesByUser[otherUserId];
      if (existingLastMessage == null) {
        lastMessagesByUser[otherUserId] = msg;
      } else if (msg.createdAt.isAfter(existingLastMessage.createdAt)) {
        lastMessagesByUser[otherUserId] = msg;
      }
    }

    // Combine last message and unread count
    for (final entry in lastMessagesByUser.entries) {
      result[entry.key] = ConversationInfo(
        otherUserId: entry.key,
        lastMessage: entry.value,
        unreadCount: unreadCountsByUser[entry.key] ?? 0,
      );
    }

    // Add entries for users with unread messages but no last message processed
    for (final entry in unreadCountsByUser.entries) {
      if (!result.containsKey(entry.key)) {
        result[entry.key] = ConversationInfo(
          otherUserId: entry.key,
          unreadCount: entry.value,
        );
      }
    }

    return result;
  }

  /// Gets the unread message count for a specific conversation.
  Future<int> getUnreadCount(String senderId) async {
    final userId = currentUserId;
    if (userId == null) return 0;

    final response = await _client
        .from('messages')
        .select('id')
        .eq('sender_id', senderId)
        .eq('receiver_id', userId)
        .eq('is_read', false);

    return (response as List).length;
  }
}
