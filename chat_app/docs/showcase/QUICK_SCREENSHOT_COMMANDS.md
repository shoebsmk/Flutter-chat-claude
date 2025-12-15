# Quick Screenshot Commands

> **📋 Follow the sequence**: See `SCREENSHOT_SEQUENCE.md` for step-by-step navigation order

## Launch App for Screenshots

### Launch on iOS Simulator:
```bash
# List available simulators
flutter devices

# Launch on specific simulator (replace with your device ID)
flutter run -d B5CCBC99-569C-4100-91E1-614A68E1A113

# Or launch on any available iOS simulator
flutter run -d ios
```

### Open iOS Simulator First:
```bash
# Open Simulator app
open -a Simulator

# Or boot a specific device
xcrun simctl boot "iPhone 15 Pro"
```

## Taking Screenshots

### On Simulator:
- **Cmd + S** - Takes screenshot, saves to Desktop
- **Device → Screenshot** - Alternative method

### Screenshot Location:
Screenshots are saved to: `~/Desktop/Screen Shot [timestamp].png`

## Quick Feature Navigation

> **For complete sequence**: See `SCREENSHOT_SEQUENCE.md` (25 steps, ~30 minutes)

**Quick order:**
1. Auth Screen → Sign Up/Sign In
2. Chat List → Main screen after login
3. Chat Screen → Tap conversation
4. Chat Assist → Bottom nav tab
5. Settings → Profile/Settings icon
6. Profile Edit → From profile/settings
7. Contact Profile → Tap contact name in chat header

## Batch Screenshot Workflow

```bash
# 1. Launch simulator
open -a Simulator

# 2. Launch app
cd /Users/shoebmohammedkhan/Documents/Developer/Chat\ App\ github/Flutter-chat-claude/chat_app
flutter run -d ios

# 3. Take screenshots using Cmd+S as you navigate
# 4. Organize screenshots later
```

## Organize Screenshots

```bash
# Create screenshot directory
mkdir -p screenshots/ios

# Move screenshots (run after taking them)
mv ~/Desktop/Screen\ Shot*.png screenshots/ios/

# Rename for organization (manual or use script)
```

