# backend/user_service/models/users.py
from sqlalchemy import Column, String, TIMESTAMP, Integer, Boolean, func
from datetime import datetime
from core.db import Base

class User(Base):
    __tablename__ = "tbl_auth"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    email = Column(String, unique=True, index=True, nullable=False)
    name = Column(String, index=True, nullable=True)
    phone = Column(String, index=True, nullable=True)
    role = Column(String, index=True, default="user")
    auth_provider = Column(String, index=True, default="email")
    verified = Column(Boolean, default=False)
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())



class OTP(Base):
    __tablename__ = "tbl_otp"
    __table_args__ = {"schema": "users"}

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    email = Column(String, index=True, nullable=False)
    code = Column(String, nullable=False)
    expires_at = Column(TIMESTAMP, nullable=False)
    created_at = Column(TIMESTAMP, server_default=func.now())


