import 'package:flutter/services.dart';

/// Service for providing haptic feedback throughout the app.
class HapticService {
  HapticService._();
  static final HapticService instance = HapticService._();

  /// Light haptic feedback for subtle interactions (button taps, selections)
  Future<void> lightImpact() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (e) {
      // Haptic feedback may not be available on all devices
      // Silently fail to avoid disrupting user experience
    }
  }

  /// Medium haptic feedback for more significant actions (message send, confirmations)
  Future<void> mediumImpact() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (e) {
      // Silently fail if not available
    }
  }

  /// Heavy haptic feedback for important actions (delete, errors)
  Future<void> heavyImpact() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (e) {
      // Silently fail if not available
    }
  }

  /// Selection haptic feedback for UI element selections
  Future<void> selectionClick() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (e) {
      // Silently fail if not available
    }
  }

  /// Vibrate for notifications or alerts
  Future<void> vibrate() async {
    try {
      await HapticFeedback.vibrate();
    } catch (e) {
      // Silently fail if not available
    }
  }
}


