import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class UserAvatar extends StatelessWidget {
  final String? username;
  final String? imageUrl;
  final double size;
  final bool showOnlineStatus;
  final bool isOnline;
  final Color? backgroundColor;

  const UserAvatar({
    super.key,
    this.username,
    this.imageUrl,
    this.size = 48,
    this.showOnlineStatus = false,
    this.isOnline = false,
    this.backgroundColor,
  });

  String _getInitials() {
    if (username == null || username!.isEmpty) {
      return '?';
    }
    final parts = username!.trim().split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return username!.substring(0, 1).toUpperCase();
  }

  Color _getBackgroundColor(BuildContext context) {
    if (backgroundColor != null) return backgroundColor!;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Generate a color based on username hash for consistency
    if (username != null && username!.isNotEmpty) {
      final hash = username!.hashCode;
      final colors = isDark
          ? [
              const Color(0xFF6366F1),
              const Color(0xFF8B5CF6),
              const Color(0xFFEC4899),
              const Color(0xFFF59E0B),
              const Color(0xFF10B981),
              const Color(0xFF3B82F6),
            ]
          : [
              const Color(0xFF6366F1),
              const Color(0xFF8B5CF6),
              const Color(0xFFEC4899),
              const Color(0xFFF59E0B),
              const Color(0xFF10B981),
              const Color(0xFF3B82F6),
            ];
      return colors[hash.abs() % colors.length];
    }

    return isDark ? AppTheme.primaryDarkTheme : AppTheme.primaryLight;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = _getBackgroundColor(context);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: bgColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: imageUrl != null && imageUrl!.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildInitials(bgColor, theme);
                    },
                  ),
                )
              : _buildInitials(bgColor, theme),
        ),
        if (showOnlineStatus)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.3,
              height: size * 0.3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOnline ? AppTheme.successLight : Colors.grey.shade400,
                border: Border.all(
                  color: theme.scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInitials(Color bgColor, ThemeData theme) {
    return Center(
      child: Text(
        _getInitials(),
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
