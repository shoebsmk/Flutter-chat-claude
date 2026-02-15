import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for persisting the LangGraph agent thread ID and message
/// history locally per-user.
class ThreadStorageService {
  ThreadStorageService._();

  static const String _threadKeyPrefix = 'ai_thread_id_';
  static const String _messagesKeyPrefix = 'ai_messages_';

  // ── Thread ID ──

  static Future<String?> loadThreadId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_threadKeyPrefix$userId');
  }

  static Future<void> saveThreadId(String userId, String threadId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_threadKeyPrefix$userId', threadId);
  }

  static Future<void> clearThreadId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_threadKeyPrefix$userId');
  }

  // ── Message History ──

  /// Loads persisted messages for the given user.
  /// Each message is a Map with 'content', 'isUser', 'timestamp', etc.
  static Future<List<Map<String, dynamic>>> loadMessages(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_messagesKeyPrefix$userId');
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        // Restore DateTime from ISO string
        if (m['timestamp'] is String) {
          m['timestamp'] = DateTime.parse(m['timestamp'] as String);
        }
        return m;
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Persists the current message list for the given user.
  static Future<void> saveMessages(
    String userId,
    List<Map<String, dynamic>> messages,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    // Convert DateTime to ISO string for JSON serialization
    final serializable = messages.map((m) {
      final copy = Map<String, dynamic>.from(m);
      if (copy['timestamp'] is DateTime) {
        copy['timestamp'] = (copy['timestamp'] as DateTime).toIso8601String();
      }
      return copy;
    }).toList();
    await prefs.setString('$_messagesKeyPrefix$userId', jsonEncode(serializable));
  }

  static Future<void> clearMessages(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_messagesKeyPrefix$userId');
  }

  // ── Cleanup ──

  /// Removes all stored threads and messages (used on logout).
  static Future<void> clearAllThreads() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where(
      (k) => k.startsWith(_threadKeyPrefix) || k.startsWith(_messagesKeyPrefix),
    );
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
