from celery import Celery
from core.config import settings

celery_app = Celery(
    "alert_service",
    broker=settings.CELERY_BROKER_URL,
    backend=settings.CELERY_RESULT_BACKEND,
)

celery_app.conf.update(
    task_ignore_result=True,
    task_serializer="json",
    result_serializer="json",
    accept_content=["json"],
    timezone="UTC",
    enable_utc=True,
)

# Ensure tasks are imported/registered
celery_app.conf.update(imports=("tasks",))

# Beat schedule (periodic tasks)
celery_app.conf.beat_schedule = {
    # Every 15 minutes: run insurance expiry check
    "check-insurance-expiry": {
        "task": "run_rule_check",
        "schedule": 15 * 60,
        "args": ["insurance_expiry"],
    },
    # Every 30 minutes: run service due check
    "check-service-due": {
        "task": "run_rule_check",
        "schedule": 30 * 60,
        "args": ["service_due"],
    },
}


