from sqlalchemy.orm import Session
from app.models.provider import Service, ProviderService
from app.schemas.provider import ServiceCreate, ServiceUpdate
from typing import Optional, List, Dict
from uuid import UUID



def create_service(db: Session, service_in: ServiceCreate) -> Service:
    service = Service(
        category_id=service_in.category_id,
        name=service_in.name,
        description=service_in.description,
        requirements=service_in.requirements
    )
    db.add(service)
    db.commit()
    db.refresh(service)
    return service


def get_service(db: Session, service_id: UUID) -> Optional[Service]:
    return db.query(Service).filter(Service.id == service_id).first()


def list_services(db: Session, category_id: Optional[int] = None, limit: int = 50, offset: int = 0):
    q = db.query(Service)
    if category_id:
        q = q.filter(Service.category_id == category_id)
    return q.offset(offset).limit(limit).all()


def update_service(db: Session, service_id: UUID, updates: ServiceUpdate):
    s = db.query(Service).filter(Service.id == service_id).first()
    if not s:
        return None
    for k, v in updates.dict(exclude_unset=True).items():
        setattr(s, k, v)
    db.commit()
    db.refresh(s)
    return s


def delete_service(db: Session, service_id: UUID) -> bool:
    s = db.query(Service).filter(Service.id == service_id).first()
    if not s:
        return False
    db.delete(s)
    db.commit()
    return True

def create_provider_service(db: Session, provider_id: UUID, payload: Dict) -> ProviderService:
    ps = ProviderService(
        provider_id=provider_id,
        service_id=payload.get("service_id"),
        price=payload.get("price"),
        duration=payload.get("duration"),
        booking_required=payload.get("booking_required", False),
        metadata=payload.get("metadata") or {}
    )
    db.add(ps)
    db.commit()
    db.refresh(ps)
    return ps

def get_provider_services(db: Session, provider_id: UUID) -> List[ProviderService]:
    return db.query(ProviderService).filter(ProviderService.provider_id == provider_id).all()

def upsert_provider_service(db: Session, provider_id: UUID, payload: Dict):
    # payload contains service_id and metadata, price etc.
    q = db.query(ProviderService).filter(
        ProviderService.provider_id == provider_id,
        ProviderService.service_id == payload["service_id"]
    )
    existing = q.first()
    if existing:
        # update
        for k in ["price", "duration", "booking_required", "metadata"]:
            if k in payload:
                setattr(existing, k, payload.get(k))
        db.commit()
        db.refresh(existing)
        return existing
    else:
        return create_provider_service(db, provider_id, payload)
