# SmartChat Agent — 6 Features Implementation Plan (Final)

Zero Supabase schema changes. All features are agent-native (Python server + Flutter client).

---

## Practicality Review

### ✅ No Risk — Pure Backend Tools (Features 2, 7, 9)

These only add new Python tool files + register them in `graph.py`. Zero Flutter changes beyond adding suggestion chips. The agent already handles arbitrary tool responses.

### ⚠️ Moderate Risk — Server Infrastructure (Features 1, 10)

| Feature | Concern | Mitigation |
|---------|---------|------------|
| 1. Scheduling | APScheduler in single-process server; jobs lost if process crashes before SQLite flush | SQLite job store persists jobs. On Render free tier, server sleeps — but waking it resumes jobs. |
| 10. Auto-reply | Supabase Realtime WebSocket must stay connected | Reconnect logic with exponential backoff. Auto-replies pause on disconnect, resume on reconnect. |

### ⚠️ Moderate Risk — Flutter UI Changes (Features 3, 9)

The `ai_assistant_screen.dart` is 1139 lines with tightly coupled state. Our changes are **strictly additive**:

| Change | Location | What we touch |
|--------|----------|---------------|
| Mic button | L828-864 | Add mic button **beside** existing send button |
| Sentiment chart | L992-1106 | Add `if` check for JSON → render chart above text |
| Example chips | L739-756 | Append 3 more `_buildExampleItem()` calls |
| State vars | L30-58 | Add 2 new booleans |
| Dispose | L1130-1136 | Add `_speechService.stop()` |

**Rule: Every Flutter edit is an addition, never a modification of existing code.**

---

## Build Order

```
Phase 1 (Backend only — zero Flutter changes):
  Feature 2: Summarization → Feature 7: Digest → Feature 9: Sentiment tool

Phase 2 (Flutter UI — minimal, additive):
  Feature 9: Sentiment chart widget + bubble detect
  Feature 3: Voice commands (mic button + speech service)
  Welcome screen: new example chips

Phase 3 (Server infrastructure):
  Feature 1: APScheduler + scheduling tools
  Feature 10: Realtime listener + auto-reply tools + settings UI
```

---

## Phase 1 — Backend Tools (Python only)

### Feature 2: Message Summarization 📋

- [NEW] `src/tools/summarization.py` — `summarize_conversation` tool
  - Fetches messages between user and contact from Supabase
  - Returns raw messages; LLM generates the summary naturally
- [MODIFY] `src/agent/graph.py` — register tool + update system prompt

### Feature 7: Daily Digest 📰

- [NEW] `src/tools/digest.py` — `get_daily_digest` tool
  - Queries: unread count, unanswered convos, most active contacts
  - Returns structured data; LLM formats a friendly briefing
- [MODIFY] `src/agent/graph.py` — register tool

### Feature 9: Sentiment Analysis Tool 📊

- [NEW] `src/tools/sentiment.py` — `analyze_sentiment` tool
  - Fetches messages, runs ONE nested LLM call for batch sentiment rating
  - Returns `{ overall_mood, score, trend, message_sentiments }`
  - Includes `__SENTIMENT_CHART__` marker for Flutter chart rendering
- [MODIFY] `src/agent/graph.py` — register tool

---

## Phase 2 — Flutter UI (Additive only)

### Sentiment Chart Widget

- [NEW] `lib/widgets/sentiment_chart_widget.dart` — self-contained chart card
- [MODIFY] `ai_assistant_screen.dart` — detect sentiment JSON in bubbles → render chart
- [MODIFY] `pubspec.yaml` — add `fl_chart: ^0.70.2`

### Voice Commands 🎙️

- [NEW] `lib/services/speech_service.dart` — singleton (same pattern as `HapticService`)
- [MODIFY] `ai_assistant_screen.dart` — mic button beside send button
- [MODIFY] `pubspec.yaml` — add `speech_to_text: ^7.0.0`
- Platform config: iOS `Info.plist`, macOS entitlements, Android manifest

### Welcome Screen Chips

- [MODIFY] `ai_assistant_screen.dart` — 3 new example items (summarize, briefing, sentiment)

---

## Phase 3 — Server Infrastructure

### Feature 1: Smart Scheduling ⏰

- [NEW] `src/scheduler.py` — APScheduler singleton with SQLite job store
- [NEW] `src/tools/scheduling.py` — `schedule_message`, `list_scheduled_messages`, `cancel_scheduled_message`
- [MODIFY] `server.py` — FastAPI lifespan to start/stop scheduler
- [MODIFY] `pyproject.toml` — add `apscheduler`, `python-dateutil`, `sqlalchemy`

Supports seconds-level precision. Short delays (<2min) use asyncio directly.

### Feature 10: Auto-Responder 🤖

- [NEW] `src/tools/auto_reply.py` — `set_auto_reply`, `clear_auto_reply` (local SQLite storage)
- [NEW] `src/realtime_listener.py` — Supabase Realtime WebSocket listener
  - `smart_context = true` → LLM-personalized auto-replies
  - Loop prevention: skips replying to auto-replies
- [MODIFY] `settings_screen.dart` — "AI Features" section with Away Mode toggle
- Settings saved via existing `AICommandService.sendToAgent()` (no new Flutter service)

---

## Files Summary

| Layer | File | Type |
|-------|------|------|
| Python tools | `src/tools/summarization.py` | NEW |
| | `src/tools/digest.py` | NEW |
| | `src/tools/sentiment.py` | NEW |
| | `src/tools/scheduling.py` | NEW |
| | `src/tools/auto_reply.py` | NEW |
| Python infra | `src/scheduler.py` | NEW |
| | `src/realtime_listener.py` | NEW |
| Python core | `src/agent/graph.py` | MODIFY |
| | `server.py` | MODIFY |
| | `pyproject.toml` | MODIFY |
| Flutter | `lib/services/speech_service.dart` | NEW |
| | `lib/widgets/sentiment_chart_widget.dart` | NEW |
| | `lib/screens/ai_assistant_screen.dart` | MODIFY (~40 lines added) |
| | `lib/screens/settings_screen.dart` | MODIFY (~50 lines added) |
| | `pubspec.yaml` | MODIFY (2 lines) |
| Config | iOS `Info.plist`, macOS entitlements | MODIFY (mic permissions) |

**Flutter safety:** Only 2 existing Dart files modified, ~90 lines added total. Zero existing lines rewritten.
