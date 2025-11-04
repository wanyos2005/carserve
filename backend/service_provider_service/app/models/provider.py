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
    # No explicit relationship to ratings to avoid heavy lazy loads

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
    
    # Legacy price field (kept for backward compatibility and display)
    price = Column(String(50))
    
    # New structured pricing fields
    min_price = Column(Numeric(10, 2), nullable=True)
    max_price = Column(Numeric(10, 2), nullable=True)
    price_type = Column(String(20), default='range')  # fixed, range, per_unit, free, variable
    currency = Column(String(3), default='KES')
    unit = Column(String(20), nullable=True)  # per_liter, per_hour, etc.
    negotiable = Column(Boolean, default=True)
    
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


class ProviderServiceView(Base):
    __tablename__ = "provider_service_view"
    __table_args__ = {"schema": "service_providers"}
    __mapper_args__ = {"primary_key": ["provider_service_id"]}

    provider_id = Column(String)
    provider_name = Column(String)
    provider_category_id = Column(Integer)
    provider_description = Column(Text)
    provider_contact_info = Column(JSON)
    provider_location = Column(JSON)
    provider_rating = Column(Numeric(2, 1))
    provider_is_registered = Column(Boolean)
    provider_created_at = Column(TIMESTAMP(timezone=True))

    provider_service_id = Column(String)
    display_name = Column(String)
    price = Column(String)  # Legacy field
    min_price = Column(Numeric(10, 2))
    max_price = Column(Numeric(10, 2))
    price_type = Column(String(20))
    currency = Column(String(3))
    unit = Column(String(20))
    negotiable = Column(Boolean)
    duration = Column(String)
    booking_required = Column(Boolean)
    extra_data = Column(JSON)
    service_id = Column(String)
    service_name = Column(String)
    service_category_id = Column(Integer)
    service_description = Column(Text)
    service_requirements = Column(JSON)
    
    # Category names for better readability
    provider_category_name = Column(String)
    service_category_name = Column(String)




# New table to store individual provider ratings
class ProviderRating(Base):
    __tablename__ = "provider_ratings"
    __table_args__ = {"schema": "service_providers"}

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    provider_id = Column(String, ForeignKey("service_providers.providers.id"), index=True, nullable=False)
    user_id = Column(Integer, index=True, nullable=False)
    booking_id = Column(String, index=True, nullable=True)
    log_id = Column(String, index=True, nullable=True)  # Service log ID this rating is for
    rating = Column(Integer, nullable=False)  # 1-5
    comment = Column(Text, nullable=True)
    created_at = Column(TIMESTAMP(timezone=True), server_default=func.now())
    updated_at = Column(TIMESTAMP(timezone=True), server_default=func.now(), onupdate=func.now())

