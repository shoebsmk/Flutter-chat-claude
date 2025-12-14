import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../exceptions/app_exceptions.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/typing_service.dart';
import '../services/user_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';
import '../widgets/loading_shimmer.dart';
import '../widgets/user_avatar.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';

/// Screen for displaying and sending messages in a conversation.
class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String currentUserName;
  final String receiverName;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.currentUserName,
    required this.receiverName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Services
  final _authService = AuthService();
  final _chatService = ChatService();
  final _typingService = TypingService();
  final _userService = UserService();

  // Controllers
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  // Streams
  late Stream<List<Message>> _messagesStream;
  StreamSubscription<bool>? _typingStreamSubscription;

  // Typing indicator state
  Timer? _typingDebounceTimer;
  Timer? _typingAnimationTimer;
  bool _isOtherUserTyping = false;
  int _typingAnimationFrame = 0;

  // Constants
  static const Duration _typingDebounceDuration = Duration(seconds: 2);
  static const Duration _typingAnimationInterval = Duration(milliseconds: 400);
  static const int _typingDotCount = 3;

  String? get _currentUserId => _authService.currentUserId;

  @override
  void initState() {
    super.initState();
    _initializeMessagesStream();
    _markMessagesAsRead();
    _setupTypingListener();
    _messageController.addListener(_onTextChanged);
  }

  /// Sets up the typing indicator stream listener.
  ///
  /// Listens for typing status changes from the other user and updates
  /// the UI accordingly, including starting/stopping the animation.
  void _setupTypingListener() {
    _typingStreamSubscription?.cancel();
    _typingStreamSubscription = _typingService
        .getTypingStream(widget.receiverId)
        .listen(
          (isTyping) {
            if (!mounted) return;

            setState(() {
              _isOtherUserTyping = isTyping;
            });

            if (isTyping) {
              _startTypingAnimation();
            } else {
              _stopTypingAnimation();
            }
          },
          onError: (error) {
            debugPrint('Error in typing stream: $error');
          },
        );
  }

  /// Starts the typing indicator animation.
  ///
  /// Creates a periodic timer that cycles through animation frames
  /// to create a wave effect on the typing dots.
  void _startTypingAnimation() {
    _stopTypingAnimation();
    _typingAnimationTimer = Timer.periodic(
      _typingAnimationInterval,
      (_) {
        if (mounted && _isOtherUserTyping) {
          setState(() {
            _typingAnimationFrame = (_typingAnimationFrame + 1) % _typingDotCount;
          });
        }
      },
    );
  }

  /// Stops the typing indicator animation and resets the frame.
  void _stopTypingAnimation() {
    _typingAnimationTimer?.cancel();
    _typingAnimationTimer = null;
    _typingAnimationFrame = 0;
  }

  /// Handles text input changes to manage typing indicator.
  ///
  /// Starts typing indicator when user types, stops when input is empty,
  /// and automatically stops after a debounce period of no input.
  void _onTextChanged() {
    _typingDebounceTimer?.cancel();

    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText) {
      _typingService.startTyping(widget.receiverId);
      // Stop typing after debounce period of no input
      _typingDebounceTimer = Timer(_typingDebounceDuration, () {
        _typingService.stopTyping(widget.receiverId);
      });
    } else {
      _typingService.stopTyping(widget.receiverId);
    }
  }

  void _initializeMessagesStream() {
    _messagesStream = _chatService.getConversationStream(widget.receiverId);
  }

  /// Marks all unread messages from the receiver as read when chat is opened.
  Future<void> _markMessagesAsRead() async {
    await _chatService.markMessagesAsRead(widget.receiverId);
  }

  @override
  void dispose() {
    // Remove text controller listener and dispose
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();

    // Clean up typing indicator resources
    _typingDebounceTimer?.cancel();
    _stopTypingAnimation();
    _typingStreamSubscription?.cancel();
    _typingService.stopTyping(widget.receiverId);
    _typingService.dispose();

    super.dispose();
  }

  /// Sends a message to the receiver and scrolls to bottom.
  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    try {
      await _chatService.sendMessage(
        receiverId: widget.receiverId,
        content: content,
      );
      _messageController.clear();
      _typingService.stopTyping(widget.receiverId);

      // Scroll to bottom after sending (reverse list, so 0 is bottom)
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: AppConstants.animationSlow,
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ExceptionHandler.getMessage(e)),
            backgroundColor: AppTheme.errorLight,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: _buildAppBar(theme),
      body: Column(
        children: [
          Expanded(child: _buildMessageList(theme)),
          if (_isOtherUserTyping) _buildTypingIndicator(theme),
          MessageInput(
            controller: _messageController,
            onSend: _sendMessage,
            hintText: 'Type a message...',
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(ThemeData theme) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: StreamBuilder(
        stream: _userService.getUsersStream().map((users) {
          return users.firstWhere(
            (u) => u.id == widget.receiverId,
            orElse: () => User(
              id: widget.receiverId,
              username: widget.receiverName,
            ),
          );
        }),
        builder: (context, snapshot) {
          final user = snapshot.data;
          final isOnline = user?.isOnline ?? false;
          
          // Show "Typing..." if user is typing, otherwise show online/offline status
          final statusText = _isOtherUserTyping
              ? 'Typing...'
              : isOnline
                  ? 'Online'
                  : user?.lastSeen != null
                      ? 'Last seen ${AppDateUtils.formatRelative(user!.lastSeen)}'
                      : 'Offline';

          return Row(
            children: [
              UserAvatar(
                username: widget.receiverName,
                imageUrl: user?.avatarUrl,
                size: 36,
                showOnlineStatus: true,
                isOnline: isOnline,
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.receiverName,
                      style: AppTheme.headingSmall.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      statusText,
                      style: AppTheme.caption.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            // TODO: Show options menu
          },
        ),
      ],
    );
  }

  Widget _buildMessageList(ThemeData theme) {
    return StreamBuilder<List<Message>>(
      stream: _messagesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ChatListShimmer();
        }

        if (snapshot.hasError) {
          return _buildErrorState(theme);
        }

        final messages = snapshot.data ?? [];
        if (messages.isEmpty) {
          return _buildEmptyState(theme);
        }

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            return _buildMessageBubble(message, messages, index);
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(
    Message message,
    List<Message> messages,
    int index,
  ) {
    final isMe = message.isSentBy(_currentUserId ?? '');

    // Determine if we should show avatar (for received messages)
    final showAvatar =
        !isMe &&
        (index >= messages.length - 1 ||
            messages[index + 1].senderId != widget.receiverId);

    return MessageBubble(
      content: message.content,
      createdAt: message.createdAt,
      isMe: isMe,
      senderName: isMe ? null : widget.receiverName,
      showAvatar: showAvatar,
      isDeletable: isMe && !message.isDeleted,
      onDelete: isMe && !message.isDeleted
          ? () => _handleDeleteMessage(message)
          : null,
    );
  }

  /// Handles message deletion with confirmation dialog.
  Future<void> _handleDeleteMessage(Message message) async {
    if (message.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete message'),
        content: const Text(
          'Are you sure you want to delete this message? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _chatService.deleteMessage(message.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Message deleted'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ExceptionHandler.getMessage(e)),
              backgroundColor: AppTheme.errorLight,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Widget _buildTypingIndicator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      child: Row(
        children: [
          UserAvatar(
            username: widget.receiverName,
            imageUrl: null, // Will be updated when user data is available
            size: 32,
            showOnlineStatus: false,
          ),
          const SizedBox(width: AppTheme.spacingS),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(theme, 0),
                const SizedBox(width: 3),
                _buildTypingDot(theme, 1),
                const SizedBox(width: 3),
                _buildTypingDot(theme, 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a single typing indicator dot with animated opacity.
  ///
  /// Creates a wave effect by varying opacity based on the current
  /// animation frame and the dot's index.
  Widget _buildTypingDot(ThemeData theme, int index) {
    final frameOffset = (index - _typingAnimationFrame) % _typingDotCount;
    final opacity = frameOffset == 0 ? 1.0 : (frameOffset == 1 ? 0.5 : 0.3);

    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(opacity),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            'Error loading messages',
            style: AppTheme.bodyMedium.copyWith(color: theme.colorScheme.error),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: AppTheme.spacingL),
          Text(
            'No messages yet',
            style: AppTheme.headingSmall.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'Start the conversation!',
            style: AppTheme.bodyMedium.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}
