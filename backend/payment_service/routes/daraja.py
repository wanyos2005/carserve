"""
Daraja C2B Callback
-------------------
When you register a Confirmation URL with Safaricom Daraja (paybill/till),
Safaricom will POST to this endpoint on every customer payment.

This normalises the Daraja payload into a MpesaTransaction — the same model
used by the SMS reader — then fires the same webhook fanout.

Setup steps (when ready to go live with Daraja):
  1. Create a Safaricom developer account at developer.safaricom.co.ke
  2. Register your paybill/till under a Daraja app
  3. Call the C2B Register URL API pointing to: POST /daraja/callback
  4. Set DARAJA_SHORTCODE in your environment
"""

from fastapi import APIRouter, Depends, BackgroundTasks, Request, status
from sqlalchemy.orm import Session
import logging
import os

from core.db import get_db
from models.transaction import MpesaTransaction
from schemas.transaction import DarajaC2BCallback
from services.webhook_dispatcher import dispatch_to_webhooks

router = APIRouter()
logger = logging.getLogger("uvicorn")

# Map paybill/till shortcodes to provider IDs.
# Populate this from your DB or env when you go live.
SHORTCODE_TO_PROVIDER: dict[str, str] = {}


@router.post(
    "/callback",
    status_code=status.HTTP_200_OK,
    summary="Safaricom Daraja C2B confirmation callback",
)
async def daraja_callback(
    payload: DarajaC2BCallback,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
):
    """
    Safaricom sends this when a customer pays to a registered paybill/till.
    We normalise it to the same MpesaTransaction shape used by the SMS reader.
    """
    logger.info(f"📩 Daraja callback: {payload.TransID} | Ksh{payload.TransAmount}")

    # Resolve provider from shortcode
    provider_id = SHORTCODE_TO_PROVIDER.get(payload.BusinessShortCode)

    sender_name = " ".join(
        filter(None, [payload.FirstName, payload.MiddleName, payload.LastName])
    ).strip() or None

    try:
        amount = float(payload.TransAmount)
        balance = float(payload.OrgAccountBalance) if payload.OrgAccountBalance else None
    except ValueError:
        amount = 0.0
        balance = None

    transaction = MpesaTransaction(
        transaction_code=payload.TransID,
        transaction_type="daraja_c2b",
        amount=amount,
        balance=balance,
        sender_name=sender_name,
        sender_phone=payload.MSISDN,
        provider_id=provider_id,
        raw_sms=None,
        source="daraja",
    )

    db.add(transaction)
    db.commit()
    db.refresh(transaction)

    background_tasks.add_task(dispatch_to_webhooks, transaction, db)

    # Safaricom requires a specific JSON acknowledgement
    return {"ResultCode": "0", "ResultDesc": "Accepted"}
