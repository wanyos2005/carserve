from pydantic import BaseModel, HttpUrl
from typing import Optional
from datetime import datetime


class WebhookSubscriptionCreate(BaseModel):
    """
    Sent by a provider (or their admin) to register a new callback URL.

    Example:
      POST /webhooks/
      {
        "provider_id": "abc-123",
        "label": "My POS System",
        "callback_url": "https://mypos.example.com/mpesa-hook",
        "secret": "my-signing-secret"
      }

    On every new payment for that provider, we POST to callback_url
    with header: X-DriveOn-Signature: sha256=<hmac_hex>
    The receiving app verifies the signature using the same secret.
    """
    provider_id: str
    label: Optional[str] = None
    callback_url: str
    secret: str


class WebhookSubscriptionRead(BaseModel):
    id: str
    provider_id: str
    label: Optional[str]
    callback_url: str
    is_active: bool
    created_at: datetime
    # secret is intentionally excluded from read responses

    class Config:
        from_attributes = True


class WebhookSubscriptionUpdate(BaseModel):
    label: Optional[str] = None
    callback_url: Optional[str] = None
    secret: Optional[str] = None
    is_active: Optional[bool] = None


class WebhookDeliveryLogRead(BaseModel):
    id: str
    subscription_id: str
    transaction_id: str
    http_status: Optional[int]
    status: str
    error: Optional[str]
    attempt_number: int
    response_body: Optional[str]
    attempted_at: datetime

    class Config:
        from_attributes = True
