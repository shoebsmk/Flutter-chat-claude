import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';
import '../widgets/loading_shimmer.dart';
import '../widgets/user_avatar.dart';
import '../theme/app_theme.dart';

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
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  late Stream<List<Map<String, dynamic>>> _messagesStream;
  final currentUserId = Supabase.instance.client.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();

    // Query only messages between these two users
    _messagesStream = Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map(
          (data) => List<Map<String, dynamic>>.from(data)
              .where(
                (msg) =>
                    (msg['sender_id'] == currentUserId &&
                        msg['receiver_id'] == widget.receiverId) ||
                    (msg['sender_id'] == widget.receiverId &&
                        msg['receiver_id'] == currentUserId),
              )
              .toList(),
        );
    
    // Mark messages as read when opening chat
    _markMessagesAsRead();
  }

  /// Marks all unread messages from the receiver as read when chat is opened
  Future<void> _markMessagesAsRead() async {
    try {
      final response = await Supabase.instance.client
          .from('messages')
          .update({'is_read': true})
          .eq('sender_id', widget.receiverId)
          .eq('receiver_id', currentUserId)
          .eq('is_read', false)
          .select();
      
      if (response.isNotEmpty) {
        debugPrint('Marked ${response.length} messages as read');
      }
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Sends a message to the receiver and scrolls to bottom
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    try {
      await Supabase.instance.client.from('messages').insert({
        'sender_id': currentUserId,
        'receiver_id': widget.receiverId,
        'content': _messageController.text.trim(),
        'is_read': false, // New messages are unread by default
      });
      _messageController.clear();
      
      // Scroll to bottom after sending (reverse list, so 0 is bottom)
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $e'),
            backgroundColor: AppTheme.errorLight,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Parses timestamp from various formats (DateTime, String, or null)
  DateTime? _parseCreatedAt(dynamic createdAt) {
    if (createdAt == null) return DateTime.now();
    if (createdAt is DateTime) return createdAt;
    if (createdAt is String) {
      return DateTime.tryParse(createdAt) ?? DateTime.now();
    }
    return DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
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
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ChatListShimmer();
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        Text(
                          'Error loading messages',
                          style: AppTheme.bodyMedium.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
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

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTheme.spacingM,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['sender_id'] == currentUserId;
                    final createdAt = _parseCreatedAt(msg['created_at']) ?? DateTime.now();
                    
                    return MessageBubble(
                      content: msg['content'] ?? '',
                      createdAt: createdAt,
                      isMe: isMe,
                      senderName: isMe ? null : widget.receiverName,
                      showAvatar: !isMe && index < messages.length - 1
                          ? messages[index + 1]['sender_id'] != widget.receiverId
                          : !isMe,
                    );
                  },
                );
              },
            ),
          ),
          MessageInput(
            controller: _messageController,
            onSend: _sendMessage,
            hintText: 'Type a message...',
          ),
        ],
      ),
    );
  }
}
