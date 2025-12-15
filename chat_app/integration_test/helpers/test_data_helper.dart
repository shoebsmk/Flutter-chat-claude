import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Helper class for managing test data and authentication state.
class TestDataHelper {
  /// Checks if the user is currently authenticated.
  static bool isAuthenticated() {
    try {
      final client = Supabase.instance.client;
      return client.auth.currentSession != null;
    } catch (e) {
      return false;
    }
  }

  /// Gets the current user ID if authenticated.
  static String? getCurrentUserId() {
    try {
      final client = Supabase.instance.client;
      return client.auth.currentUser?.id;
    } catch (e) {
      return null;
    }
  }

  /// Waits for authentication state to be determined.
  static Future<bool> waitForAuthState({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final endTime = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(endTime)) {
      try {
        final client = Supabase.instance.client;
        if (client.auth.currentSession != null) {
          return true;
        }
        // Wait a bit for async auth state to resolve
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (e) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
    return false;
  }

  /// Checks if a specific screen is visible by looking for key widgets.
  static bool isAuthScreenVisible(WidgetTester tester) {
    // Look for common auth screen elements
    final signInButton = find.text('Sign In');
    final signUpButton = find.text('Sign Up');
    final emailField = find.textContaining('Email');
    final passwordField = find.textContaining('Password');
    
    return (signInButton.evaluate().isNotEmpty || 
            signUpButton.evaluate().isNotEmpty) &&
           (emailField.evaluate().isNotEmpty || 
            passwordField.evaluate().isNotEmpty);
  }

  /// Checks if the main app screen (chat list) is visible.
  static bool isMainScreenVisible(WidgetTester tester) {
    // Look for bottom navigation or chat list elements
    final bottomNav = find.byType(BottomNavigationBar);
    final chatList = find.textContaining('Chat');
    final settingsIcon = find.byIcon(Icons.settings);
    
    return bottomNav.evaluate().isNotEmpty || 
           chatList.evaluate().isNotEmpty ||
           settingsIcon.evaluate().isNotEmpty;
  }
}

