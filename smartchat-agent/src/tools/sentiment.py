"""Sentiment analysis tool for the SmartChat LangGraph agent.

Fetches conversation messages and runs a nested LLM call to
analyze the sentiment/mood of the conversation.
"""

import json

from langchain_core.tools import tool
from langchain_openai import ChatOpenAI
from pydantic import BaseModel, Field

from src.tools.supabase_client import get_supabase_client


# --- Schema ---


class AnalyzeSentimentInput(BaseModel):
    """Input for analyzing conversation sentiment."""

    user_id: str = Field(description="The authenticated user's ID (UUID)")
    contact_name: str = Field(
        description="The display name of the contact to analyze sentiment for"
    )
    message_count: int = Field(
        default=20,
        description="Number of recent messages to analyze (default 20, max 50)",
    )


# --- Nested LLM call ---


def _analyze_batch_sentiment(messages: list[dict]) -> dict:
    """Run a single LLM call to classify sentiment of all messages."""
    llm = ChatOpenAI(model="gpt-4o-mini", temperature=0)

    formatted = "\n".join(
        f"[{m['time']}] {m['from']}: {m['content']}" for m in messages
    )

    prompt = f"""Analyze the sentiment of this conversation. Return ONLY valid JSON with no extra text:
{{
  "overall_mood": "positive" | "negative" | "neutral" | "mixed",
  "score": <float from -1.0 (very negative) to 1.0 (very positive)>,
  "trend": "improving" | "declining" | "stable",
  "message_sentiments": [
    {{"index": 0, "sentiment": "positive" | "negative" | "neutral", "score": <float -1.0 to 1.0>}},
    ...one entry per message in order...
  ]
}}

Conversation ({len(messages)} messages):
{formatted}"""

    response = llm.invoke(prompt)

    # Parse JSON from response
    content = response.content.strip()
    # Strip markdown code fences if present
    if content.startswith("```"):
        content = content.split("\n", 1)[1] if "\n" in content else content[3:]
        if content.endswith("```"):
            content = content[:-3]
        content = content.strip()

    return json.loads(content)


# --- Tool ---


@tool(args_schema=AnalyzeSentimentInput)
def analyze_sentiment(
    user_id: str,
    contact_name: str,
    message_count: int = 20,
) -> dict:
    """Analyze the sentiment and mood of a conversation with a contact.

    Use this when the user asks about the mood, vibe, sentiment, or tone
    of a conversation. Examples: "How's my vibe with Sara?",
    "Are things weird with Ahmed?", "What's the mood of my chat with John?"
    """
    client = get_supabase_client()

    # Cap message count
    message_count = min(max(message_count, 5), 50)

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

    matched_user = None
    for user in users_response.data:
        if user["username"].lower() == search:
            matched_user = user
            break
    if matched_user is None:
        matched_user = users_response.data[0]

    contact_id = matched_user["id"]

    # --- Fetch messages ---
    try:
        response = (
            client.table("messages")
            .select("id, sender_id, receiver_id, content, created_at")
            .or_(
                f"and(sender_id.eq.{user_id},receiver_id.eq.{contact_id}),"
                f"and(sender_id.eq.{contact_id},receiver_id.eq.{user_id})"
            )
            .is_("deleted_at", "null")
            .order("created_at", desc=True)
            .limit(message_count)
            .execute()
        )
    except Exception as e:
        return {"error": f"Failed to fetch messages: {str(e)}", "status": "error"}

    raw_messages = response.data or []

    if not raw_messages:
        return {
            "contact_name": matched_user["username"],
            "message_count": 0,
            "error": "No messages found to analyze.",
        }

    # Reverse to chronological order for analysis
    raw_messages.reverse()

    messages = [
        {
            "from": "You" if msg["sender_id"] == user_id else matched_user["username"],
            "content": msg["content"],
            "time": msg["created_at"],
        }
        for msg in raw_messages
    ]

    # --- Run nested LLM sentiment analysis ---
    try:
        analysis = _analyze_batch_sentiment(messages)
    except Exception as e:
        return {
            "contact_name": matched_user["username"],
            "message_count": len(messages),
            "error": f"Sentiment analysis failed: {str(e)}",
        }

    # Build chart data for Flutter rendering
    data_points = []
    for i, sent in enumerate(analysis.get("message_sentiments", [])):
        if i < len(messages):
            data_points.append(
                {
                    "index": i,
                    "score": sent.get("score", 0),
                    "label": messages[i]["from"],
                }
            )

    chart_data = {
        "contact_name": matched_user["username"],
        "overall_mood": analysis.get("overall_mood", "neutral"),
        "score": analysis.get("score", 0),
        "trend": analysis.get("trend", "stable"),
        "data_points": data_points,
    }

    return {
        "contact_name": matched_user["username"],
        "message_count": len(messages),
        "analysis": analysis,
        "__SENTIMENT_CHART__": json.dumps(chart_data),
    }
