# Feature Suggestions

A prioritized list of features to enhance the chat application, organized by complexity and impact.

---

## ✅ Implemented

### 1. Online/Offline Status
- Track user presence (last seen, online/offline)
- Show status indicators in chat list and chat screen
- Heartbeat updates every 30 seconds
- "Online" or "Last seen X ago" display

### 2. Typing Indicators
- Show "Typing..." when the other user is typing
- Animated dots indicator
- Auto-stops after inactivity

### 3. Profile Editing
Edit username, profile picture, and bio.

**Implementation:**
- Add `avatar_url` and `bio` columns to users table
- Create profile edit screen
- Use Supabase Storage for profile images
- Update UserAvatar widget to show real images

### 4. Theme Toggle UI
Add a settings screen with theme switcher.

**Implementation:**
- Create settings screen accessible from chat list
- Add theme preference persistence (SharedPreferences)
- Expose existing `toggleTheme()` method in main.dart

---

## 🔴 High Priority — Core Enhancements

### 5. Message Deletion
Delete your own messages (soft delete or hard delete).

**Implementation:**
- Add `deleted_at` column to messages table
- Update message queries to filter deleted messages
- Add delete button/swipe action on messages
- Consider "Delete for everyone" vs "Delete for me"

---

## 🟡 Medium Priority — User Experience

### 6. Image/File Sharing
Send images, documents, and other files in chat.

**Implementation:**
- Use Supabase Storage for file uploads
- Add `message_type` enum (text, image, file, voice)
- Add `file_url` and `file_name` columns to messages
- Create image picker and file preview widgets
- Handle image compression before upload

### 8. Message Search
Search within conversations or across all messages.

**Implementation:**
- Add search bar in chat screen
- Use PostgreSQL full-text search or ILIKE
- Highlight search results in messages
- Consider global search across all conversations

### 8. Message Reactions
React to messages with emojis.

**Implementation:**
- Create `message_reactions` table
- Add emoji picker widget
- Show reaction counts on messages
- Allow removing own reactions

### 9. Read Receipts (Detailed)
Show "delivered" and "read" status with timestamps.

**Implementation:**
- Add `delivered_at` and `read_at` timestamps to messages
- Show double checkmarks (delivered) and blue checkmarks (read)
- Display exact read time on tap

### 10. Message Forwarding
Forward messages to other users.

**Implementation:**
- Add forward button in message options
- Show user picker dialog
- Create forwarded message with reference to original

### 11. Voice Messages
Record and send voice messages.

**Implementation:**
- Use audio recording package (record, flutter_sound)
- Store audio files in Supabase Storage
- Create audio player widget for playback
- Show waveform visualization

---

## 🟠 Advanced Features

### 12. Group Chats
Create and manage group conversations.

**Implementation:**
- Create `conversations` table (id, name, type, created_at)
- Create `conversation_members` junction table
- Update messages to reference conversation_id instead of receiver_id
- Create group management UI (add/remove members, rename)
- Handle group avatars and admin permissions

### 13. Push Notifications
Notify users of new messages when app is closed.

**Implementation:**
- Integrate Firebase Cloud Messaging (FCM)
- Store device tokens in database
- Create Supabase Edge Function to send notifications on new message
- Handle notification taps to open specific chat

### 14. Message Encryption
End-to-end encryption for messages.

**Implementation:**
- Use encryption library (encrypt, cryptography)
- Generate and store key pairs per user
- Exchange public keys on conversation start
- Encrypt message content before sending
- Decrypt on receive

### 15. Message Pinning
Pin important messages in conversations.

**Implementation:**
- Add `is_pinned` and `pinned_at` columns to messages
- Show pinned messages section at top of chat
- Limit number of pinned messages per conversation

### 16. Chat Archiving
Archive conversations to hide from main list.

**Implementation:**
- Add `archived_at` timestamp to conversations/users junction
- Filter archived chats from main list
- Create "Archived Chats" section in settings
- Allow unarchiving

### 17. Custom Notifications
Per-conversation notification settings.

**Implementation:**
- Create `notification_preferences` table
- Options: all, mentions only, muted
- Add mute duration options (1 hour, 8 hours, 1 day, forever)
- Show muted indicator in chat list

### 18. Message Editing
Edit sent messages (with "edited" indicator).

**Implementation:**
- Add `edited_at` timestamp to messages
- Store edit history (optional)
- Show "edited" label on modified messages
- Time limit for editing (e.g., 15 minutes)

### 19. Rich Text Formatting
Bold, italic, code blocks, links.

**Implementation:**
- Use markdown or custom formatting syntax
- Parse and render formatted text
- Add formatting toolbar in message input
- Auto-detect and linkify URLs

### 20. Chat Backup/Export
Export conversation history.

**Implementation:**
- Generate PDF or JSON export
- Include media files option
- Email or share export file
- Consider cloud backup integration

---

## 🔵 Nice-to-Have Features

### 21. User Blocking
Block users to prevent messages.

**Implementation:**
- Create `blocked_users` table
- Filter blocked users from search and chat
- Prevent sending messages to blocked users
- Show "User blocked" placeholder

### 22. Message Scheduling
Schedule messages to send later.

**Implementation:**
- Create `scheduled_messages` table
- Add date/time picker UI
- Use Supabase Edge Function or cron job to send
- Show pending scheduled messages

### 23. Chat Templates
Pre-defined message templates.

**Implementation:**
- Store templates locally or in database
- Quick access from message input
- Allow creating custom templates

### 24. Message Translation
Translate messages to different languages.

**Implementation:**
- Integrate translation API (Google Translate, DeepL)
- Add "Translate" button on messages
- Show original and translated text
- Remember language preference

### 25. GIF Support
Search and send GIFs.

**Implementation:**
- Integrate Giphy or Tenor API
- Add GIF search in message input
- Display GIFs in message bubbles
- Consider GIF keyboard integration

### 26. Location Sharing
Share current location in chat.

**Implementation:**
- Use device location services
- Send location as special message type
- Display map preview in chat
- Add "Open in Maps" action

### 27. Video/Voice Calls
Make video or voice calls within the app.

**Implementation:**
- Integrate WebRTC or third-party service (Agora, Twilio)
- Create call UI screens
- Handle call notifications
- Support call history

### 28. Chat Statistics
View conversation statistics.

**Implementation:**
- Count messages per user
- Track most active times
- Word frequency analysis
- Media shared count

### 29. Custom Emojis/Stickers
Add custom emoji packs or stickers.

**Implementation:**
- Store sticker packs in Supabase Storage
- Create sticker picker UI
- Allow downloading additional packs
- Support custom emoji upload

### 30. Message Drafts
Save message drafts.

**Implementation:**
- Store drafts locally per conversation
- Restore draft when opening chat
- Clear draft on send
- Sync drafts across devices (optional)

---

## Recommended Implementation Order

| Priority | Feature | Impact | Effort |
|----------|---------|--------|--------|
| 1 | ~~Online/Offline Status~~ | High | Medium | ✅ Done |
| 2 | ~~Typing Indicators~~ | High | Medium | ✅ Done |
| 3 | Message Deletion | High | Low |
| 4 | Profile Editing | High | Medium |
| 5 | Theme Toggle UI | Medium | Low |
| 6 | Image/File Sharing | High | High |
| 7 | Message Search | Medium | Medium |
| 8 | Group Chats | High | High |
| 9 | Push Notifications | High | High |
| 10 | Message Reactions | Medium | Medium |

---

## Database Schema Changes Required

### For Message Deletion
```sql
ALTER TABLE messages ADD COLUMN deleted_at TIMESTAMP WITH TIME ZONE;
```

### For Profile Editing
```sql
ALTER TABLE users ADD COLUMN avatar_url TEXT;
ALTER TABLE users ADD COLUMN bio TEXT;
```

### For Image/File Sharing
```sql
ALTER TABLE messages ADD COLUMN message_type TEXT DEFAULT 'text';
ALTER TABLE messages ADD COLUMN file_url TEXT;
ALTER TABLE messages ADD COLUMN file_name TEXT;
ALTER TABLE messages ADD COLUMN file_size INTEGER;
```

### For Message Reactions
```sql
CREATE TABLE message_reactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id UUID REFERENCES messages(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  emoji TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(message_id, user_id, emoji)
);
```

### For Group Chats
```sql
CREATE TABLE conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT,
  type TEXT DEFAULT 'direct', -- 'direct' or 'group'
  created_by UUID REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE conversation_members (
  conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'member', -- 'admin' or 'member'
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  PRIMARY KEY (conversation_id, user_id)
);
```

---

*Last Updated: 2024*
