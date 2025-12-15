# Screenshot Capture Sequence

A step-by-step sequence to navigate through the app and capture all feature screenshots efficiently.

---

## 🚀 Pre-Flight Checklist

- [ ] iOS Simulator is open
- [ ] App is running (`flutter run -d ios`)
- [ ] Desktop is ready for screenshots (Cmd+S saves here)
- [ ] You have at least 2 test accounts (for real-time features)

---

## 📸 Complete Screenshot Sequence

### **PHASE 1: Authentication (2 screenshots)**

#### Step 1: Sign Up Screen
- **Action**: App launches → Shows Auth Screen
- **Screenshot**: Capture sign up form (email, password, username fields)
- **File name**: `01-auth-signup.png`
- **Note**: If already logged in, sign out first

#### Step 2: Sign In Screen  
- **Action**: Tap "Sign In" tab (if on Sign Up)
- **Screenshot**: Capture sign in form
- **File name**: `02-auth-signin.png`

---

### **PHASE 2: Main App Interface (3 screenshots)**

#### Step 3: Chat List Screen
- **Action**: After login, you'll see the chat list
- **Screenshot**: Capture chat list with conversations
- **File name**: `03-chat-list.png`
- **Look for**: Unread badges, online status indicators

#### Step 4: Chat List - Unread Messages
- **Action**: Ensure some conversations have unread messages
- **Screenshot**: Capture unread badge counts on conversations
- **File name**: `04-unread-badges.png`
- **Tip**: Send messages from another account if needed

#### Step 5: Online/Offline Status Indicators
- **Action**: Look at chat list for green dots (online) or last seen
- **Screenshot**: Capture status indicators in chat list
- **File name**: `05-online-status-list.png`

---

### **PHASE 3: Real-Time Messaging (3 screenshots)**

#### Step 6: Active Chat Screen
- **Action**: Tap any conversation to open chat
- **Screenshot**: Capture chat interface with message bubbles
- **File name**: `06-chat-screen.png`
- **Look for**: Sent/received messages, timestamps

#### Step 7: Typing Indicator
- **Action**: Have another user/account start typing
- **Screenshot**: Capture "Typing..." indicator
- **File name**: `07-typing-indicator.png`
- **Tip**: Use second device or simulator instance
- **Alternative**: Screen recording works better for this

#### Step 8: Message Status Indicators
- **Action**: Send a message and observe status
- **Screenshot**: Capture read receipts/delivery status
- **File name**: `08-message-status.png`

---

### **PHASE 4: Media & Attachments (3 screenshots)**

#### Step 9: Image Attachment Picker
- **Action**: In chat, tap attachment/image icon
- **Screenshot**: Capture image picker (Gallery/Camera options)
- **File name**: `09-image-picker.png`

#### Step 10: Image Preview
- **Action**: Select an image from gallery
- **Screenshot**: Capture image preview before sending
- **File name**: `10-image-preview.png`

#### Step 11: Image in Chat
- **Action**: Send the image
- **Screenshot**: Capture image message in chat bubble
- **File name**: `11-image-message.png`
- **Look for**: Image thumbnail, loading state (if visible)

---

### **PHASE 5: Profile Features (3 screenshots)**

#### Step 12: Contact Profile
- **Action**: In chat screen, tap contact's name/avatar in header
- **Screenshot**: Capture contact profile (avatar, bio, online status, last seen)
- **File name**: `12-contact-profile.png`

#### Step 13: Profile Edit Screen
- **Action**: Navigate to your own profile edit (from profile or settings)
- **Screenshot**: Capture profile edit screen (username, bio, avatar fields)
- **File name**: `13-profile-edit.png`

#### Step 14: Profile Picture Upload
- **Action**: Tap avatar/photo in profile edit
- **Screenshot**: Capture image picker for profile picture
- **File name**: `14-profile-picture-picker.png`

---

### **PHASE 6: Theme & Settings (4 screenshots)**

#### Step 15: Settings Screen
- **Action**: Navigate to Settings (from profile or menu)
- **Screenshot**: Capture full settings screen
- **File name**: `15-settings-screen.png`
- **Look for**: Theme options, app version, links

#### Step 16: Theme Selection
- **Action**: Tap theme section in settings
- **Screenshot**: Capture theme options (System/Light/Dark)
- **File name**: `16-theme-selection.png`

#### Step 17: Light Theme
- **Action**: Select Light theme, go back to chat list
- **Screenshot**: Capture app in light theme
- **File name**: `17-light-theme.png`
- **Tip**: Capture same screen as Step 3 for comparison

#### Step 18: Dark Theme
- **Action**: Go to Settings → Select Dark theme, return to chat list
- **Screenshot**: Capture app in dark theme
- **File name**: `18-dark-theme.png`
- **Tip**: Capture same screen as Step 3 for comparison

---

### **PHASE 7: AI Features - Chat Assist (4 screenshots)**

#### Step 19: Chat Assist Welcome Screen
- **Action**: Tap "Chat Assist" tab in bottom navigation
- **Screenshot**: Capture welcome screen with examples
- **File name**: `19-chat-assist-welcome.png`
- **Look for**: Examples, suggestion button, sparkles icon

#### Step 20: Chat Assist Command Input
- **Action**: Type a command like "Send [username] Hello there"
- **Screenshot**: Capture command in input field
- **File name**: `20-chat-assist-command.png`

#### Step 21: Chat Assist Confirmation
- **Action**: Send command, wait for confirmation dialog
- **Screenshot**: Capture confirmation dialog (recipient + message)
- **File name**: `21-chat-assist-confirmation.png`

#### Step 22: Chat Assist Success
- **Action**: Confirm and send, wait for success message
- **Screenshot**: Capture success message in Chat Assist
- **File name**: `22-chat-assist-success.png`
- **Look for**: "Message sent to [username]" confirmation

---

### **PHASE 8: Cross-Platform (Optional - 2+ screenshots)**

#### Step 23: iOS App
- **Action**: You're already here! Capture a key screen
- **Screenshot**: Final iOS screenshot (chat list or main screen)
- **File name**: `23-ios-app.png`

#### Step 24: Web App (if available)
- **Action**: Run `flutter run -d chrome`
- **Screenshot**: Capture same screen on web
- **File name**: `24-web-app.png`

#### Step 25: Android App (if available)
- **Action**: Run `flutter run -d android`
- **Screenshot**: Capture same screen on Android
- **File name**: `25-android-app.png`

---

## 📋 Quick Sequence Summary

```
1.  Auth Sign Up          → 01-auth-signup.png
2.  Auth Sign In          → 02-auth-signin.png
3.  Chat List             → 03-chat-list.png
4.  Unread Badges         → 04-unread-badges.png
5.  Online Status List    → 05-online-status-list.png
6.  Chat Screen           → 06-chat-screen.png
7.  Typing Indicator     → 07-typing-indicator.png
8.  Message Status       → 08-message-status.png
9.  Image Picker          → 09-image-picker.png
10. Image Preview         → 10-image-preview.png
11. Image Message         → 11-image-message.png
12. Contact Profile       → 12-contact-profile.png
13. Profile Edit          → 13-profile-edit.png
14. Profile Pic Picker    → 14-profile-picture-picker.png
15. Settings Screen       → 15-settings-screen.png
16. Theme Selection       → 16-theme-selection.png
17. Light Theme           → 17-light-theme.png
18. Dark Theme            → 18-dark-theme.png
19. Chat Assist Welcome   → 19-chat-assist-welcome.png
20. Chat Assist Command   → 20-chat-assist-command.png
21. Chat Assist Confirm  → 21-chat-assist-confirmation.png
22. Chat Assist Success   → 22-chat-assist-success.png
23. iOS App (Final)       → 23-ios-app.png
24. Web App (Optional)    → 24-web-app.png
25. Android (Optional)     → 25-android-app.png
```

---

## ⚡ Time Estimates

- **Phase 1 (Auth)**: 2 minutes
- **Phase 2 (Main Interface)**: 3 minutes
- **Phase 3 (Messaging)**: 5 minutes (typing indicator may need setup)
- **Phase 4 (Media)**: 3 minutes
- **Phase 5 (Profile)**: 3 minutes
- **Phase 6 (Theme)**: 4 minutes
- **Phase 7 (AI)**: 5 minutes
- **Phase 8 (Cross-platform)**: 5-10 minutes (optional)

**Total Time**: ~30-35 minutes for all screenshots

---

## 🎯 Tips for Efficient Capture

1. **Batch Similar Screenshots**: Do all theme screenshots together
2. **Use Two Devices**: For typing indicators and real-time features
3. **Prepare Test Data**: Have conversations and messages ready
4. **Take Multiple Angles**: Some features benefit from different views
5. **Screen Recordings**: Consider for typing indicators and animations

---

## 🔄 If You Need to Restart

If you need to restart the sequence:

1. **Sign Out**: Go to Settings → Sign Out (if available)
2. **Or**: Clear app data and restart
3. **Or**: Use a fresh simulator instance

---

## ✅ Final Checklist

After completing the sequence:

- [ ] All 22+ screenshots captured
- [ ] Files named correctly (01-25)
- [ ] Screenshots are clear and high quality
- [ ] No debug information visible
- [ ] Consistent theme where applicable
- [ ] All features represented
- [ ] Screenshots organized in folder

---

## 📁 Organization

After capturing, organize screenshots:

```bash
# Create folders
mkdir -p screenshots/ios/features
mkdir -p screenshots/ios/themes

# Move and organize
mv ~/Desktop/Screen\ Shot*.png screenshots/ios/features/
```

---

## 🚨 Troubleshooting

**If app is already logged in:**
- Sign out first, or use a fresh simulator

**If typing indicator doesn't show:**
- Use second device/account
- Or capture as screen recording

**If unread badges don't show:**
- Send messages from another account
- Or manually mark as unread in database

**If Chat Assist doesn't work:**
- Check AI provider configuration
- Verify Edge Function is deployed
- Check API keys in Supabase

---

## 📝 Notes

- Some screenshots may require specific app state (unread messages, online users)
- Prepare test accounts/data before starting
- Take multiple shots and choose the best ones
- Consider screen recordings for dynamic features

