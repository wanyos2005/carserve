from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from uuid import UUID

from app.core.db import get_db
from app.schemas.provider import (
    ProviderCreate, Provider, ProviderUpdate,
    Service as ServiceSchema,  # ✅ alias schema
    ServiceCreate, ServiceUpdate,
    ProviderServiceAttach, ProviderServiceCreate  # ✅ new schema
)
from app.schemas.category import (
    ProviderCategory, ProviderCategoryCreate,
    ServiceCategory, ServiceCategoryCreate,
)
from app.models.provider import Service  # ✅ ORM model
from app.crud import provider as crud_provider
from app.crud import service as crud_service
from app.crud import category as crud_category

router = APIRouter()

# -----------------------
# Categories
# -----------------------
@router.post("/categories/provider-categories", response_model=ProviderCategory)
def create_provider_category(payload: ProviderCategoryCreate, db: Session = Depends(get_db)):
    return crud_category.create_provider_category(db, payload.name)


@router.get("/categories/provider-categories", response_model=List[ProviderCategory])
def list_provider_categories(db: Session = Depends(get_db)):
    return crud_category.list_provider_categories(db)


@router.post("/categories/service-categories", response_model=ServiceCategory)
def create_service_category(payload: ServiceCategoryCreate, db: Session = Depends(get_db)):
    return crud_category.create_service_category(db, payload.name)


@router.get("/categories/service-categories", response_model=List[ServiceCategory])
def list_service_categories(db: Session = Depends(get_db)):
    return crud_category.list_service_categories(db)


# -----------------------
# Global Services
# -----------------------
@router.post("/services", response_model=ServiceSchema)
def create_service(payload: ServiceCreate, db: Session = Depends(get_db)):
    return crud_service.create_service(db, payload)


@router.get("/services", response_model=List[ServiceSchema])
def list_services(
    category_id: Optional[int] = Query(None),
    db: Session = Depends(get_db)
):
    return crud_service.list_services(db=db, category_id=category_id)


@router.get("/services/{service_id}", response_model=ServiceSchema)
def get_service(service_id: str, db: Session = Depends(get_db)):
    s = crud_service.get_service(db, service_id)
    if not s:
        raise HTTPException(status_code=404, detail="Service not found")
    return s


@router.put("/services/{service_id}", response_model=ServiceSchema)
def update_service(service_id: str, updates: ServiceUpdate, db: Session = Depends(get_db)):
    s = crud_service.update_service(db, service_id, updates)
    if not s:
        raise HTTPException(status_code=404, detail="Service not found")
    return s


@router.delete("/services/{service_id}", status_code=204)
def delete_service(service_id: str, db: Session = Depends(get_db)):
    ok = crud_service.delete_service(db, service_id)
    if not ok:
        raise HTTPException(status_code=404, detail="Service not found")
    return {}


# -----------------------
# Providers
# -----------------------
@router.post("/", response_model=Provider)
def create_provider(payload: ProviderCreate, db: Session = Depends(get_db)):
    return crud_provider.create_provider(db, payload)


@router.get("/", response_model=List[Provider])
def list_providers(
    category_id: Optional[int] = Query(None),
    limit: int = 50,
    offset: int = 0,
    db: Session = Depends(get_db)
):
    return crud_provider.list_providers(db=db, category_id=category_id, limit=limit, offset=offset)


# -----------------------
# Provider-specific routes (placed LAST to avoid collisions)
# -----------------------
@router.get("/{provider_id}", response_model=Provider)
def get_provider(provider_id: str, db: Session = Depends(get_db)):
    provider = crud_provider.get_provider(db, provider_id)
    if not provider:
        raise HTTPException(status_code=404, detail="Provider not found")

    services = [ps.service for ps in provider.provider_services]

    return {
        **provider.__dict__,
        "services": services  # ✅ explicit merge
    }



@router.put("/{provider_id}", response_model=Provider)
def update_provider(provider_id: str, updates: ProviderUpdate, db: Session = Depends(get_db)):
    p = crud_provider.update_provider(db, provider_id, updates)
    if not p:
        raise HTTPException(status_code=404, detail="Provider not found")
    return p


@router.delete("/{provider_id}", status_code=204)
def delete_provider(provider_id: str, db: Session = Depends(get_db)):
    ok = crud_provider.delete_provider(db, provider_id)
    if not ok:
        raise HTTPException(status_code=404, detail="Provider not found")
    return {}


@router.get("/{provider_id}/services", response_model=List[ServiceSchema])
def get_provider_services(provider_id: str, db: Session = Depends(get_db)):
    provider = crud_provider.get_provider(db, provider_id)
    if not provider:
        raise HTTPException(status_code=404, detail="Provider not found")

    if not provider.provider_services:
        return []

    service_ids = [ps.service_id for ps in provider.provider_services]
    services = db.query(Service).filter(Service.id.in_(service_ids)).all()  # ✅ ORM model
    return services


@router.post("/{provider_id}/services", response_model=List[ProviderServiceAttach])
def attach_services_to_provider(
    provider_id: str,
    services: List[ProviderServiceCreate],   # <-- INPUT
    db: Session = Depends(get_db)
):
    provider = crud_provider.get_provider(db, provider_id)
    if not provider:
        raise HTTPException(status_code=404, detail="Provider not found")

    created_or_updated = []
    for s in services:
        payload = {
            "service_id": s.service_id,
            "price": s.price,
            "duration": s.duration,
            "booking_required": s.booking_required,
            "extra_data": s.extra_data or {}
        }
        ps = crud_service.upsert_provider_service(db, provider_id, payload)
        created_or_updated.append(ps)

    return created_or_updated
