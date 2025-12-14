import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../exceptions/app_exceptions.dart';
import '../models/user.dart' as models;

/// Service for handling AI-powered command-based messaging.
class AICommandService {
  final SupabaseClient _client;

  AICommandService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Extracts intent from natural language command.
  /// 
  /// Calls the Supabase Edge Function to extract recipient query and message.
  /// Returns a map with 'recipient_query' and 'message' keys.
  /// 
  /// Throws [AICommandException] if extraction fails.
  Future<Map<String, String>> extractIntent(String command) async {
    if (command.trim().isEmpty) {
      throw AICommandException('Command cannot be empty');
    }

    // Validate command length (prevent abuse)
    if (command.length > 500) {
      throw AICommandException('Command is too long (max 500 characters)');
    }

    try {
      final response = await _client.functions.invoke(
        'extract-message-intent',
        body: {'command': command.trim()},
      );

      final data = response.data as Map<String, dynamic>;
      
      // Check if Edge Function returned an error
      if (data.containsKey('error')) {
        final errorMessage = data['error'].toString();
        debugPrint('Edge Function error: $errorMessage');
        
        // Check for specific error types
        if (errorMessage.toLowerCase().contains('command is required') ||
            errorMessage.toLowerCase().contains('too long')) {
          throw AICommandException(errorMessage);
        }
        
        // Check if it's a Gemini API error
        if (errorMessage.toLowerCase().contains('gemini api error') ||
            errorMessage.toLowerCase().contains('ai service not configured')) {
          throw AICommandException('AI service error: $errorMessage');
        }
        
        throw AICommandException('Failed to extract intent: $errorMessage');
      }
      
      final recipientQuery = data['recipient_query']?.toString() ?? '';
      final message = data['message']?.toString() ?? '';

      if (recipientQuery.isEmpty && message.isEmpty) {
        throw AICommandException.extractionFailed();
      }

      return {
        'recipient_query': recipientQuery,
        'message': message,
      };
    } catch (e) {
      debugPrint('Error extracting intent: $e');
      
      if (e is AICommandException) {
        rethrow;
      }
      
      // Handle network errors
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('network') || 
          errorString.contains('connection') ||
          errorString.contains('timeout')) {
        throw NetworkException('Network error. Please check your connection.');
      }
      
      throw AICommandException.extractionFailed();
    }
  }

  /// Resolves recipient from query string.
  /// 
  /// Returns the best matching user or null if no match found.
  /// Matching priority:
  /// 1. Exact match (case-insensitive)
  /// 2. Partial match (username contains query)
  /// 
  /// If multiple partial matches exist, returns the first one.
  /// For future enhancement, this could show a selection dialog.
  Future<models.User?> resolveRecipient(String query, List<models.User> allUsers) async {
    if (query.isEmpty) return null;

    final lowerQuery = query.toLowerCase().trim();
    final matches = <models.User>[];

    // Exact match first (highest priority)
    for (final user in allUsers) {
      if (user.username.toLowerCase() == lowerQuery) {
        return user; // Return immediately for exact match
      }
    }

    // Partial matches
    for (final user in allUsers) {
      if (user.username.toLowerCase().contains(lowerQuery)) {
        matches.add(user);
      }
    }

    if (matches.isEmpty) return null;
    if (matches.length == 1) return matches.first;

    // Multiple matches - return first match for now
    // Future enhancement: show selection dialog
    return matches.first;
  }
}

