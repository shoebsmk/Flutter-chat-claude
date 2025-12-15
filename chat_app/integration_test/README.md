# Screenshot Automation

This directory contains automated screenshot capture tests for the chat app, covering Phases 1-7 of the screenshot sequence.

## Overview

The automation uses Flutter's `integration_test` package to programmatically navigate through the app and capture screenshots at each step. Screenshots are saved to `screenshots/ios/automated/` with consistent naming (01-auth-signup.png, 02-auth-signin.png, etc.).

## Structure

```
integration_test/
├── screenshot_automation_test.dart  # Main test file
└── helpers/
    ├── screenshot_helper.dart        # Screenshot capture utilities
    ├── navigation_helper.dart       # Navigation and widget interaction
    └── test_data_helper.dart        # Test data and auth state helpers
```

## Prerequisites

1. **iOS Simulator**: Ensure an iOS simulator is available and running
2. **App Setup**: The app should be configured with Supabase credentials
3. **Dependencies**: Run `flutter pub get` to install required packages

## Running the Automation

### Basic Run

```bash
flutter test integration_test/screenshot_automation_test.dart -d ios
```

### With Specific Device

```bash
# List available devices
flutter devices

# Run on specific device
flutter test integration_test/screenshot_automation_test.dart -d <device-id>
```

### Using Integration Test Runner

```bash
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/screenshot_automation_test.dart \
  -d ios
```

## What Gets Captured

The automation captures screenshots for:

### Phase 1: Authentication (Steps 1-2)
- Sign Up screen
- Sign In screen
- *Note: Skips if already authenticated*

### Phase 2: Main Interface (Steps 3-5)
- Chat list screen
- Unread badges
- Online status indicators

### Phase 3: Real-Time Messaging (Steps 6-8)
- Active chat screen
- Message status indicators
- *Note: Typing indicator skipped (requires second account)*

### Phase 4: Media & Attachments (Steps 9-11)
- Image picker dialog
- Image preview (if possible)
- *Note: Full image sending may require manual setup*

### Phase 5: Profile Features (Steps 12-14)
- Contact profile screen
- Profile edit screen
- Profile picture picker

### Phase 6: Theme & Settings (Steps 15-18)
- Settings screen
- Theme selection
- Light theme view
- Dark theme view

### Phase 7: AI Features (Steps 19-22)
- Chat Assist welcome screen
- Command input
- Confirmation dialog
- Success message

## Output Location

Screenshots are saved to:
```
screenshots/ios/automated/
├── 01-auth-signup.png
├── 02-auth-signin.png
├── 03-chat-list.png
└── ... (all 22 screenshots)
```

## Limitations

1. **Authentication**: If already logged in, auth screenshots are skipped
2. **Typing Indicator**: Requires second account - not automated
3. **Image Picker**: Platform-specific behavior may vary in tests
4. **Real-time Features**: Some features require actual user interaction

## Troubleshooting

### Screenshots Not Saving

- Check that the `screenshots/ios/automated/` directory is writable
- Ensure the app has proper permissions

### Widgets Not Found

- The app UI may have changed - update finders in the test file
- Add delays if widgets load asynchronously

### Authentication Issues

- Ensure Supabase is properly configured
- Check that test accounts exist if needed

## Customization

To modify the automation:

1. **Add Screenshots**: Add new steps in the appropriate phase function
2. **Change Navigation**: Update `navigation_helper.dart` with new helper methods
3. **Adjust Timing**: Modify delays in `screenshot_helper.dart` or test file

## Notes

- The automation assumes the app is in a usable state
- Some screenshots may require manual verification
- Screenshots are taken after animations complete (500ms delay)
- The test will print progress messages to the console

