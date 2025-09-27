#backend/service_provider_service/app/routers/providers.py
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
from uuid import UUID

from app.core.db import get_db
from app.schemas.provider import ProviderCreate, Provider, ProviderUpdate, Service, ServiceCreate, ServiceUpdate
from app.schemas.category import (
    ProviderCategory, ProviderCategoryCreate,
    ServiceCategory, ServiceCategoryCreate
)
from app.crud import provider as crud_provider
from app.crud import service as crud_service
from app.crud import category as crud_category

router = APIRouter()


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


@router.get("/{provider_id}", response_model=Provider)
def get_provider(provider_id: UUID, db: Session = Depends(get_db)):
    p = crud_provider.get_provider(db, provider_id)
    if not p:
        raise HTTPException(status_code=404, detail="Provider not found")
    return p


@router.put("/{provider_id}", response_model=Provider)
def update_provider(provider_id: UUID, updates: ProviderUpdate, db: Session = Depends(get_db)):
    p = crud_provider.update_provider(db, provider_id, updates)
    if not p:
        raise HTTPException(status_code=404, detail="Provider not found")
    return p


@router.delete("/{provider_id}", status_code=204)
def delete_provider(provider_id: UUID, db: Session = Depends(get_db)):
    ok = crud_provider.delete_provider(db, provider_id)
    if not ok:
        raise HTTPException(status_code=404, detail="Provider not found")
    return {}


# -----------------------
# Services
# -----------------------
@router.post("/{provider_id}/services", response_model=Service)
def create_service(provider_id: UUID, payload: ServiceCreate, db: Session = Depends(get_db)):
    return crud_service.create_service(db, provider_id, payload)


@router.get("/services/{service_id}", response_model=Service)
def get_service(service_id: UUID, db: Session = Depends(get_db)):
    s = crud_service.get_service(db, service_id)
    if not s:
        raise HTTPException(status_code=404, detail="Service not found")
    return s


@router.put("/services/{service_id}", response_model=Service)
def update_service(service_id: UUID, updates: ServiceUpdate, db: Session = Depends(get_db)):
    s = crud_service.update_service(db, service_id, updates)
    if not s:
        raise HTTPException(status_code=404, detail="Service not found")
    return s


@router.delete("/services/{service_id}", status_code=204)
def delete_service(service_id: UUID, db: Session = Depends(get_db)):
    ok = crud_service.delete_service(db, service_id)
    if not ok:
        raise HTTPException(status_code=404, detail="Service not found")
    return {}


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
