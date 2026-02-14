"""Supabase client singleton for the SmartChat agent."""

import os
from supabase import create_client, Client


_client: Client | None = None


def get_supabase_client() -> Client:
    """Get or create a Supabase client instance.

    Uses the service role key for full access to the database.
    This is safe because the agent runs server-side, never in the browser.
    """
    global _client
    if _client is None:
        url = os.environ.get("SUPABASE_URL")
        key = os.environ.get("SUPABASE_SERVICE_KEY")

        if not url or not key:
            raise ValueError(
                "SUPABASE_URL and SUPABASE_SERVICE_KEY must be set. "
                "Check your .env file."
            )

        _client = create_client(url, key)

    return _client
