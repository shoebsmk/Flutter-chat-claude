# Integration Plan: LangGraph Agent → Flutter App

## Principle: ZERO breaking changes. Old path stays intact.

---

## Files to Change (4 files total)

### 1. `pubspec.yaml` — Add HTTP package (1 line)
- Add `http: ^1.2.0` to dependencies
- Needed because the app currently has NO HTTP client (only Supabase SDK)

### 2. `lib/config/agent_config.dart` — NEW file (small)
- Stores the agent base URL: `https://smartchat-agent.onrender.com`
- Follows the same pattern as `supabase_config.dart`
- Supports `--dart-define` override for production

### 3. `lib/services/ai_command_service.dart` — Add ONE new method
- Keep ALL existing methods untouched (`extractIntent`, `resolveRecipient`)
- Add new method: `sendToAgent(String command, String userId, {String? threadId})`
  - Makes HTTP POST to the deployed agent
  - Returns `{response, thread_id, tool_results}`
  - Throws `AICommandException` / `NetworkException` (reuses existing exceptions)

### 4. `lib/screens/ai_assistant_screen.dart` — Modify `_processCommand()`
- Add `_useAgent = true` flag (defaults to new agent)
- In `_processCommand()`:
  - If `_useAgent` is true → call `sendToAgent()` (new path, simpler)
  - If `_useAgent` is false → existing code runs exactly as before
- The agent handles everything server-side (extract + resolve + send)
  so the new path is actually SIMPLER: no confirmation dialog needed,
  no ChatService call, just display the agent's response
- Update welcome screen examples to show multi-person commands

---

## What does NOT change
- `chat_service.dart` — untouched
- `user_service.dart` — untouched
- `auth_service.dart` — untouched
- `app_exceptions.dart` — untouched
- All models — untouched
- All other screens — untouched
- Theme — untouched
- Supabase Edge Function — still exists, still works

---

## New Flow (agent path)

```
User types: "Send Ahmed and Sara hello"
  → _processCommand()
  → _useAgent is true
  → AICommandService.sendToAgent(command, userId)
  → HTTP POST to https://smartchat-agent.onrender.com/agent
  → Agent returns: { response: "Sent hello to Ahmed and Sara!", tool_results: [...] }
  → Display agent response in chat bubble (success)
```

## Old Flow (still works if _useAgent = false)

```
User types: "Send Ahmed hello"
  → _processCommand()
  → _useAgent is false
  → extractIntent() → resolveRecipient() → confirm dialog → sendMessage()
  → (exactly as before, zero changes)
```
