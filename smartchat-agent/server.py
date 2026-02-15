"""FastAPI server for the SmartChat LangGraph agent.

Exposes the agent as a REST API that the Flutter app can call.
Deployed to Google Cloud Run (free tier).
"""

import json
import os
import re
import uuid
from contextlib import asynccontextmanager

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from langchain_core.messages import HumanMessage
from langgraph.checkpoint.memory import MemorySaver
from pydantic import BaseModel

load_dotenv()

from src.agent.graph import workflow

# Compile with in-memory checkpointer for thread persistence
memory = MemorySaver()
agent = workflow.compile(checkpointer=memory)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Start scheduler on startup, shut it down on shutdown."""
    from src.scheduler import get_scheduler

    scheduler = get_scheduler()
    scheduler.start()
    print("[server] Scheduler started")
    yield
    scheduler.shutdown(wait=False)
    print("[server] Scheduler stopped")


app = FastAPI(title="SmartChat Agent", version="0.1.0", lifespan=lifespan)

# Allow Flutter web app to call this API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


class AgentRequest(BaseModel):
    """Request body for the agent endpoint."""

    message: str
    user_id: str
    thread_id: str | None = None
    confirm_only: bool = False  # Preview mode: extract intent without sending
    execute: bool = False  # Execute after user confirmation


class AgentResponse(BaseModel):
    """Response from the agent."""

    response: str
    thread_id: str
    tool_results: list[dict] | None = None
    pending_action: dict | None = None  # What the agent wants to do (for confirmation)


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/agent", response_model=AgentResponse)
async def run_agent(req: AgentRequest):
    """Run the SmartChat agent with a user message."""
    if not req.message.strip():
        raise HTTPException(status_code=400, detail="Message cannot be empty")

    thread_id = req.thread_id or str(uuid.uuid4())
    config = {"configurable": {"thread_id": thread_id}}

    try:
        # Determine the message to send
        actual_message = req.message
        if req.execute and req.thread_id:
            # User confirmed — tell agent to proceed with the same thread context
            actual_message = "Yes, send the message as planned."

        result = agent.invoke(
            {
                "messages": [HumanMessage(content=actual_message)],
                "user_id": req.user_id,
                "confirm_only": req.confirm_only,
            },
            config=config,
        )

        # Extract the final AI response and any tool results
        ai_response = ""
        tool_results = []

        for msg in result["messages"]:
            if msg.type == "ai" and msg.content:
                ai_response = msg.content
            elif msg.type == "tool":
                try:
                    tool_results.append(json.loads(msg.content))
                except (json.JSONDecodeError, TypeError):
                    tool_results.append({"raw": str(msg.content)})

        # In confirm_only mode, try to extract the pending action from AI response
        pending_action = None
        if req.confirm_only:
            pending_action = _extract_pending_action(ai_response)

        return AgentResponse(
            response=ai_response if not pending_action else "Ready to send.",
            thread_id=thread_id,
            tool_results=tool_results if tool_results else None,
            pending_action=pending_action,
        )

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


def _extract_pending_action(ai_response: str) -> dict | None:
    """Parse a JSON action block from the AI's confirm_only response."""
    try:
        # Try to find a JSON object with "action" key
        json_match = re.search(
            r'\{[^{}]*"action"[^{}]*\}', ai_response, re.DOTALL
        )
        if json_match:
            parsed = json.loads(json_match.group())
            if parsed.get("action") == "send_message":
                return parsed
    except (json.JSONDecodeError, AttributeError):
        pass
    return None


if __name__ == "__main__":
    import uvicorn

    port = int(os.environ.get("PORT", 8080))
    uvicorn.run(app, host="0.0.0.0", port=port)
