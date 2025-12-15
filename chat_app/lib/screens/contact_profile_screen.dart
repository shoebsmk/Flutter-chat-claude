import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../widgets/user_avatar.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';
import '../exceptions/app_exceptions.dart';

/// Screen for viewing a contact's profile details.
class ContactProfileScreen extends StatefulWidget {
  final String userId;

  const ContactProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  State<ContactProfileScreen> createState() => _ContactProfileScreenState();
}

class _ContactProfileScreenState extends State<ContactProfileScreen> {
  final _userService = UserService();
  User? _user;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _userService.getUserById(widget.userId);
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
          if (user == null) {
            _errorMessage = 'User not found';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = ExceptionHandler.getMessage(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null || _user == null
              ? _buildErrorState(theme)
              : _buildProfileContent(theme),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.alertCircle,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: AppTheme.spacingL),
            Text(
              _errorMessage ?? 'Failed to load profile',
              style: AppTheme.bodyMedium.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXL),
            ElevatedButton(
              onPressed: _loadUserProfile,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent(ThemeData theme) {
    final isOnline = _user!.isOnline;
    final statusText = isOnline
        ? 'Online'
        : _user!.lastSeen != null
            ? 'Last seen ${AppDateUtils.formatRelative(_user!.lastSeen)}'
            : 'Offline';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: AppTheme.spacingXL),
          // Large profile picture
          UserAvatar(
            username: _user!.username,
            imageUrl: _user!.avatarUrl,
            size: 200,
            showOnlineStatus: true,
            isOnline: isOnline,
          ),
          const SizedBox(height: AppTheme.spacingXL),
          // Username
          Text(
            _user!.username,
            style: AppTheme.headingMedium.copyWith(
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingS),
          // Status
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOnline
                      ? AppTheme.successLight
                      : Colors.grey.shade400,
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Text(
                statusText,
                style: AppTheme.bodyMedium.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
          // Bio section
          if (_user!.bio != null && _user!.bio!.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingXXL),
            _buildBioSection(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildBioSection(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bio',
            style: AppTheme.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            _user!.bio!,
            style: AppTheme.bodyLarge.copyWith(
              color: theme.colorScheme.onSurface,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

