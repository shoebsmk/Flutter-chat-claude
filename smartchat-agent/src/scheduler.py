"""APScheduler singleton for scheduled message delivery.

Uses a SQLite job store so scheduled jobs persist across server restarts.
The scheduler runs in a background thread within the FastAPI process.
"""

import os

from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.jobstores.sqlalchemy import SQLAlchemyJobStore

_scheduler: BackgroundScheduler | None = None


def get_scheduler() -> BackgroundScheduler:
    """Get or create the APScheduler singleton.

    The SQLite job store path is read from SCHEDULER_DB_PATH env var,
    defaulting to 'data/jobs.sqlite'.
    """
    global _scheduler
    if _scheduler is None:
        db_path = os.environ.get("SCHEDULER_DB_PATH", "data/jobs.sqlite")
        # Ensure directory exists
        db_dir = os.path.dirname(db_path)
        if db_dir:
            os.makedirs(db_dir, exist_ok=True)

        jobstores = {
            "default": SQLAlchemyJobStore(url=f"sqlite:///{db_path}"),
        }
        _scheduler = BackgroundScheduler(jobstores=jobstores)
    return _scheduler


def send_scheduled_message(
    sender_id: str,
    recipient_names: list[str],
    message: str,
) -> None:
    """Callback function executed by APScheduler when a job fires.

    Runs outside the LangGraph agent loop. Directly uses the Supabase
    client to resolve recipient names and insert messages.
    """
    from src.tools.supabase_client import get_supabase_client

    client = get_supabase_client()

    for name in recipient_names:
        search = name.strip().lower()
        users_response = (
            client.table("users")
            .select("id, username")
            .ilike("username", f"%{search}%")
            .execute()
        )

        if not users_response.data:
            print(f"[scheduler] Recipient not found: {name}")
            continue

        # Prefer exact match, fall back to first partial
        matched_user = None
        for user in users_response.data:
            if user["username"].lower() == search:
                matched_user = user
                break
        if matched_user is None:
            matched_user = users_response.data[0]

        try:
            client.table("messages").insert(
                {
                    "sender_id": sender_id,
                    "receiver_id": matched_user["id"],
                    "content": message,
                    "is_read": False,
                    "message_type": "text",
                }
            ).execute()
            print(
                f"[scheduler] Sent scheduled message to {matched_user['username']}"
            )
        except Exception as e:
            print(f"[scheduler] Failed to send to {name}: {e}")
