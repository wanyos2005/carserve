from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from uuid import UUID

from app.core.db import get_db
from app.schemas.provider import (
    ProviderCreate, Provider, ProviderUpdate, ProviderOut,
    Service as ServiceSchema,  # ✅ alias schema
    ServiceCreate, ServiceUpdate,
    ProviderServiceAttach, ProviderServiceCreate, ServiceTemplateCreate, ServiceTemplateRead
)
from app.schemas.category import (
    ProviderCategory, ProviderCategoryCreate,
    ServiceCategory, ServiceCategoryCreate,
)
from app.models.provider import Service, ServiceTemplate, ProviderService
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


@router.get("/{provider_id}/services", response_model=List[ProviderServiceAttach])
def get_provider_services(provider_id: str, db: Session = Depends(get_db)):
    provider = crud_provider.get_provider(db, provider_id)
    if not provider:
        raise HTTPException(status_code=404, detail="Provider not found")

    return provider.provider_services  # includes both provider-specific fields + service



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
            "display_name": s.display_name,
            "price": s.price,
            "duration": s.duration,
            "booking_required": s.booking_required,
            "extra_data": s.extra_data or {}
        }
        ps = crud_service.upsert_provider_service(db, provider_id, payload)
        created_or_updated.append(ps)

    return created_or_updated

# -----------------------
# Provider Templates
# -----------------------

@router.post("/{provider_id}/templates", response_model=ServiceTemplateRead)
def create_service_template_for_provider(
    provider_id: str,
    payload: ServiceTemplateCreate,
    db: Session = Depends(get_db)
):
    # Ensure provider exists
    provider = crud_provider.get_provider(db, provider_id)
    if not provider:
        raise HTTPException(status_code=404, detail="Provider not found")

    # Ensure provider consistency
    if provider_id != payload.provider_id:
        raise HTTPException(status_code=400, detail="Provider ID mismatch in payload")

    template = crud_provider.create_service_template(db, payload)
    return template


@router.get("/{provider_id}/templates", response_model=List[ServiceTemplateRead])
def list_service_templates_for_provider(
    provider_id: str,
    db: Session = Depends(get_db)
):
    # Ensure provider exists
    provider = crud_provider.get_provider(db, provider_id)
    if not provider:
        raise HTTPException(status_code=404, detail="Provider not found")

    templates = crud_provider.get_service_templates_by_provider(db, provider_id)
    return templates

@router.get("/", response_model=List[ProviderOut])
def list_providers(
    category_id: Optional[int] = Query(None),
    service_ids: Optional[List[str]] = Query(None),
    match_all: bool = Query(False, description="If true, provider must offer ALL services (AND). If false, ANY (OR)."),
    db: Session = Depends(get_db)
):
    query = db.query(Provider)

    if category_id:
        query = query.filter(Provider.category_id == category_id)

    if service_ids:
        query = query.join(Provider.provider_services)
        if match_all:
            for sid in service_ids:
                query = query.filter(
                    Provider.provider_services.any(ProviderService.service_id == sid)
                )
        else:
            query = query.filter(
                Provider.provider_services.any(ProviderService.service_id.in_(service_ids))
            )

    providers = query.distinct().all()

    # Populate enriched ProviderServiceOut
    result = []
    for p in providers:
        result.append({
            "id": p.id,
            "name": p.name,
            "location": p.location,
            "services": [
                {
                    "service_id": ps.service_id,
                    "display_name": ps.display_name,
                    "price": ps.price,
                    "duration": ps.duration,
                    "booking_required": ps.booking_required,
                    "extra_data": ps.extra_data,
                    "service": ps.service
                }
                for ps in p.provider_services
            ]
        })
    return result
