# Simple Screenshot Automation

This directory contains simple shell scripts for capturing screenshots from the iOS Simulator.

## Prerequisites

1. **iOS Simulator running** with your app
2. **Xcode Command Line Tools** installed (for `xcrun simctl`)

## Method 1: Interactive Script (Recommended)

The `automated_screenshots.sh` script guides you through each screenshot step-by-step:

```bash
# Make sure your app is running in iOS Simulator first
flutter run -d ios

# In another terminal, run the script
./scripts/automated_screenshots.sh
```

The script will:
- Prompt you at each step
- Wait for you to navigate to the correct screen
- Take the screenshot automatically
- Save it with the correct filename (01-auth-signup.png, etc.)

**Advantages:**
- Simple and reliable
- No complex path resolution
- You control when each screenshot is taken
- Works with any app state

## Method 2: Quick Continuous Capture

For rapid capture while manually navigating:

```bash
./scripts/quick_screenshots.sh
```

This takes a screenshot every 3 seconds automatically. Navigate through your app manually, and press Ctrl+C when done.

## Manual Method (Simplest)

If scripts don't work, you can take screenshots manually:

1. **Using Simulator Menu:**
   - Device → Screenshot (Cmd+S)
   - Screenshots save to Desktop by default
   - Rename them according to the sequence

2. **Using Command Line:**
   ```bash
   # Take a screenshot
   xcrun simctl io booted screenshot ~/Desktop/01-auth-signup.png
   ```

3. **Using Keyboard Shortcut:**
   - Cmd+S in Simulator saves to Desktop
   - Then move/rename files to `screenshots/ios/automated/`

## Screenshot Sequence

Follow the sequence from `docs/showcase/SCREENSHOT_SEQUENCE.md`:

1. Auth screens (sign up, sign in)
2. Main interface (chat list, badges, status)
3. Messaging (chat screen, status indicators)
4. Media (image picker, preview, message)
5. Profile (contact profile, edit, picture picker)
6. Theme (settings, selection, light, dark)
7. AI Features (Chat Assist screens)

## Troubleshooting

### "xcrun: error: unable to find utility 'simctl'"
- Install Xcode Command Line Tools: `xcode-select --install`

### "No booted simulator found"
- Make sure iOS Simulator is running
- Check with: `xcrun simctl list devices | grep Booted`

### Screenshots not saving
- Check write permissions on the screenshot directory
- Try saving to Desktop first, then move files

## Alternative: Use Flutter's Built-in Screenshot

If you prefer, you can also use Flutter's screenshot package in a simple Dart script, but the shell script approach is much simpler and more reliable.

