from sqlalchemy.orm import Session
from app.models.provider import Provider, Service
from app.schemas.provider import ProviderCreate, ServiceCreate, ProviderUpdate
from typing import List, Optional
from uuid import UUID


def create_provider(db: Session, provider_in: ProviderCreate) -> Provider:
    provider = Provider(
        name=provider_in.name,
        category_id=provider_in.category_id,
        description=provider_in.description,
        contact_info=provider_in.contact_info,
        location=provider_in.location,
        is_registered=provider_in.is_registered
    )
    db.add(provider)
    db.flush()  # ensures provider.id is available

    for sv in provider_in.services or []:
        service = Service(
            provider_id=provider.id,
            category_id=sv.category_id,
            name=sv.name,
            description=sv.description,
            price_range=sv.price_range,
            requirements=sv.requirements or {}
        )
        db.add(service)

    db.commit()
    db.refresh(provider)
    return provider


def get_provider(db: Session, provider_id: UUID) -> Optional[Provider]:
    return db.query(Provider).filter(Provider.id == provider_id).first()


def list_providers(db: Session, category_id: Optional[int] = None, limit: int = 50, offset: int = 0):
    q = db.query(Provider)
    if category_id:
        q = q.filter(Provider.category_id == category_id)
    return q.offset(offset).limit(limit).all()


def delete_provider(db: Session, provider_id: UUID):
    p = db.query(Provider).filter(Provider.id == provider_id).first()
    if not p:
        return False
    db.delete(p)
    db.commit()
    return True


def update_provider(db: Session, provider_id: UUID, updates: ProviderUpdate):
    p = db.query(Provider).filter(Provider.id == provider_id).first()
    if not p:
        return None
    for k, v in updates.dict(exclude_unset=True).items():
        setattr(p, k, v)
    db.commit()
    db.refresh(p)
    return p
