#!/bin/bash

# Automated Screenshot Capture Script
# This script uses iOS Simulator's built-in screenshot capability
# Run this while the app is running in the iOS Simulator

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the project root directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Check if user wants timestamped folder (to preserve old screenshots)
if [ "$1" == "--timestamp" ] || [ "$1" == "-t" ]; then
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    SCREENSHOT_DIR="$PROJECT_ROOT/screenshots/ios/automated_$TIMESTAMP"
    echo -e "${YELLOW}Using timestamped folder to preserve old screenshots${NC}"
else
    SCREENSHOT_DIR="$PROJECT_ROOT/screenshots/ios/automated"
    echo -e "${YELLOW}Note: Existing screenshots will be overwritten${NC}"
    echo -e "${YELLOW}Use --timestamp flag to save to a new folder${NC}"
fi

# Create screenshot directory
mkdir -p "$SCREENSHOT_DIR"

echo -e "${BLUE}📸 Automated Screenshot Capture${NC}"
echo -e "${BLUE}================================${NC}"
echo ""
echo "This script will capture screenshots from the iOS Simulator."
echo "Make sure the app is running in the iOS Simulator."
echo ""
echo "Screenshots will be saved to: $SCREENSHOT_DIR"
echo ""
echo "Usage:"
echo "  ./scripts/automated_screenshots.sh        # Overwrites existing screenshots"
echo "  ./scripts/automated_screenshots.sh -t     # Saves to timestamped folder (preserves old)"
echo ""

# Function to take a screenshot
take_screenshot() {
    local step=$1
    local filename=$2
    local description=$3
    
    echo -e "${YELLOW}Step $step: $description${NC}"
    echo "Press ENTER when the screen is ready, or 's' to skip..."
    read -r response
    
    if [[ "$response" != "s" ]]; then
        # Wait a moment for any animations
        sleep 0.5
        
        # Take screenshot using xcrun simctl
        xcrun simctl io booted screenshot "$SCREENSHOT_DIR/$filename" 2>/dev/null || {
            echo "⚠️  Could not take screenshot automatically."
            echo "   Please take a screenshot manually and save it as: $filename"
            echo "   Location: $SCREENSHOT_DIR"
        }
        
        if [ -f "$SCREENSHOT_DIR/$filename" ]; then
            echo -e "${GREEN}✅ Screenshot saved: $filename${NC}"
        else
            echo -e "${YELLOW}⚠️  Screenshot file not found. Please capture manually.${NC}"
        fi
    else
        echo "⏭️  Skipped"
    fi
    echo ""
}

# Phase 1: Authentication
echo -e "${BLUE}=== Phase 1: Authentication ===${NC}"
take_screenshot "1" "01-auth-signup.png" "Sign Up Screen"
take_screenshot "2" "02-auth-signin.png" "Sign In Screen"

# Phase 2: Main Interface
echo -e "${BLUE}=== Phase 2: Main Interface ===${NC}"
take_screenshot "3" "03-chat-list.png" "Chat List Screen"
take_screenshot "4" "04-unread-badges.png" "Unread Badges"
take_screenshot "5" "05-online-status-list.png" "Online Status Indicators"

# Phase 3: Real-Time Messaging
echo -e "${BLUE}=== Phase 3: Real-Time Messaging ===${NC}"
take_screenshot "6" "06-chat-screen.png" "Active Chat Screen"
echo "Step 7: Typing Indicator (requires second account - skip if not available)"
take_screenshot "7" "07-typing-indicator.png" "Typing Indicator (optional)"
take_screenshot "8" "08-message-status.png" "Message Status Indicators"

# Phase 4: Media & Attachments
echo -e "${BLUE}=== Phase 4: Media & Attachments ===${NC}"
take_screenshot "9" "09-image-picker.png" "Image Picker Dialog"
take_screenshot "10" "10-image-preview.png" "Image Preview"
take_screenshot "11" "11-image-message.png" "Image in Chat"

# Phase 5: Profile Features
echo -e "${BLUE}=== Phase 5: Profile Features ===${NC}"
take_screenshot "12" "12-contact-profile.png" "Contact Profile"
take_screenshot "13" "13-profile-edit.png" "Profile Edit Screen"
take_screenshot "14" "14-profile-picture-picker.png" "Profile Picture Picker"

# Phase 6: Theme & Settings
echo -e "${BLUE}=== Phase 6: Theme & Settings ===${NC}"
take_screenshot "15" "15-settings-screen.png" "Settings Screen"
take_screenshot "16" "16-theme-selection.png" "Theme Selection"
take_screenshot "17" "17-light-theme.png" "Light Theme (chat list)"
take_screenshot "18" "18-dark-theme.png" "Dark Theme (chat list)"

# Phase 7: AI Features
echo -e "${BLUE}=== Phase 7: AI Features ===${NC}"
take_screenshot "19" "19-chat-assist-welcome.png" "Chat Assist Welcome"
take_screenshot "20" "20-chat-assist-command.png" "Chat Assist Command Input"
take_screenshot "21" "21-chat-assist-confirmation.png" "Chat Assist Confirmation"
take_screenshot "22" "22-chat-assist-success.png" "Chat Assist Success"

echo -e "${GREEN}✅ All screenshots captured!${NC}"
echo ""
echo "Screenshots saved to: $SCREENSHOT_DIR"
echo ""
ls -lh "$SCREENSHOT_DIR"/*.png 2>/dev/null || echo "No PNG files found"

