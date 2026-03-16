import logging
from celery_app import celery_app
from core.db import SessionLocal
from models.transaction import MpesaTransaction
from services.webhook_dispatcher import dispatch_to_webhooks

logger = logging.getLogger("celery")


@celery_app.task(name="dispatch_webhooks", max_retries=3, default_retry_delay=60)
def dispatch_webhooks_task(transaction_id: str) -> None:
    """
    Picks up a saved transaction by ID and fires it to all registered
    webhook URLs for that provider.

    Runs inside the payment-worker container — completely separate process
    from the FastAPI web server. Opens its own DB session because SQLAlchemy
    sessions cannot be shared across processes.

    If this task crashes or the worker restarts, Celery will automatically
    retry it (up to max_retries=3, waiting 60s between attempts).
    """
    logger.info(f"dispatch_webhooks_task: received transaction_id={transaction_id}")
    db = SessionLocal()
    try:
        transaction = (
            db.query(MpesaTransaction)
            .filter(MpesaTransaction.id == transaction_id)
            .first()
        )
        if not transaction:
            logger.error(f"dispatch_webhooks_task: transaction not found id={transaction_id}")
            return

        logger.info(
            f"dispatch_webhooks_task: dispatching {transaction.transaction_code} "
            f"Ksh{transaction.amount} for provider={transaction.provider_id}"
        )
        dispatch_to_webhooks(transaction, db)
        logger.info(f"dispatch_webhooks_task: done for transaction_id={transaction_id}")

    except Exception as exc:
        logger.error(f"dispatch_webhooks_task: error for {transaction_id}: {exc}")
        raise dispatch_webhooks_task.retry(exc=exc)
    finally:
        db.close()
