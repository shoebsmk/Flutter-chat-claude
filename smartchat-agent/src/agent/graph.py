"""SmartChat LangGraph agent - main graph definition.

This agent handles natural language commands for the SmartChat app:
- Send messages to multiple people
- Find contacts
- Get recent conversations
- Human-in-the-loop confirmation before sending messages
"""

from langchain_openai import ChatOpenAI
from langgraph.graph import StateGraph, END
from langgraph.prebuilt import ToolNode
from src.agent.state import AgentState
from src.tools.messaging import send_message, find_contacts, get_recent_conversations

# --- Configuration ---

SYSTEM_PROMPT = """You are SmartChat Assistant, an AI helper for a messaging app.

You can ONLY help with three things:
1. Sending messages to contacts
2. Finding/searching for contacts
3. Viewing recent conversations

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

SCOPE & GUARDRAILS:
12. If the user asks about something outside your capabilities (weather, math, trivia,
    coding, general knowledge, etc.), politely say:
    "I can only help with messaging — sending messages, finding contacts, or checking
    recent conversations. How can I help with that?"
13. If the input is gibberish, random characters, or makes no sense, respond:
    "I didn't quite understand that. I can help you send messages, find contacts,
    or check your recent conversations. What would you like to do?"
14. Do NOT send a message from the user to themselves. If detected, let them know.
15. Refuse to send messages containing threats, harassment, or abuse. Politely decline
    and suggest rephrasing.

EXAMPLES:
- "Send Ahmed and Sara I'll be late" -> use send_message with recipient_names=["Ahmed", "Sara"]
- "Text John hello" -> use send_message with recipient_names=["John"]
- "Who are my contacts?" -> use find_contacts
- "Message everyone from today" -> first get_recent_conversations, then send_message to all
- "Send a message" -> ask: "Sure! Who would you like to message, and what should I say?"
- "Send text" -> ask: "Who would you like me to send that to?"
- "Text hello" -> ask: "Who should I send 'hello' to?"
- "Message Ahmed" -> ask: "What would you like to say to Ahmed?"
- "asdfghjkl" -> respond with "I didn't quite understand that..." (see rule 13)
- "What's the weather?" -> respond with "I can only help with messaging..." (see rule 12)
"""

# Tools available to the agent
tools = [send_message, find_contacts, get_recent_conversations]


def _get_model():
    """Create the LLM instance lazily (so API key is only needed at runtime)."""
    return ChatOpenAI(model="gpt-4o-mini", temperature=0.1).bind_tools(tools)


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

    If the agent called a tool, route to the tool node.
    Otherwise, end the conversation turn.
    """
    last_message = state["messages"][-1]

    # If the LLM made tool calls, execute them
    if hasattr(last_message, "tool_calls") and last_message.tool_calls:
        return "tools"

    # Otherwise, we're done
    return END


# --- Build the graph ---

# Create the tool node
tool_node = ToolNode(tools)

# Build the state graph
workflow = StateGraph(AgentState)

# Add nodes
workflow.add_node("agent", agent_node)
workflow.add_node("tools", tool_node)

# Set entry point
workflow.set_entry_point("agent")

# Add edges
workflow.add_conditional_edges("agent", should_continue, {"tools": "tools", END: END})
workflow.add_edge("tools", "agent")  # After tool execution, go back to agent

# Compile the graph (LangGraph Platform handles persistence automatically)
graph = workflow.compile()
