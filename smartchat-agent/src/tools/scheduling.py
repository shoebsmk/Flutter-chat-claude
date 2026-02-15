"""Scheduling tools for the SmartChat LangGraph agent.

Allows users to schedule messages for future delivery,
list pending scheduled messages, and cancel them.

Persistence: Supabase `scheduled_messages` table (replaces APScheduler).
Execution: A Supabase Edge Function runs on a cron schedule to send due messages.
"""

from datetime import datetime, timezone

from dateutil import parser as dateutil_parser
from langchain_core.tools import tool
from pydantic import BaseModel, Field

from src.tools.supabase_client import get_supabase_client


# --- Schemas ---


class ScheduleMessageInput(BaseModel):
    """Input for scheduling a message for future delivery."""

    sender_id: str = Field(description="The authenticated user's ID (UUID)")
    recipient_names: list[str] = Field(
        description="List of recipient display names to send the message to"
    )
    message: str = Field(description="The message content to send")
    send_at: str = Field(
        description=(
            "ISO 8601 datetime string for when to send "
            "(e.g. '2024-03-15T17:00:00Z'). "
            "Parse natural language times into this format."
        ),
    )


class ListScheduledMessagesInput(BaseModel):
    """Input for listing scheduled messages."""

    sender_id: str = Field(description="The authenticated user's ID (UUID)")


class CancelScheduledMessageInput(BaseModel):
    """Input for cancelling a scheduled message."""

    job_id: str = Field(
        description="The UUID of the scheduled message to cancel"
    )


# --- Tools ---


@tool(args_schema=ScheduleMessageInput)
def schedule_message(
    sender_id: str,
    recipient_names: list[str],
    message: str,
    send_at: str,
) -> dict:
    """Schedule a message to be sent at a future time.

    Use this when the user says "schedule", "send later", "send at 5pm",
    "remind me to text", or specifies a future delivery time.
    Examples: "Schedule a message to Ahmed at 5pm saying meeting is moved",
    "Send Sara happy birthday tomorrow at 9am"
    """
    # Parse the scheduled time
    try:
        send_time = dateutil_parser.isoparse(send_at)
    except (ValueError, TypeError):
        return {
            "status": "error",
            "error": f"Could not parse time: {send_at}. Please use ISO 8601 format.",
        }

    # Ensure timezone-aware
    if send_time.tzinfo is None:
        send_time = send_time.replace(tzinfo=timezone.utc)

    # Must be in the future
    if send_time <= datetime.now(timezone.utc):
        return {
            "status": "error",
            "error": "Scheduled time must be in the future.",
        }

    client = get_supabase_client()

    try:
        result = (
            client.table("scheduled_messages")
            .insert(
                {
                    "sender_id": sender_id,
                    "recipient_names": recipient_names,
                    "message": message,
                    "send_at": send_time.isoformat(),
                    "status": "pending",
                }
            )
            .execute()
        )

        row = result.data[0] if result.data else {}

        return {
            "status": "scheduled",
            "job_id": row.get("id", "unknown"),
            "recipients": recipient_names,
            "message": message,
            "send_at": send_time.isoformat(),
            "summary": (
                f"Message to {', '.join(recipient_names)} scheduled for "
                f"{send_time.strftime('%Y-%m-%d %H:%M %Z')}."
            ),
        }
    except Exception as e:
        return {
            "status": "error",
            "error": f"Failed to schedule message: {str(e)}",
        }


@tool(args_schema=ListScheduledMessagesInput)
def list_scheduled_messages(sender_id: str) -> dict:
    """List all pending scheduled messages for the user.

    Use this when the user asks to see their scheduled messages,
    pending messages, or what's queued for sending.
    """
    client = get_supabase_client()

    try:
        result = (
            client.table("scheduled_messages")
            .select("id, recipient_names, message, send_at, status, created_at")
            .eq("sender_id", sender_id)
            .eq("status", "pending")
            .order("send_at")
            .execute()
        )

        scheduled = []
        for row in result.data or []:
            scheduled.append(
                {
                    "job_id": row["id"],
                    "recipients": row["recipient_names"],
                    "message": row["message"],
                    "send_at": row["send_at"],
                    "created_at": row["created_at"],
                }
            )

        return {
            "sender_id": sender_id,
            "pending_count": len(scheduled),
            "scheduled_messages": scheduled,
        }
    except Exception as e:
        return {
            "status": "error",
            "error": f"Failed to list scheduled messages: {str(e)}",
        }


@tool(args_schema=CancelScheduledMessageInput)
def cancel_scheduled_message(job_id: str) -> dict:
    """Cancel a previously scheduled message by its ID.

    Use this when the user asks to cancel or remove a scheduled message.
    The job_id comes from list_scheduled_messages or schedule_message output.
    """
    client = get_supabase_client()

    try:
        # Only cancel if still pending
        result = (
            client.table("scheduled_messages")
            .update({"status": "cancelled"})
            .eq("id", job_id)
            .eq("status", "pending")
            .execute()
        )

        if result.data:
            return {"status": "cancelled", "job_id": job_id}
        else:
            return {
                "status": "error",
                "error": (
                    f"Could not cancel message {job_id}. "
                    "It may have already been sent or cancelled."
                ),
            }
    except Exception as e:
        return {
            "status": "error",
            "error": f"Could not cancel message {job_id}: {str(e)}",
        }
