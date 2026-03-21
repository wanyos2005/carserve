from celery import Celery
from core.config import CELERY_BROKER_URL, CELERY_RESULT_BACKEND

celery_app = Celery(
    "payment_service",
    broker=CELERY_BROKER_URL,
    backend=CELERY_RESULT_BACKEND,
)

celery_app.conf.update(
    task_ignore_result=True,
    task_serializer="json",
    result_serializer="json",
    accept_content=["json"],
    timezone="UTC",
    enable_utc=True,
    broker_connection_retry_on_startup=True,
    broker_heartbeat=10,
    broker_connection_timeout=30,
    broker_transport_options={
        "visibility_timeout": 3600,
        "socket_keepalive": True,
        "socket_timeout": 5,
        "socket_connect_timeout": 5,
        "health_check_interval": 25,
    },
)

# Ensure tasks module is imported so tasks are registered with the worker
celery_app.conf.update(imports=("tasks",))
