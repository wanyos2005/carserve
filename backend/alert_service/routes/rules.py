# backend/alert_service/routes/rules.py
from fastapi import APIRouter, Depends, HTTPException, BackgroundTasks
from sqlalchemy.orm import Session
from typing import List, Optional

from core.db import get_db
from models.alert import AlertRule, AlertType
from schemas.alert import AlertRuleCreate, AlertRuleResponse
from services.rule_engine import RuleEngine

router = APIRouter()


@router.post("/", response_model=AlertRuleResponse)
async def create_alert_rule(
    rule_data: AlertRuleCreate,
    db: Session = Depends(get_db)
):
    """Create a new alert rule"""
    rule = AlertRule(
        name=rule_data.name,
        description=rule_data.description,
        alert_type=rule_data.alert_type,
        trigger_conditions=rule_data.trigger_conditions,
        message_template=rule_data.message_template,
        title_template=rule_data.title_template,
        channels=rule_data.channels,
        priority=rule_data.priority,
        is_active=rule_data.is_active,
        schedule_expression=rule_data.schedule_expression,
        created_by=rule_data.created_by
    )
    
    db.add(rule)
    db.commit()
    db.refresh(rule)
    return rule

# Support no-trailing-slash variant to avoid proxy redirect issues
@router.post("", response_model=AlertRuleResponse)
async def create_alert_rule_no_slash(
    rule_data: AlertRuleCreate,
    db: Session = Depends(get_db)
):
    return await create_alert_rule(rule_data, db)

@router.get("/", response_model=List[AlertRuleResponse])
async def get_alert_rules(
    alert_type: Optional[AlertType] = None,
    is_active: Optional[bool] = None,
    limit: int = 50,
    offset: int = 0,
    db: Session = Depends(get_db)
):
    """Get alert rules with optional filtering"""
    query = db.query(AlertRule)
    
    if alert_type:
        query = query.filter(AlertRule.alert_type == alert_type)
    if is_active is not None:
        query = query.filter(AlertRule.is_active == is_active)
        
    return query.offset(offset).limit(limit).all()

# Support no-trailing-slash variant to avoid proxy redirect issues
@router.get("", response_model=List[AlertRuleResponse])
async def get_alert_rules_no_slash(
    alert_type: Optional[AlertType] = None,
    is_active: Optional[bool] = None,
    limit: int = 50,
    offset: int = 0,
    db: Session = Depends(get_db)
):
    return await get_alert_rules(alert_type, is_active, limit, offset, db)


@router.get("/{rule_id}", response_model=AlertRuleResponse)
async def get_alert_rule(rule_id: str, db: Session = Depends(get_db)):
    """Get a specific alert rule by ID"""
    rule = db.query(AlertRule).filter(AlertRule.id == rule_id).first()
    if not rule:
        raise HTTPException(status_code=404, detail="Alert rule not found")
    return rule

@router.patch("/{rule_id}/activate")
async def activate_alert_rule(rule_id: str, db: Session = Depends(get_db)):
    """Activate an alert rule"""
    rule = db.query(AlertRule).filter(AlertRule.id == rule_id).first()
    if not rule:
        raise HTTPException(status_code=404, detail="Alert rule not found")
    
    rule.is_active = True
    db.commit()
    return {"message": "Alert rule activated"}

@router.patch("/{rule_id}/deactivate")
async def deactivate_alert_rule(rule_id: str, db: Session = Depends(get_db)):
    """Deactivate an alert rule"""
    rule = db.query(AlertRule).filter(AlertRule.id == rule_id).first()
    if not rule:
        raise HTTPException(status_code=404, detail="Alert rule not found")
    
    rule.is_active = False
    db.commit()
    return {"message": "Alert rule deactivated"}

@router.post("/run-all")
async def run_all_alert_rules(
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db)
):
    """Manually run all active alert rules"""
    rule_engine = RuleEngine(db)
    background_tasks.add_task(rule_engine.check_insurance_expiry)
    background_tasks.add_task(rule_engine.check_service_due)
    return {"message": "All alert rules triggered"}
