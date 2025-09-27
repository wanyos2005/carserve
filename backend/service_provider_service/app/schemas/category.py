
# backend/service_provider_service/app/schemas/category.py
from pydantic import BaseModel
from typing import List


class ProviderCategoryBase(BaseModel):
    name: str


class ProviderCategoryCreate(ProviderCategoryBase):
    pass


class ProviderCategory(ProviderCategoryBase):
    id: int

    class Config:
        from_attributes = True


class ServiceCategoryBase(BaseModel):
    name: str


class ServiceCategoryCreate(ServiceCategoryBase):
    pass


class ServiceCategory(ServiceCategoryBase):
    id: int

    class Config:
        from_attributes = True

