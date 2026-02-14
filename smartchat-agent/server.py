"""FastAPI server for the SmartChat LangGraph agent.

Exposes the agent as a REST API that the Flutter app can call.
Deployed to Google Cloud Run (free tier).
"""

import json
import os
import uuid

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

app = FastAPI(title="SmartChat Agent", version="0.1.0")

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


class AgentResponse(BaseModel):
    """Response from the agent."""

    response: str
    thread_id: str
    tool_results: list[dict] | None = None


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
        result = agent.invoke(
            {
                "messages": [HumanMessage(content=req.message)],
                "user_id": req.user_id,
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

        return AgentResponse(
            response=ai_response,
            thread_id=thread_id,
            tool_results=tool_results if tool_results else None,
        )

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn

    port = int(os.environ.get("PORT", 8080))
    uvicorn.run(app, host="0.0.0.0", port=port)
