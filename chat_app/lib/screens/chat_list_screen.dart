import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'chat_screen.dart';
import 'auth_screen.dart';
import 'profile_edit_screen.dart';
import '../models/user.dart' as models;
import '../models/message.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/chat_service.dart';
import '../services/presence_service.dart';
import '../widgets/user_avatar.dart';
import '../widgets/loading_shimmer.dart';
import '../widgets/unread_badge.dart';
import '../services/haptic_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';
import '../utils/constants.dart';

// Type alias for readability
typedef User = models.User;

/// Screen displaying a list of chat conversations.
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with WidgetsBindingObserver {
  final _authService = AuthService();
  final _userService = UserService();
  final _chatService = ChatService();
  final _presenceService = PresenceService();

  late Stream<List<User>> _usersStream;
  late Stream<List<Message>> _messagesStream;
  final StreamController<List<User>> _usersStreamController = StreamController<List<User>>.broadcast();
  StreamSubscription<List<User>>? _realtimeStreamSubscription;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Map<String, int> _previousUnreadCounts = {};
  AppLifecycleState? _appLifecycleState;

  String? get _currentUserId => _authService.currentUserId;
  String? get _currentUserEmail => _authService.currentUserEmail;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeStreams();
    _setupSearchListener();
    _presenceService.startHeartbeat();
    _presenceService.updateLastSeen();
  }

  void _initializeStreams() {
    // Use StreamController to combine real-time updates with manual refresh
    // Real-time stream handles automatic updates from Supabase
    // Manual refresh can inject fresh data into the same controller
    _usersStream = _usersStreamController.stream;
    _messagesStream = _chatService.getCurrentUserMessagesStream();
    
    // Subscribe to real-time stream and forward events to our controller
    final realtimeStream = _userService.getUsersStream();
    _realtimeStreamSubscription = realtimeStream.listen(
      (users) {
        if (!_usersStreamController.isClosed) {
          _usersStreamController.add(users);
        }
      },
      onError: (error) {
        debugPrint('Error in real-time users stream: $error');
      },
    );
  }

  /// Manually refreshes the users list by fetching fresh data from the database.
  Future<void> _refreshUsers() async {
    try {
      final users = await _userService.getAllUsers();
      if (!_usersStreamController.isClosed) {
        _usersStreamController.add(users);
      }
    } catch (e) {
      debugPrint('Error refreshing users: $e');
      // Don't throw - let the stream handle errors
    }
  }

  void _setupSearchListener() {
    _searchController.addListener(() {
      final newQuery = _searchController.text.toLowerCase();
      if (newQuery != _searchQuery) {
        setState(() {
          _searchQuery = newQuery;
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _realtimeStreamSubscription?.cancel();
    _usersStreamController.close();
    _presenceService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appLifecycleState = state;
    if (state == AppLifecycleState.resumed) {
      // Update last_seen when app comes to foreground
      _presenceService.updateLastSeen();
      _presenceService.startHeartbeat();
      // Refresh users to get latest profile updates when app comes to foreground
      _refreshUsers();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Stop heartbeat when app goes to background
      _presenceService.stopHeartbeat();
    }
  }

  Future<void> _playNotificationSound() async {
    // Only play if app is in foreground
    if (_appLifecycleState != AppLifecycleState.resumed) return;

    try {
      SystemSound.play(SystemSoundType.alert);
    } catch (e) {
      debugPrint('Error playing notification sound: $e');
    }
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
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
        );
      }
    }
  }

  /// Sorts users by conversation priority (unread first, then by last message time).
  List<_UserConversationData> _sortUsersByConversation(
    List<User> users,
    Map<String, ConversationInfo> conversations,
  ) {
    final result = <_UserConversationData>[];

    for (final user in users) {
      final conversationInfo = conversations[user.id];
      result.add(
        _UserConversationData(
          user: user,
          lastMessage: conversationInfo?.lastMessage,
          unreadCount: conversationInfo?.unreadCount ?? 0,
        ),
      );
    }

    result.sort((a, b) {
      // Priority 1: Conversations with unread messages come first
      if (a.unreadCount > 0 && b.unreadCount == 0) return -1;
      if (b.unreadCount > 0 && a.unreadCount == 0) return 1;
      if (a.unreadCount > 0 && b.unreadCount > 0) {
        final unreadCompare = b.unreadCount.compareTo(a.unreadCount);
        if (unreadCompare != 0) return unreadCompare;
      }

      // Priority 2: Users with messages come before users without
      final aTime = a.lastMessage?.createdAt;
      final bTime = b.lastMessage?.createdAt;

      if (aTime != null && bTime != null) {
        return bTime.compareTo(aTime);
      } else if (aTime != null) {
        return -1;
      } else if (bTime != null) {
        return 1;
      }

      return 0;
    });

    return result;
  }

  /// Checks for new messages and plays notification sound.
  void _checkForNewMessages(List<_UserConversationData> users) {
    final currentUnreadCounts = <String, int>{};

    for (final userData in users) {
      currentUnreadCounts[userData.user.id] = userData.unreadCount;

      final previousCount = _previousUnreadCounts[userData.user.id] ?? 0;
      if (userData.unreadCount > previousCount) {
        _playNotificationSound();
      }
    }

    _previousUnreadCounts = currentUnreadCounts;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: _buildAppBar(theme),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildUserList(theme)),
        ],
      ),
    );
  }

  AppBar _buildAppBar(ThemeData theme) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Messages',
            style: AppTheme.headingSmall.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          if (_currentUserEmail != null)
            Text(
              _currentUserEmail!,
              style: AppTheme.caption.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.userCircle),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ProfileEditScreen(),
              ),
            );
          },
          tooltip: 'Edit Profile',
        ),
        IconButton(
          icon: const Icon(LucideIcons.power),
          onPressed: _handleLogout,
          tooltip: 'Logout',
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search conversations...',
          prefixIcon: const Icon(LucideIcons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(LucideIcons.x),
                  onPressed: _searchController.clear,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildUserList(ThemeData theme) {
    return StreamBuilder<List<User>>(
      stream: _usersStream,
      builder: (context, usersSnapshot) {
        if (usersSnapshot.connectionState == ConnectionState.waiting) {
          return const ChatListShimmer();
        }

        if (usersSnapshot.hasError) {
          return _buildErrorState(theme, 'Error loading chats');
        }

        final allUsers = usersSnapshot.data ?? [];
        final otherUsers = allUsers
            .where((u) => u.id != _currentUserId)
            .toList();

        if (otherUsers.isEmpty) {
          return _buildEmptyState(theme);
        }

        final currentUser = allUsers.where((u) => u.id == _currentUserId);
        final currentUserName = currentUser.isNotEmpty
            ? currentUser.first.username
            : 'User';

        return _buildMessagesStream(theme, otherUsers, currentUserName);
      },
    );
  }

  Widget _buildMessagesStream(
    ThemeData theme,
    List<User> otherUsers,
    String currentUserName,
  ) {
    return StreamBuilder<List<Message>>(
      stream: _messagesStream,
      builder: (context, messagesSnapshot) {
        if (messagesSnapshot.hasError) {
          debugPrint('Error loading messages: ${messagesSnapshot.error}');
        }

        final messages = messagesSnapshot.data ?? [];
        final userIds = otherUsers.map((u) => u.id).toList();
        final conversations = _chatService.processConversations(
          messages,
          userIds,
        );

        final sortedUsers = _sortUsersByConversation(otherUsers, conversations);
        _checkForNewMessages(sortedUsers);

        // Apply search filter
        final filteredUsers = _searchQuery.isEmpty
            ? sortedUsers
            : sortedUsers
                  .where(
                    (data) =>
                        data.user.username.toLowerCase().contains(_searchQuery),
                  )
                  .toList();

        if (filteredUsers.isEmpty && _searchQuery.isNotEmpty) {
          return _buildNoSearchResults(theme);
        }

        return RefreshIndicator(
          onRefresh: _refreshUsers,
          child: ListView.builder(
            itemCount: filteredUsers.length,
            itemBuilder: (context, index) {
              final userData = filteredUsers[index];
              return _ChatListItem(
                    user: userData.user,
                    currentUserName: currentUserName,
                    lastMessage: userData.lastMessage,
                    unreadCount: userData.unreadCount,
                    onTap: () =>
                        _navigateToChat(userData.user, currentUserName),
                  )
                  .animate()
                  .fadeIn(
                    duration: AppConstants.animationNormal,
                    delay: Duration(milliseconds: index * 50),
                  )
                  .slideX(
                    begin: 0.1,
                    end: 0,
                    duration: AppConstants.animationNormal,
                  );
            },
          ),
        );
      },
    );
  }

  Future<void> _navigateToChat(User user, String currentUserName) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          receiverId: user.id,
          currentUserName: currentUserName,
          receiverName: user.username,
        ),
      ),
    );
    // Refresh users when returning from chat to get latest profile updates
    if (mounted) {
      _refreshUsers();
    }
  }

  Widget _buildErrorState(ThemeData theme, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.alertCircle, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            message,
            style: AppTheme.bodyMedium.copyWith(color: theme.colorScheme.error),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingXL),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.messageSquare,
                size: 64,
                color: theme.colorScheme.primary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: AppTheme.spacingXL),
            Text(
              'No conversations yet',
              style: AppTheme.headingMedium.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'Start chatting with someone!\nYour conversations will appear here.',
              style: AppTheme.bodyMedium.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSearchResults(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingXL),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.searchX,
                size: 64,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: AppTheme.spacingXL),
            Text(
              'No users found',
              style: AppTheme.headingMedium.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'Try a different search term',
              style: AppTheme.bodyMedium.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Internal data class for user conversation list items.
class _UserConversationData {
  final User user;
  final Message? lastMessage;
  final int unreadCount;

  const _UserConversationData({
    required this.user,
    this.lastMessage,
    this.unreadCount = 0,
  });
}

/// Widget for displaying a single chat list item.
class _ChatListItem extends StatelessWidget {
  final User user;
  final String currentUserName;
  final Message? lastMessage;
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lastMessageText = lastMessage?.content ?? '';
    final lastMessageTime = lastMessage?.createdAt;
    final hasUnread = unreadCount > 0;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingXS,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingM,
          vertical: AppTheme.spacingS,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        leading: UserAvatar(
          username: user.username,
          imageUrl: user.avatarUrl,
          size: 56,
          showOnlineStatus: true,
          isOnline: user.isOnline,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.username,
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (lastMessageTime != null)
              Text(
                AppDateUtils.formatRelative(lastMessageTime),
                style: AppTheme.caption.copyWith(
                  color: hasUnread
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.5),
                  fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
          ],
        ),
        subtitle: Text(
          lastMessageText.isEmpty ? 'No messages yet' : lastMessageText,
          style: AppTheme.bodySmall.copyWith(
            color: hasUnread
                ? theme.colorScheme.onSurface.withOpacity(0.8)
                : theme.colorScheme.onSurface.withOpacity(0.6),
            fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        trailing: unreadCount > 0
            ? UnreadBadge(count: unreadCount)
            : null,
        onTap: () {
          HapticService.instance.lightImpact();
          onTap();
        },
      ),
    );
  }
}
