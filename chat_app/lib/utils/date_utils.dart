import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Utility class for date and time operations.
class AppDateUtils {
  AppDateUtils._();

  /// Parses a DateTime from various formats (DateTime, String, or null).
  ///
  /// Handles Supabase timestamp formats including:
  /// - ISO 8601 strings (e.g., "2024-01-01T12:00:00Z")
  /// - DateTime objects
  /// - Timestamp strings with timezone information
  ///
  /// Supabase stores timestamps as UTC. Strings without timezone are treated as UTC
  /// and converted to local time for proper comparison with DateTime.now().
  /// Returns null if the value cannot be parsed.
  static DateTime? parse(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      // Try parsing as ISO 8601 string (Supabase's default format)
      var parsed = DateTime.tryParse(value);
      
      // If parsing succeeds but the string doesn't have timezone info, 
      // Supabase timestamps are stored in UTC, so we need to treat them as UTC
      if (parsed != null) {
        final hasTimezone = value.endsWith('Z') || 
                           RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(value);
        if (!hasTimezone) {
          // String has no timezone indicator - treat as UTC (Supabase stores in UTC)
          // Convert to local time for proper comparison with DateTime.now()
          parsed = DateTime.utc(
            parsed.year,
            parsed.month,
            parsed.day,
            parsed.hour,
            parsed.minute,
            parsed.second,
            parsed.millisecond,
            parsed.microsecond,
          ).toLocal();
        }
      }
      
      if (parsed != null) return parsed;
      return null;
    }
    return null;
  }

  /// Parses a DateTime, returning [fallback] if parsing fails.
  static DateTime parseOrDefault(dynamic value, [DateTime? fallback]) {
    return parse(value) ?? fallback ?? DateTime.now();
  }

  /// Formats a timestamp for display in chat lists (e.g., "2 minutes ago").
  ///
  /// Uses the timeago package for relative formatting.
  static String formatRelative(DateTime? dateTime) {
    if (dateTime == null) return '';
    return timeago.format(dateTime);
  }

  /// Formats a timestamp for message bubbles.
  ///
  /// Shows relative time for recent messages, then time of day,
  /// then day of week, then full date for older messages.
  static String formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return DateFormat('h:mm a').format(dateTime);
    } else if (difference.inDays == 1) {
      return 'Yesterday ${DateFormat('h:mm a').format(dateTime)}';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE h:mm a').format(dateTime);
    } else {
      return DateFormat('MMM d, h:mm a').format(dateTime);
    }
  }

  /// Formats a full timestamp with date and time.
  static String formatFull(DateTime dateTime) {
    return DateFormat('MMM d, y h:mm a').format(dateTime);
  }

  /// Formats just the time portion.
  static String formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  /// Formats just the date portion.
  static String formatDate(DateTime dateTime) {
    return DateFormat('MMM d, y').format(dateTime);
  }

  /// Returns true if the date is today.
  static bool isToday(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  /// Returns true if the date is yesterday.
  static bool isYesterday(DateTime dateTime) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return dateTime.year == yesterday.year &&
        dateTime.month == yesterday.month &&
        dateTime.day == yesterday.day;
  }

  /// Returns true if the date is within the last week.
  static bool isWithinLastWeek(DateTime dateTime) {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return dateTime.isAfter(weekAgo);
  }
}
