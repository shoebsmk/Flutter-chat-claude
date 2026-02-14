"""State definition for the SmartChat LangGraph agent."""

from typing import Annotated

from langgraph.graph import MessagesState


class AgentState(MessagesState):
    """State for the SmartChat agent.

    Extends MessagesState which provides a `messages` list
    with add-only semantics (messages are appended, never replaced).

    Additional fields:
    - user_id: The authenticated user's Supabase UUID (passed from Flutter)
    """

    user_id: str
