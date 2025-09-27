from sqlalchemy.orm import Session
from app.models.provider import ProviderCategory, ServiceCategory
from typing import List, Optional
from sqlalchemy.exc import IntegrityError

# -----------------------
# ProviderCategory CRUD
# -----------------------
def create_provider_category(db: Session, name: str) -> ProviderCategory:
    category = ProviderCategory(name=name)
    db.add(category)
    try:
        db.commit()
        db.refresh(category)
        return category
    except IntegrityError:
        db.rollback()
        return db.query(ProviderCategory).filter_by(name=name).first()


def list_provider_categories(db: Session) -> List[ProviderCategory]:
    return db.query(ProviderCategory).all()


# -----------------------
# ServiceCategory CRUD
# -----------------------
def create_service_category(db: Session, name: str) -> ServiceCategory:
    category = ServiceCategory(name=name)
    db.add(category)
    db.commit()
    db.refresh(category)
    return category


def list_service_categories(db: Session) -> List[ServiceCategory]:
    return db.query(ServiceCategory).all()
