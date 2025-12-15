import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
  final _scrollController = ScrollController();
  bool _isProcessing = false;
  List<User> _allUsers = [];
  bool _isLoadingUsers = true;
  bool _showSuggestionButton = true;
  User? _suggestionContact;
  final String _suggestionMessage = "I'll be late";
  
  // Chat state
  List<Map<String, dynamic>> _messages = [];
  bool _hasMessages = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
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
        // Try to get ai_response from the exception context if available
        // For now, use the exception message
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Assist'),
      ),
      body: _isLoadingUsers
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Content area - Welcome or Chat
                Expanded(
                  child: _hasMessages
                      ? ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppTheme.spacingM,
                          ),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
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
                      crossAxisAlignment: CrossAxisAlignment.start,
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
    _commandController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

