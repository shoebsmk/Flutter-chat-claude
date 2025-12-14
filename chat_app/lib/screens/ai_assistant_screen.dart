import 'dart:math';
import 'package:flutter/material.dart';
import '../services/ai_command_service.dart';
import '../services/user_service.dart';
import '../services/chat_service.dart';
import '../models/user.dart' as models;
import '../exceptions/app_exceptions.dart';
import '../theme/app_theme.dart';

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
  bool _isProcessing = false;
  List<User> _allUsers = [];
  bool _isLoadingUsers = true;
  bool _showSuggestionButton = true;
  User? _suggestionContact;
  final String _suggestionMessage = "I'll be late";

  @override
  void initState() {
    super.initState();
    _loadUsers();
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

    setState(() => _isProcessing = true);

    try {
      // Extract intent
      final intent = await _aiCommandService.extractIntent(command);

      // Validate extracted message
      if (intent['message']?.isEmpty ?? true) {
        _showError('Could not extract message from command');
        return;
      }

      // Resolve recipient
      final recipientQuery = intent['recipient_query'] ?? '';
      if (recipientQuery.isEmpty) {
        _showError('Could not identify recipient. Please include a name in your command.');
        return;
      }

      final recipient = await _aiCommandService.resolveRecipient(
        recipientQuery,
        _allUsers,
      );

      if (recipient == null) {
        _showError('Recipient "$recipientQuery" not found. Please check the name and try again.');
        return;
      }

      // Show confirmation
      final confirmed = await _showConfirmationDialog(
        recipient: recipient,
        message: intent['message']!,
      );

      if (confirmed == true && mounted) {
        // Send message
        await _chatService.sendMessage(
          receiverId: recipient.id,
          content: intent['message']!,
        );

        _showSuccess('Message sent to ${recipient.username}');
        _commandController.clear();
        
        // Hide suggestion button after successful send
        if (mounted) {
          setState(() {
            _showSuggestionButton = false;
          });
        }
      }
    } on AICommandException catch (e) {
      _showError(e.message);
    } on NetworkException catch (e) {
      _showError('Network error. Please check your connection.');
    } catch (e) {
      debugPrint('Error processing command: $e');
      _showError('An unexpected error occurred. Please try again.');
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
      ),
      body: _isLoadingUsers
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Content area
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingXL,
                        vertical: AppTheme.spacingXXL,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.smart_toy,
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
                                        Icons.lightbulb_outline,
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
                              _buildExampleItem('"Tell Ahmed Meeting cancelled"', theme),
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
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commandController,
                            enabled: !_isProcessing,
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
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isProcessing ? null : _processCommand,
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
                                        Icons.send,
                                        color: Colors.white,
                                        size: 20,
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

  @override
  void dispose() {
    _commandController.dispose();
    super.dispose();
  }
}

