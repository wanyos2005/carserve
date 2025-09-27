from sqlalchemy.orm import Session
from app.models.provider import Service
from app.schemas.provider import ServiceCreate, ServiceUpdate
from typing import Optional
from uuid import UUID


def create_service(db: Session, provider_id: UUID, service_in: ServiceCreate) -> Service:
    service = Service(
        provider_id=provider_id,
        category_id=service_in.category_id,
        name=service_in.name,
        description=service_in.description,
        price_range=service_in.price_range,
        requirements=service_in.requirements or {}
    )
    db.add(service)
    db.commit()
    db.refresh(service)
    return service


def get_service(db: Session, service_id: UUID) -> Optional[Service]:
    return db.query(Service).filter(Service.id == service_id).first()


def delete_service(db: Session, service_id: UUID) -> bool:
    s = db.query(Service).filter(Service.id == service_id).first()
    if not s:
        return False
    db.delete(s)
    db.commit()
    return True


def update_service(db: Session, service_id: UUID, updates: ServiceUpdate):
    s = db.query(Service).filter(Service.id == service_id).first()
    if not s:
        return None
    for k, v in updates.dict(exclude_unset=True).items():
        setattr(s, k, v)
    db.commit()
    db.refresh(s)
    return s
