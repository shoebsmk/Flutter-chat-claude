"""Daily digest tool for the SmartChat LangGraph agent.

Provides a summary of recent messaging activity: unread messages,
unanswered conversations, and most active contacts.
"""

from datetime import datetime, timedelta, timezone

from langchain_core.tools import tool
from pydantic import BaseModel, Field

from src.tools.supabase_client import get_supabase_client


# --- Schema ---


class GetDailyDigestInput(BaseModel):
    """Input for getting a daily activity digest."""

    user_id: str = Field(description="The authenticated user's ID (UUID)")


# --- Tool ---


@tool(args_schema=GetDailyDigestInput)
def get_daily_digest(user_id: str) -> dict:
    """Get a daily digest of messaging activity for the user.

    Use this when the user asks for a briefing, digest, catch-up, or
    wants to know what they missed. Examples: "Give me my morning briefing",
    "What did I miss?", "Show me my daily digest"
    """
    client = get_supabase_client()
    since_24h = (datetime.now(timezone.utc) - timedelta(hours=24)).isoformat()

    # --- Query 1: Unread messages count ---
    try:
        unread_resp = (
            client.table("messages")
            .select("id, sender_id", count="exact")
            .eq("receiver_id", user_id)
            .eq("is_read", False)
            .gte("created_at", since_24h)
            .is_("deleted_at", "null")
            .execute()
        )
        unread_count = unread_resp.count or 0
    except Exception:
        unread_count = 0

    # --- Query 2: Recent messages involving user (last 24h) ---
    try:
        recent_resp = (
            client.table("messages")
            .select("id, sender_id, receiver_id, content, created_at, is_read")
            .or_(f"sender_id.eq.{user_id},receiver_id.eq.{user_id}")
            .gte("created_at", since_24h)
            .is_("deleted_at", "null")
            .order("created_at", desc=True)
            .limit(200)
            .execute()
        )
        recent_messages = recent_resp.data or []
    except Exception:
        recent_messages = []

    # --- Derive stats from messages ---
    contact_ids: set[str] = set()
    contact_msg_counts: dict[str, int] = {}
    sent_count = 0
    received_count = 0

    # Track last message per contact to find unanswered
    # contact_id -> {"last_from": "them"|"me", "last_msg": ..., "last_time": ...}
    last_per_contact: dict[str, dict] = {}

    for msg in recent_messages:
        is_from_me = msg["sender_id"] == user_id
        other_id = msg["receiver_id"] if is_from_me else msg["sender_id"]

        contact_ids.add(other_id)

        # Count messages per contact
        contact_msg_counts[other_id] = contact_msg_counts.get(other_id, 0) + 1

        if is_from_me:
            sent_count += 1
        else:
            received_count += 1

        # Track the latest message per contact (messages are desc ordered)
        if other_id not in last_per_contact:
            last_per_contact[other_id] = {
                "last_from": "me" if is_from_me else "them",
                "last_msg": msg["content"],
                "last_time": msg["created_at"],
            }

    # Unanswered = contacts whose last message was FROM them (not from me)
    unanswered_ids = [
        cid for cid, info in last_per_contact.items() if info["last_from"] == "them"
    ]

    # Most active contacts (sorted by message count, top 5)
    sorted_contacts = sorted(
        contact_msg_counts.items(), key=lambda x: x[1], reverse=True
    )[:5]

    # --- Query 3: Resolve usernames ---
    username_map: dict[str, str] = {}
    if contact_ids:
        try:
            users_resp = (
                client.table("users")
                .select("id, username")
                .in_("id", list(contact_ids))
                .execute()
            )
            username_map = {u["id"]: u["username"] for u in (users_resp.data or [])}
        except Exception:
            pass

    # Build unanswered conversations list
    unanswered_conversations = []
    for cid in unanswered_ids:
        info = last_per_contact[cid]
        unanswered_conversations.append(
            {
                "contact_name": username_map.get(cid, "Unknown"),
                "last_message": info["last_msg"][:100],  # Truncate for brevity
                "time": info["last_time"],
            }
        )

    # Build most active contacts list
    most_active = [
        {
            "contact_name": username_map.get(cid, "Unknown"),
            "message_count": count,
        }
        for cid, count in sorted_contacts
    ]

    return {
        "user_id": user_id,
        "period": "last_24_hours",
        "since": since_24h,
        "unread_count": unread_count,
        "unanswered_conversations": unanswered_conversations,
        "most_active_contacts": most_active,
        "total_messages_exchanged": len(recent_messages),
        "messages_sent": sent_count,
        "messages_received": received_count,
    }
