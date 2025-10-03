from sqlalchemy import Column, Integer, String, Text, JSON, Numeric, TIMESTAMP, func, ForeignKey, Boolean
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID
import uuid
from app.core.db import Base
from sqlalchemy.sql import expression
from app.core.db import Base
from sqlalchemy.sql import expression



class ProviderCategory(Base):
    __tablename__ = "provider_categories"
    __table_args__ = {"schema": "service_providers"}

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(100), unique=True, nullable=False)  # e.g., insurance, garage, mechanic
    providers = relationship("Provider", back_populates="category")


class ServiceCategory(Base):
    __tablename__ = "service_categories"
    __table_args__ = {"schema": "service_providers"}

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(100), unique=True, nullable=False)
    services = relationship("Service", back_populates="category")

class Provider(Base):
    __tablename__ = "providers"
    __table_args__ = {"schema": "service_providers"}

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String(255), nullable=False)
    category_id = Column(Integer, ForeignKey("service_providers.provider_categories.id"))
    description = Column(Text)
    contact_info = Column(JSON)
    location = Column(JSON)
    is_registered = Column(Boolean, default=False)
    rating = Column(Numeric(2,1), default=0.0)
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())

    category = relationship("ProviderCategory", back_populates="providers")
    provider_services = relationship("ProviderService", back_populates="provider")

class Service(Base):
    __tablename__ = "services"
    __table_args__ = {"schema": "service_providers"}

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    category_id = Column(Integer, ForeignKey("service_providers.service_categories.id"))
    name = Column(String(255), nullable=False)
    description = Column(Text)
    requirements = Column(JSON, server_default=expression.text("'{}'::jsonb"))
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())

    category = relationship("ServiceCategory", back_populates="services")
    provider_services = relationship("ProviderService", back_populates="service")

class ProviderService(Base):
    __tablename__ = "provider_services"
    __table_args__ = {"schema": "service_providers"}

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    provider_id = Column(String, ForeignKey("service_providers.providers.id"))
    service_id = Column(String, ForeignKey("service_providers.services.id"))
    display_name = Column(String(255), nullable=True)  # provider-specific alias
    price = Column(String(50))
    duration = Column(String(50))
    booking_required = Column(Boolean, default=False)
    extra_data = Column(JSON, default=dict)

    provider = relationship("Provider", back_populates="provider_services")
    service = relationship("Service", back_populates="provider_services")


class ServiceTemplate(Base):
    __tablename__ = "service_templates"
    __table_args__ = {"schema": "service_providers"}

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    provider_id = Column(String, ForeignKey("service_providers.providers.id"))
    name = Column(String(255), nullable=False)  # e.g., "Standard Oil Service"

    # Instead of raw JSON items, make it a relationship
    items = relationship("ServiceTemplateItem", back_populates="template")


class ServiceTemplateItem(Base):
    __tablename__ = "service_template_items"
    __table_args__ = {"schema": "service_providers"}

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    template_id = Column(String, ForeignKey("service_providers.service_templates.id"))
    service_id = Column(String, ForeignKey("service_providers.services.id"))

    template = relationship("ServiceTemplate", back_populates="items")
    service = relationship("Service")
