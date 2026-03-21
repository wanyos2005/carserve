import uuid
import logging
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy.exc import IntegrityError
from typing import Optional

from core.db import get_db
from models.transaction import MpesaTransaction
from schemas.transaction import TransactionCreate, TransactionRead
from celery_app import celery_app

router = APIRouter()
logger = logging.getLogger("uvicorn")


@router.post(
    "",
    response_model=TransactionRead,
    status_code=status.HTTP_201_CREATED,
    summary="Receive a transaction from the Flutter SMS reader",
)
def create_transaction(
    payload: TransactionCreate,
    db: Session = Depends(get_db),
):
    """
    Called by the Flutter app every time it parses a new M-Pesa SMS.
    Saves the transaction then queues a Celery task to fire webhooks —
    the worker picks it up independently so the app gets a fast response,
    and deliveries survive a server restart.
    """
    # Auto-generate a stable code if SMS parsing could not extract one
    transaction_code = payload.transaction_code or f"RAW-{uuid.uuid4().hex[:12].upper()}"

    transaction = MpesaTransaction(
        transaction_code=transaction_code,
        transaction_type=payload.transaction_type,
        amount=payload.amount,
        balance=payload.balance,
        sender_name=payload.sender_name,
        sender_phone=payload.sender_phone,
        provider_id=payload.provider_id,
        raw_sms=payload.raw_sms,
        source=payload.source,
        received_at=payload.received_at,
    )

    try:
        db.add(transaction)
        db.commit()
        db.refresh(transaction)
    except IntegrityError:
        db.rollback()
        # Duplicate transaction_code — already processed, return the existing record
        existing = (
            db.query(MpesaTransaction)
            .filter(MpesaTransaction.transaction_code == payload.transaction_code)
            .first()
        )
        if existing:
            return existing
        raise HTTPException(status_code=409, detail="Duplicate transaction")

    # Queue a Celery task — the payment-worker picks this up from Redis
    # and dispatches webhooks independently of this web server process
    logger.info(f"📤 Queuing dispatch_webhooks for transaction {transaction.transaction_code} id={transaction.id}")
    try:
        task = celery_app.send_task("dispatch_webhooks", args=[transaction.id])
        logger.info(f"✅ Task queued: task_id={task.id} for transaction {transaction.transaction_code}")
    except Exception as e:
        logger.error(f"❌ Failed to queue dispatch_webhooks for {transaction.transaction_code}: {type(e).__name__}: {e}")

    return transaction


@router.get(
    "",
    response_model=list[TransactionRead],
    summary="List transactions for a provider",
)
def list_transactions(
    provider_id: Optional[str] = None,
    limit: int = 50,
    offset: int = 0,
    db: Session = Depends(get_db),
):
    q = db.query(MpesaTransaction)
    if provider_id:
        q = q.filter(MpesaTransaction.provider_id == provider_id)
    return q.order_by(MpesaTransaction.created_at.desc()).offset(offset).limit(limit).all()


@router.get(
    "/{transaction_id}",
    response_model=TransactionRead,
    summary="Get a single transaction",
)
def get_transaction(transaction_id: str, db: Session = Depends(get_db)):
    tx = db.query(MpesaTransaction).filter(MpesaTransaction.id == transaction_id).first()
    if not tx:
        raise HTTPException(status_code=404, detail="Transaction not found")
    return tx
