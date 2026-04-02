"""
WebSocket Connection Manager + Router.

Security: Verifies user_id in URL matches the token's user_id.
"""

import json
import uuid
import asyncio
from typing import Dict

from fastapi import (
    APIRouter,
    Depends,
    WebSocket,
    WebSocketDisconnect,
    Query,
    HTTPException,
)
from starlette.websockets import WebSocketState
import structlog

from app.core.auth import verify_auth_token
from app.services.chat_service import ChatService
from app.core.database import get_db
from sqlalchemy import select
from app.models.user import User

router = APIRouter()
logger = structlog.get_logger(__name__)


class ConnectionManager:
    """Manages active WebSocket connections for this instance."""

    def __init__(self):
        # user_id -> list of WebSocket connections (same user on multiple devices)
        self._connections: Dict[str, list[WebSocket]] = {}

    async def connect(self, user_id: str, ws: WebSocket) -> None:
        await ws.accept()
        if user_id not in self._connections:
            self._connections[user_id] = []
        self._connections[user_id].append(ws)
        logger.info("WS connected", user_id=user_id, total=len(self._connections))

    def disconnect(self, user_id: str, ws: WebSocket) -> None:
        if user_id in self._connections:
            self._connections[user_id] = [
                c for c in self._connections[user_id] if c != ws
            ]
            if not self._connections[user_id]:
                self._connections.pop(user_id, None)
        logger.info("WS disconnected", user_id=user_id)

    async def send_to_user(self, user_id: str, payload: dict) -> None:
        """Send a dict payload to all connections of a specific user."""
        conns = self._connections.get(user_id, [])
        for ws in conns:
            if ws.client_state == WebSocketState.CONNECTED:
                try:
                    await ws.send_json(payload)
                except Exception as e:
                    logger.warning("WS send failed", user_id=user_id, error=str(e))

    def is_online(self, user_id: str) -> bool:
        return user_id in self._connections and len(self._connections[user_id]) > 0


manager = ConnectionManager()


async def _authenticate_ws(token: str, expected_user_id: str) -> str:
    """
    Verify an auth token AND validate it matches the user_id in the URL.
    Returns the external auth UID on success.
    """
    try:
        claims = await verify_auth_token(token)
        auth_uid = claims["sub"]

        # SECURITY: Verify user_id in URL matches token
        async with get_db() as db:
            result = await db.execute(
                select(User.id).where(User.supabase_uid == auth_uid)
            )
            db_user_id = result.scalar_one_or_none()

            if not db_user_id or str(db_user_id) != expected_user_id:
                raise HTTPException(status_code=4003, reason="User ID mismatch")

        return auth_uid
    except HTTPException:
        raise
    except Exception as e:
        logger.warning("WS auth failed", error=str(e))
        raise HTTPException(status_code=4001, reason="Invalid token")


@router.websocket("/{user_id}")
async def websocket_endpoint(
    websocket: WebSocket,
    user_id: str,
    token: str = Query(..., description="Auth provider ID token"),
):
    """
    Main WebSocket endpoint.
    Client connects to: wss://api.pluto.app/ws/{user_id}?token=<id_token>
    """
    # Authenticate AND verify user_id matches token
    try:
        await _authenticate_ws(token, user_id)
    except HTTPException as e:
        await websocket.close(code=e.status_code, reason=e.detail or "Unauthorized")
        return

    await manager.connect(user_id, websocket)

    try:
        async for ws_message in websocket.iter_json():
            msg_type = ws_message.get("type")

            if msg_type == "ping":
                await websocket.send_json({"type": "pong"})

            elif msg_type == "message":
                chat_id_str = ws_message.get("chat_id")
                content = ws_message.get("content", "")
                m_type = ws_message.get("msg_type", "TEXT")

                if not chat_id_str:
                    continue

                try:
                    chat_id = uuid.UUID(chat_id_str)
                except ValueError:
                    continue

                # Persist message
                msg = None
                participant_ids = []
                async with get_db() as db:
                    service = ChatService(db)
                    msg = await service.send_message(
                        chat_id=chat_id,
                        sender_id=uuid.UUID(user_id),
                        content=content,
                        msg_type=m_type,
                    )

                    # Get members to fan out
                    chat_obj = await service.get_chat(chat_id)
                    if chat_obj:
                        participant_ids = [
                            str(p.user_id) for p in chat_obj.participants
                        ]

                if msg:
                    # Construct outgoing payload
                    payload = {
                        "type": "message",
                        "chat_id": chat_id_str,
                        "message": {
                            "id": str(msg.id),
                            "sender_id": user_id,
                            "content": content,
                            "msg_type": m_type,
                            "created_at": msg.created_at.isoformat(),
                        },
                    }

                    # Fan-out to all participants
                    for pid in participant_ids:
                        if manager.is_online(pid):
                            asyncio.create_task(manager.send_to_user(pid, payload))

            elif msg_type == "typing":
                chat_id_str = ws_message.get("chat_id")
                if chat_id_str:
                    try:
                        chat_id = uuid.UUID(chat_id_str)
                    except ValueError:
                        continue

                    participant_ids = []
                    async with get_db() as db:
                        service = ChatService(db)
                        chat_obj = await service.get_chat(chat_id)
                        if chat_obj:
                            participant_ids = [
                                str(p.user_id) for p in chat_obj.participants
                            ]

                    typing_payload = {
                        "type": "typing",
                        "chat_id": chat_id_str,
                        "sender_id": user_id,
                    }

                    for pid in participant_ids:
                        if pid != user_id and manager.is_online(pid):
                            asyncio.create_task(
                                manager.send_to_user(pid, typing_payload)
                            )

    except WebSocketDisconnect:
        pass
    except Exception as e:
        logger.error("WS error", error=str(e))
    finally:
        manager.disconnect(user_id, websocket)
        logger.info("WS session ended", user_id=user_id)
