from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class TransactionCreate(BaseModel):
    """Posted by the Flutter SMS reader after parsing an M-Pesa message."""
    transaction_code: str
    raw_sms: str
    transaction_type: str = "received"
    amount: float
    balance: Optional[float] = None
    sender_name: Optional[str] = None
    sender_phone: Optional[str] = None
    provider_id: Optional[str] = None
    raw_sms: Optional[str] = None
    source: str = "sms_reader"
    received_at: Optional[datetime] = None


class DarajaC2BCallback(BaseModel):
    """
    Payload shape sent by Safaricom Daraja API on a C2B payment.
    Field names match Safaricom's official spec.
    """
    RawSMS: str
    TransactionType: str
    TransID: str                    # M-Pesa transaction code
    TransTime: str                  # e.g. "20260316103000"
    TransAmount: str                # e.g. "1000.00"
    BusinessShortCode: str          # paybill or till number
    BillRefNumber: Optional[str] = None   # account reference
    InvoiceNumber: Optional[str] = None
    OrgAccountBalance: Optional[str] = None
    ThirdPartyTransID: Optional[str] = None
    MSISDN: str                     # customer phone
    FirstName: Optional[str] = None
    MiddleName: Optional[str] = None
    LastName: Optional[str] = None


class TransactionRead(BaseModel):
    id: str
    raw_sms: str
    transaction_code: str
    transaction_type: str
    amount: float
    balance: Optional[float]
    sender_name: Optional[str]
    sender_phone: Optional[str]
    provider_id: Optional[str]
    source: str
    received_at: Optional[datetime]
    created_at: datetime

    class Config:
        from_attributes = True
