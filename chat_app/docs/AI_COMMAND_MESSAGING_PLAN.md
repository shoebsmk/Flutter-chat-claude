# AI-Powered Command-Based Messaging Integration Plan

## Overview

This document outlines the plan for integrating an AI-powered command-based messaging feature that allows users to send messages using natural language commands like "Send Ahmed I'll be late".

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Flutter App                                │
│  ┌──────────────────┐         ┌──────────────────────────┐  │
│  │  Chat List Tab   │         │   AI Assistant Tab       │  │
│  │  (Existing)      │         │   (New)                  │  │
│  └──────────────────┘         └──────────────────────────┘  │
│                                      │                         │
│                                      ▼                         │
│                            ┌──────────────────┐              │
│                            │ AICommandService │              │
│                            └──────────────────┘              │
│                                      │                         │
└──────────────────────────────────────┼─────────────────────────┘
                                        │
                                        ▼
                            ┌──────────────────────────┐
                            │ Supabase Edge Function   │
                            │ (Intent Extraction)      │
                            └──────────────────────────┘
                                        │
                                        ▼
                            ┌──────────────────────────┐
                            │ Google Gemini API        │
                            │ JSON-only output         │
                            └──────────────────────────┘
```

## Design Decisions

### 1. Navigation Structure
- **Add Bottom Navigation Bar** with 2 tabs:
  - Tab 1: "Chats" (existing ChatListScreen)
  - Tab 2: "AI Assistant" (new AIAssistantScreen)
- Replace direct navigation to ChatListScreen with a MainScreen that contains the bottom navigation

### 2. AI Integration Flow
1. User types natural language command in AI Assistant screen
2. Flutter calls Supabase Edge Function with command text
3. Edge Function calls AI API to extract intent (recipient_query, message)
4. Edge Function returns JSON: `{recipient_query: string, message: string}`
5. Flutter resolves recipient using UserService.searchUsers()
6. Flutter shows confirmation dialog with resolved recipient and message
7. User confirms → Flutter calls ChatService.sendMessage()
8. User cancels → No action

### 3. Security & Constraints
- ✅ AI only extracts intent (no message sending)
- ✅ All AI calls via Supabase Edge Function (API keys secured)
- ✅ User confirmation mandatory before sending
- ✅ No local parsing fallback
- ✅ Uses existing chat infrastructure

### 4. Risk Assessment for Supabase DB

**This feature is SAFE for Supabase DB because:**

1. **No Direct Database Access from AI**
   - AI only returns extracted data (recipient_query, message)
   - AI never touches the database
   - All database operations use existing, protected services

2. **User Confirmation Required**
   - Even if AI extracts wrong data, user must confirm before sending
   - User can see exactly what will be sent and to whom
   - User can cancel at any time

3. **Uses Existing Protected Services**
   - `ChatService.sendMessage()` already has RLS (Row Level Security) protection
   - All existing security policies apply
   - No new database permissions needed

4. **Server-Side API Keys**
   - Gemini API key stored in Supabase Edge Function secrets
   - Never exposed to client
   - Protected by Supabase's security model

5. **Input Validation**
   - Command text is validated before processing
   - Recipient resolution validates against existing users
   - Message content goes through existing validation

6. **Error Handling**
   - All errors are caught and handled gracefully
   - Failed extractions don't affect database
   - Network errors don't cause data corruption

**Risk Mitigation:**
- If AI extracts wrong recipient → User sees it in confirmation dialog
- If AI extracts wrong message → User sees it in confirmation dialog
- If Edge Function fails → Error shown, no database changes
- If recipient not found → Error shown, no message sent

**Conclusion:** This feature is **low risk** because it's read-only for AI (extraction only) and all writes go through existing, protected chat infrastructure with mandatory user confirmation.

## Implementation Tasks

### Task 1: Supabase Edge Function for Intent Extraction

**File**: `supabase/functions/extract-message-intent/index.ts`

**Purpose**: Extract recipient query and message from natural language input

**Input**:
```json
{
  "command": "Send Ahmed I'll be late"
}
```

**Output**:
```json
{
  "recipient_query": "Ahmed",
  "message": "I'll be late"
}
```

**Implementation Details**:
- Use Google Gemini API (gemini-1.5-flash or gemini-1.5-pro)
- System prompt: "Extract recipient name/query and message text from user commands. Return JSON only."
- Strict JSON schema validation
- Error handling for malformed responses
- Rate limiting considerations
- Cost optimization: use gemini-1.5-flash for simple extraction (faster, cheaper)

**Edge Function Structure**:
```typescript
// supabase/functions/extract-message-intent/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

serve(async (req) => {
  try {
    const { command } = await req.json()
    
    if (!command || typeof command !== 'string' || command.trim().length === 0) {
      return new Response(
        JSON.stringify({ error: 'Command is required' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }
    
    // Get Gemini API key from environment
    const geminiApiKey = Deno.env.get('GEMINI_API_KEY')
    if (!geminiApiKey) {
      return new Response(
        JSON.stringify({ error: 'Gemini API key not configured' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }
    
    // Call Google Gemini API
    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${geminiApiKey}`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          contents: [{
            parts: [{
              text: `Extract recipient name/query and message text from this command: "${command.trim()}"\n\nReturn ONLY valid JSON with this exact format (no other text):\n{"recipient_query": "name or partial name", "message": "message text"}`
            }]
          }],
          generationConfig: {
            temperature: 0.1, // Low temperature for consistent extraction
            responseMimeType: 'application/json',
          },
        }),
      }
    )
    
    if (!response.ok) {
      const errorData = await response.text()
      console.error('Gemini API error:', errorData)
      return new Response(
        JSON.stringify({ error: 'Failed to extract intent' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }
    
    const data = await response.json()
    
    // Extract text from Gemini response
    const content = data.candidates?.[0]?.content?.parts?.[0]?.text
    if (!content) {
      return new Response(
        JSON.stringify({ error: 'Invalid response from AI' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }
    
    // Parse JSON response
    let parsedContent
    try {
      parsedContent = JSON.parse(content)
    } catch (parseError) {
      console.error('JSON parse error:', parseError, 'Content:', content)
      return new Response(
        JSON.stringify({ error: 'Failed to parse AI response' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }
    
    // Validate and return
    return new Response(
      JSON.stringify({
        recipient_query: parsedContent.recipient_query || '',
        message: parsedContent.message || '',
      }),
      { headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Edge function error:', error)
    return new Response(
      JSON.stringify({ error: error.message || 'Internal server error' }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
```

**Deployment**:
```bash
# Set Gemini API key as secret
supabase secrets set GEMINI_API_KEY=your_gemini_api_key_here

# Deploy the function
supabase functions deploy extract-message-intent
```

**Getting Gemini API Key**:
1. Go to https://aistudio.google.com/app/apikey
2. Create a new API key
3. Store it in Supabase secrets (never commit to code)

---

### Task 2: Flutter Service for AI Command Processing

**File**: `lib/services/ai_command_service.dart`

**Purpose**: Handle AI intent extraction and recipient resolution

**Key Methods**:
- `extractIntent(String command)` - Calls Edge Function
- `resolveRecipient(String query, List<User> users)` - Finds matching user

**Implementation**:
```dart
class AICommandService {
  final SupabaseClient _client;
  
  AICommandService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;
  
  /// Extracts intent from natural language command
  /// Returns: {recipient_query: string, message: string}
  Future<Map<String, String>> extractIntent(String command) async {
    try {
      final response = await _client.functions.invoke(
        'extract-message-intent',
        body: {'command': command.trim()},
      );
      
      final data = response.data as Map<String, dynamic>;
      return {
        'recipient_query': data['recipient_query']?.toString() ?? '',
        'message': data['message']?.toString() ?? '',
      };
    } catch (e) {
      throw AICommandException('Failed to extract intent: $e');
    }
  }
  
  /// Resolves recipient from query string
  /// Returns best matching user or null
  Future<User?> resolveRecipient(String query, List<User> allUsers) async {
    if (query.isEmpty) return null;
    
    final lowerQuery = query.toLowerCase().trim();
    
    // Exact match first
    for (final user in allUsers) {
      if (user.username.toLowerCase() == lowerQuery) {
        return user;
      }
    }
    
    // Partial match
    for (final user in allUsers) {
      if (user.username.toLowerCase().contains(lowerQuery)) {
        return user;
      }
    }
    
    // Fuzzy match (simple contains check)
    final matches = allUsers.where((user) =>
      user.username.toLowerCase().contains(lowerQuery) ||
      lowerQuery.contains(user.username.toLowerCase())
    ).toList();
    
    return matches.isNotEmpty ? matches.first : null;
  }
}
```

**Exception Class**:
```dart
// Add to lib/exceptions/app_exceptions.dart
class AICommandException extends AppException {
  AICommandException(super.message);
  
  factory AICommandException.extractionFailed() =>
      AICommandException('Failed to extract message intent');
  
  factory AICommandException.recipientNotFound() =>
      AICommandException('Recipient not found');
}
```

---

### Task 3: Main Screen with Bottom Navigation

**File**: `lib/screens/main_screen.dart`

**Purpose**: Container screen with bottom navigation bar

**Implementation**:
```dart
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const ChatListScreen(),
    const AIAssistantScreen(),
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy),
            label: 'AI Assistant',
          ),
        ],
      ),
    );
  }
}
```

**Update main.dart**:
- Replace `ChatListScreen()` with `MainScreen()` in authenticated routes

---

### Task 4: AI Assistant Screen

**File**: `lib/screens/ai_assistant_screen.dart`

**Purpose**: Chatbot-like interface for AI command input

**Features**:
- Text input field for natural language commands
- Send button
- Loading state during intent extraction
- Error display
- Example commands hint

**UI Structure**:
```
┌─────────────────────────────────┐
│  AI Assistant          [Settings]│
├─────────────────────────────────┤
│                                   │
│  💡 Try: "Send Ahmed I'll be late"│
│                                   │
│  [Text Input Field]        [Send]│
│                                   │
│  Recent commands:                 │
│  • Send John Hello                │
│                                   │
└─────────────────────────────────┘
```

**Implementation**:
```dart
class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});
  
  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final _commandController = TextEditingController();
  final _aiCommandService = AICommandService();
  final _userService = UserService();
  final _chatService = ChatService();
  bool _isProcessing = false;
  List<User> _allUsers = [];
  
  @override
  void initState() {
    super.initState();
    _loadUsers();
  }
  
  Future<void> _loadUsers() async {
    _allUsers = await _userService.getAllUsers();
  }
  
  Future<void> _processCommand() async {
    final command = _commandController.text.trim();
    if (command.isEmpty || _isProcessing) return;
    
    setState(() => _isProcessing = true);
    
    try {
      // Extract intent
      final intent = await _aiCommandService.extractIntent(command);
      
      // Resolve recipient
      final recipient = await _aiCommandService.resolveRecipient(
        intent['recipient_query']!,
        _allUsers,
      );
      
      if (recipient == null) {
        _showError('Recipient "${intent['recipient_query']}" not found');
        return;
      }
      
      // Show confirmation
      final confirmed = await _showConfirmationDialog(
        recipient: recipient,
        message: intent['message']!,
      );
      
      if (confirmed == true) {
        // Send message
        await _chatService.sendMessage(
          receiverId: recipient.id,
          content: intent['message']!,
        );
        
        _showSuccess('Message sent to ${recipient.username}');
        _commandController.clear();
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }
  
  Future<bool?> _showConfirmationDialog({
    required User recipient,
    required String message,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Send'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('To: ${recipient.username}'),
            const SizedBox(height: 16),
            Text('Message: $message'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
  
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
        actions: [
          // Settings button if needed
        ],
      ),
      body: Column(
        children: [
          // Example commands hint
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Try: "Send Ahmed I\'ll be late"',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          
          // Input field
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commandController,
                    enabled: !_isProcessing,
                    decoration: const InputDecoration(
                      hintText: 'Type your command...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _processCommand(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isProcessing ? null : _processCommand,
                  child: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _commandController.dispose();
    super.dispose();
  }
}
```

---

### Task 5: Recipient Resolution Logic

**Enhancement to AICommandService**:
- Handle multiple matches (show selection dialog)
- Handle partial matches
- Handle case-insensitive matching
- Handle special characters in usernames

**Multiple Matches Handling**:
```dart
Future<User?> resolveRecipient(String query, List<User> allUsers) async {
  if (query.isEmpty) return null;
  
  final lowerQuery = query.toLowerCase().trim();
  final matches = <User>[];
  
  // Exact match
  for (final user in allUsers) {
    if (user.username.toLowerCase() == lowerQuery) {
      return user; // Return immediately for exact match
    }
  }
  
  // Partial matches
  for (final user in allUsers) {
    if (user.username.toLowerCase().contains(lowerQuery)) {
      matches.add(user);
    }
  }
  
  if (matches.isEmpty) return null;
  if (matches.length == 1) return matches.first;
  
  // Multiple matches - let user choose (future enhancement)
  // For now, return first match
  return matches.first;
}
```

---

### Task 6: Error Handling & Edge Cases

**Error Scenarios**:
1. **AI API failure**: Show user-friendly error, suggest retry
2. **Invalid JSON from AI**: Log error, show generic error message
3. **Recipient not found**: Show specific error with query
4. **Network failure**: Show network error, allow retry
5. **Empty command**: Prevent submission
6. **Empty message after extraction**: Show error

**Error Handling Implementation**:
```dart
try {
  final intent = await _aiCommandService.extractIntent(command);
  
  if (intent['message']?.isEmpty ?? true) {
    _showError('Could not extract message from command');
    return;
  }
  
  // ... rest of flow
} on AICommandException catch (e) {
  _showError(e.message);
} on NetworkException catch (e) {
  _showError('Network error. Please check your connection.');
} catch (e) {
  _showError('An unexpected error occurred');
  debugPrint('Error: $e');
}
```

---

### Task 7: Integration with Existing Chat Logic

**Reuse Existing Services**:
- ✅ `ChatService.sendMessage()` - Already handles message sending
- ✅ `UserService.getAllUsers()` - Get all users for recipient resolution
- ✅ `UserService.searchUsers()` - Alternative for recipient search

**No Changes Required**:
- Message model remains the same
- Database schema unchanged
- Real-time updates work automatically
- Unread counts update automatically

---

## File Structure

```
lib/
├── screens/
│   ├── main_screen.dart          # NEW: Bottom navigation container
│   ├── ai_assistant_screen.dart  # NEW: AI command interface
│   ├── chat_list_screen.dart     # EXISTING: Modified to work in tab
│   └── ...
├── services/
│   ├── ai_command_service.dart   # NEW: AI intent extraction service
│   ├── chat_service.dart          # EXISTING: No changes
│   ├── user_service.dart         # EXISTING: No changes
│   └── ...
├── exceptions/
│   └── app_exceptions.dart       # MODIFIED: Add AICommandException
└── ...

supabase/
└── functions/
    └── extract-message-intent/
        └── index.ts               # NEW: Edge Function
```

---

## Testing Plan

### Unit Tests
1. **AICommandService.extractIntent()**
   - Test with various command formats
   - Test error handling
   - Test empty/invalid commands

2. **AICommandService.resolveRecipient()**
   - Test exact match
   - Test partial match
   - Test no match
   - Test multiple matches

### Integration Tests
1. **End-to-end flow**
   - User types command → Intent extracted → Recipient resolved → Confirmation shown → Message sent

2. **Error scenarios**
   - Network failure
   - AI API failure
   - Recipient not found
   - Invalid command format

### Manual Testing Checklist
- [ ] Type "Send Ahmed I'll be late" → Verify intent extraction
- [ ] Verify recipient resolution with exact match
- [ ] Verify recipient resolution with partial match
- [ ] Test confirmation dialog
- [ ] Test message sending after confirmation
- [ ] Test error handling for invalid commands
- [ ] Test network error handling
- [ ] Verify message appears in chat list
- [ ] Test bottom navigation switching

---

## Cost & Performance Considerations

### AI API Costs (Gemini)
- **Model**: Use `gemini-1.5-flash` for cost efficiency (faster, cheaper)
- **Alternative**: `gemini-1.5-pro` for better accuracy (if needed)
- **Token usage**: ~50-100 tokens per request (very low)
- **Estimated cost**: ~$0.00001 per command (extremely cheap with flash model)
- **Free tier**: Gemini has generous free tier (60 requests/minute)

### Latency Optimization
- **Edge Function location**: Deploy close to users
- **Caching**: Consider caching common patterns (optional, future)
- **Timeout**: Set 10s timeout for AI calls
- **Loading states**: Show clear loading indicators

### Rate Limiting
- Consider rate limiting per user (optional)
- Handle rate limit errors gracefully

---

## Security Considerations

1. **API Keys**: Stored in Supabase Edge Function secrets (never in client)
   - Gemini API key stored as `GEMINI_API_KEY` secret
   - Never exposed to Flutter app
2. **Input Validation**: Validate command length, sanitize input
   - Max command length: 500 characters (prevent abuse)
   - Trim and validate before processing
3. **User Authentication**: Edge Function verifies user auth token
   - Optional: Add auth verification in Edge Function
   - Flutter app already requires authentication
4. **RLS**: Existing RLS policies protect message sending
   - All messages go through `ChatService.sendMessage()`
   - Existing RLS policies apply automatically
5. **Error Messages**: Don't expose internal errors to users
   - Generic error messages for users
   - Detailed errors logged server-side only
6. **Rate Limiting**: Consider rate limiting per user (optional)
   - Prevent abuse of AI API
   - Can be implemented in Edge Function or Supabase

---

## Future Enhancements (Out of Scope)

- [ ] Command history
- [ ] Multiple recipient support ("Send Ahmed and John Hello")
- [ ] Scheduled messages ("Send Ahmed I'll be late tomorrow")
- [ ] Message templates
- [ ] Voice input
- [ ] Multi-language support

---

## Questions for Clarification

1. ✅ **AI Provider**: **Gemini API** (confirmed)
2. ✅ **Model Selection**: **gemini-1.5-flash** (cost-effective, fast) or **gemini-1.5-pro** (if better accuracy needed)
3. **Multiple Matches**: How should we handle when query matches multiple users?
   - Option A: Return first match (simplest)
   - Option B: Show selection dialog (better UX)
4. **Command Examples**: Should we show example commands in the UI?
5. **Error Recovery**: Should we allow retry on errors or just show error message?

---

## Implementation Order

1. ✅ Create Supabase Edge Function
2. ✅ Create AICommandService
3. ✅ Create MainScreen with bottom navigation
4. ✅ Create AIAssistantScreen
5. ✅ Update main.dart to use MainScreen
6. ✅ Add error handling
7. ✅ Test end-to-end flow
8. ✅ Polish UI/UX

---

## Success Criteria

- [ ] Users can type natural language commands
- [ ] AI extracts recipient and message correctly
- [ ] Recipient is resolved from existing users
- [ ] Confirmation dialog appears before sending
- [ ] Messages are sent using existing chat infrastructure
- [ ] Error handling works for all edge cases
- [ ] UI is intuitive and matches app design
- [ ] No breaking changes to existing features

---

**Last Updated**: 2024
**Status**: Planning Phase

