from sqlalchemy.orm import Session, joinedload
from app.models.provider import Provider, ServiceTemplate, ServiceTemplateItem, ProviderService, ProviderServiceView, ProviderRating
from app.schemas.provider import ProviderCreate, ProviderUpdate, ServiceTemplateCreate, ProviderRatingCreate
from typing import List, Optional
from uuid import UUID
from sqlalchemy import func, distinct
from datetime import datetime


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


# -----------------------
# Ratings
# -----------------------
def create_provider_rating(db: Session, provider_id: str, payload: ProviderRatingCreate):
    # Clamp rating between 1 and 5
    r_value = max(1, min(5, payload.rating))
    
    # Check for existing rating to prevent duplicates
    # Priority: log_id > booking_id > user+provider (general rating)
    existing_rating = None
    if payload.log_id:
        # Check for rating on this specific service log
        existing_rating = db.query(ProviderRating).filter(
            ProviderRating.provider_id == provider_id,
            ProviderRating.user_id == payload.user_id,
            ProviderRating.log_id == payload.log_id
        ).first()
    elif payload.booking_id:
        # Check for rating on this specific booking
        existing_rating = db.query(ProviderRating).filter(
            ProviderRating.provider_id == provider_id,
            ProviderRating.user_id == payload.user_id,
            ProviderRating.booking_id == payload.booking_id
        ).first()
    else:
        # For general ratings without log_id/booking_id, check if rated recently (within 24 hours)
        # This prevents spam but allows re-rating after some time
        from datetime import datetime, timedelta
        recent_threshold = datetime.utcnow() - timedelta(hours=24)
        existing_rating = db.query(ProviderRating).filter(
            ProviderRating.provider_id == provider_id,
            ProviderRating.user_id == payload.user_id,
            ProviderRating.log_id.is_(None),
            ProviderRating.booking_id.is_(None),
            ProviderRating.created_at >= recent_threshold
        ).first()
    
    if existing_rating:
        # Update existing rating instead of creating duplicate
        existing_rating.rating = r_value
        existing_rating.comment = payload.comment
        existing_rating.updated_at = datetime.utcnow()
        r = existing_rating
    else:
        # Create new rating
        r = ProviderRating(
            provider_id=provider_id,
            user_id=payload.user_id,
            booking_id=payload.booking_id,
            log_id=payload.log_id,
            rating=r_value,
            comment=payload.comment,
        )
        db.add(r)
    
    db.flush()

    # Recompute provider average rating from ratings table
    avg = db.query(func.avg(ProviderRating.rating)).filter(ProviderRating.provider_id == provider_id).scalar()
    p = db.query(Provider).filter(Provider.id == provider_id).first()
    if p:
        try:
            p.rating = round(float(avg or 0.0), 1)
        except Exception:
            p.rating = 0.0
    
    # Optionally notify alert service that rating was submitted (fire-and-forget)
    # This allows the alert service to track completion but doesn't block the rating submission
    try:
        import os
        import httpx
        alert_service_url = os.getenv("ALERT_SERVICE_URL", "http://alert-service:8006")
        # If we have log_id or booking_id, we can find and mark the related alert as acted upon
        # For now, just log that rating was submitted
        with httpx.Client(timeout=2.0) as client:
            # This is a fire-and-forget notification - we don't wait for response
            try:
                client.post(
                    f"{alert_service_url}/alerts/rating-submitted",
                    json={
                        "user_id": payload.user_id,
                        "provider_id": provider_id,
                        "log_id": payload.log_id,
                        "booking_id": payload.booking_id,
                        "rating": r_value,
                    },
                    timeout=1.0
                )
            except Exception:
                # Silently fail - this is just for tracking, not critical
                pass
    except Exception:
        # If alert service is unavailable, just continue - rating submission should succeed
        pass
    
    db.commit()
    db.refresh(r)
    return r

def list_provider_ratings(db: Session, provider_id: str):
    return (
        db.query(ProviderRating)
        .filter(ProviderRating.provider_id == provider_id)
        .order_by(ProviderRating.created_at.desc())
        .all()
    )
