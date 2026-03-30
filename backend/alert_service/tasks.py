from celery_app import celery_app
from core.db import SessionLocal
from models.alert import Alert, AlertStatus, BroadcastAlert, BroadcastAlertStatus
from services.notification_service import NotificationService
from services.rule_engine import RuleEngine
from datetime import datetime, timezone
import logging
import asyncio
import uuid
from services.metrics import inc, mark_rule_run


@celery_app.task(name="deliver_alert")
def deliver_alert_task(alert_id: str) -> None:
    logger = logging.getLogger("uvicorn")
    logger.info(f"deliver_alert_task: received task for alert_id={alert_id}")
    db = SessionLocal()
    try:
        # Fetch alert directly via ORM (CRUD module removed)
        alert = db.query(Alert).filter(Alert.id == alert_id).first()
        if not alert:
            logger.error(f"deliver_alert_task: alert not found id={alert_id}")
            return
        logger.info(f"deliver_alert_task: processing alert {alert_id} for user {alert.user_id}, type={alert.type}")
        service = NotificationService(db)
        try:
            inc("deliveries_attempted")
            asyncio.run(service.send_alert(alert))
            alert.status = AlertStatus.DELIVERED
            alert.delivered_at = datetime.utcnow()
            inc("deliveries_succeeded")
        except Exception as exc:
            logger.error(f"deliver_alert_task: delivery failed for {alert_id}: {exc}")
            alert.status = AlertStatus.FAILED
            alert.error_message = str(exc)
            inc("deliveries_failed")
        finally:
            db.commit()
    finally:
        db.close()


@celery_app.task(name="run_rule_check")
def run_rule_check(rule_key: str) -> None:
    logger = logging.getLogger("uvicorn")
    db = SessionLocal()
    try:
        logger.info(f"run_rule_check: start rule={rule_key}")
        engine = RuleEngine(db)
        if rule_key == "insurance_expiry":
            asyncio.run(engine.check_insurance_expiry())
        elif rule_key == "service_due":
            asyncio.run(engine.check_service_due())
        else:
            logger.error(f"run_rule_check: unknown rule key '{rule_key}'")
            return
        mark_rule_run(rule_key)
        logger.info(f"run_rule_check: completed rule={rule_key}")
    finally:
        db.close()


# ─────────────────────────────────────────────────────────────────────────────
# Broadcast fan-out — chunked, scalable design
#
# Architecture:
#   broadcast_alert_fanout  (master, runs once)
#     ├── sends FCM topic push immediately  →  reaches ALL subscribed devices
#     │   in ONE API call regardless of user count
#     └── splits user IDs into chunks of FANOUT_CHUNK_SIZE
#         └── enqueues fanout_chunk per chunk  (parallel across workers)
#               └── creates Alert DB records (in_app + sms/email)
#                   └── enqueues deliver_alert only if sms/email present
#
# This means 100 000 users at FANOUT_CHUNK_SIZE=500 → 200 parallel chunk tasks.
# Push is O(1) via FCM topic; DB writes are O(n/chunk) parallel.
# ─────────────────────────────────────────────────────────────────────────────

FANOUT_CHUNK_SIZE = 500
DRIVON_ALERTS_TOPIC = "drivon_alerts_all"


def _fetch_all_user_ids(settings) -> list:
    """Paginate through user-service /users/ids and return the full list."""
    import requests
    user_ids = []
    page, page_size = 1, 1000  # larger page size for efficiency
    while True:
        try:
            resp = requests.get(
                f"{settings.USER_SERVICE_URL}/users/ids",
                params={"page": page, "page_size": page_size},
                timeout=15,
            )
            if resp.status_code == 200:
                data = resp.json()
                ids = data.get("ids") if isinstance(data, dict) else (data if isinstance(data, list) else [])
                if not ids:
                    break
                user_ids.extend(ids)
                if len(ids) < page_size:
                    break
                page += 1
            else:
                logging.getLogger("uvicorn").error(
                    f"_fetch_all_user_ids: user-service returned {resp.status_code}"
                )
                break
        except Exception as exc:
            logging.getLogger("uvicorn").error(f"_fetch_all_user_ids: {exc}")
            break
    return user_ids


def _ensure_fcm(settings) -> bool:
    """Initialize FCM service from settings if not already done. Returns True on success."""
    from services.fcm_service import FCMService
    if FCMService.is_initialized():
        return True
    return FCMService.initialize(
        project_id=settings.FCM_PROJECT_ID,
        private_key=settings.FCM_PRIVATE_KEY,
        client_email=settings.FCM_CLIENT_EMAIL,
    )


@celery_app.task(name="broadcast_alert_fanout")
def broadcast_alert_fanout(broadcast_id: str) -> None:
    """
    Master task: fires the FCM topic push (one API call → all subscribed devices)
    then enqueues parallel fanout_chunk tasks for in-app / SMS / email records.
    """
    logger = logging.getLogger("uvicorn")
    logger.info(f"broadcast_alert_fanout: start broadcast_id={broadcast_id}")
    db = SessionLocal()
    try:
        from core.config import settings

        broadcast = db.query(BroadcastAlert).filter(BroadcastAlert.id == broadcast_id).first()
        if not broadcast:
            logger.error(f"broadcast_alert_fanout: broadcast not found id={broadcast_id}")
            return

        broadcast_channels = broadcast.channels or []

        # ── 1. Send FCM topic push immediately (O(1), regardless of user count) ──
        if "push" in broadcast_channels:
            if _ensure_fcm(settings):
                from services.fcm_service import FCMService
                result = FCMService.send_topic_notification(
                    topic=DRIVON_ALERTS_TOPIC,
                    title=broadcast.title,
                    body=broadcast.message,
                    data={
                        "broadcast_id": broadcast_id,
                        "type": broadcast.type.value if hasattr(broadcast.type, "value") else str(broadcast.type),
                        "priority": str(broadcast.priority),
                        "action_url": broadcast.action_url or "",
                        "action_text": broadcast.action_text or "",
                    },
                )
                if result.get("success"):
                    logger.info(f"broadcast_alert_fanout: FCM topic push sent for {broadcast_id}")
                else:
                    logger.warning(
                        f"broadcast_alert_fanout: FCM topic push failed: {result.get('error')}"
                    )
            else:
                logger.error("broadcast_alert_fanout: FCM not initialized, topic push skipped")

        # ── 2. Determine non-push channels for DB records ──
        # Push is handled by topic above. In-app is always included (app polls for it).
        # deliver_alert is only queued when SMS or email need actual delivery.
        non_push_delivery_channels = [
            c for c in broadcast_channels if c in ("sms", "email")
        ]

        # ── 3. Fetch all user IDs ──
        user_ids = _fetch_all_user_ids(settings)
        if not user_ids:
            logger.warning(f"broadcast_alert_fanout: no users found, skipping DB fanout")
            return

        logger.info(
            f"broadcast_alert_fanout: {len(user_ids)} users → "
            f"{(len(user_ids) + FANOUT_CHUNK_SIZE - 1) // FANOUT_CHUNK_SIZE} chunks "
            f"of {FANOUT_CHUNK_SIZE}"
        )

        # ── 4. Enqueue one chunk task per batch (runs in parallel across workers) ──
        chunk_count = 0
        for i in range(0, len(user_ids), FANOUT_CHUNK_SIZE):
            chunk = user_ids[i : i + FANOUT_CHUNK_SIZE]
            celery_app.send_task(
                "fanout_chunk",
                args=[broadcast_id, chunk, non_push_delivery_channels],
            )
            chunk_count += 1

        logger.info(
            f"broadcast_alert_fanout: enqueued {chunk_count} chunk tasks for {broadcast_id}"
        )
    finally:
        db.close()


@celery_app.task(name="fanout_chunk")
def fanout_chunk(broadcast_id: str, user_ids: list, delivery_channels: list) -> None:
    """
    Worker task: creates Alert DB records for a batch of users and enqueues
    deliver_alert only when SMS/email delivery is needed.

    In-app alerts are created for every user (app polls GET /alerts).
    Push is already handled by FCM topic in the master task.
    SMS/email require per-user Alert records + deliver_alert queuing.
    """
    logger = logging.getLogger("uvicorn")
    db = SessionLocal()
    try:
        broadcast = db.query(BroadcastAlert).filter(BroadcastAlert.id == broadcast_id).first()
        if not broadcast:
            logger.error(f"fanout_chunk: broadcast not found id={broadcast_id}")
            return

        # Always include in_app so users see it when they open the app.
        # Add sms/email only if the broadcast requested them.
        record_channels = ["in_app"] + [c for c in delivery_channels if c in ("sms", "email")]
        needs_active_delivery = bool(delivery_channels)  # sms or email present

        created = 0
        queued = 0
        for user_id in user_ids:
            try:
                alert = Alert(
                    id=str(uuid.uuid4()),
                    user_id=int(user_id),
                    type=broadcast.type,
                    title=broadcast.title,
                    message=broadcast.message,
                    priority=broadcast.priority,
                    channels=record_channels,
                    status=AlertStatus.PENDING,
                    action_url=broadcast.action_url,
                    action_text=broadcast.action_text,
                    alert_metadata={
                        "broadcast_id": broadcast_id,
                        "source": broadcast.source,
                    },
                )
                db.add(alert)
                db.flush()
                created += 1

                # Only queue deliver_alert for sms/email — in_app needs no push
                if needs_active_delivery:
                    celery_app.send_task("deliver_alert", args=[alert.id])
                    queued += 1
                    inc("deliveries_attempted")
                else:
                    # Mark as delivered immediately (in_app = record exists)
                    alert.status = AlertStatus.DELIVERED
                    alert.delivered_at = datetime.utcnow()

            except Exception as exc:
                logger.error(
                    f"fanout_chunk: failed for user {user_id} in broadcast {broadcast_id}: {exc}"
                )

        db.commit()
        logger.info(
            f"fanout_chunk: broadcast={broadcast_id} "
            f"created={created} queued_delivery={queued} users={len(user_ids)}"
        )
    finally:
        db.close()


@celery_app.task(name="expire_broadcast_alerts")
def expire_broadcast_alerts() -> None:
    """Mark broadcast alerts whose expires_at has passed as EXPIRED."""
    logger = logging.getLogger("uvicorn")
    db = SessionLocal()
    try:
        now = datetime.now(timezone.utc)
        expired = (
            db.query(BroadcastAlert)
            .filter(
                BroadcastAlert.status == BroadcastAlertStatus.ACTIVE,
                BroadcastAlert.expires_at != None,
                BroadcastAlert.expires_at <= now,
            )
            .all()
        )
        for alert in expired:
            alert.status = BroadcastAlertStatus.EXPIRED
        if expired:
            db.commit()
            logger.info(f"expire_broadcast_alerts: expired {len(expired)} broadcast alerts")
    finally:
        db.close()


