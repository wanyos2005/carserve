from pydantic import BaseModel
from typing import Optional
from datetime import datetime


class TransactionCreate(BaseModel):
    """Posted by the Flutter SMS reader after parsing an M-Pesa message."""
    raw_sms: str                                  # always required — never drop the original SMS
    transaction_code: Optional[str] = None        # auto-generated server-side if parsing failed
    transaction_type: str = "unknown"
    amount: Optional[float] = None                # None when SMS could not be parsed
    balance: Optional[float] = None
    sender_name: Optional[str] = None
    sender_phone: Optional[str] = None
    provider_id: Optional[str] = None
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
    raw_sms: Optional[str]
    transaction_code: str
    transaction_type: str
    amount: Optional[float]
    balance: Optional[float]
    sender_name: Optional[str]
    sender_phone: Optional[str]
    provider_id: Optional[str]
    source: str
    received_at: Optional[datetime]
    created_at: datetime

    class Config:
        from_attributes = True
