"""Messaging tools for the SmartChat LangGraph agent.

These tools interact with Supabase to send messages,
find contacts, and retrieve conversation history.
"""

from typing import Annotated

from langchain_core.tools import tool
from pydantic import BaseModel, Field

from src.tools.supabase_client import get_supabase_client


# --- Schemas for structured tool inputs ---


class SendMessageInput(BaseModel):
    """Input for sending a message to one or more recipients."""

    sender_id: str = Field(description="The authenticated user's ID (UUID)")
    recipient_names: list[str] = Field(
        description="List of recipient display names to send the message to"
    )
    message: str = Field(description="The message content to send")


class FindContactsInput(BaseModel):
    """Input for finding contacts by name."""

    query: str = Field(
        description="Name or partial name to search for (case-insensitive)"
    )


class GetRecentConversationsInput(BaseModel):
    """Input for getting recent conversations."""

    user_id: str = Field(description="The authenticated user's ID (UUID)")
    limit: int = Field(default=10, description="Max number of conversations to return")


# --- Tool implementations ---


@tool(args_schema=SendMessageInput)
def send_message(
    sender_id: str,
    recipient_names: list[str],
    message: str,
) -> dict:
    """Send a message to one or more people by their display name.

    Use this when the user wants to text/message someone.
    Examples: "Send Ahmed and Sara that I'll be late",
              "Text John hello", "Message everyone I'm on my way"
    """
    client = get_supabase_client()
    results = []

    for name in recipient_names:
        # Look up user by display name (case-insensitive partial match)
        search = name.strip().lower()
        users_response = (
            client.table("users")
            .select("id, username")
            .ilike("username", f"%{search}%")
            .execute()
        )

        if not users_response.data:
            results.append(
                {
                    "recipient": name,
                    "status": "not_found",
                    "error": f"No user found matching '{name}'",
                }
            )
            continue

        # Use the best match (exact first, then first partial)
        matched_user = None
        for user in users_response.data:
            if user["username"].lower() == search:
                matched_user = user
                break
        if matched_user is None:
            matched_user = users_response.data[0]

        # Send the message
        try:
            msg_response = (
                client.table("messages")
                .insert(
                    {
                        "sender_id": sender_id,
                        "receiver_id": matched_user["id"],
                        "content": message,
                        "is_read": False,
                        "message_type": "text",
                    }
                )
                .execute()
            )

            results.append(
                {
                    "recipient": matched_user["username"],
                    "status": "sent",
                    "message_id": msg_response.data[0]["id"]
                    if msg_response.data
                    else None,
                }
            )
        except Exception as e:
            results.append(
                {
                    "recipient": matched_user["username"],
                    "status": "failed",
                    "error": str(e),
                }
            )

    sent_count = sum(1 for r in results if r["status"] == "sent")
    failed = [r for r in results if r["status"] != "sent"]

    return {
        "total_recipients": len(recipient_names),
        "sent_count": sent_count,
        "results": results,
        "summary": f"Message sent to {sent_count}/{len(recipient_names)} recipients.",
        "failures": failed if failed else None,
    }


@tool(args_schema=FindContactsInput)
def find_contacts(query: str) -> dict:
    """Search for contacts/users by name.

    Use this when the user asks "who are my contacts",
    "find someone named...", or when you need to look up a user
    before sending a message.
    """
    client = get_supabase_client()

    response = (
        client.table("users")
        .select("id, username, avatar_url, bio, last_seen")
        .ilike("username", f"%{query.strip()}%")
        .limit(10)
        .execute()
    )

    contacts = []
    for user in response.data or []:
        contacts.append(
            {
                "id": user["id"],
                "username": user["username"],
                "avatar_url": user.get("avatar_url", ""),
                "bio": user.get("bio", ""),
            }
        )

    return {
        "query": query,
        "count": len(contacts),
        "contacts": contacts,
    }


@tool(args_schema=GetRecentConversationsInput)
def get_recent_conversations(user_id: str, limit: int = 10) -> dict:
    """Get a user's recent conversations with other people.

    Use this when the user asks "who did I talk to recently",
    "show my recent chats", or "message everyone I talked to today".
    """
    client = get_supabase_client()

    # Get recent messages involving this user
    response = (
        client.table("messages")
        .select("id, sender_id, receiver_id, content, created_at, is_read")
        .or_(f"sender_id.eq.{user_id},receiver_id.eq.{user_id}")
        .is_("deleted_at", "null")
        .order("created_at", desc=True)
        .limit(100)
        .execute()
    )

    # Extract unique conversation partners
    conversations: dict[str, dict] = {}
    for msg in response.data or []:
        other_id = (
            msg["receiver_id"]
            if msg["sender_id"] == user_id
            else msg["sender_id"]
        )

        if other_id not in conversations:
            conversations[other_id] = {
                "user_id": other_id,
                "last_message": msg["content"],
                "last_message_time": msg["created_at"],
                "is_from_me": msg["sender_id"] == user_id,
                "unread_count": 0,
            }

        # Count unread messages sent TO the current user
        if msg["receiver_id"] == user_id and not msg["is_read"]:
            conversations[other_id]["unread_count"] += 1

    # Resolve usernames for conversation partners
    partner_ids = list(conversations.keys())[:limit]
    if partner_ids:
        users_response = (
            client.table("users")
            .select("id, username")
            .in_("id", partner_ids)
            .execute()
        )

        username_map = {u["id"]: u["username"] for u in (users_response.data or [])}

        for uid in partner_ids:
            conversations[uid]["username"] = username_map.get(uid, "Unknown")

    result = [conversations[uid] for uid in partner_ids]

    return {
        "user_id": user_id,
        "conversation_count": len(result),
        "conversations": result,
    }
