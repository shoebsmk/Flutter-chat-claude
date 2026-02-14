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

You help users send messages, find contacts, and manage their conversations.

IMPORTANT RULES:
1. When the user wants to send a message, ALWAYS use the send_message tool.
2. The user's ID is provided in the conversation context - use it as sender_id.
3. When the user mentions multiple people, send to ALL of them in a single tool call.
4. If the user says "send to everyone I talked to recently", first use get_recent_conversations,
   then use send_message with all those recipients.
5. Always confirm what you did after sending messages.
6. Be concise and friendly.
7. If you can't find a contact, let the user know and suggest they check the spelling.

EXAMPLES:
- "Send Ahmed and Sara I'll be late" -> use send_message with recipient_names=["Ahmed", "Sara"]
- "Text John hello" -> use send_message with recipient_names=["John"]
- "Who are my contacts?" -> use find_contacts
- "Message everyone from today" -> first get_recent_conversations, then send_message to all
"""

# Tools available to the agent
tools = [send_message, find_contacts, get_recent_conversations]


def _get_model():
    """Create the LLM instance lazily (so API key is only needed at runtime)."""
    return ChatOpenAI(model="gpt-4o-mini", temperature=0.1).bind_tools(tools)


# --- Node functions ---


def agent_node(state: AgentState) -> dict:
    """The main agent node - decides what to do based on the conversation."""
    model = _get_model()

    # Inject user_id context into the system message
    system_message = {
        "role": "system",
        "content": f"{SYSTEM_PROMPT}\n\nCurrent user's ID (sender_id): {state['user_id']}",
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
