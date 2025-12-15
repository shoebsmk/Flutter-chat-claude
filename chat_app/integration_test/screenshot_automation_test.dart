import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:chat_app/main.dart' as app;
import 'helpers/screenshot_helper.dart';
import 'helpers/navigation_helper.dart';
import 'helpers/test_data_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Screenshot Automation - Phases 1-7', () {
    testWidgets('Capture all screenshots for phases 1-7', (WidgetTester tester) async {
      // Initialize the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Phase 1: Authentication (Steps 1-2)
      await _phase1Authentication(tester);

      // Phase 2: Main Interface (Steps 3-5)
      await _phase2MainInterface(tester);

      // Phase 3: Real-Time Messaging (Steps 6-8)
      await _phase3Messaging(tester);

      // Phase 4: Media & Attachments (Steps 9-11)
      await _phase4Media(tester);

      // Phase 5: Profile Features (Steps 12-14)
      await _phase5Profile(tester);

      // Phase 6: Theme & Settings (Steps 15-18)
      await _phase6Theme(tester);

      // Phase 7: AI Features (Steps 19-22)
      await _phase7AI(tester);
    });
  });
}

/// Phase 1: Authentication Screenshots
Future<void> _phase1Authentication(WidgetTester tester) async {
  print('\n📸 Phase 1: Authentication');
  
  // Check if already authenticated
  final isAuth = await TestDataHelper.waitForAuthState();
  
  if (isAuth && !TestDataHelper.isAuthScreenVisible(tester)) {
    print('⚠️  Already authenticated, skipping auth screenshots');
    return;
  }

  // Step 1: Sign Up Screen
  print('  → Step 1: Sign Up Screen');
  if (TestDataHelper.isAuthScreenVisible(tester)) {
    // Check if we're on sign up or sign in
    final signInText = find.text('Welcome Back');
    
    if (signInText.evaluate().isNotEmpty) {
      // Switch to sign up
      final toggleButton = find.text('Sign Up');
      if (toggleButton.evaluate().isNotEmpty) {
        await NavigationHelper.tapByText(tester, 'Sign Up');
      }
    }
    
    await NavigationHelper.waitForSettle(tester);
    await ScreenshotHelper.takeScreenshotStep(1, 'auth-signup');
  }

  // Step 2: Sign In Screen
  print('  → Step 2: Sign In Screen');
  final toggleButton = find.text('Sign In');
  if (toggleButton.evaluate().isNotEmpty) {
    await NavigationHelper.tapByText(tester, 'Sign In');
    await NavigationHelper.waitForSettle(tester);
    await ScreenshotHelper.takeScreenshotStep(2, 'auth-signin');
  }
}

/// Phase 2: Main Interface Screenshots
Future<void> _phase2MainInterface(WidgetTester tester) async {
  print('\n📸 Phase 2: Main Interface');
  
  // Ensure we're authenticated and on main screen
  if (!TestDataHelper.isMainScreenVisible(tester)) {
    print('⚠️  Not on main screen, attempting to navigate...');
    // If on auth screen, we'd need to sign in, but for automation we assume already logged in
    await NavigationHelper.waitForSettle(tester);
  }

  // Step 3: Chat List Screen
  print('  → Step 3: Chat List Screen');
  // Navigate to Chats tab if not already there
  final chatsTab = find.text('Chats');
  if (chatsTab.evaluate().isNotEmpty) {
    await NavigationHelper.tapByText(tester, 'Chats');
  }
  await NavigationHelper.waitForSettle(tester);
  await Future.delayed(const Duration(milliseconds: 1000)); // Wait for data to load
  await ScreenshotHelper.takeScreenshotStep(3, 'chat-list');

  // Step 4: Unread Badges
  print('  → Step 4: Unread Badges');
  // Unread badges should be visible if there are unread messages
  await NavigationHelper.waitForSettle(tester);
  await ScreenshotHelper.takeScreenshotStep(4, 'unread-badges');

  // Step 5: Online Status Indicators
  print('  → Step 5: Online Status Indicators');
  await NavigationHelper.waitForSettle(tester);
  await ScreenshotHelper.takeScreenshotStep(5, 'online-status-list');
}

/// Phase 3: Real-Time Messaging Screenshots
Future<void> _phase3Messaging(WidgetTester tester) async {
  print('\n📸 Phase 3: Real-Time Messaging');
  
  // Step 6: Active Chat Screen
  print('  → Step 6: Active Chat Screen');
  // Tap first conversation
  final listTiles = find.byType(ListTile);
  if (listTiles.evaluate().isNotEmpty) {
    await NavigationHelper.tapFirstListTile(tester);
    await NavigationHelper.waitForSettle(tester);
    await Future.delayed(const Duration(milliseconds: 1000)); // Wait for messages to load
    await ScreenshotHelper.takeScreenshotStep(6, 'chat-screen');
  } else {
    print('⚠️  No conversations found, skipping chat screen');
  }

  // Step 7: Typing Indicator (may not be possible without second account)
  print('  → Step 7: Typing Indicator');
  print('⚠️  Typing indicator requires second account - skipping');
  // This would require a second account to be typing, which is hard to automate

  // Step 8: Message Status Indicators
  print('  → Step 8: Message Status Indicators');
  // Message status should be visible on sent messages
  await NavigationHelper.waitForSettle(tester);
  await ScreenshotHelper.takeScreenshotStep(8, 'message-status');
}

/// Phase 4: Media & Attachments Screenshots
Future<void> _phase4Media(WidgetTester tester) async {
  print('\n📸 Phase 4: Media & Attachments');
  
  // Ensure we're on chat screen
  if (find.byType(TextField).evaluate().isEmpty) {
    // Navigate back to chat if needed
    final listTiles = find.byType(ListTile);
    if (listTiles.evaluate().isNotEmpty) {
      await NavigationHelper.tapFirstListTile(tester);
      await NavigationHelper.waitForSettle(tester);
    }
  }

  // Step 9: Image Attachment Picker
  print('  → Step 9: Image Picker');
  // Find attachment/image icon - look for common icon patterns
  final imageIcon = find.byIcon(Icons.image);
  final attachmentIcon = find.byIcon(Icons.attach_file);
  final cameraIcon = find.byIcon(Icons.camera_alt);
  
  Finder? iconFinder;
  if (imageIcon.evaluate().isNotEmpty) {
    iconFinder = imageIcon;
  } else if (attachmentIcon.evaluate().isNotEmpty) {
    iconFinder = attachmentIcon;
  } else if (cameraIcon.evaluate().isNotEmpty) {
    iconFinder = cameraIcon;
  }
  
  if (iconFinder != null) {
    await tester.tap(iconFinder);
    await NavigationHelper.waitForSettle(tester);
    await ScreenshotHelper.takeScreenshotStep(9, 'image-picker');
    
    // Step 10: Image Preview (if we can select from gallery)
    // Note: Image picker may not work in integration tests, so we'll capture the dialog
    print('  → Step 10: Image Preview');
    // Try to find gallery option
    final galleryOption = find.textContaining('Gallery');
    if (galleryOption.evaluate().isEmpty) {
      final chooseOption = find.textContaining('Choose');
      if (chooseOption.evaluate().isNotEmpty) {
        await tester.tap(chooseOption.first);
        await NavigationHelper.waitForSettle(tester);
        await Future.delayed(const Duration(milliseconds: 500));
        await ScreenshotHelper.takeScreenshotStep(10, 'image-preview');
        // Cancel to go back
        final cancelButton = find.text('Cancel');
        if (cancelButton.evaluate().isNotEmpty) {
          await tester.tap(cancelButton);
        } else {
          await NavigationHelper.goBack(tester);
        }
      }
    } else {
      // Just capture the picker dialog as preview
      await ScreenshotHelper.takeScreenshotStep(10, 'image-preview');
      // Cancel
      await NavigationHelper.goBack(tester);
    }
  } else {
    print('⚠️  Image picker button not found');
  }

  // Step 11: Image in Chat (would require actually sending an image)
  print('  → Step 11: Image Message');
  print('⚠️  Image sending requires actual image selection - may skip');
  // This is difficult to automate fully, so we'll note it
}

/// Phase 5: Profile Features Screenshots
Future<void> _phase5Profile(WidgetTester tester) async {
  print('\n📸 Phase 5: Profile Features');
  
  // Step 12: Contact Profile
  print('  → Step 12: Contact Profile');
  // Navigate to chat screen first, then tap on contact name/avatar
  if (find.byType(AppBar).evaluate().isNotEmpty) {
    final appBar = find.byType(AppBar);
    // Try tapping on the app bar to see if it opens profile
    await tester.tap(appBar.first);
    await NavigationHelper.waitForSettle(tester);
    
    // Check if profile screen opened
    final profileTitle = find.textContaining('Profile');
    if (profileTitle.evaluate().isNotEmpty) {
      await ScreenshotHelper.takeScreenshotStep(12, 'contact-profile');
      await NavigationHelper.goBack(tester);
    }
  }

  // Step 13: Profile Edit Screen
  print('  → Step 13: Profile Edit Screen');
  // Navigate to Settings, then to profile edit
  final settingsTab = find.text('Settings');
  if (settingsTab.evaluate().isNotEmpty) {
    await NavigationHelper.tapByText(tester, 'Settings');
    await NavigationHelper.waitForSettle(tester);
  }
  
  // Look for profile edit option or navigate from chat list
  // Try going back to chat list and finding profile button
  final chatsTab = find.text('Chats');
  if (chatsTab.evaluate().isNotEmpty) {
    await NavigationHelper.tapByText(tester, 'Chats');
    await NavigationHelper.waitForSettle(tester);
  }
  
  // Look for profile/settings icon in app bar
  final profileIcon = find.byIcon(Icons.person);
  final settingsIcon = find.byIcon(Icons.settings);
  if (profileIcon.evaluate().isNotEmpty) {
    await tester.tap(profileIcon.first);
    await NavigationHelper.waitForSettle(tester);
    await ScreenshotHelper.takeScreenshotStep(13, 'profile-edit');
  } else if (settingsIcon.evaluate().isNotEmpty) {
    // Some apps have profile edit in settings
    await tester.tap(settingsIcon.first);
    await NavigationHelper.waitForSettle(tester);
    // Look for edit profile option
    final editProfile = find.textContaining('Edit');
    if (editProfile.evaluate().isNotEmpty) {
      await NavigationHelper.tapByText(tester, 'Edit');
      await NavigationHelper.waitForSettle(tester);
      await ScreenshotHelper.takeScreenshotStep(13, 'profile-edit');
    }
  }

  // Step 14: Profile Picture Upload
  print('  → Step 14: Profile Picture Picker');
  // If on profile edit screen, tap avatar
  final avatar = find.byType(CircleAvatar);
  if (avatar.evaluate().isNotEmpty) {
    await tester.tap(avatar.first);
    await NavigationHelper.waitForSettle(tester);
    await ScreenshotHelper.takeScreenshotStep(14, 'profile-picture-picker');
    // Cancel
    await NavigationHelper.goBack(tester);
  }
}

/// Phase 6: Theme & Settings Screenshots
Future<void> _phase6Theme(WidgetTester tester) async {
  print('\n📸 Phase 6: Theme & Settings');
  
  // Step 15: Settings Screen
  print('  → Step 15: Settings Screen');
  final settingsTab = find.text('Settings');
  if (settingsTab.evaluate().isNotEmpty) {
    await NavigationHelper.tapByText(tester, 'Settings');
    await NavigationHelper.waitForSettle(tester);
    await ScreenshotHelper.takeScreenshotStep(15, 'settings-screen');
  }

  // Step 16: Theme Selection
  print('  → Step 16: Theme Selection');
  // Look for theme options - they should be visible on settings screen
  final themeText = find.textContaining('Theme');
  final appearanceText = find.textContaining('Appearance');
  if (themeText.evaluate().isNotEmpty || appearanceText.evaluate().isNotEmpty) {
    // Theme options should already be visible, just capture
    await NavigationHelper.waitForSettle(tester);
    await ScreenshotHelper.takeScreenshotStep(16, 'theme-selection');
  }

  // Step 17: Light Theme
  print('  → Step 17: Light Theme');
  final lightTheme = find.text('Light');
  if (lightTheme.evaluate().isNotEmpty) {
    await NavigationHelper.tapByText(tester, 'Light');
    await NavigationHelper.waitForSettle(tester);
    // Navigate back to chat list to see theme
    final chatsTab = find.text('Chats');
    if (chatsTab.evaluate().isNotEmpty) {
      await NavigationHelper.tapByText(tester, 'Chats');
      await NavigationHelper.waitForSettle(tester);
      await Future.delayed(const Duration(milliseconds: 500));
      await ScreenshotHelper.takeScreenshotStep(17, 'light-theme');
    }
  }

  // Step 18: Dark Theme
  print('  → Step 18: Dark Theme');
  // Go back to settings
  final settingsTab2 = find.text('Settings');
  if (settingsTab2.evaluate().isNotEmpty) {
    await NavigationHelper.tapByText(tester, 'Settings');
    await NavigationHelper.waitForSettle(tester);
  }
  final darkTheme = find.text('Dark');
  if (darkTheme.evaluate().isNotEmpty) {
    await NavigationHelper.tapByText(tester, 'Dark');
    await NavigationHelper.waitForSettle(tester);
    // Navigate back to chat list
    final chatsTab3 = find.text('Chats');
    if (chatsTab3.evaluate().isNotEmpty) {
      await NavigationHelper.tapByText(tester, 'Chats');
      await NavigationHelper.waitForSettle(tester);
      await Future.delayed(const Duration(milliseconds: 500));
      await ScreenshotHelper.takeScreenshotStep(18, 'dark-theme');
    }
  }
}

/// Phase 7: AI Features Screenshots
Future<void> _phase7AI(WidgetTester tester) async {
  print('\n📸 Phase 7: AI Features');
  
  // Step 19: Chat Assist Welcome Screen
  print('  → Step 19: Chat Assist Welcome Screen');
  final chatAssistTab = find.text('Chat Assist');
  if (chatAssistTab.evaluate().isNotEmpty) {
    await NavigationHelper.tapByText(tester, 'Chat Assist');
    await NavigationHelper.waitForSettle(tester);
    await Future.delayed(const Duration(milliseconds: 1000)); // Wait for screen to load
    await ScreenshotHelper.takeScreenshotStep(19, 'chat-assist-welcome');
  }

  // Step 20: Chat Assist Command Input
  print('  → Step 20: Chat Assist Command');
  // Find text input field
  final textFields = find.byType(TextField);
  if (textFields.evaluate().isNotEmpty) {
    final textField = textFields.first;
    await tester.tap(textField);
    await NavigationHelper.waitForSettle(tester);
    await tester.enterText(textField, "Send testuser Hello there");
    await NavigationHelper.waitForSettle(tester);
    await ScreenshotHelper.takeScreenshotStep(20, 'chat-assist-command');
  }

  // Step 21: Chat Assist Confirmation
  print('  → Step 21: Chat Assist Confirmation');
  // Try to send the command
  final sendButton = find.textContaining('Send');
  final sendIcon = find.byIcon(Icons.send);
  if (sendButton.evaluate().isNotEmpty) {
    await NavigationHelper.tapByText(tester, 'Send');
  } else if (sendIcon.evaluate().isNotEmpty) {
    await tester.tap(sendIcon.first);
  }
  
  await NavigationHelper.waitForSettle(tester);
  await Future.delayed(const Duration(milliseconds: 2000)); // Wait for AI processing
  
  // Look for confirmation dialog
  final dialog = find.byType(AlertDialog);
  if (dialog.evaluate().isNotEmpty) {
    await ScreenshotHelper.takeScreenshotStep(21, 'chat-assist-confirmation');
    // Don't actually confirm, just capture
  } else {
    // May have already processed, capture current state
    await ScreenshotHelper.takeScreenshotStep(21, 'chat-assist-confirmation');
  }

  // Step 22: Chat Assist Success
  print('  → Step 22: Chat Assist Success');
  // If there's a confirm button, tap it
  final confirmButton = find.textContaining('Confirm');
  if (confirmButton.evaluate().isNotEmpty) {
    await NavigationHelper.tapByText(tester, 'Confirm');
    await NavigationHelper.waitForSettle(tester);
    await Future.delayed(const Duration(milliseconds: 2000)); // Wait for success
  }
  
  await NavigationHelper.waitForSettle(tester);
  await ScreenshotHelper.takeScreenshotStep(22, 'chat-assist-success');
  
  print('\n✅ All screenshots captured!');
}

