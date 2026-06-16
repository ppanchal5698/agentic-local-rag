import asyncio
import json

from fastapi import APIRouter, HTTPException, Query, WebSocket, WebSocketDisconnect, status
from starlette.responses import StreamingResponse

from app.auth.jwt import decode_access_token

router = APIRouter(tags=["streaming"])


def _validate_ws_token(token: str | None) -> None:
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing authentication token",
        )
    try:
        decode_access_token(token)
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(exc),
        ) from exc


@router.websocket("/api/v1/stream")
async def stream_stub(websocket: WebSocket, token: str | None = Query(default=None)) -> None:
    if not token:
        await websocket.close(code=1008, reason="Missing authentication token")
        return
    try:
        decode_access_token(token)
    except ValueError:
        await websocket.close(code=1008, reason="Invalid or expired token")
        return

    await websocket.accept()
    try:
        await websocket.send_json({"type": "status", "message": "connected"})
        while True:
            await asyncio.sleep(30)
            await websocket.send_json({"type": "status", "message": "heartbeat"})
    except WebSocketDisconnect:
        return


@router.get("/api/v1/events")
async def events_stub(token: str = Query(..., description="JWT access token")) -> StreamingResponse:
    _validate_ws_token(token)

    async def event_generator():
        for _ in range(3):
            payload = json.dumps({"type": "status", "message": "connected"})
            yield f"data: {payload}\n\n"
            await asyncio.sleep(1)

    return StreamingResponse(event_generator(), media_type="text/event-stream")
