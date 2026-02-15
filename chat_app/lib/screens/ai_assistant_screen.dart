import 'dart:async';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/ai_command_service.dart';
import '../services/thread_storage_service.dart';
import '../services/user_service.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../models/user.dart' as models;
import '../exceptions/app_exceptions.dart';
import '../theme/app_theme.dart';
import '../widgets/sentiment_chart_widget.dart';
import '../services/speech_service.dart';

// Type alias for readability
typedef User = models.User;

/// Screen for AI-powered command-based messaging.
/// 
/// Allows users to send messages using natural language commands
/// like "Send Ahmed I'll be late".
class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final _commandController = TextEditingController();
  final _aiCommandService = AICommandService();
  final _userService = UserService();
  final _chatService = ChatService();
  final _scrollController = ScrollController();
  bool _isProcessing = false;
  List<User> _allUsers = [];
  bool _isLoadingUsers = true;
  bool _showSuggestionButton = true;

  // Agent mode: when true, commands go to LangGraph agent
  bool _useAgent = true;
  String? _threadId;

  // Connectivity
  bool _isOffline = false;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  // Typing indicator for cold start UX
  bool _showTypingIndicator = false;
  Timer? _coldStartTimer;
  String? _coldStartHint;
  User? _suggestionContact;
  final String _suggestionMessage = "I'll be late";

  // Voice input
  bool _isListeningToVoice = false;
  
  // Chat state
  List<Map<String, dynamic>> _messages = [];
  bool _hasMessages = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadPersistedThread();
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      if (mounted) {
        setState(() {
          _isOffline = results.contains(ConnectivityResult.none);
        });
      }
    });
  }

  /// Hydrates _threadId and _messages from local storage for conversation continuity.
  Future<void> _loadPersistedThread() async {
    final userId = AuthService().currentUserId;
    if (userId == null) return;
    final stored = await ThreadStorageService.loadThreadId(userId);
    final messages = await ThreadStorageService.loadMessages(userId);
    if (mounted) {
      setState(() {
        if (stored != null) _threadId = stored;
        if (messages.isNotEmpty) {
          _messages = messages;
          _hasMessages = true;
        }
      });
    }
  }

  /// Starts a fresh conversation by clearing the stored thread and messages.
  Future<void> _startNewConversation() async {
    final userId = AuthService().currentUserId;
    if (userId != null) {
      await ThreadStorageService.clearThreadId(userId);
      await ThreadStorageService.clearMessages(userId);
    }
    if (mounted) {
      setState(() {
        _threadId = null;
        _messages = [];
        _hasMessages = false;
      });
    }
  }

  void _addMessage({
    required String content,
    required bool isUser,
    bool? isSuccess,
    String? recipientName,
  }) {
    setState(() {
      _messages.add({
        'content': content,
        'isUser': isUser,
        'timestamp': DateTime.now(),
        'isSuccess': isSuccess,
        'recipientName': recipientName,
      });
      if (!_hasMessages) {
        _hasMessages = true;
      }
    });
    // Persist messages to local storage
    final userId = AuthService().currentUserId;
    if (userId != null) {
      ThreadStorageService.saveMessages(userId, _messages);
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _userService.getAllUsers();
      if (mounted) {
        // Filter out current user from available contacts
        final currentUserId = _userService.currentUserId;
        final otherUsers = currentUserId != null
            ? users.where((user) => user.id != currentUserId).toList()
            : users;
        
        setState(() {
          _allUsers = users;
          _isLoadingUsers = false;
          // Select random contact for suggestion button (excluding current user)
          if (otherUsers.isNotEmpty) {
            _suggestionContact = otherUsers[Random().nextInt(otherUsers.length)];
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading users: $e');
      if (mounted) {
        setState(() {
          _isLoadingUsers = false;
        });
        _showError('Failed to load users. Please try again.');
      }
    }
  }

  Future<void> _processCommand() async {
    final command = _commandController.text.trim();
    if (command.isEmpty || _isProcessing) return;

    // Add user command to messages
    _addMessage(
      content: command,
      isUser: true,
    );

    setState(() => _isProcessing = true);
    _commandController.clear();

    if (_useAgent) {
      await _processWithAgent(command);
    } else {
      await _processWithEdgeFunction(command);
    }
  }

  /// New path: sends command to the LangGraph agent.
  /// Two-step flow: first preview (confirm_only), then execute after user confirms.
  Future<void> _processWithAgent(String command) async {
    setState(() => _showTypingIndicator = true);
    _scrollToBottom();

    // Show cold start hint after 8 seconds of waiting
    _coldStartTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && _showTypingIndicator) {
        setState(() => _coldStartHint = 'This may take a moment...');
      }
    });

    try {
      final userId = AuthService().currentUserId ?? '';

      // Step 1: Preview — ask agent to extract intent without sending
      final preview = await _aiCommandService.sendToAgent(
        command,
        userId,
        threadId: _threadId,
        confirmOnly: true,
      );

      // Persist thread for the execute step and for future sessions
      if (preview['thread_id']?.toString().isNotEmpty == true) {
        _threadId = preview['thread_id'] as String;
        final userId = AuthService().currentUserId;
        if (userId != null) {
          ThreadStorageService.saveThreadId(userId, _threadId!);
        }
      }

      _coldStartTimer?.cancel();
      setState(() {
        _showTypingIndicator = false;
        _coldStartHint = null;
      });

      final pendingAction = preview['pending_action'] as Map<String, dynamic>?;
      final previewResponse = preview['response']?.toString() ?? '';

      if (pendingAction != null && pendingAction['action'] == 'send_message') {
        // Extract recipients and message for confirmation
        final recipients = (pendingAction['recipients'] as List<dynamic>?)
                ?.map((r) => (r as Map<String, dynamic>)['name']?.toString() ?? '')
                .where((n) => n.isNotEmpty)
                .toList() ??
            [];
        final message = pendingAction['message']?.toString() ?? '';

        if (recipients.isEmpty) {
          _addMessage(
            content: 'Could not identify recipients. Please try again.',
            isUser: false,
            isSuccess: false,
          );
          return;
        }

        // Don't show the raw JSON response to the user - it's not user-friendly
        // The confirmation dialog will show the message details in a clean format

        // Show confirmation dialog
        final confirmed = await _showAgentConfirmationDialog(
          recipients: recipients,
          message: message,
        );

        if (confirmed == true && mounted) {
          // Step 2: Execute — tell agent to send
          setState(() => _showTypingIndicator = true);
          _scrollToBottom();

          final result = await _aiCommandService.sendToAgent(
            'Yes, send the message as planned.',
            userId,
            threadId: _threadId,
            execute: true,
          );

          setState(() => _showTypingIndicator = false);

          final agentResponse = result['response']?.toString() ?? '';
          final toolResults = result['tool_results'] as List<dynamic>? ?? [];

          if (mounted) {
            _addMessage(
              content: agentResponse.isNotEmpty ? agentResponse : 'Done!',
              isUser: false,
              isSuccess: toolResults.isNotEmpty ? true : null,
            );
          }
        } else if (mounted) {
          _addMessage(
            content: 'Message cancelled.',
            isUser: false,
            isSuccess: false,
          );
        }
      } else {
        // No send action (e.g. contact lookup, recent chats, general chat)
        final agentResponse = preview['response']?.toString() ?? '';
        if (mounted) {
          _addMessage(
            content: agentResponse.isNotEmpty ? agentResponse : 'Done!',
            isUser: false,
            isSuccess: null,
          );
        }
      }
    } on AICommandException catch (e) {
      if (mounted) {
        _addMessage(
          content: e.message,
          isUser: false,
          isSuccess: false,
        );
      }
    } on NetworkException catch (e) {
      if (mounted) {
        _addMessage(
          content: e.message,
          isUser: false,
          isSuccess: false,
        );
      }
    } catch (e) {
      debugPrint('Error processing agent command: $e');
      if (mounted) {
        _addMessage(
          content: 'An unexpected error occurred. Please try again.',
          isUser: false,
          isSuccess: false,
        );
      }
    } finally {
      _coldStartTimer?.cancel();
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _showTypingIndicator = false;
          _coldStartHint = null;
        });
      }
    }
  }

  /// Confirmation dialog for the agent path.
  /// Shows recipients (supports multiple) and message preview.
  Future<bool?> _showAgentConfirmationDialog({
    required List<String> recipients,
    required String message,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Send'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('To: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text(
                    recipients.join(', '),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            const Text('Message:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppTheme.spacingS),
            Text(message),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  /// Old path: uses Supabase Edge Function for intent extraction
  /// and local recipient resolution. Kept intact for fallback.
  Future<void> _processWithEdgeFunction(String command) async {
    try {
      // Extract intent
      final intent = await _aiCommandService.extractIntent(command);

      // Validate extracted message
      if (intent['message']?.isEmpty ?? true) {
        if (mounted) {
          final aiResponse = intent['ai_response']?.toString() ?? '';
          _addMessage(
            content: aiResponse.isNotEmpty
                ? aiResponse
                : "I'm here to help! Please tell me who you'd like to text and what message you want to send. For example: \"Send John Hello there\" or \"Message Sarah I'll be late\"",
            isUser: false,
            isSuccess: false,
          );
        }
        return;
      }

      // Resolve recipient
      final recipientQuery = intent['recipient_query'] ?? '';
      if (recipientQuery.isEmpty) {
        if (mounted) {
          final aiResponse = intent['ai_response']?.toString() ?? '';
          _addMessage(
            content: aiResponse.isNotEmpty
                ? aiResponse
                : 'Could not identify recipient. Please include a name in your command.',
            isUser: false,
            isSuccess: false,
          );
        }
        return;
      }

      final recipient = await _aiCommandService.resolveRecipient(
        recipientQuery,
        _allUsers,
      );

      if (recipient == null) {
        if (mounted) {
          final aiResponse = intent['ai_response']?.toString() ?? '';
          _addMessage(
            content: aiResponse.isNotEmpty
                ? aiResponse
                : 'Recipient "$recipientQuery" not found. Please check the name and try again.',
            isUser: false,
            isSuccess: false,
          );
        }
        return;
      }

      // Show confirmation
      final confirmed = await _showConfirmationDialog(
        recipient: recipient,
        message: intent['message']!,
      );

      if (confirmed == true && mounted) {
        // Send message
        try {
          await _chatService.sendMessage(
            receiverId: recipient.id,
            content: intent['message']!,
          );

          if (mounted) {
            _addMessage(
              content: 'Message sent to ${recipient.username}',
              isUser: false,
              isSuccess: true,
              recipientName: recipient.username,
            );
          }
        } on ChatException catch (e) {
          if (mounted) {
            _addMessage(
              content: 'Failed to send message: ${e.message}',
              isUser: false,
              isSuccess: false,
            );
          }
        } on AuthException catch (e) {
          if (mounted) {
            _addMessage(
              content: 'Authentication error: ${e.message}',
              isUser: false,
              isSuccess: false,
            );
          }
        } catch (e) {
          debugPrint('Error sending message: $e');
          if (mounted) {
            _addMessage(
              content: 'Failed to send message. Please try again.',
              isUser: false,
              isSuccess: false,
            );
          }
        }
      } else if (confirmed == false && mounted) {
        // User cancelled
        _addMessage(
          content: 'Message cancelled',
          isUser: false,
          isSuccess: false,
        );
      }
    } on AICommandException catch (e) {
      if (mounted) {
        _addMessage(
          content: 'Failed to send: ${e.message}',
          isUser: false,
          isSuccess: false,
        );
      }
    } on NetworkException catch (e) {
      if (mounted) {
        _addMessage(
          content: 'Network error. Please check your connection.',
          isUser: false,
          isSuccess: false,
        );
      }
    } catch (e) {
      debugPrint('Error processing command: $e');
      if (mounted) {
        _addMessage(
          content: 'An unexpected error occurred. Please try again.',
          isUser: false,
          isSuccess: false,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<bool?> _showConfirmationDialog({
    required User recipient,
    required String message,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Send'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('To: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text(
                    recipient.username,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            const Text('Message:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppTheme.spacingS),
            Text(message),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successLight,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleSuggestionTap() async {
    if (_suggestionContact == null || _isProcessing) return;

    // Construct command string
    final command = 'Send ${_suggestionContact!.username} $_suggestionMessage';
    
    // Set the command in the text field and process it
    _commandController.text = command;
    await _processCommand();
  }

  Future<void> _toggleVoiceInput() async {
    final speech = SpeechService.instance;

    if (_isListeningToVoice) {
      await speech.stopListening();
      setState(() => _isListeningToVoice = false);
      // If text was captured, auto-submit
      if (_commandController.text.trim().isNotEmpty) {
        _processCommand();
      }
      return;
    }

    final available = await speech.initialize();
    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Speech recognition not available on this device.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    setState(() => _isListeningToVoice = true);

    await speech.startListening(
      onResult: (text, isFinal) {
        if (mounted) {
          setState(() {
            _commandController.text = text;
            _commandController.selection = TextSelection.fromPosition(
              TextPosition(offset: text.length),
            );
          });
          if (isFinal) {
            setState(() => _isListeningToVoice = false);
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Assist'),
        actions: [
          if (_hasMessages || _threadId != null)
            IconButton(
              icon: const Icon(LucideIcons.plusCircle),
              tooltip: 'New Conversation',
              onPressed: _isProcessing ? null : _startNewConversation,
            ),
        ],
      ),
      body: _isLoadingUsers
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Offline banner
                if (_isOffline)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingM,
                      vertical: AppTheme.spacingS,
                    ),
                    color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.wifiOff,
                          size: 16,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: AppTheme.spacingS),
                        Text(
                          'No internet connection',
                          style: AppTheme.bodySmall.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Content area - Welcome or Chat
                Expanded(
                  child: (_hasMessages || _showTypingIndicator)
                      ? ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppTheme.spacingM,
                          ),
                          itemCount: _messages.length + (_showTypingIndicator ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _messages.length && _showTypingIndicator) {
                              return _buildTypingIndicator(theme);
                            }
                            return _buildMessageBubble(_messages[index], theme);
                          },
                        )
                      : Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingXL,
                              vertical: AppTheme.spacingXXL,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.sparkles,
                                  size: 72,
                                  color: theme.colorScheme.onSurface.withOpacity(0.2),
                                ),
                                const SizedBox(height: AppTheme.spacingXL),
                                Text(
                                  'AI-Powered Messaging',
                                  style: AppTheme.headingMedium.copyWith(
                                    color: theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppTheme.spacingM),
                                Text(
                                  'Send messages using natural language commands.',
                                  style: AppTheme.bodyLarge.copyWith(
                                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppTheme.spacingXL),
                                // Suggestion button (only show if enabled and contact available)
                                if (_showSuggestionButton && _suggestionContact != null)
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _isProcessing ? null : _handleSuggestionTap,
                                      borderRadius: BorderRadius.circular(AppTheme.radiusL),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppTheme.spacingM,
                                          vertical: AppTheme.spacingS,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(AppTheme.radiusL),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              LucideIcons.lightbulb,
                                              size: 16,
                                              color: theme.colorScheme.primary.withOpacity(0.7),
                                            ),
                                            const SizedBox(width: AppTheme.spacingS),
                                            Text(
                                              'Try: "Send ${_suggestionContact!.username} $_suggestionMessage"',
                                              style: AppTheme.bodySmall.copyWith(
                                                color: theme.colorScheme.primary.withOpacity(0.8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                if (_showSuggestionButton && _suggestionContact != null)
                                  const SizedBox(height: AppTheme.spacingXL),
                                // Examples
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Examples:',
                                      style: AppTheme.bodyMedium.copyWith(
                                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: AppTheme.spacingS),
                                    _buildExampleItem('"Send John Hello"', theme),
                                    const SizedBox(height: AppTheme.spacingXS),
                                    _buildExampleItem('"Message Sarah I\'ll be there in 10 minutes"', theme),
                                    const SizedBox(height: AppTheme.spacingXS),
                                    _buildExampleItem('"Tell Ahmed and Sara Meeting at 3pm"', theme),
                                    const SizedBox(height: AppTheme.spacingXS),
                                    _buildExampleItem('"Summarize my chat with Ahmed"', theme),
                                    const SizedBox(height: AppTheme.spacingXS),
                                    _buildExampleItem('"What did I miss today?"', theme),
                                    const SizedBox(height: AppTheme.spacingXS),
                                    _buildExampleItem('"How\'s the mood with Sara?"', theme),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                ),

                // Bottom input section
                SafeArea(
                  top: false,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.only(
                      left: AppTheme.spacingM,
                      right: AppTheme.spacingM,
                      top: AppTheme.spacingM,
                      bottom: AppTheme.spacingM + MediaQuery.of(context).padding.bottom,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commandController,
                            enabled: !_isProcessing && !_isOffline,
                            decoration: InputDecoration(
                              hintText: 'Type your command...',
                              hintStyle: AppTheme.bodyMedium.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.4),
                              ),
                              filled: true,
                              fillColor: theme.colorScheme.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusL),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusL),
                                borderSide: BorderSide(
                                  color: theme.colorScheme.onSurface.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTheme.radiusL),
                                borderSide: BorderSide(
                                  color: theme.colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.spacingM,
                                vertical: AppTheme.spacingM,
                              ),
                            ),
                            onSubmitted: (_) => _processCommand(),
                            maxLength: 500,
                            maxLines: 3,
                            minLines: 1,
                            style: AppTheme.bodyMedium,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingS),
                        // Mic button for voice commands
                        Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: _isListeningToVoice
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.surface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _isListeningToVoice
                                      ? theme.colorScheme.error
                                      : theme.colorScheme.onSurface.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: (_isProcessing || _isOffline) ? null : _toggleVoiceInput,
                                  borderRadius: BorderRadius.circular(24),
                                  child: Center(
                                    child: Icon(
                                      _isListeningToVoice ? LucideIcons.micOff : LucideIcons.mic,
                                      color: _isListeningToVoice
                                          ? Colors.white
                                          : theme.colorScheme.onSurface.withOpacity(0.6),
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingS),
                        // Send button
                        Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: (_isProcessing || _isOffline) ? null : _processCommand,
                                  borderRadius: BorderRadius.circular(24),
                                  child: Center(
                                    child: _isProcessing
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : const Icon(
                                            LucideIcons.send,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildExampleItem(String text, ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.only(right: AppTheme.spacingS),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.4),
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: AppTheme.bodySmall.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypingIndicator(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final messageColor = isDark
        ? AppTheme.messageReceivedDark
        : AppTheme.messageReceivedLight;

    return Padding(
      padding: const EdgeInsets.only(
        left: AppTheme.spacingS,
        right: AppTheme.spacingL,
        top: AppTheme.spacingXS,
        bottom: AppTheme.spacingXS,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppTheme.spacingS),
            child: Icon(
              LucideIcons.sparkles,
              size: 20,
              color: theme.colorScheme.primary.withOpacity(0.7),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingM,
                  vertical: AppTheme.spacingS + 4,
                ),
                decoration: BoxDecoration(
                  color: messageColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.radiusM),
                    topRight: Radius.circular(AppTheme.radiusM),
                    bottomLeft: Radius.circular(AppTheme.radiusXS),
                    bottomRight: Radius.circular(AppTheme.radiusM),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildBouncingDot(0, theme),
                    const SizedBox(width: 4),
                    _buildBouncingDot(1, theme),
                    const SizedBox(width: 4),
                    _buildBouncingDot(2, theme),
                  ],
                ),
              ),
              if (_coldStartHint != null)
                Padding(
                  padding: const EdgeInsets.only(
                    top: AppTheme.spacingXS,
                    left: AppTheme.spacingXS,
                  ),
                  child: Text(
                    _coldStartHint!,
                    style: AppTheme.bodySmall.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 11,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBouncingDot(int index, ThemeData theme) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withOpacity(0.4),
        shape: BoxShape.circle,
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .fadeIn(
          delay: Duration(milliseconds: index * 200),
          duration: 400.ms,
        )
        .then()
        .fadeOut(duration: 400.ms);
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, ThemeData theme) {
    final isUser = message['isUser'] as bool;
    final content = message['content'] as String;
    final timestamp = message['timestamp'] as DateTime;
    final isSuccess = message['isSuccess'] as bool?;
    final isDark = theme.brightness == Brightness.dark;

    final messageColor = isUser
        ? (isDark ? AppTheme.messageSentDark : AppTheme.messageSentLight)
        : (isDark
              ? AppTheme.messageReceivedDark
              : AppTheme.messageReceivedLight);

    final textColor = isUser
        ? Colors.white
        : (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight);

    return Padding(
      padding: EdgeInsets.only(
        left: isUser ? AppTheme.spacingL : AppTheme.spacingS,
        right: isUser ? AppTheme.spacingS : AppTheme.spacingL,
        top: AppTheme.spacingXS,
        bottom: AppTheme.spacingXS,
      ),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser)
            Padding(
              padding: const EdgeInsets.only(right: AppTheme.spacingS),
              child: Icon(
                LucideIcons.sparkles,
                size: 20,
                color: theme.colorScheme.primary.withOpacity(0.7),
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingM,
                vertical: AppTheme.spacingS,
              ),
              decoration: BoxDecoration(
                color: messageColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppTheme.radiusM),
                  topRight: const Radius.circular(AppTheme.radiusM),
                  bottomLeft: Radius.circular(
                    isUser ? AppTheme.radiusM : AppTheme.radiusXS,
                  ),
                  bottomRight: Radius.circular(
                    isUser ? AppTheme.radiusXS : AppTheme.radiusM,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          content,
                          style: AppTheme.bodyMedium.copyWith(color: textColor),
                        ),
                      ),
                      if (!isUser && isSuccess != null) ...[
                        const SizedBox(width: AppTheme.spacingXS),
                        Icon(
                          isSuccess ? LucideIcons.checkCircle2 : LucideIcons.alertCircle,
                          size: 16,
                          color: isSuccess
                              ? AppTheme.successLight
                              : AppTheme.errorLight,
                        ),
                      ],
                    ],
                  ),
                  // Sentiment chart (only for AI responses)
                  if (!isUser) ..._buildSentimentChart(content),
                  const SizedBox(height: AppTheme.spacingXS),
                  Text(
                    _formatTimestamp(timestamp),
                    style: TextStyle(
                      color: textColor.withOpacity(0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser)
            Padding(
              padding: const EdgeInsets.only(left: AppTheme.spacingXS),
              child: Icon(
                LucideIcons.checkCheck,
                size: 16,
                color: textColor.withOpacity(0.7),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildSentimentChart(String content) {
    final chartJson = SentimentChartWidget.extractChartData(content);
    if (chartJson == null) return [];
    return [
      const SizedBox(height: AppTheme.spacingS),
      SentimentChartWidget(jsonData: chartJson),
    ];
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  @override
  void dispose() {
    _coldStartTimer?.cancel();
    _connectivitySubscription.cancel();
    _commandController.dispose();
    _scrollController.dispose();
    SpeechService.instance.cancel();
    super.dispose();
  }
}

