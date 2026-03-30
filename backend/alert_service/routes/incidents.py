# backend/alert_service/routes/incidents.py
"""
Drivon Alerts – Incident Report endpoints.

Users submit incidents (CTA from the Drivon Alerts screen).
Admins review and update incident status.
"""
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import List, Optional
import uuid
import logging

from core.db import get_db
from models.alert import IncidentReport, IncidentStatus, IncidentType
from schemas.alert import IncidentReportCreate, IncidentReportUpdate, IncidentReportResponse
from routes.broadcast_alerts import require_admin

router = APIRouter()
logger = logging.getLogger(__name__)


@router.post("/", response_model=IncidentReportResponse, status_code=201)
def submit_incident(
    data: IncidentReportCreate,
    db: Session = Depends(get_db),
):
    """User submits an incident report."""
    report = IncidentReport(
        id=str(uuid.uuid4()),
        user_id=data.user_id,
        incident_type=data.incident_type,
        title=data.title,
        description=data.description,
        latitude=data.latitude,
        longitude=data.longitude,
        location_text=data.location_text,
        media_urls=data.media_urls or [],
        status=IncidentStatus.SUBMITTED,
    )
    db.add(report)
    db.commit()
    db.refresh(report)
    logger.info(f"Incident report submitted id={report.id} user_id={data.user_id}")
    return report


@router.get("/mine", response_model=List[IncidentReportResponse])
def get_my_incidents(
    user_id: int = Query(..., description="Authenticated user's ID"),
    limit: int = Query(20, le=100),
    offset: int = 0,
    db: Session = Depends(get_db),
):
    """Return incidents submitted by a specific user."""
    return (
        db.query(IncidentReport)
        .filter(IncidentReport.user_id == user_id)
        .order_by(IncidentReport.created_at.desc())
        .offset(offset)
        .limit(limit)
        .all()
    )


@router.get("/", response_model=List[IncidentReportResponse])
async def list_incidents(
    status: Optional[IncidentStatus] = None,
    incident_type: Optional[IncidentType] = None,
    limit: int = Query(50, le=200),
    offset: int = 0,
    db: Session = Depends(get_db),
    admin_id: str = Depends(require_admin),
):
    """Admin: list all incident reports."""
    q = db.query(IncidentReport)
    if status:
        q = q.filter(IncidentReport.status == status)
    if incident_type:
        q = q.filter(IncidentReport.incident_type == incident_type)
    return q.order_by(IncidentReport.created_at.desc()).offset(offset).limit(limit).all()


@router.get("/{report_id}", response_model=IncidentReportResponse)
async def get_incident(
    report_id: str,
    db: Session = Depends(get_db),
    admin_id: str = Depends(require_admin),
):
    report = db.query(IncidentReport).filter(IncidentReport.id == report_id).first()
    if not report:
        raise HTTPException(status_code=404, detail="Incident report not found")
    return report


@router.patch("/{report_id}", response_model=IncidentReportResponse)
async def update_incident(
    report_id: str,
    data: IncidentReportUpdate,
    db: Session = Depends(get_db),
    admin_id: str = Depends(require_admin),
):
    """Admin: update incident status / add notes."""
    report = db.query(IncidentReport).filter(IncidentReport.id == report_id).first()
    if not report:
        raise HTTPException(status_code=404, detail="Incident report not found")
    for field, value in data.model_dump(exclude_unset=True).items():
        setattr(report, field, value)
    db.commit()
    db.refresh(report)
    return report
