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
        exoense_type=payload.expense_type,
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
    db: Session = Depends(get_db),
):
    expenses = db.query(Expense).all()
    return expenses

#GET insurance policy by owner ID
@router.get("/get-expenses-by-owner/{owner_id}", response_model=list[ExpenseRead], status_code=status.HTTP_200_OK)
def get_expenses_by_owner(
    owner_id: int,
    db: Session = Depends(get_db),
):
    expenses = db.query(Expense).filter(Expense.owner_id == owner_id).all()
    return expenses

