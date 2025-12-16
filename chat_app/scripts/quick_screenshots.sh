#!/bin/bash

# Quick Screenshot Capture - Fully Automated
# This version takes screenshots automatically with delays
# Best used when you can navigate the app manually between shots

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
SCREENSHOT_DIR="$PROJECT_ROOT/screenshots/ios/automated"

mkdir -p "$SCREENSHOT_DIR"

echo "📸 Quick Screenshot Capture"
echo "=========================="
echo ""
echo "This will take screenshots every 3 seconds."
echo "Navigate through your app manually, and screenshots will be captured automatically."
echo ""
echo "Press Ctrl+C to stop"
echo "Starting in 5 seconds..."
sleep 5

counter=1
while true; do
    filename=$(printf "%02d-screenshot-%03d.png" $((counter/22 + 1)) $counter)
    xcrun simctl io booted screenshot "$SCREENSHOT_DIR/$filename" 2>/dev/null || true
    echo "📸 Captured: $filename"
    sleep 3
    ((counter++))
done


