# backend/booking_service/app/routers/service_logs.py
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from uuid import UUID

from app.core.db import get_db
from app.schemas.booking import ServiceLogCreate, ServiceLog
from app.crud.booking import (
    create_service_log,
    list_service_logs_for_user,
)

router = APIRouter(tags=["service logs"])


@router.post("/", response_model=ServiceLog)
def create(payload: ServiceLogCreate, db: Session = Depends(get_db)):
    return create_service_log(db, payload)


@router.get("/user/{user_id}", response_model=List[ServiceLog])
def list_for_user(user_id: int, db: Session = Depends(get_db)):
    return list_service_logs_for_user(db, user_id)