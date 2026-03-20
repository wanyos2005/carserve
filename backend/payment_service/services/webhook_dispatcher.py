"""
Webhook Dispatcher
------------------
After a transaction is saved, this service:
  1. Finds all active WebhookSubscriptions for that provider
  2. POSTs the payment event to each callback_url
  3. Signs each request with HMAC-SHA256 using the subscription secret
  4. Logs every delivery attempt in WebhookDeliveryLog

Signing:
  Header: X-DriveOn-Signature: sha256=<hex>
  The receiving app recomputes HMAC(secret, body) and compares to verify authenticity.
"""

import hmac
import hashlib
import json
import logging
from datetime import datetime, timezone

import httpx
from sqlalchemy.orm import Session

from core.config import WEBHOOK_MAX_RETRIES, WEBHOOK_TIMEOUT_SECONDS
from models.transaction import MpesaTransaction
from models.webhook import WebhookSubscription, WebhookDeliveryLog

logger = logging.getLogger("uvicorn")


def _sign_payload(secret: str, body: str) -> str:
    """Returns HMAC-SHA256 hex digest of body using secret."""
    return hmac.new(
        secret.encode("utf-8"),
        body.encode("utf-8"),
        hashlib.sha256,
    ).hexdigest()


def _build_event_payload(transaction: MpesaTransaction) -> dict:
    """Shapes the outbound event body sent to all subscribers."""
    return {
        "event": "mpesa.payment.received",
        "transaction_id": transaction.id,
        "transaction_code": transaction.transaction_code,
        "transaction_type": transaction.transaction_type,
        "raw_sms": transaction.raw_sms,
        "amount": transaction.amount,
        "balance": transaction.balance,
        "sender_name": transaction.sender_name,
        "sender_phone": transaction.sender_phone,
        "provider_id": transaction.provider_id,
        "source": transaction.source,
        "received_at": transaction.received_at.isoformat() if transaction.received_at else None,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


def dispatch_to_webhooks(transaction: MpesaTransaction, db: Session) -> None:
    """
    Called (as a FastAPI BackgroundTask) after a transaction is saved.
    Delivers the event to every active subscription registered for this provider.
    """
    if not transaction.provider_id:
        logger.info(f"⏭️  No provider_id on transaction {transaction.transaction_code} — skipping webhooks")
        return

    subscriptions: list[WebhookSubscription] = (
        db.query(WebhookSubscription)
        .filter(
            WebhookSubscription.provider_id == transaction.provider_id,
            WebhookSubscription.is_active == True,
        )
        .all()
    )

    if not subscriptions:
        logger.info(f"ℹ️  No active webhooks for provider {transaction.provider_id}")
        return

    payload = _build_event_payload(transaction)
    body_str = json.dumps(payload, separators=(",", ":"))

    for sub in subscriptions:
        _deliver(sub, transaction.id, body_str, db)


def _deliver(
    sub: WebhookSubscription,
    transaction_id: str,
    body_str: str,
    db: Session,
    attempt: int = 1,
) -> None:
    """Attempts a single HTTP POST delivery with up to WEBHOOK_MAX_RETRIES attempts."""
    signature = _sign_payload(sub.secret, body_str)
    headers = {
        "Content-Type": "application/json",
        "X-DriveOn-Signature": f"sha256={signature}",
        "X-DriveOn-Event": "mpesa.payment.received",
    }

    status = "failed"
    http_status = None
    error = None

    try:
        response = httpx.post(
            sub.callback_url,
            content=body_str,
            headers=headers,
            timeout=WEBHOOK_TIMEOUT_SECONDS,
        )
        http_status = response.status_code
        if 200 <= response.status_code < 300:
            status = "success"
            logger.info(
                f"✅ Webhook delivered to {sub.callback_url} "
                f"[{response.status_code}] attempt={attempt}"
            )
        else:
            error = f"HTTP {response.status_code}: {response.text[:200]}"
            logger.warning(f"⚠️  Webhook {sub.callback_url} returned {response.status_code}")

    except httpx.TimeoutException as exc:
        status = "timeout"
        error = f"Timed out after {WEBHOOK_TIMEOUT_SECONDS}s ({type(exc).__name__})"
        logger.warning(f"⏱️  Webhook {sub.callback_url} timed out (attempt {attempt}/{WEBHOOK_MAX_RETRIES})")
    except httpx.ConnectError as exc:
        error = f"ConnectError: {exc} — target server refused or is unreachable"
        logger.error(f"❌ Webhook {sub.callback_url} connection refused (attempt {attempt}/{WEBHOOK_MAX_RETRIES}): {exc}")
    except httpx.RemoteProtocolError as exc:
        error = f"RemoteProtocolError: {exc} — server closed connection without a valid HTTP response"
        logger.error(f"❌ Webhook {sub.callback_url} remote protocol error (attempt {attempt}/{WEBHOOK_MAX_RETRIES}): {exc}")
    except httpx.NetworkError as exc:
        error = f"NetworkError ({type(exc).__name__}): {exc}"
        logger.error(f"❌ Webhook {sub.callback_url} network error (attempt {attempt}/{WEBHOOK_MAX_RETRIES}): {type(exc).__name__}: {exc}")
    except Exception as exc:
        error = f"{type(exc).__name__}: {str(exc)[:400]}"
        logger.error(f"❌ Webhook {sub.callback_url} unexpected error (attempt {attempt}/{WEBHOOK_MAX_RETRIES}): {type(exc).__name__}: {exc}")

    # Log this attempt
    log = WebhookDeliveryLog(
        subscription_id=sub.id,
        transaction_id=transaction_id,
        http_status=http_status,
        status=status,
        error=error,
        attempt_number=attempt,
    )
    db.add(log)
    db.commit()

    # Retry on failure (up to WEBHOOK_MAX_RETRIES)
    if status != "success" and attempt < WEBHOOK_MAX_RETRIES:
        logger.info(f"🔄 Retrying webhook {sub.callback_url} (attempt {attempt + 1}/{WEBHOOK_MAX_RETRIES})")
        _deliver(sub, transaction_id, body_str, db, attempt + 1)
    elif status != "success":
        logger.error(
            f"🚫 Webhook PERMANENTLY FAILED for {sub.callback_url} after {WEBHOOK_MAX_RETRIES} attempts. "
            f"Last error: {error} | subscription_id={sub.id} | transaction_id={transaction_id}"
        )
