from celery_app import celery_app
from core.db import SessionLocal
from models.alert import Alert, AlertStatus
from services.notification_service import NotificationService
from services.rule_engine import RuleEngine
from datetime import datetime
import logging
import asyncio
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


