import uuid
from sqlalchemy import Column, String, Boolean, Integer, TIMESTAMP, Text, func, ForeignKey
from core.db import Base


class WebhookSubscription(Base):
    """
    A provider-configured callback URL.
    Every time a payment transaction is received for that provider,
    the payment_service POSTs the event to this URL signed with the secret.

    Multiple subscriptions per provider are supported (e.g. POS + accounting system).

    ID is auto-generated (UUID) on creation and returned to the provider.
    """
    __tablename__ = "webhook_subscriptions"
    __table_args__ = {"schema": "payments"}

    # Auto-generated UUID — returned to provider on creation, used to manage subscription
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))

    # Provider that owns this subscription (links to service_providers.providers.id)
    # which station this belongs to
    provider_id = Column(String, nullable=False, index=True)

    # A human-readable label: "My POS System", "QuickBooks", etc.
    label = Column(String, nullable=True)

    # The URL that will receive POST requests on every new payment
    #FuelPro's or DEMOFMS URL (can be same across many providers)
    callback_url = Column(String, nullable=False)

    # HMAC-SHA256 signing secret — provider supplies this when subscribing.
    # Every outbound webhook is signed: X-DriveOn-Signature: sha256=<hex>
    # The receiving app uses this to verify the request came from us.
    secret = Column(String, nullable=False)

    is_active = Column(Boolean, default=True, nullable=False)

    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())


class WebhookDeliveryLog(Base):
    """
    Records every outbound webhook delivery attempt — success or failure.

    Flow:
      1. Flutter app posts SMS transaction → MpesaTransaction row created (gets transaction_id)
      2. Dispatcher finds all active WebhookSubscriptions for that provider_id
      3. For each subscription, POSTs the event and writes one row here with:
           - subscription_id  = WebhookSubscription.id (which URL we called)
           - transaction_id   = MpesaTransaction.id    (which payment triggered it)
    """
    __tablename__ = "webhook_delivery_logs"
    __table_args__ = {"schema": "payments"}

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))

    # Which webhook subscription (URL) this delivery was sent to
    subscription_id = Column(
        String,
        ForeignKey("payments.webhook_subscriptions.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    # Which transaction triggered this delivery
    transaction_id = Column(
        String,
        ForeignKey("payments.mpesa_transactions.id", ondelete="CASCADE"),
        nullable=False,
        index=True,
    )

    # HTTP status code returned by the target URL (null if connection failed)
    http_status = Column(Integer, nullable=True)

    # "success" | "failed" | "timeout"
    status = Column(String, nullable=False)

    # Error message if delivery failed
    error = Column(Text, nullable=True)

    attempt_number = Column(Integer, default=1, nullable=False)

    # Raw response body returned by the subscriber's server (capped at 2000 chars)
    response_body = Column(Text, nullable=True)

    attempted_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
