# backend/user_service/models/users.py

from sqlalchemy import Column, Integer, String, Text, JSON, Numeric, TIMESTAMP, func, ForeignKey, Boolean

from datetime import datetime
from core.db import Base
from sqlalchemy.dialects.postgresql import UUID
import uuid
from sqlalchemy.orm import relationship

class User(Base):
    __tablename__ = "tbl_auth"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    email = Column(String, unique=True, index=True, nullable=True)  # now optional
    name = Column(String, index=True, nullable=True)
    phone = Column(String, index=True, nullable=True)
    auth_provider = Column(String, index=True, default="email")
    verified = Column(Boolean, default=False)

    # 🔹 NEW FIELDS
    is_guest = Column(Boolean, default=False)  # True if created by provider
    created_by_provider_id = Column(String, nullable=True)  # link provider UUID

    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())

    roles = relationship("User_Roles", back_populates="user", uselist=True)




class OTP(Base):
    __tablename__ = "tbl_otp"
    __table_args__ = {"schema": "users"}

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    email = Column(String, index=True, nullable=False)
    code = Column(String, nullable=False)
    expires_at = Column(TIMESTAMP, nullable=False)
    created_at = Column(TIMESTAMP, server_default=func.now())

class Roles(Base):
    __tablename__ = "tbl_roles"
    __table_args__ = {"schema": "users"}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String, index=True, nullable=False)
    created_at = Column(TIMESTAMP, server_default=func.now())

class User_Roles(Base):
    __tablename__ = "tbl_auth_roles"
    __table_args__ = {"schema": "users"}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(Integer, ForeignKey("users.tbl_auth.id"))
    role_id = Column(String, nullable=False)
    active = Column(Boolean, default=True)
    created_at = Column(TIMESTAMP, server_default=func.now())
    user = relationship("User", back_populates="roles")

class ProviderUserLink(Base):
    __tablename__ = "provider_user_links"
    __table_args__ = {"schema": "users"}  # or service_providers if you prefer

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.tbl_auth.id"), nullable=False)
    provider_id = Column(String, nullable=False)  # uuid from service_providers.providers
    created_at = Column(TIMESTAMP, server_default=func.now())

