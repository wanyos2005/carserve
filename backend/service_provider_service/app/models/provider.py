from sqlalchemy import Column, Integer, String, Text, JSON, Numeric, TIMESTAMP, func, ForeignKey, Boolean
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID
import uuid
from app.core.db import Base


class ProviderCategory(Base):
    __tablename__ = "provider_categories"
    __table_args__ = {"schema": "service_providers"}

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(100), unique=True, nullable=False)  # e.g., insurance, garage, mechanic
    providers = relationship("Provider", back_populates="category")


class Provider(Base):
    __tablename__ = "providers"
    __table_args__ = {"schema": "service_providers"}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(255), nullable=False)
    category_id = Column(Integer, ForeignKey("service_providers.provider_categories.id"))
    description = Column(Text)
    contact_info = Column(JSON)  # {phone1, phone2, email}
    location = Column(JSON)      # {lat, lng, address}
    is_registered = Column(Boolean, default=False)
    rating = Column(Numeric(2,1), default=0.0)
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())

    category = relationship("ProviderCategory", back_populates="providers")
    services = relationship("Service", back_populates="provider", cascade="all, delete-orphan")


class ServiceCategory(Base):
    __tablename__ = "service_categories"
    __table_args__ = {"schema": "service_providers"}

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(100), unique=True, nullable=False)
    services = relationship("Service", back_populates="category")


class Service(Base):
    __tablename__ = "services"
    __table_args__ = {"schema": "service_providers"}

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    provider_id = Column(UUID(as_uuid=True),
                         ForeignKey("service_providers.providers.id", ondelete="CASCADE"),
                         nullable=False)
    category_id = Column(Integer, ForeignKey("service_providers.service_categories.id"))
    name = Column(String(255), nullable=False)
    description = Column(Text)
    price_range = Column(String(50))
    requirements = Column(JSON, default=dict)  # extra fields depending on service
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())

    provider = relationship("Provider", back_populates="services")
    category = relationship("ServiceCategory", back_populates="services")
