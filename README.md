# SmartChat

A full-featured AI-powered real-time chat application built with **Flutter**, **Supabase**, and a **LangGraph AI agent backend**.

**Live app:** [smart-chat-78868.web.app](https://smart-chat-78868.web.app) · **Landing page:** [shoebsmk.github.io/smart-chat-landing](https://shoebsmk.github.io/smart-chat-landing/)

## Project Structure

| Directory | Description |
|-----------|-------------|
| [`chat_app/`](./chat_app/) | Flutter web/mobile app — real-time messaging, profiles, image attachments, AI Assistant UI |
| [`smartchat-agent/`](./smartchat-agent/) | LangGraph AI agent backend — natural language messaging, summarization, sentiment analysis, scheduling |

## Quick Start

### Flutter App
```bash
cd chat_app
flutter pub get
flutter run -d chrome
```
👉 [Full setup guide](./chat_app/README.md)

### Agent Backend
```bash
cd smartchat-agent
cp .env.example .env   # Add your OpenAI + Supabase keys
pip install -e .
langgraph dev
```
👉 [Full agent docs](./smartchat-agent/README.md)

## Deploy
```bash
cd chat_app
./deploy.sh   # Deploys to Firebase Hosting
```
👉 [Firebase deployment guide](./chat_app/docs/deployment/DEPLOY_TO_FIREBASE.md)

## Documentation

- [Flutter App README](./chat_app/README.md)
- [Agent Backend README](./smartchat-agent/README.md)
- [Architecture](./chat_app/docs/architecture/ARCHITECTURE.md)
- [All Documentation](./chat_app/docs/README.md)
