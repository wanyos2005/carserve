from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from core.db import get_db
from models.webhook import WebhookSubscription, WebhookDeliveryLog
from schemas.webhook import (
    WebhookSubscriptionCreate,
    WebhookSubscriptionRead,
    WebhookSubscriptionUpdate,
    WebhookDeliveryLogRead,
)

router = APIRouter()


@router.post(
    "",
    response_model=WebhookSubscriptionRead,
    status_code=status.HTTP_201_CREATED,
    summary="Register a callback URL for a provider",
)
def subscribe(payload: WebhookSubscriptionCreate, db: Session = Depends(get_db)):
    """
    Registers a new webhook callback URL for a provider.

    On every incoming M-Pesa payment for that provider, a signed POST request
    is sent to callback_url with header: X-DriveOn-Signature: sha256=<hmac_hex>

    The receiving app should verify the signature using the same secret.
    """
    sub = WebhookSubscription(
        provider_id=payload.provider_id,
        label=payload.label,
        callback_url=str(payload.callback_url),
        secret=payload.secret,
    )
    db.add(sub)
    db.commit()
    db.refresh(sub)
    return sub


@router.get(
    "",
    response_model=list[WebhookSubscriptionRead],
    summary="List webhook subscriptions for a provider",
)
def list_subscriptions(provider_id: str, db: Session = Depends(get_db)):
    return (
        db.query(WebhookSubscription)
        .filter(WebhookSubscription.provider_id == provider_id)
        .order_by(WebhookSubscription.created_at.desc())
        .all()
    )


@router.patch(
    "/{subscription_id}",
    response_model=WebhookSubscriptionRead,
    summary="Update a webhook subscription (URL, secret, active state)",
)
def update_subscription(
    subscription_id: str,
    payload: WebhookSubscriptionUpdate,
    db: Session = Depends(get_db),
):
    sub = db.query(WebhookSubscription).filter(WebhookSubscription.id == subscription_id).first()
    if not sub:
        raise HTTPException(status_code=404, detail="Subscription not found")

    if payload.label is not None:
        sub.label = payload.label
    if payload.callback_url is not None:
        sub.callback_url = str(payload.callback_url)
    if payload.secret is not None:
        sub.secret = payload.secret
    if payload.is_active is not None:
        sub.is_active = payload.is_active

    db.commit()
    db.refresh(sub)
    return sub


@router.delete(
    "/{subscription_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Unsubscribe / delete a webhook",
)
def delete_subscription(subscription_id: str, db: Session = Depends(get_db)):
    sub = db.query(WebhookSubscription).filter(WebhookSubscription.id == subscription_id).first()
    if not sub:
        raise HTTPException(status_code=404, detail="Subscription not found")
    db.delete(sub)
    db.commit()


@router.get(
    "/{subscription_id}/logs",
    response_model=list[WebhookDeliveryLogRead],
    summary="View delivery logs for a webhook subscription",
)
def get_delivery_logs(
    subscription_id: str,
    limit: int = 50,
    db: Session = Depends(get_db),
):
    """
    Returns recent delivery attempts for this subscription.
    Useful for providers to debug failed webhook deliveries.
    """
    return (
        db.query(WebhookDeliveryLog)
        .filter(WebhookDeliveryLog.subscription_id == subscription_id)
        .order_by(WebhookDeliveryLog.attempted_at.desc())
        .limit(limit)
        .all()
    )
