# Interactive Screenshot Script - Instructions

## Option B: Interactive Script (`automated_screenshots.sh`)

### How It Works:
1. The script prompts you for each screenshot
2. You navigate to the correct screen in your app
3. Press **ENTER** when ready
4. The script takes the screenshot automatically
5. Type **'s'** and ENTER to skip any step

### Step-by-Step Guide:

**1. Start your app:**
```bash
flutter run -d ios
```

**2. Run the script:**
```bash
./scripts/automated_screenshots.sh
```

**3. Follow the prompts:**

The script will show:
```
Step 1: Sign Up Screen
Press ENTER when the screen is ready, or 's' to skip...
```

**What to do:**
- Navigate your app to the Sign Up screen
- When it looks good, press **ENTER**
- The screenshot will be taken automatically
- Repeat for each step

### Screenshot Sequence:

**Phase 1: Authentication**
- Step 1: Sign Up screen
- Step 2: Sign In screen (tap "Sign In" tab)

**Phase 2: Main Interface**
- Step 3: Chat List (main screen after login)
- Step 4: Unread Badges (same screen, showing badges)
- Step 5: Online Status (same screen, showing status indicators)

**Phase 3: Real-Time Messaging**
- Step 6: Chat Screen (tap a conversation)
- Step 7: Typing Indicator (optional - requires second account)
- Step 8: Message Status (showing read receipts)

**Phase 4: Media & Attachments**
- Step 9: Image Picker (tap attachment icon)
- Step 10: Image Preview (after selecting image)
- Step 11: Image in Chat (after sending)

**Phase 5: Profile Features**
- Step 12: Contact Profile (tap contact name/avatar in chat)
- Step 13: Profile Edit (navigate to your profile edit)
- Step 14: Profile Picture Picker (tap avatar in edit screen)

**Phase 6: Theme & Settings**
- Step 15: Settings Screen (tap Settings tab)
- Step 16: Theme Selection (theme options visible)
- Step 17: Light Theme (switch to light, go to chat list)
- Step 18: Dark Theme (switch to dark, go to chat list)

**Phase 7: AI Features**
- Step 19: Chat Assist Welcome (tap Chat Assist tab)
- Step 20: Chat Assist Command (type a command)
- Step 21: Chat Assist Confirmation (confirmation dialog)
- Step 22: Chat Assist Success (success message)

### Tips:
- Take your time - no rush!
- You can skip any step by typing 's' and pressing ENTER
- Screenshots save automatically to `screenshots/ios/automated/`
- Check the screenshots after to make sure they look good

### If Something Goes Wrong:
- Press **Ctrl+C** to stop the script
- Screenshots already taken will be saved
- You can re-run and skip steps you missed


