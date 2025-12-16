import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

/// A badge widget for displaying unread message counts.
class UnreadBadge extends StatelessWidget {
  final int count;
  final double? size;
  final Color? backgroundColor;
  final Color? textColor;

  const UnreadBadge({
    super.key,
    required this.count,
    this.size,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final badgeSize = size ?? 20.0;
    final bgColor = backgroundColor ?? AppTheme.primaryLight;
    final txtColor = textColor ?? Colors.white;

    // For counts > 99, show "99+"
    final displayText = count > 99 ? '99+' : count.toString();
    
    // Adjust size based on digit count
    final width = count > 99 
        ? badgeSize * 1.5 
        : count > 9 
            ? badgeSize * 1.3 
            : badgeSize;

    return Container(
      width: width,
      height: badgeSize,
      constraints: BoxConstraints(
        minWidth: badgeSize,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(badgeSize / 2),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.4),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          displayText,
          style: TextStyle(
            color: txtColor,
            fontSize: badgeSize * 0.5,
            fontWeight: FontWeight.w600,
            height: 1.0,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    )
        .animate()
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
          duration: 200.ms,
          curve: Curves.elasticOut,
        )
        .fadeIn(duration: 200.ms);
  }
}






