import uuid
from sqlalchemy import Column, String, Float, TIMESTAMP, func, UniqueConstraint
from core.db import Base


class MpesaTransaction(Base):
    __tablename__ = "mpesa_transactions"
    __table_args__ = (
        # DB-level dedup: same transaction code can never be stored twice
        UniqueConstraint("transaction_code", name="uq_transaction_code"),
        {"schema": "payments"},
    )

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    
    # The raw SMS body — useful for auditing and re-parsing
    raw_sms = Column(String, nullable=True)
    # The M-Pesa transaction reference, e.g. "RA12B3C4DE5"
    transaction_code = Column(String, nullable=False, index=True)

    # "received" = personal M-Pesa received money
    # "paybill_payment" = customer paid to paybill/till
    # "daraja_c2b" = came directly from Safaricom Daraja callback
    transaction_type = Column(String, nullable=False, default="received")

    amount = Column(Float, nullable=False)
    balance = Column(Float, nullable=True)   # merchant balance after transaction

    sender_name = Column(String, nullable=True)
    sender_phone = Column(String, nullable=True)

    # The provider (merchant) who received the payment
    provider_id = Column(String, nullable=True, index=True)


    # Source that reported the transaction: "sms_reader" | "daraja"
    source = Column(String, nullable=False, default="sms_reader")

    received_at = Column(TIMESTAMP(timezone=True), nullable=True)
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
