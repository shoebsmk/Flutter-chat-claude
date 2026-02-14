import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/agent_config.dart';
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

      // Validate response data exists and is a Map
      if (response.data == null) {
        throw AICommandException('No response from AI service');
      }

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        debugPrint('Unexpected response type: ${data.runtimeType}');
        throw AICommandException('Invalid response format from AI service');
      }
      
      // Check if Edge Function returned an error
      if (data.containsKey('error')) {
        final errorMessage = data['error'].toString();
        debugPrint('Edge Function error: $errorMessage');
        
        // Check for specific error types
        if (errorMessage.toLowerCase().contains('command is required') ||
            errorMessage.toLowerCase().contains('too long')) {
          throw AICommandException(errorMessage);
        }
        
        // Check if it's an AI API error
        if (errorMessage.toLowerCase().contains('gemini api error') ||
            errorMessage.toLowerCase().contains('openai api error') ||
            errorMessage.toLowerCase().contains('ai service not configured')) {
          throw AICommandException('AI service error: $errorMessage');
        }
        
        // Check for rate limiting
        if (errorMessage.toLowerCase().contains('rate limit') ||
            errorMessage.toLowerCase().contains('quota')) {
          throw AICommandException('AI service is temporarily unavailable. Please try again in a moment.');
        }
        
        throw AICommandException('Failed to extract intent: $errorMessage');
      }
      
      final recipientQuery = data['recipient_query']?.toString() ?? '';
      final message = data['message']?.toString() ?? '';
      final aiResponse = data['ai_response']?.toString() ?? '';

      if (recipientQuery.isEmpty && message.isEmpty) {
        throw AICommandException.extractionFailed();
      }

      return {
        'recipient_query': recipientQuery,
        'message': message,
        'ai_response': aiResponse,
      };
    } on AICommandException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      debugPrint('Error extracting intent: $e');
      
      // Handle Supabase function-specific errors
      final errorString = e.toString().toLowerCase();
      
      // Handle network errors
      if (errorString.contains('network') || 
          errorString.contains('connection') ||
          errorString.contains('timeout') ||
          errorString.contains('timed out') ||
          errorString.contains('socket')) {
        throw NetworkException('Network error. Please check your connection.');
      }
      
      // Handle rate limiting
      if (errorString.contains('rate limit') || errorString.contains('429')) {
        throw AICommandException('Service is temporarily unavailable. Please try again in a moment.');
      }
      
      // Handle function invocation errors
      if (errorString.contains('function') || errorString.contains('invoke')) {
        throw AICommandException('Service unavailable. Please try again later.');
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

  /// Sends a command to the LangGraph agent backend.
  ///
  /// The agent handles everything server-side: intent extraction,
  /// recipient resolution, and message sending.
  ///
  /// Includes automatic retry with exponential backoff for transient errors
  /// (timeouts, network issues, 5xx). Max 2 retries (3 total attempts).
  ///
  /// Returns a map with 'response', 'thread_id', and 'tool_results'.
  ///
  /// Throws [AICommandException] if the agent returns an error.
  /// Throws [NetworkException] if there is a connectivity issue.
  Future<Map<String, dynamic>> sendToAgent(
    String command,
    String userId, {
    String? threadId,
    bool confirmOnly = false,
    bool execute = false,
  }) async {
    if (command.trim().isEmpty) {
      throw AICommandException('Command cannot be empty');
    }

    if (command.length > 500) {
      throw AICommandException('Command is too long (max 500 characters)');
    }

    await _checkConnectivity();

    const maxRetries = 2;
    const baseDelay = Duration(seconds: 2);

    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await _executeAgentRequest(
          command,
          userId,
          threadId: threadId,
          confirmOnly: confirmOnly,
          execute: execute,
        );
      } catch (e) {
        final isLastAttempt = attempt == maxRetries;

        if (isLastAttempt || !_isRetryableError(e)) {
          rethrow;
        }

        // Exponential backoff: 2s, 4s
        final delay = baseDelay * (1 << attempt);
        debugPrint('Agent request failed (attempt ${attempt + 1}), retrying in ${delay.inSeconds}s...');
        await Future.delayed(delay);
      }
    }

    // Unreachable, but Dart requires it
    throw AICommandException('Failed to reach agent after retries.');
  }

  /// Executes a single HTTP request to the agent.
  Future<Map<String, dynamic>> _executeAgentRequest(
    String command,
    String userId, {
    String? threadId,
    bool confirmOnly = false,
    bool execute = false,
  }) async {
    try {
      final body = <String, dynamic>{
        'message': command.trim(),
        'user_id': userId,
      };
      if (threadId != null) {
        body['thread_id'] = threadId;
      }
      if (confirmOnly) {
        body['confirm_only'] = true;
      }
      if (execute) {
        body['execute'] = true;
      }

      final response = await http
          .post(
            Uri.parse(AgentConfig.agentEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'response': data['response']?.toString() ?? '',
          'thread_id': data['thread_id']?.toString() ?? '',
          'tool_results': data['tool_results'] ?? [],
          'pending_action': data['pending_action'],
        };
      } else if (response.statusCode == 429) {
        throw AICommandException(
          'Service is temporarily unavailable. Please try again in a moment.',
        );
      } else if (response.statusCode >= 500) {
        throw NetworkException.serverError();
      } else {
        final errorBody = _tryDecodeError(response.body);
        throw AICommandException(
          errorBody ?? 'Agent returned status ${response.statusCode}',
        );
      }
    } on AICommandException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      debugPrint('Error calling agent: $e');
      final errorString = e.toString().toLowerCase();

      if (errorString.contains('timeout') ||
          errorString.contains('timed out')) {
        throw NetworkException.timeout();
      }

      if (errorString.contains('network') ||
          errorString.contains('connection') ||
          errorString.contains('socket')) {
        throw NetworkException.noConnection();
      }

      throw AICommandException('Failed to reach agent. Please try again.');
    }
  }

  /// Checks device connectivity before making network requests.
  /// Throws [NetworkException.noConnection] if offline.
  Future<void> _checkConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity();
      if (result.contains(ConnectivityResult.none)) {
        throw NetworkException.noConnection();
      }
    } on NetworkException {
      rethrow;
    } catch (e) {
      // If connectivity check itself fails, proceed anyway
      // and let the HTTP call fail naturally if truly offline
      debugPrint('Connectivity check failed: $e');
    }
  }

  /// Returns true if the error is transient and worth retrying.
  bool _isRetryableError(Object e) {
    if (e is NetworkException) return true;
    final s = e.toString().toLowerCase();
    return s.contains('timeout') ||
        s.contains('socket') ||
        s.contains('connection') ||
        s.contains('network');
  }

  /// Tries to extract an error message from a JSON response body.
  String? _tryDecodeError(String body) {
    try {
      final data = jsonDecode(body);
      if (data is Map<String, dynamic>) {
        return data['detail']?.toString() ?? data['error']?.toString();
      }
    } catch (_) {}
    return null;
  }
}

