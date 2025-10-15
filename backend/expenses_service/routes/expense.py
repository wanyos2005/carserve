# insurance_service/routes/insurance.py

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from core.db import get_db
from models.expense import Expense
from schemas.expense import ExpenseCreate, ExpenseRead, ExpenseUpdate

router = APIRouter()

@router.post("/create-expense", response_model=ExpenseRead, status_code=status.HTTP_201_CREATED)
def create_expense(
    payload: ExpenseCreate,
    db: Session = Depends(get_db),
):
    
    expense = Expense(
        owner_id=payload.owner_id,
        vehicle_id=payload.vehicle_id,
        expense_type=payload.expense_type,
        provider_id=payload.provider_id, 
        location=payload.location, 
        cost=payload.cost, 
    )
    db.add(expense)
    db.commit()
    db.refresh(expense)
    return expense

#GET all insurance policies
@router.get("/get-expenses", response_model=list[ExpenseRead], status_code=status.HTTP_200_OK)
def get_expenses(
    owner_id: int | None = None,
    vehicle_id: str | None = None,
    db: Session = Depends(get_db),
):
    q = db.query(Expense)
    if owner_id is not None:
        q = q.filter(Expense.owner_id == owner_id)
    if vehicle_id is not None:
        q = q.filter(Expense.vehicle_id == vehicle_id)
    expenses = q.order_by(Expense.created_at.desc()).all()
    return expenses

#GET insurance policy by owner ID
@router.get("/stats", status_code=status.HTTP_200_OK)
def get_expense_stats(
    owner_id: int,
    vehicle_id: str | None = None,
    db: Session = Depends(get_db),
):
    from sqlalchemy import func
    q = db.query(Expense).filter(Expense.owner_id == owner_id)
    if vehicle_id is not None:
        q = q.filter(Expense.vehicle_id == vehicle_id)
    total = db.query(func.coalesce(func.sum(Expense.cost), 0)).filter(q.whereclause).scalar() if hasattr(q, 'whereclause') else 0
    count = q.count()
    return {"total": int(total or 0), "count": count}

