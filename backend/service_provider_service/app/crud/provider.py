from sqlalchemy.orm import Session, joinedload
from app.models.provider import Provider, ServiceTemplate, ServiceTemplateItem, ProviderService, ProviderServiceView
from app.schemas.provider import ProviderCreate, ProviderUpdate, ServiceTemplateCreate
from typing import List, Optional
from uuid import UUID
from sqlalchemy import func, distinct


def create_provider(db: Session, provider_in: ProviderCreate) -> Provider:
    provider = Provider(
        name=provider_in.name,
        category_id=provider_in.category_id,
        description=provider_in.description,
        contact_info=provider_in.contact_info,
        location=provider_in.location,
        is_registered=provider_in.is_registered,
    )
    db.add(provider)
    db.commit()
    db.refresh(provider)
    return provider

def get_provider_by_name(db: Session, name: str):
    return db.query(Provider).filter(Provider.name.ilike(name)).first()


def get_provider(db: Session, provider_id: str) -> Optional[Provider]:
    return db.query(Provider).filter(Provider.id == provider_id).first()


def list_providers(db: Session, category_id: Optional[int] = None, limit: int = 50, offset: int = 0):
    q = db.query(Provider)
    if category_id:
        q = q.filter(Provider.category_id == category_id)
    return q.offset(offset).limit(limit).all()


def delete_provider(db: Session, provider_id: str):
    p = db.query(Provider).filter(Provider.id == provider_id).first()
    if not p:
        return False
    db.delete(p)
    db.commit()
    return True


def update_provider(db: Session, provider_id: str, updates: ProviderUpdate):
    p = db.query(Provider).filter(Provider.id == provider_id).first()
    if not p:
        return None
    for k, v in updates.dict(exclude_unset=True).items():
        setattr(p, k, v)
    db.commit()
    db.refresh(p)
    return p

def create_service_template(db: Session, payload: ServiceTemplateCreate):
    # Create template
    template = ServiceTemplate(
        provider_id=payload.provider_id,
        name=payload.name,
    )
    db.add(template)
    db.flush()  # ensures template.id is available before inserting items

    # Create items
    items = [ServiceTemplateItem(template_id=template.id, service_id=item.service_id) for item in payload.items]
    db.add_all(items)
    db.commit()
    db.refresh(template)
    return template


def get_service_templates_by_provider(db: Session, provider_id: str):
    return (
        db.query(ServiceTemplate)
        .filter(ServiceTemplate.provider_id == provider_id)
        .all()
    )

def get_providers_by_service(db: Session, service_id: str):
    return (
        db.query(Provider)
        .join(Provider.provider_services)  # inner join
        .filter(ProviderService.service_id == service_id)
        .options(joinedload(Provider.provider_services).joinedload(ProviderService.service))
        .all()
    )

def search_provider_view(
    db: Session,
    service_ids: list[str] | None = None,
    match_all: bool = False,
    search_term: str | None = None,
    category_id: int | None = None,
):
    # Use the database view for better performance
    q = db.query(ProviderServiceView)

    # Filter by provider category
    if category_id is not None:
        q = q.filter(ProviderServiceView.provider_category_id == category_id)

    # Search term
    if search_term:
        pattern = f"%{search_term.lower()}%"
        q = q.filter(
            func.lower(ProviderServiceView.provider_name).ilike(pattern)
            | func.lower(ProviderServiceView.service_name).ilike(pattern)
            | func.lower(ProviderServiceView.provider_description).ilike(pattern)
        )

    # Service filter
    if service_ids:
        if match_all:
            subq = (
                db.query(
                    ProviderServiceView.provider_id,
                    func.count(func.distinct(ProviderServiceView.service_id)).label("service_count")
                )
                .filter(ProviderServiceView.service_id.in_(service_ids))
                .group_by(ProviderServiceView.provider_id)
                .having(func.count(func.distinct(ProviderServiceView.service_id)) == len(service_ids))
                .subquery()
            )
            q = q.join(subq, ProviderServiceView.provider_id == subq.c.provider_id)
        else:
            q = q.filter(ProviderServiceView.service_id.in_(service_ids))

    print(q.statement.compile(compile_kwargs={"literal_binds": True}))
    results = q.all()
    print(f"Query returned {len(results)} rows")
    # Debug: Check for None rows
    none_count = sum(1 for r in results if r is None)
    if none_count > 0:
        print(f"WARNING: Found {none_count} None rows in results")
    return results
