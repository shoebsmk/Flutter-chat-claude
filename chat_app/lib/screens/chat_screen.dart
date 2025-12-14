import 'package:flutter/material.dart';
import '../exceptions/app_exceptions.dart';
import '../models/message.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';
import '../widgets/loading_shimmer.dart';
import '../widgets/user_avatar.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';

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
  final _authService = AuthService();
  final _chatService = ChatService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  late Stream<List<Message>> _messagesStream;

  String? get _currentUserId => _authService.currentUserId;

  @override
  void initState() {
    super.initState();
    _initializeMessagesStream();
    _markMessagesAsRead();
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
    _messageController.dispose();
    _scrollController.dispose();
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
      title: Row(
        children: [
          UserAvatar(
            username: widget.receiverName,
            size: 36,
            showOnlineStatus: true,
            isOnline: false, // TODO: Implement online status
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
                  'Online', // TODO: Get actual status
                  style: AppTheme.caption.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
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
