import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing user presence (online/offline status).
class PresenceService {
  final SupabaseClient _client;
  Timer? _heartbeatTimer;

  PresenceService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Returns the current user's ID.
  String? get currentUserId => _client.auth.currentUser?.id;

  /// Updates the current user's last_seen timestamp.
  ///
  /// This should be called periodically (e.g., every 30 seconds) when the app is active,
  /// and when the app comes to foreground.
  Future<void> updateLastSeen() async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      await _client.rpc('update_last_seen');
    } catch (e) {
      debugPrint('Error updating last_seen: $e');
    }
  }

  /// Starts a periodic heartbeat to update last_seen.
  ///
  /// Updates every [interval] seconds. Default is 30 seconds.
  void startHeartbeat({Duration interval = const Duration(seconds: 30)}) {
    stopHeartbeat();
    _heartbeatTimer = Timer.periodic(interval, (_) => updateLastSeen());
    // Update immediately
    updateLastSeen();
  }

  /// Stops the periodic heartbeat.
  void stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Disposes resources.
  void dispose() {
    stopHeartbeat();
  }
}

