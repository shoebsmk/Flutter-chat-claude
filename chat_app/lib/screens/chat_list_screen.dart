import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_animate/flutter_animate.dart';
import 'chat_screen.dart';
import 'auth_screen.dart';
import '../widgets/user_avatar.dart';
import '../widgets/loading_shimmer.dart';
import '../theme/app_theme.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> with WidgetsBindingObserver {
  late Stream<List<Map<String, dynamic>>> _usersStream;
  late Stream<List<Map<String, dynamic>>> _messagesStream;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final currentUserId = Supabase.instance.client.auth.currentUser?.id;
  Map<String, int> _previousUnreadCounts = {};
  AppLifecycleState? _appLifecycleState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _usersStream = Supabase.instance.client
        .from('users')
        .stream(primaryKey: ['id'])
        .order('created_at');
    
    // Stream all messages involving the current user
    if (currentUserId != null) {
      _messagesStream = Supabase.instance.client
          .from('messages')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .map((data) => List<Map<String, dynamic>>.from(data)
              .where((msg) =>
                  msg['sender_id'] == currentUserId ||
                  msg['receiver_id'] == currentUserId)
              .toList());
    } else {
      _messagesStream = Stream.value([]);
    }
    
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appLifecycleState = state;
  }

  Future<void> _playNotificationSound() async {
    // Only play if app is in foreground
    if (_appLifecycleState != AppLifecycleState.resumed) return;
    
    try {
      // Use system sound for simplicity (no asset file needed)
      SystemSound.play(SystemSoundType.alert);
    } catch (e) {
      debugPrint('Error playing notification sound: $e');
    }
  }

  /// Processes stream data to extract the absolute latest message per conversation and unread counts
  Map<String, Map<String, dynamic>> _processLastMessages(
      List<Map<String, dynamic>> messages, List<String> userIds) {
    final result = <String, Map<String, dynamic>>{};
    
    if (currentUserId == null || userIds.isEmpty) return result;

    // Map to store the absolute latest message per conversation
    final Map<String, Map<String, dynamic>> lastMessagesByUser = {};
    // Map to store unread counts per conversation
    final Map<String, int> unreadCountsByUser = {};
    
    for (final msg in messages) {
      final senderId = msg['sender_id']?.toString();
      final receiverId = msg['receiver_id']?.toString();
      final isRead = msg['is_read'] as bool? ?? false;
      final createdAt = _parseTimestamp(msg['created_at']);
      
      // Determine the other user in this conversation
      String? otherUserId;
      if (senderId == currentUserId) {
        otherUserId = receiverId;
      } else if (receiverId == currentUserId) {
        otherUserId = senderId;
        // Count unread messages (only for messages received by current user)
        if (!isRead && otherUserId != null && userIds.contains(otherUserId)) {
          unreadCountsByUser[otherUserId] = (unreadCountsByUser[otherUserId] ?? 0) + 1;
        }
      }
      
      if (otherUserId == null || !userIds.contains(otherUserId)) continue;
      
      // Store the absolute latest message for this conversation by comparing timestamps
      final existingLastMessage = lastMessagesByUser[otherUserId];
      if (existingLastMessage == null) {
        lastMessagesByUser[otherUserId] = Map<String, dynamic>.from(msg);
      } else {
        // Compare timestamps to ensure we have the absolute latest message
        final existingTime = _parseTimestamp(existingLastMessage['created_at']);
        if (createdAt != null && existingTime != null && createdAt.isAfter(existingTime)) {
          lastMessagesByUser[otherUserId] = Map<String, dynamic>.from(msg);
        }
      }
    }
    
    // Combine last message and unread count
    for (final entry in lastMessagesByUser.entries) {
      result[entry.key] = {
        'lastMessage': entry.value,
        'unreadCount': unreadCountsByUser[entry.key] ?? 0,
      };
    }
    
    return result;
  }

  /// Parses a timestamp from various formats
  DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;
    if (timestamp is DateTime) return timestamp;
    if (timestamp is String) return DateTime.tryParse(timestamp);
    return null;
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserEmail = Supabase.instance.client.auth.currentUser?.email;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Messages',
              style: AppTheme.headingSmall.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (currentUserEmail != null)
              Text(
                currentUserEmail,
                style: AppTheme.caption.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search conversations...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
          ),
          // Chat list
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _usersStream,
              builder: (context, usersSnapshot) {
                if (usersSnapshot.connectionState == ConnectionState.waiting) {
                  return const ChatListShimmer();
                }

                if (usersSnapshot.hasError) {
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
                          'Error loading chats',
                          style: AppTheme.bodyMedium.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final users = usersSnapshot.data ?? [];
                final otherUsers = users
                    .where((u) => u['id'] != currentUserId)
                    .toList();

                if (otherUsers.isEmpty) {
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
                          'No conversations yet',
                          style: AppTheme.headingSmall.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: AppTheme.spacingS),
                          child: Text(
                            'Start chatting with someone!',
                            style: AppTheme.bodyMedium.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final currentUserList = users
                    .where((u) => u['id'] == currentUserId)
                    .toList();
                final currentUserName = currentUserList.isNotEmpty
                    ? (currentUserList.first['username'] ?? 'User')
                    : 'User';

                // Stream messages and process them in real-time
                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _messagesStream,
                  builder: (context, messagesSnapshot) {
                    // Show loading state while initializing messages stream
                    if (messagesSnapshot.connectionState == ConnectionState.waiting &&
                        usersSnapshot.connectionState == ConnectionState.waiting) {
                      return const ChatListShimmer();
                    }
                    
                    // Handle errors gracefully - still show users even if messages fail to load
                    if (messagesSnapshot.hasError) {
                      debugPrint('Error loading messages: ${messagesSnapshot.error}');
                    }
                    
                    // Process messages to get last message per conversation
                    final messages = messagesSnapshot.data ?? [];
                    final userIds = otherUsers.map((u) => u['id'].toString()).toList();
                    final lastMessages = _processLastMessages(messages, userIds);
                    
                    // Combine users with their last messages and sort
                    final List<Map<String, dynamic>> sortedUsers = [];
                    
                    for (final user in otherUsers) {
                      final userId = user['id'].toString();
                      final data = lastMessages[userId];
                      final lastMessage = data?['lastMessage'] as Map<String, dynamic>?;
                      final unreadCount = data?['unreadCount'] as int? ?? 0;
                      
                      sortedUsers.add({
                        'user': user,
                        'lastMessage': lastMessage,
                        'lastMessageTime': lastMessage != null
                            ? _parseTimestamp(lastMessage['created_at'])
                            : null,
                        'unreadCount': unreadCount,
                      });
                    }

                    // Sort: prioritize unread conversations, then by message time, then no messages at bottom
                    sortedUsers.sort((a, b) {
                      final aTime = a['lastMessageTime'] as DateTime?;
                      final bTime = b['lastMessageTime'] as DateTime?;
                      final aUnread = a['unreadCount'] as int? ?? 0;
                      final bUnread = b['unreadCount'] as int? ?? 0;
                      
                      // Priority 1: Conversations with unread messages come first
                      if (aUnread > 0 && bUnread == 0) return -1;
                      if (bUnread > 0 && aUnread == 0) return 1;
                      if (aUnread > 0 && bUnread > 0) {
                        // Both have unread - sort by unread count (desc), then by time
                        final unreadCompare = bUnread.compareTo(aUnread);
                        if (unreadCompare != 0) return unreadCompare;
                      }
                      
                      // Priority 2: Users with messages come before users without messages
                      if (aTime != null && bTime != null) {
                        return bTime.compareTo(aTime); // Most recent first
                      } else if (aTime != null) {
                        return -1; // a has message, b doesn't - a comes first
                      } else if (bTime != null) {
                        return 1; // b has message, a doesn't - b comes first
                      } else {
                        // Both have no messages - keep at bottom (no sorting)
                        return 0;
                      }
                    });

                    // Check for new unread messages and play notification sound
                    final currentUnreadCounts = <String, int>{};
                    for (final item in sortedUsers) {
                      final userId = item['user']['id'].toString();
                      final unreadCount = item['unreadCount'] as int? ?? 0;
                      currentUnreadCounts[userId] = unreadCount;
                      
                      // Play sound if unread count increased (new message received)
                      final previousCount = _previousUnreadCounts[userId] ?? 0;
                      if (unreadCount > previousCount) {
                        _playNotificationSound();
                      }
                    }
                    // Update previous counts for next comparison
                    _previousUnreadCounts = currentUnreadCounts;

                    // Apply search filter after sorting
                    final filteredUsers = sortedUsers.where((item) {
                      if (_searchQuery.isEmpty) return true;
                      final username = (item['user']['username'] ?? '').toString().toLowerCase();
                      return username.contains(_searchQuery);
                    }).toList();

                    if (filteredUsers.isEmpty && _searchQuery.isNotEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: theme.colorScheme.onSurface.withOpacity(0.3),
                            ),
                            const SizedBox(height: AppTheme.spacingL),
                            Text(
                              'No users found',
                              style: AppTheme.headingSmall.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        setState(() {});
                      },
                      child: ListView.builder(
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final item = filteredUsers[index];
                          final user = item['user'] as Map<String, dynamic>;
                          final lastMessage = item['lastMessage'] as Map<String, dynamic>?;
                          
                          return _ChatListItem(
                            user: user,
                            currentUserName: currentUserName,
                            lastMessage: lastMessage,
                            unreadCount: item['unreadCount'] as int? ?? 0,
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    receiverId: user['id'],
                                    currentUserName: currentUserName,
                                    receiverName: user['username'] ?? 'Unknown',
                                  ),
                                ),
                              );
                              // Force a refresh when returning from chat screen to update unread counts
                              if (mounted) {
                                setState(() {});
                              }
                            },
                          )
                              .animate()
                              .fadeIn(duration: 200.ms, delay: (index * 50).ms)
                              .slideX(begin: 0.1, end: 0, duration: 200.ms);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatListItem extends StatefulWidget {
  final Map<String, dynamic> user;
  final String currentUserName;
  final Map<String, dynamic>? lastMessage;
  final int unreadCount;
  final VoidCallback onTap;

  const _ChatListItem({
    required this.user,
    required this.currentUserName,
    this.lastMessage,
    this.unreadCount = 0,
    required this.onTap,
  });

  @override
  State<_ChatListItem> createState() => _ChatListItemState();
}

class _ChatListItemState extends State<_ChatListItem> {
  /// Formats timestamp for display (e.g., "2 minutes ago")
  String _formatTimestamp(dynamic createdAt) {
    if (createdAt == null) return '';
    DateTime? dateTime;
    if (createdAt is DateTime) {
      dateTime = createdAt;
    } else if (createdAt is String) {
      dateTime = DateTime.tryParse(createdAt);
    }
    if (dateTime == null) return '';
    return timeago.format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final username = widget.user['username'] ?? 'Unknown';
    final lastMessageText = widget.lastMessage?['content'] ?? '';
    final lastMessageTime = widget.lastMessage?['created_at'];

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      leading: UserAvatar(
        username: username,
        size: 56,
        showOnlineStatus: true,
        isOnline: false, // TODO: Implement actual online status
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              username,
              style: AppTheme.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (lastMessageTime != null)
            Text(
              _formatTimestamp(lastMessageTime),
              style: AppTheme.caption.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
        ],
      ),
      subtitle: Text(
        lastMessageText.isEmpty
            ? 'No messages yet'
            : lastMessageText,
        style: AppTheme.bodySmall.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      trailing: widget.unreadCount > 0
          ? Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            )
          : null,
      onTap: widget.onTap,
    );
  }
}
