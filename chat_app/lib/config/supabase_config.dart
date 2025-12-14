import 'package:supabase_flutter/supabase_flutter.dart';

/// Configuration for Supabase initialization.
///
/// Uses environment variables passed via --dart-define for security.
/// Falls back to hardcoded values for development (not recommended for production).
class SupabaseConfig {
  SupabaseConfig._();

  /// Supabase project URL.
  ///
  /// Pass via: --dart-define=SUPABASE_URL=your_url
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://djpzzwjxjlslnkgstgfk.supabase.co',
  );

  /// Supabase anonymous key.
  ///
  /// Pass via: --dart-define=SUPABASE_ANON_KEY=your_key
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRqcHp6d2p4amxzbG5rZ3N0Z2ZrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUyNTI5ODYsImV4cCI6MjA4MDgyODk4Nn0.wQsV7inD7QjuAh-tgHUV6Z7jJUQ1PXPiQ4_ott_3raY',
  );

  /// Initializes Supabase with the configured URL and key.
  static Future<Supabase> initialize() async {
    return await Supabase.initialize(url: url, anonKey: anonKey);
  }

  /// Returns the Supabase client instance.
  static SupabaseClient get client => Supabase.instance.client;

  /// Returns true if using environment variables (not default values).
  static bool get isConfigured {
    return url != 'https://djpzzwjxjlslnkgstgfk.supabase.co' ||
        const String.fromEnvironment('SUPABASE_URL').isNotEmpty;
  }
}
