"""Summarization tool for the SmartChat LangGraph agent.

Fetches conversation history between the user and a contact,
returning raw messages for the LLM to summarize naturally.
"""

from langchain_core.tools import tool
from pydantic import BaseModel, Field

from src.tools.supabase_client import get_supabase_client


# --- Schema ---


class SummarizeConversationInput(BaseModel):
    """Input for summarizing a conversation with a contact."""

    user_id: str = Field(description="The authenticated user's ID (UUID)")
    contact_name: str = Field(
        description="The display name of the contact to summarize conversations with"
    )
    since: str | None = Field(
        default=None,
        description=(
            "Optional ISO 8601 timestamp to limit how far back to summarize "
            "(e.g. '2024-01-15T00:00:00Z'). If omitted, returns the last 50 messages."
        ),
    )


# --- Tool ---


@tool(args_schema=SummarizeConversationInput)
def summarize_conversation(
    user_id: str,
    contact_name: str,
    since: str | None = None,
) -> dict:
    """Summarize a conversation between the user and a contact.

    Use this when the user asks to summarize, recap, or review a chat
    with someone. Examples: "Summarize my chat with Ahmed",
    "What did Sara say yesterday?", "Recap my conversation with John"
    """
    client = get_supabase_client()

    # --- Resolve contact by name ---
    search = contact_name.strip().lower()
    users_response = (
        client.table("users")
        .select("id, username")
        .ilike("username", f"%{search}%")
        .execute()
    )

    if not users_response.data:
        return {
            "error": f"No user found matching '{contact_name}'",
            "status": "not_found",
        }

    # Prefer exact match, fall back to first partial
    matched_user = None
    for user in users_response.data:
        if user["username"].lower() == search:
            matched_user = user
            break
    if matched_user is None:
        matched_user = users_response.data[0]

    contact_id = matched_user["id"]

    # --- Fetch messages between user and contact ---
    query = (
        client.table("messages")
        .select("id, sender_id, receiver_id, content, created_at")
        .or_(
            f"and(sender_id.eq.{user_id},receiver_id.eq.{contact_id}),"
            f"and(sender_id.eq.{contact_id},receiver_id.eq.{user_id})"
        )
        .is_("deleted_at", "null")
    )

    if since:
        query = query.gte("created_at", since)

    query = query.order("created_at", desc=False).limit(50)

    try:
        response = query.execute()
    except Exception as e:
        return {"error": f"Failed to fetch messages: {str(e)}", "status": "error"}

    messages = response.data or []

    if not messages:
        return {
            "contact_name": matched_user["username"],
            "message_count": 0,
            "messages": [],
            "summary_hint": "No messages found between you and this contact.",
        }

    return {
        "contact_name": matched_user["username"],
        "contact_id": contact_id,
        "message_count": len(messages),
        "time_range": {
            "earliest": messages[0]["created_at"],
            "latest": messages[-1]["created_at"],
        },
        "messages": [
            {
                "from": "You" if msg["sender_id"] == user_id else matched_user["username"],
                "content": msg["content"],
                "time": msg["created_at"],
            }
            for msg in messages
        ],
    }
