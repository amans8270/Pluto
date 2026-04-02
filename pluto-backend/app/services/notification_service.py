"""
FCM (Firebase Cloud Messaging) — Push notification sender.
Called by services after creating a Notification DB record.
"""
import json
import asyncio
from typing import Optional

import firebase_admin.messaging as fcm_messaging
import structlog

logger = structlog.get_logger(__name__)


async def send_push(
    fcm_token: str,
    title: str,
    body: str,
    data: Optional[dict] = None,
    image_url: Optional[str] = None,
) -> bool:
    """
    Send a push notification via FCM.
    Returns True if sent successfully, False otherwise.
    """
    try:
        message = fcm_messaging.Message(
            notification=fcm_messaging.Notification(
                title=title,
                body=body,
                image=image_url,
            ),
            data={k: str(v) for k, v in (data or {}).items()},
            token=fcm_token,
            android=fcm_messaging.AndroidConfig(
                priority="high",
                notification=fcm_messaging.AndroidNotification(
                    icon="ic_notification",
                    color="#FF4D6D",
                    channel_id="pluto_main",
                    click_action="FLUTTER_NOTIFICATION_CLICK",
                ),
            ),
            apns=fcm_messaging.APNSConfig(
                payload=fcm_messaging.APNSPayload(
                    aps=fcm_messaging.Aps(
                        badge=1,
                        sound="default",
                        content_available=True,
                    )
                )
            ),
        )

        # Fire in a thread since firebase-admin is sync
        loop = asyncio.get_event_loop()
        response = await loop.run_in_executor(
            None,
            lambda: fcm_messaging.send(message)
        )
        logger.info("FCM sent", message_id=response, title=title)
        return True

    except fcm_messaging.UnregisteredError:
        logger.warning("FCM token unregistered", token=fcm_token[:20])
        return False
    except Exception as e:
        logger.error("FCM send failed", error=str(e))
        return False


async def send_match_notification(recipient_fcm_token: str, match_mode: str) -> bool:
    emoji = {"DATE": "❤️", "TRAVELBUDDY": "✈️", "BFF": "🤝"}.get(match_mode, "🎉")
    return await send_push(
        fcm_token=recipient_fcm_token,
        title=f"{emoji} New Match!",
        body=f"You matched in {match_mode} mode. Start a conversation!",
        data={"type": "MATCH", "mode": match_mode},
    )


async def send_message_notification(
    recipient_fcm_token: str, sender_name: str, message_preview: str, chat_id: str
) -> bool:
    return await send_push(
        fcm_token=recipient_fcm_token,
        title=f"💬 {sender_name}",
        body=message_preview[:80],
        data={"type": "MESSAGE", "chat_id": chat_id},
    )


async def send_trip_join_notification(
    creator_fcm_token: str, joiner_name: str, trip_title: str, trip_id: str
) -> bool:
    return await send_push(
        fcm_token=creator_fcm_token,
        title="🧳 New Trip Member!",
        body=f"{joiner_name} joined your trip: {trip_title}",
        data={"type": "TRIP_JOIN", "trip_id": trip_id},
    )
