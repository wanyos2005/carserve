from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from uuid import UUID

from sqlalchemy.dialects import postgresql


from app.core.db import get_db
from app.schemas.provider import (
    ProviderCreate, Provider, ProviderUpdate, ProviderOut,
    Service as ServiceSchema,  # ✅ alias schema
    ServiceCreate, ServiceUpdate, ProviderQuickCreate, ProviderQuickOut,
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


def debug_query(q):
    print(q.statement.compile(dialect=postgresql.dialect(), compile_kwargs={"literal_binds": True}))

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

DEFAULT_CATEGORY_ID = 6  # Default category for quick-created providers


@router.post("/quick-provider", response_model=ProviderQuickOut)
def quick_create_provider(payload: ProviderQuickCreate, db: Session = Depends(get_db)):
    """
    Quickly create a minimal provider with just a name.
    Other details can be added later via the full update route.
    """
    name = payload.name.strip()
    if not name:
        raise HTTPException(status_code=400, detail="Provider name cannot be empty")

    # Check if provider already exists (case-insensitive)
    existing = crud_provider.get_provider_by_name(db, name)
    if existing:
        return existing

    provider_data = {
        "name": name,
        "category_id": DEFAULT_CATEGORY_ID,
        "is_registered": False,
        "description": None,
        "contact_info": {},
        "location": {},
    }

    new_provider = crud_provider.create_provider(db, provider_data)
    return new_provider

@router.get("/providers/")
def search_providers(
    db: Session = Depends(get_db),
    service_ids: list[str] = Query(None),
    match_all: bool = Query(False),
    search: str = Query(None),
):
    rows = crud_provider.search_provider_view(db, service_ids, match_all, search)

    # optional: group results by provider for frontend structure
    grouped = {}
    for r in rows:
        if r.provider_id not in grouped:
            grouped[r.provider_id] = {
                "provider_id": r.provider_id,
                "provider_name": r.provider_name,
                "services": []
            }
        grouped[r.provider_id]["services"].append({
            "service_id": r.service_id,
            "service_name": r.service_name,
            "price": r.price,
            "display_name": r.display_name,
        })

    return list(grouped.values())

# -----------------------
# Provider-specific routes (placed LAST to avoid collisions)
# -----------------------
@router.get("/{provider_id}", response_model=Provider)
def get_provider(provider_id: str, db: Session = Depends(get_db)):
    provider = crud_provider.get_provider(db, provider_id)
    if not provider:
        raise HTTPException(status_code=404, detail="Provider not found")
    return provider

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

<<<<<<< HEAD
=======

@router.get("/providers/")
def search_providers(
    db: Session = Depends(get_db),
    service_ids: list[str] = Query(None),
    match_all: bool = Query(False),
    search: str = Query(None),
    category_id: int | None = Query(None),
    
):
    rows = crud_provider.search_provider_view(
        db,
        service_ids,
        match_all,
        search,
        category_id,
    )

    grouped = {}
    for r in rows:
        if r.provider_id not in grouped:
            grouped[r.provider_id] = {
                 "provider_id": r.provider_id,
                "provider_name": r.provider_name,
                "description": r.provider_description,
                "contact_info": r.provider_contact_info,
                "location": r.provider_location,
                "rating": float(r.provider_rating) if r.provider_rating else 0.0,
                "is_registered": r.provider_is_registered,
                "created_at": r.provider_created_at,
                "services": []
            }
        grouped[r.provider_id]["services"].append({
            "service_id": r.service_id,
            "service_name": r.service_name,
            "price": r.price,
            "display_name": r.display_name,
        })

    return list(grouped.values())
>>>>>>> e4bcbc43991ac392a637d383e35dbeb3f7585d6b
