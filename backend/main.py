from fastapi import FastAPI
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
import asyncio
import json

app = FastAPI()


class ChatRequest(BaseModel):
    message: str


async def event_generator(message: str):
    """Echo the message back character by character, simulating LLM streaming."""
    response = f"你说的是：{message}。我来逐字回复你，这也是一个测试消息。"
    for char in response:
        yield f"data: {json.dumps({'type': 'token', 'content': char}, ensure_ascii=False)}\n\n"
        await asyncio.sleep(0.05)
    yield f"data: {json.dumps({'type': 'done'})}\n\n"


@app.post("/api/chat")
async def chat(request: ChatRequest):
    return StreamingResponse(
        event_generator(request.message),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
        },
    )
