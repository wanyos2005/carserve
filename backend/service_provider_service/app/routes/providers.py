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
from app.models.provider import Service as ServiceModel, ServiceTemplate, ProviderService, Provider as ProviderModel, ServiceCategory as ServiceCategoryModel, ProviderCategory as ProviderCategoryModel
from app.crud import provider as crud_provider
from app.crud import service as crud_service
from app.crud import category as crud_category
from sqlalchemy import text
import httpx

router = APIRouter()

# -----------------------
# Statistics
# -----------------------
@router.get("/stats")
def get_provider_stats(db: Session = Depends(get_db)):
    """Get service provider statistics"""
    from sqlalchemy import func
    
    # Total providers count
    total_providers = db.query(ProviderModel).count()
    
    # Active providers count (assuming is_registered means active)
    active_providers = db.query(ProviderModel).filter(ProviderModel.is_registered == True).count()
    
    # Total service categories count
    total_categories = db.query(ServiceCategoryModel).count()
    
    # Total global services count
    total_services = db.query(ServiceModel).count()
    
    # Provider categories count
    provider_categories = db.query(ProviderCategoryModel).count()
    
    return {
        "total_providers": total_providers,
        "active_providers": active_providers,
        "inactive_providers": total_providers - active_providers,
        "service_categories": total_categories,
        "provider_categories": provider_categories,
        "total_services": total_services
    }


@router.get("/{provider_id}/stats")
def get_provider_dashboard_stats(provider_id: str, db: Session = Depends(get_db)):
    """Get provider-specific dashboard statistics"""
    from sqlalchemy import func
    from datetime import datetime, timedelta
    import httpx
    import os
    
    # Ensure provider exists
    provider = crud_provider.get_provider(db, provider_id)
    if not provider:
        raise HTTPException(status_code=404, detail="Provider not found")
    
    # Get provider category to determine stats type
    category_name = provider.category.name.lower() if provider.category else ""
    
    # Initialize base stats
    stats = {
        "rating": float(provider.rating) if provider.rating else 0.0,
        "provider_type": category_name,
        "provider_name": provider.name
    }
    
    # Get today's date for filtering
    today = datetime.utcnow().date()
    
    try:
        if "insurance" in category_name:
            # Insurance partner stats
            stats.update(_get_insurance_partner_stats(provider_id, today))
        elif "fuel" in category_name:
            # Fuel station stats
            stats.update(_get_fuel_station_stats(provider_id, today))
        elif "car wash" in category_name or "detailing" in category_name:
            # Car wash stats
            stats.update(_get_car_wash_stats(provider_id, today))
        elif "spare parts" in category_name or "parts" in category_name:
            # Spare parts dealer stats
            stats.update(_get_spare_parts_stats(provider_id, today))
        else:
            # Default garage/mechanic stats
            stats.update(_get_garage_stats(provider_id, today))
            
    except Exception as e:
        print(f"Error fetching provider stats: {e}")
        # Return default stats if external service fails
        stats.update(_get_default_stats(category_name))
    
    print(f"Returning stats for provider {provider_id}: {stats}")
    return stats


def _get_insurance_partner_stats(provider_id: str, today) -> dict:
    """Get insurance partner specific statistics"""
    import httpx
    import os
    
    stats = {
        "active_policies": 0,
        "todays_revenue": 0,
        "pending_claims": 0,
        "total_policies": 0,
        "total_claims": 0,
        "revenue_today": 0
    }
    
    try:
        insurance_service_url = os.getenv("INSURANCE_SERVICE_URL", "http://insurance-service:8005")
        print(f"Fetching insurance stats for provider {provider_id} from {insurance_service_url}")
        
        with httpx.Client(timeout=5.0) as client:
            # Get policies for this insurance partner
            policies_response = client.get(f"{insurance_service_url}/policies?provider_id={provider_id}")
            if policies_response.status_code == 200:
                policies = policies_response.json()
                active_policies = [p for p in policies if p.get('status') == 'active']
                stats["active_policies"] = len(active_policies)
                stats["total_policies"] = len(policies)
            
            # Get claims for this insurance partner
            claims_response = client.get(f"{insurance_service_url}/claims?provider_id={provider_id}")
            if claims_response.status_code == 200:
                claims = claims_response.json()
                pending_claims = [c for c in claims if c.get('status') in ['submitted', 'under_review']]
                stats["pending_claims"] = len(pending_claims)
                stats["total_claims"] = len(claims)
                
                # Calculate today's revenue from claims
                today_claims = []
                for claim in claims:
                    if claim.get('payment_date'):
                        from datetime import datetime
                        claim_date = datetime.fromisoformat(claim['payment_date'].replace('Z', '+00:00')).date()
                        if claim_date == today:
                            today_claims.append(claim)
                
                revenue_today = 0
                for claim in today_claims:
                    if claim.get('approved_amount'):
                        revenue_today += int(claim['approved_amount'])
                
                stats["todays_revenue"] = revenue_today
                stats["revenue_today"] = revenue_today
                
    except Exception as e:
        print(f"Error fetching insurance stats: {e}")
    
    return stats


def _get_fuel_station_stats(provider_id: str, today) -> dict:
    """Get fuel station specific statistics"""
    import httpx
    import os
    
    stats = {
        "fuel_sales_liters": 0,
        "todays_revenue": 0,
        "inventory_alerts": 0,
        "total_sales_today": 0,
        "low_stock_items": 0
    }
    
    try:
        # For fuel stations, we might need to integrate with a fuel management system
        # For now, we'll use service logs to track fuel sales
        booking_service_url = os.getenv("BOOKING_SERVICE_URL", "http://booking-service:8004")
        
        with httpx.Client(timeout=5.0) as client:
            # Get service logs for fuel services
            service_logs_response = client.get(f"{booking_service_url}/service-logs/provider/{provider_id}")
            if service_logs_response.status_code == 200:
                service_logs = service_logs_response.json()
                
                # Filter today's fuel service logs
                today_logs = []
                for log in service_logs:
                    if log.get('performed_at'):
                        from datetime import datetime
                        log_date = datetime.fromisoformat(log['performed_at'].replace('Z', '+00:00')).date()
                        if log_date == today and 'fuel' in log.get('service_name', '').lower():
                            today_logs.append(log)
                
                stats["total_sales_today"] = len(today_logs)
                
                # Calculate fuel sales and revenue
                total_liters = 0
                total_revenue = 0
                for log in today_logs:
                    if log.get('cost'):
                        total_revenue += int(log['cost'])
                    # Extract liters from service items if available
                    service_items = log.get('service_items', {})
                    if 'liters' in service_items:
                        total_liters += int(service_items['liters'])
                
                stats["fuel_sales_liters"] = total_liters
                stats["todays_revenue"] = total_revenue
                
                # Mock inventory alerts (would come from inventory system)
                stats["inventory_alerts"] = 2  # Mock value
                stats["low_stock_items"] = 2
                
    except Exception as e:
        print(f"Error fetching fuel station stats: {e}")
    
    return stats


def _get_car_wash_stats(provider_id: str, today) -> dict:
    """Get car wash specific statistics"""
    import httpx
    import os
    
    stats = {
        "todays_services": 0,
        "todays_revenue": 0,
        "queue_length": 0,
        "completed_services": 0
    }
    
    try:
        booking_service_url = os.getenv("BOOKING_SERVICE_URL", "http://booking-service:8004")
        
        with httpx.Client(timeout=5.0) as client:
            # Get service logs for car wash services
            service_logs_response = client.get(f"{booking_service_url}/service-logs/provider/{provider_id}")
            if service_logs_response.status_code == 200:
                service_logs = service_logs_response.json()
                
                # Filter today's car wash service logs
                today_logs = []
                for log in service_logs:
                    if log.get('performed_at'):
                        from datetime import datetime
                        log_date = datetime.fromisoformat(log['performed_at'].replace('Z', '+00:00')).date()
                        if log_date == today and ('wash' in log.get('service_name', '').lower() or 'detailing' in log.get('service_name', '').lower()):
                            today_logs.append(log)
                
                stats["todays_services"] = len(today_logs)
                stats["completed_services"] = len(today_logs)
                
                # Calculate today's revenue
                total_revenue = 0
                for log in today_logs:
                    if log.get('cost'):
                        total_revenue += int(log['cost'])
                
                stats["todays_revenue"] = total_revenue
                
                # Get queue length from active bookings
                bookings_response = client.get(f"{booking_service_url}/provider/{provider_id}")
                if bookings_response.status_code == 200:
                    bookings = bookings_response.json()
                    queue_bookings = [b for b in bookings if b.get('status') in ['pending', 'confirmed']]
                    stats["queue_length"] = len(queue_bookings)
                
    except Exception as e:
        print(f"Error fetching car wash stats: {e}")
    
    return stats


def _get_spare_parts_stats(provider_id: str, today) -> dict:
    """Get spare parts dealer specific statistics"""
    import httpx
    import os
    
    stats = {
        "active_orders": 0,
        "todays_sales": 0,
        "low_stock": 0,
        "total_orders_today": 0,
        "revenue_today": 0
    }
    
    try:
        booking_service_url = os.getenv("BOOKING_SERVICE_URL", "http://booking-service:8004")
        
        with httpx.Client(timeout=5.0) as client:
            # Get service logs for parts sales
            service_logs_response = client.get(f"{booking_service_url}/service-logs/provider/{provider_id}")
            if service_logs_response.status_code == 200:
                service_logs = service_logs_response.json()
                
                # Filter today's parts service logs
                today_logs = []
                for log in service_logs:
                    if log.get('performed_at'):
                        from datetime import datetime
                        log_date = datetime.fromisoformat(log['performed_at'].replace('Z', '+00:00')).date()
                        if log_date == today and ('parts' in log.get('service_name', '').lower() or 'spare' in log.get('service_name', '').lower()):
                            today_logs.append(log)
                
                stats["total_orders_today"] = len(today_logs)
                
                # Calculate today's sales
                total_sales = 0
                for log in today_logs:
                    if log.get('cost'):
                        total_sales += int(log['cost'])
                
                stats["todays_sales"] = total_sales
                stats["revenue_today"] = total_sales
                
                # Get active orders from bookings
                bookings_response = client.get(f"{booking_service_url}/provider/{provider_id}")
                if bookings_response.status_code == 200:
                    bookings = bookings_response.json()
                    active_orders = [b for b in bookings if b.get('status') in ['pending', 'confirmed', 'in_progress']]
                    stats["active_orders"] = len(active_orders)
                
                # Mock low stock (would come from inventory system)
                stats["low_stock"] = 7  # Mock value
                
    except Exception as e:
        print(f"Error fetching spare parts stats: {e}")
    
    return stats


def _get_garage_stats(provider_id: str, today) -> dict:
    """Get garage/mechanic specific statistics"""
    import httpx
    import os
    
    stats = {
        "active_bookings": 0,
        "todays_earnings": 0,
        "pending_tasks": 0,
        "total_services_today": 0,
        "completed_services_today": 0
    }
    
    try:
        booking_service_url = os.getenv("BOOKING_SERVICE_URL", "http://booking-service:8004")
        print(f"Fetching garage stats for provider {provider_id} from {booking_service_url}")
        
        with httpx.Client(timeout=5.0) as client:
            # Get provider's bookings
            bookings_response = client.get(f"{booking_service_url}/provider/{provider_id}")
            if bookings_response.status_code == 200:
                bookings = bookings_response.json()
                active_bookings = [b for b in bookings if b.get('status') in ['pending', 'confirmed', 'in_progress']]
                stats["active_bookings"] = len(active_bookings)
            
            # Get service logs for this provider
            service_logs_response = client.get(f"{booking_service_url}/service-logs/provider/{provider_id}")
            if service_logs_response.status_code == 200:
                service_logs = service_logs_response.json()
                
                # Filter today's service logs
                today_logs = []
                for log in service_logs:
                    if log.get('performed_at'):
                        from datetime import datetime
                        log_date = datetime.fromisoformat(log['performed_at'].replace('Z', '+00:00')).date()
                        if log_date == today:
                            today_logs.append(log)
                
                stats["total_services_today"] = len(today_logs)
                stats["completed_services_today"] = len(today_logs)
                
                # Calculate today's earnings
                total_earnings = 0
                for log in today_logs:
                    if log.get('cost'):
                        total_earnings += int(log['cost'])
                
                stats["todays_earnings"] = total_earnings
                
                # Calculate pending tasks (bookings + incomplete service logs)
                pending_tasks = stats["active_bookings"] + len([log for log in service_logs if not log.get('performed_at')])
                stats["pending_tasks"] = pending_tasks
                
    except Exception as e:
        print(f"Error fetching garage stats: {e}")
    
    return stats


def _get_default_stats(category_name: str) -> dict:
    """Get default stats when external services fail"""
    if "insurance" in category_name:
        return {
            "active_policies": 0,
            "todays_revenue": 0,
            "pending_claims": 0,
            "total_policies": 0,
            "total_claims": 0,
            "revenue_today": 0
        }
    elif "fuel" in category_name:
        return {
            "fuel_sales_liters": 0,
            "todays_revenue": 0,
            "inventory_alerts": 0,
            "total_sales_today": 0,
            "low_stock_items": 0
        }
    elif "car wash" in category_name or "detailing" in category_name:
        return {
            "todays_services": 0,
            "todays_revenue": 0,
            "queue_length": 0,
            "completed_services": 0
        }
    elif "spare parts" in category_name or "parts" in category_name:
        return {
            "active_orders": 0,
            "todays_sales": 0,
            "low_stock": 0,
            "total_orders_today": 0,
            "revenue_today": 0
        }
    else:
        return {
            "active_bookings": 0,
            "todays_earnings": 0,
            "pending_tasks": 0,
            "total_services_today": 0,
            "completed_services_today": 0
        }

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
# Services with categories (DB view)
# -----------------------
@router.get("/services-with-categories")
def list_services_with_categories(db: Session = Depends(get_db)):
    """
    Read-only endpoint backed by the DB view service_providers.services_with_categories.
    Returns service + category fields in a flattened shape for consumers.
    """
    rows = db.execute(text(
        """
        SELECT 
            service_id,
            service_name,
            service_description,
            service_requirements,
            service_created_at,
            service_category_id,
            service_category_name
        FROM service_providers.services_with_categories
        ORDER BY service_category_name NULLS LAST, service_name
        """
    )).mappings().all() #mappings() is used to return a dictionary of the result

    return [
        {
            "service_id": r["service_id"],
            "service_name": r["service_name"],
            "service_description": r["service_description"],
            "service_requirements": r["service_requirements"],
            "service_created_at": r["service_created_at"],
            "service_category_id": r["service_category_id"],
            "service_category_name": r["service_category_name"],
        }
        for r in rows
    ]


# -----------------------
# Providers
# -----------------------
@router.post("/", response_model=Provider)
def create_provider(payload: ProviderCreate, db: Session = Depends(get_db)):
    return crud_provider.create_provider(db, payload)

DEFAULT_CATEGORY_ID = 1  # Default category for quick-created providers


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

    provider_data = ProviderCreate(
        name=name,
        category_id=DEFAULT_CATEGORY_ID,
        is_registered=False,
        description=None,
        contact_info={},
        location={},
    )

    new_provider = crud_provider.create_provider(db, provider_data)
    return new_provider


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
            
            # Legacy price field
            "price": s.price,
            
            # New structured pricing fields
            "min_price": s.min_price,
            "max_price": s.max_price,
            "price_type": s.price_type,
            "currency": s.currency,
            "unit": s.unit,
            "negotiable": s.negotiable,
            
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


@router.get("/providers/")
def search_providers(
    db: Session = Depends(get_db),
    service_ids: list[str] = Query(None),
    match_all: bool = Query(False),
    category_id: int | None = Query(None),
    search: str = Query(None),
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
        # Skip None rows that might be returned from the view
        if r is None or r.provider_id is None:
            continue
            
        if r.provider_id not in grouped:
            # Format location data to be more user-friendly
            location_data = r.provider_location or {}
            formatted_location = {
                "area": location_data.get("name", "Nairobi"),
                "coordinates": {
                    "lat": location_data.get("lat"),
                    "lng": location_data.get("lng")
                },
                "address": f"{location_data.get('name', 'Nairobi')}, Kenya"
            }
            
            grouped[r.provider_id] = {
                "provider_id": r.provider_id,
                "provider_name": r.provider_name,
                "description": r.provider_description,
                "contact_info": r.provider_contact_info,
                "location": formatted_location,
                "rating": float(r.provider_rating) if r.provider_rating else 0.0,
                "is_registered": r.provider_is_registered,
                "created_at": r.provider_created_at,
                "category": {
                    "id": r.provider_category_id,
                    "name": r.provider_category_name
                },
                "services": []
            }
        grouped[r.provider_id]["services"].append({
            "service_id": r.service_id,
            "service_name": r.service_name,
            "service_description": r.service_description,
            
            # Legacy price field
            "price": r.price,
            
            # New structured pricing fields
            "min_price": float(r.min_price) if r.min_price else None,
            "max_price": float(r.max_price) if r.max_price else None,
            "price_type": r.price_type,
            "currency": r.currency,
            "unit": r.unit,
            "negotiable": r.negotiable,
            
            "duration": r.duration,
            "display_name": r.display_name,
            "booking_required": r.booking_required,
            "extra_data": r.extra_data,
            "category": {
                "id": r.service_category_id,
                "name": r.service_category_name
            },
            "requirements": r.service_requirements
        })

    return list(grouped.values())
