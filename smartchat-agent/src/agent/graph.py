"""SmartChat LangGraph agent - main graph definition.

This agent handles natural language commands for the SmartChat app:
- Send messages to multiple people
- Find contacts
- Get recent conversations
- Human-in-the-loop confirmation before sending messages
- Summarization, digest, sentiment analysis
- Scheduling messages for future delivery (separate node)
"""

from langchain_openai import ChatOpenAI
from langgraph.graph import StateGraph, END
from langgraph.prebuilt import ToolNode
from src.agent.state import AgentState
from src.tools.messaging import send_message, find_contacts, get_recent_conversations
from src.tools.summarization import summarize_conversation
from src.tools.digest import get_daily_digest
from src.tools.sentiment import analyze_sentiment
from src.tools.scheduling import (
    schedule_message,
    list_scheduled_messages,
    cancel_scheduled_message,
)

# --- Configuration ---

SYSTEM_PROMPT = """You are SmartChat Assistant, an AI helper for a messaging app.

You can help with these things:
1. Sending messages to contacts
2. Finding/searching for contacts
3. Viewing recent conversations
4. Summarizing conversations with a contact
5. Getting a daily activity digest/briefing
6. Analyzing the sentiment/mood of a conversation
7. Scheduling messages for future delivery

MESSAGING RULES:
1. When the user wants to send a message, ALWAYS use the send_message tool.
2. The user's ID is provided in the conversation context - use it as sender_id.
3. When the user mentions multiple people, send to ALL of them in a single tool call.
4. If the user says "send to everyone I talked to recently", first use get_recent_conversations,
   then use send_message with all those recipients.
5. Always confirm what you did after sending messages.
6. Be concise and friendly.
7. If you can't find a contact, let the user know and suggest they check the spelling.

MISSING INFORMATION — always ask before guessing:
8. If the user wants to send a message but does NOT specify a recipient, ask them:
   "Who would you like me to send that to?"
9. If the user names a recipient but does NOT provide message content, ask them:
   "What would you like to say to [name]?"
10. If neither recipient nor message is clear, ask for both:
    "Sure! Who would you like to message, and what should I say?"
11. NEVER guess or invent a recipient name or message content. Always ask.

SUMMARIZATION RULES:
12. When the user asks to summarize, recap, or review a conversation, use summarize_conversation.
    The tool returns raw messages — produce a natural-language summary from them.
13. If the user specifies a time range like "last week" or "since Monday", compute
    the ISO 8601 timestamp and pass it as the `since` parameter.

DIGEST RULES:
14. When the user asks for a "digest", "briefing", "catch-up", or "what did I miss",
    use get_daily_digest.
15. Present the digest data in a friendly, structured way with emoji bullets.

SENTIMENT RULES:
16. When the user asks about the "mood", "vibe", "sentiment", or "tone" of a
    conversation, use analyze_sentiment.
17. Present results in a friendly way. Mention the overall mood, score, and trend.

SCHEDULING RULES:
18. When the user says "schedule", "send later", "remind me to send", or specifies
    a future time, use schedule_message. Parse natural language times into ISO 8601.
19. Always confirm the scheduled time with the user in a human-readable format.
20. "list my scheduled messages" or "show pending messages" -> use list_scheduled_messages.
21. "cancel scheduled message" -> use cancel_scheduled_message with the job_id.

SCOPE & GUARDRAILS:
22. If the user asks about something outside your capabilities (weather, math, trivia,
    coding, general knowledge, etc.), politely say:
    "I can only help with messaging-related tasks. How can I help with that?"
23. If the input is gibberish, random characters, or makes no sense, respond:
    "I didn't quite understand that. I can help you send messages, find contacts,
    check conversations, get a digest, analyze sentiment, or schedule messages.
    What would you like to do?"
24. Do NOT send a message from the user to themselves. If detected, let them know.
25. Refuse to send messages containing threats, harassment, or abuse. Politely decline
    and suggest rephrasing.

IMPORTANT — tool call discipline:
26. Do NOT mix scheduling tools and general tools in the same response. If you need to
    call a scheduling tool, only call scheduling tools in that turn. If you need to
    call a general tool, only call general tools in that turn.

EXAMPLES:
- "Send Ahmed and Sara I'll be late" -> use send_message with recipient_names=["Ahmed", "Sara"]
- "Text John hello" -> use send_message with recipient_names=["John"]
- "Who are my contacts?" -> use find_contacts
- "Message everyone from today" -> first get_recent_conversations, then send_message to all
- "Send a message" -> ask: "Sure! Who would you like to message, and what should I say?"
- "Send text" -> ask: "Who would you like me to send that to?"
- "Text hello" -> ask: "Who should I send 'hello' to?"
- "Message Ahmed" -> ask: "What would you like to say to Ahmed?"
- "Summarize my chat with Ahmed" -> use summarize_conversation
- "What did Sara say yesterday?" -> use summarize_conversation with since parameter
- "What did I miss?" -> use get_daily_digest
- "Give me my morning briefing" -> use get_daily_digest
- "How's the mood with Sara?" -> use analyze_sentiment
- "Are things weird with Ahmed?" -> use analyze_sentiment
- "Schedule a message to John at 5pm saying I'm running late" -> use schedule_message
- "Show my scheduled messages" -> use list_scheduled_messages
- "Cancel scheduled message abc-123" -> use cancel_scheduled_message
- "asdfghjkl" -> respond with "I didn't quite understand that..." (see rule 23)
- "What's the weather?" -> respond with "I can only help with messaging..." (see rule 22)
"""

# --- Tool groups ---

# General tools — messaging, search, analytics
general_tools = [
    send_message,
    find_contacts,
    get_recent_conversations,
    summarize_conversation,
    get_daily_digest,
    analyze_sentiment,
]

# Scheduling tools — separate node for routing
scheduling_tools = [
    schedule_message,
    list_scheduled_messages,
    cancel_scheduled_message,
]

# The LLM sees ALL tools so it can decide which to call
all_tools = general_tools + scheduling_tools

SCHEDULING_TOOL_NAMES = {t.name for t in scheduling_tools}


def _get_model():
    """Create the LLM instance lazily (so API key is only needed at runtime)."""
    return ChatOpenAI(model="gpt-4o-mini", temperature=0.1).bind_tools(all_tools)


# --- Node functions ---


CONFIRM_ONLY_INSTRUCTION = """

IMPORTANT: This is a PREVIEW request. Do NOT use the send_message tool.
Instead, use find_contacts to look up any recipients mentioned by the user.
Then respond with ONLY a JSON block in this exact format (no other text):
{"action": "send_message", "recipients": [{"name": "actual_username", "id": "user_uuid"}], "message": "the message to send"}

If you cannot find a recipient, still include them with "id": null.
If the user's command is not about sending a message (e.g. finding contacts, recent chats), proceed normally.
If the input is missing a recipient, missing message content, is gibberish, or is outside your
capabilities, respond with a plain text follow-up question or explanation — do NOT output a JSON block."""


def agent_node(state: AgentState) -> dict:
    """The main agent node - decides what to do based on the conversation."""
    model = _get_model()

    # Build system prompt — append confirm_only instruction when in preview mode
    confirm_instruction = CONFIRM_ONLY_INSTRUCTION if state.get("confirm_only", False) else ""

    # Inject user_id context into the system message
    system_message = {
        "role": "system",
        "content": f"{SYSTEM_PROMPT}{confirm_instruction}\n\nCurrent user's ID (sender_id): {state['user_id']}",
    }

    # Call the LLM with tools
    response = model.invoke([system_message] + state["messages"])

    return {"messages": [response]}


def should_continue(state: AgentState) -> str:
    """Determine the next step after the agent responds.

    Routes to the appropriate tool node based on which tools the LLM called,
    or ends the conversation turn if no tools were called.
    """
    last_message = state["messages"][-1]

    if hasattr(last_message, "tool_calls") and last_message.tool_calls:
        # Check if any of the called tools are scheduling tools
        called_names = {tc["name"] for tc in last_message.tool_calls}
        if called_names & SCHEDULING_TOOL_NAMES:
            return "scheduling_tools"
        return "general_tools"

    return END


# --- Build the graph ---

general_tool_node = ToolNode(general_tools)
scheduling_tool_node = ToolNode(scheduling_tools)

workflow = StateGraph(AgentState)

# Add nodes
workflow.add_node("agent", agent_node)
workflow.add_node("general_tools", general_tool_node)
workflow.add_node("scheduling_tools", scheduling_tool_node)

# Set entry point
workflow.set_entry_point("agent")

# Add edges
workflow.add_conditional_edges(
    "agent",
    should_continue,
    {
        "general_tools": "general_tools",
        "scheduling_tools": "scheduling_tools",
        END: END,
    },
)
workflow.add_edge("general_tools", "agent")
workflow.add_edge("scheduling_tools", "agent")

# Compile the graph (LangGraph Platform handles persistence automatically)
graph = workflow.compile()
