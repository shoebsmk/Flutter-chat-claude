#!/bin/bash

# Fully Automated Screenshot Capture
# Takes screenshots with automatic delays - just navigate your app manually

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
SCREENSHOT_DIR="$PROJECT_ROOT/screenshots/ios/automated"

mkdir -p "$SCREENSHOT_DIR"

echo "📸 Automated Screenshot Capture"
echo "================================"
echo ""
echo "This script will take 22 screenshots with 5-second delays."
echo "Navigate through your app manually between each screenshot."
echo ""
echo "Starting in 3 seconds..."
sleep 3

# Phase 1: Authentication
echo "📸 Phase 1: Authentication (2 screenshots)"
echo "→ Navigate to Sign Up screen..."
sleep 5
xcrun simctl io booted screenshot "$SCREENSHOT_DIR/01-auth-signup.png" 2>/dev/null && echo "✅ 01-auth-signup.png" || echo "❌ Failed"

echo "→ Navigate to Sign In screen..."
sleep 5
xcrun simctl io booted screenshot "$SCREENSHOT_DIR/02-auth-signin.png" 2>/dev/null && echo "✅ 02-auth-signin.png" || echo "❌ Failed"

# Phase 2: Main Interface
echo ""
echo "📸 Phase 2: Main Interface (3 screenshots)"
echo "→ Navigate to Chat List..."
sleep 5
xcrun simctl io booted screenshot "$SCREENSHOT_DIR/03-chat-list.png" 2>/dev/null && echo "✅ 03-chat-list.png" || echo "❌ Failed"

sleep 2
xcrun simctl io booted screenshot "$SCREENSHOT_DIR/04-unread-badges.png" 2>/dev/null && echo "✅ 04-unread-badges.png" || echo "❌ Failed"

sleep 2
xcrun simctl io booted screenshot "$SCREENSHOT_DIR/05-online-status-list.png" 2>/dev/null && echo "✅ 05-online-status-list.png" || echo "❌ Failed"

# Phase 3: Real-Time Messaging
echo ""
echo "📸 Phase 3: Real-Time Messaging (3 screenshots)"
echo "→ Open a chat conversation..."
sleep 5
xcrun simctl io booted screenshot "$SCREENSHOT_DIR/06-chat-screen.png" 2>/dev/null && echo "✅ 06-chat-screen.png" || echo "❌ Failed"

sleep 2
xcrun simctl io booted screenshot "$SCREENSHOT_DIR/08-message-status.png" 2>/dev/null && echo "✅ 08-message-status.png" || echo "❌ Failed"

# Phase 4: Media & Attachments
echo ""
echo "📸 Phase 4: Media & Attachments (3 screenshots)"
echo "→ Tap image/attachment icon..."
sleep 5
xcrun simctl io booted screenshot "$SCREENSHOT_DIR/09-image-picker.png" 2>/dev/null && echo "✅ 09-image-picker.png" || echo "❌ Failed"

echo "→ Select an image (or show preview)..."
sleep 5
xcrun simctl io booted screenshot "$SCREENSHOT_DIR/10-image-preview.png" 2>/dev/null && echo "✅ 10-image-preview.png" || echo "❌ Failed"

echo "→ Show image in chat..."
sleep 5
xcrun simctl io booted screenshot "$SCREENSHOT_DIR/11-image-message.png" 2>/dev/null && echo "✅ 11-image-message.png" || echo "❌ Failed"

# Phase 5: Profile Features
echo ""
echo "📸 Phase 5: Profile Features (3 screenshots)"
echo "→ Open contact profile..."
sleep 5
xcrun simctl io booted screenshot "$SCREENSHOT_DIR/12-contact-profile.png" 2>/dev/null && echo "✅ 12-contact-profile.png" || echo "❌ Failed"

echo "→ Open profile edit screen..."
sleep 5
xcrun simctl io booted screenshot "$SCREENSHOT_DIR/13-profile-edit.png" 2>/dev/null && echo "✅ 13-profile-edit.png" || echo "❌ Failed"

echo "→ Open profile picture picker..."
sleep 5
xcrun simctl io booted screenshot "$SCREENSHOT_DIR/14-profile-picture-picker.png" 2>/dev/null && echo "✅ 14-profile-picture-picker.png" || echo "❌ Failed"

# Phase 6: Theme & Settings
echo ""
echo "📸 Phase 6: Theme & Settings (4 screenshots)"
echo "→ Navigate to Settings..."
sleep 5
xcrun simctl io booted screenshot "$SCREENSHOT_DIR/15-settings-screen.png" 2>/dev/null && echo "✅ 15-settings-screen.png" || echo "❌ Failed"

sleep 2
xcrun simctl io booted screenshot "$SCREENSHOT_DIR/16-theme-selection.png" 2>/dev/null && echo "✅ 16-theme-selection.png" || echo "❌ Failed"

echo "→ Switch to Light theme, go to chat list..."
sleep 5
xcrun simctl io booted screenshot "$SCREENSHOT_DIR/17-light-theme.png" 2>/dev/null && echo "✅ 17-light-theme.png" || echo "❌ Failed"

echo "→ Switch to Dark theme, go to chat list..."
sleep 5
xcrun simctl io booted screenshot "$SCREENSHOT_DIR/18-dark-theme.png" 2>/dev/null && echo "✅ 18-dark-theme.png" || echo "❌ Failed"

# Phase 7: AI Features
echo ""
echo "📸 Phase 7: AI Features (4 screenshots)"
echo "→ Navigate to Chat Assist tab..."
sleep 5
xcrun simctl io booted screenshot "$SCREENSHOT_DIR/19-chat-assist-welcome.png" 2>/dev/null && echo "✅ 19-chat-assist-welcome.png" || echo "❌ Failed"

echo "→ Enter a command..."
sleep 5
xcrun simctl io booted screenshot "$SCREENSHOT_DIR/20-chat-assist-command.png" 2>/dev/null && echo "✅ 20-chat-assist-command.png" || echo "❌ Failed"

echo "→ Show confirmation dialog..."
sleep 5
xcrun simctl io booted screenshot "$SCREENSHOT_DIR/21-chat-assist-confirmation.png" 2>/dev/null && echo "✅ 21-chat-assist-confirmation.png" || echo "❌ Failed"

echo "→ Show success message..."
sleep 5
xcrun simctl io booted screenshot "$SCREENSHOT_DIR/22-chat-assist-success.png" 2>/dev/null && echo "✅ 22-chat-assist-success.png" || echo "❌ Failed"

echo ""
echo "✅ All screenshots captured!"
echo ""
echo "Screenshots saved to: $SCREENSHOT_DIR"
ls -lh "$SCREENSHOT_DIR"/*.png 2>/dev/null | wc -l | xargs echo "Total screenshots:"

