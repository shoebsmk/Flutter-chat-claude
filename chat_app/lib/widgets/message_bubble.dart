import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';

class MessageBubble extends StatefulWidget {
  final String content;
  final DateTime createdAt;
  final bool isMe;
  final String? senderName;
  final bool showAvatar;
  final bool showTimestamp;
  final bool isDeletable;
  final VoidCallback? onDelete;

  const MessageBubble({
    super.key,
    required this.content,
    required this.createdAt,
    required this.isMe,
    this.senderName,
    this.showAvatar = false,
    this.showTimestamp = true,
    this.isDeletable = false,
    this.onDelete,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _showFullTimestamp = false;

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
      return DateFormat('h:mm a').format(dateTime);
    } else if (difference.inDays == 1) {
      return 'Yesterday ${DateFormat('h:mm a').format(dateTime)}';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE h:mm a').format(dateTime);
    } else {
      return DateFormat('MMM d, h:mm a').format(dateTime);
    }
  }

  String _getFullTimestamp(DateTime dateTime) {
    return DateFormat('MMM d, y h:mm a').format(dateTime);
  }

  void _showDeleteOptions(BuildContext context) {
    if (!widget.isDeletable || widget.onDelete == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(LucideIcons.trash2, color: Colors.red),
                title: const Text('Delete message'),
                onTap: () {
                  Navigator.of(context).pop();
                  widget.onDelete?.call();
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.x),
                title: const Text('Cancel'),
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final messageColor = widget.isMe
        ? (isDark ? AppTheme.messageSentDark : AppTheme.messageSentLight)
        : (isDark
              ? AppTheme.messageReceivedDark
              : AppTheme.messageReceivedLight);

    final textColor = widget.isMe
        ? Colors.white
        : (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight);

    return Padding(
          padding: EdgeInsets.only(
            left: widget.isMe ? AppTheme.spacingL : AppTheme.spacingS,
            right: widget.isMe ? AppTheme.spacingS : AppTheme.spacingL,
            top: AppTheme.spacingXS,
            bottom: AppTheme.spacingXS,
          ),
          child: GestureDetector(
            onLongPress: widget.isDeletable && widget.onDelete != null
                ? () => _showDeleteOptions(context)
                : null,
            child: Row(
            mainAxisAlignment: widget.isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!widget.isMe && widget.showAvatar)
                Padding(
                  padding: const EdgeInsets.only(right: AppTheme.spacingS),
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: AppTheme.primaryLight,
                    child: Text(
                      widget.senderName?.substring(0, 1).toUpperCase() ?? '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              Flexible(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showFullTimestamp = !_showFullTimestamp;
                    });
                  },
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
                          widget.isMe ? AppTheme.radiusM : AppTheme.radiusXS,
                        ),
                        bottomRight: Radius.circular(
                          widget.isMe ? AppTheme.radiusXS : AppTheme.radiusM,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!widget.isMe && widget.senderName != null)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppTheme.spacingXS,
                            ),
                            child: Text(
                              widget.senderName!,
                              style: TextStyle(
                                color: textColor.withOpacity(0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        Text(
                          widget.content,
                          style: AppTheme.bodyMedium.copyWith(color: textColor),
                        ),
                        if (widget.showTimestamp)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: AppTheme.spacingXS,
                            ),
                            child: Text(
                              _showFullTimestamp
                                  ? _getFullTimestamp(widget.createdAt)
                                  : _formatTimestamp(widget.createdAt),
                              style: TextStyle(
                                color: textColor.withOpacity(0.7),
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (widget.isMe)
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
          ),
        )
        .animate()
        .fadeIn(duration: 200.ms)
        .slideY(begin: 0.1, end: 0, duration: 200.ms, curve: Curves.easeOut);
  }
}
