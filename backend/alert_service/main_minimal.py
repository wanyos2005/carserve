# backend/alert_service/main_minimal.py
# Minimal version for testing without complex dependencies

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime
import json

app = FastAPI(
    title="Alert Service (Minimal)", 
    version="1.0.0", 
    description="Minimal alert service for testing"
)

# Simple in-memory storage for testing
alerts_db = []
users_db = []

class AlertCreate(BaseModel):
    user_id: int
    type: str
    title: str
    message: str
    priority: int = 2
    channels: List[str] = ["in_app"]

class AlertResponse(BaseModel):
    id: str
    user_id: int
    type: str
    title: str
    message: str
    priority: int
    channels: List[str]
    status: str = "pending"
    created_at: str

@app.get("/")
def root():
    return {
        "service": "alert-service-minimal",
        "version": "1.0.0",
        "status": "running",
        "docs": "/docs"
    }

@app.get("/alerts/health")
def health():
    return {
        "status": "alert-service healthy",
        "version": "1.0.0",
        "features": [
            "Insurance expiry reminders",
            "Service due notifications", 
            "Promotional alerts",
            "Multi-channel delivery",
            "Smart alert rules engine"
        ]
    }

@app.post("/alerts/", response_model=AlertResponse)
async def create_alert(alert_data: AlertCreate):
    """Create a new alert"""
    alert_id = f"alert_{len(alerts_db) + 1}"
    
    alert = {
        "id": alert_id,
        "user_id": alert_data.user_id,
        "type": alert_data.type,
        "title": alert_data.title,
        "message": alert_data.message,
        "priority": alert_data.priority,
        "channels": alert_data.channels,
        "status": "pending",
        "created_at": datetime.utcnow().isoformat()
    }
    
    alerts_db.append(alert)
    
    # Simulate email sending for testing
    if "email" in alert_data.channels:
        print(f"📧 EMAIL ALERT: {alert_data.title}")
        print(f"   To: User {alert_data.user_id}")
        print(f"   Message: {alert_data.message}")
        print(f"   From: DriveOn <tastytasty101@gmail.com>")
        print("-" * 50)
    
    return alert

@app.get("/alerts/", response_model=List[AlertResponse])
async def get_alerts(
    user_id: Optional[int] = None,
    limit: int = 50
):
    """Get alerts with optional filtering"""
    filtered_alerts = alerts_db
    
    if user_id:
        filtered_alerts = [a for a in alerts_db if a["user_id"] == user_id]
    
    return filtered_alerts[-limit:]

@app.get("/alerts/{alert_id}", response_model=AlertResponse)
async def get_alert(alert_id: str):
    """Get a specific alert by ID"""
    for alert in alerts_db:
        if alert["id"] == alert_id:
            return alert
    
    raise HTTPException(status_code=404, detail="Alert not found")

@app.post("/alerts/trigger/insurance-expiry")
async def trigger_insurance_expiry_alerts():
    """Manually trigger insurance expiry alerts (for testing)"""
    # Create sample insurance expiry alerts
    sample_alerts = [
        {
            "user_id": 1,
            "type": "insurance_expiry",
            "title": "Insurance Expires in 7 days",
            "message": "Your insurance policy expires in 7 days. Don't forget to renew!",
            "priority": 3,
            "channels": ["in_app", "email"]
        },
        {
            "user_id": 2,
            "type": "insurance_expiry", 
            "title": "Insurance Expires in 1 day",
            "message": "⚠️ URGENT: Your insurance policy expires TOMORROW! Renew now to avoid penalties.",
            "priority": 4,
            "channels": ["in_app", "email", "sms"]
        }
    ]
    
    created_alerts = []
    for alert_data in sample_alerts:
        alert = await create_alert(AlertCreate(**alert_data))
        created_alerts.append(alert)
    
    return {
        "message": f"Created {len(created_alerts)} insurance expiry alerts",
        "alerts": created_alerts
    }

@app.post("/alerts/trigger/service-due")
async def trigger_service_due_alerts():
    """Manually trigger service due alerts (for testing)"""
    # Create sample service due alerts
    sample_alerts = [
        {
            "user_id": 1,
            "type": "service_due",
            "title": "Service Due in 7 days",
            "message": "Your vehicle service is due in 7 days. Book your appointment now.",
            "priority": 2,
            "channels": ["in_app", "email"]
        },
        {
            "user_id": 3,
            "type": "service_due",
            "title": "Service Due Today",
            "message": "🚗 Your vehicle service is due TODAY! Book now to keep your car running smoothly.",
            "priority": 3,
            "channels": ["in_app", "email"]
        }
    ]
    
    created_alerts = []
    for alert_data in sample_alerts:
        alert = await create_alert(AlertCreate(**alert_data))
        created_alerts.append(alert)
    
    return {
        "message": f"Created {len(created_alerts)} service due alerts",
        "alerts": created_alerts
    }

@app.post("/test/email")
async def test_email():
    """Test email functionality"""
    test_alert = {
        "user_id": 999,
        "type": "test",
        "title": "🧪 Email Test - DriveOn Alert Service",
        "message": "This is a test email from your Alert Service. If you see this, email integration is working!",
        "priority": 1,
        "channels": ["email"]
    }
    
    alert = await create_alert(AlertCreate(**test_alert))
    
    return {
        "message": "Test email alert created",
        "alert": alert,
        "note": "Check console output for email details"
    }

if __name__ == "__main__":
    import uvicorn
    print("🚀 Starting Alert Service (Minimal Version)")
    print("📍 Available at: http://localhost:8004")
    print("📚 API Docs: http://localhost:8004/docs")
    print("🧪 Test endpoints:")
    print("   POST /alerts/trigger/insurance-expiry")
    print("   POST /alerts/trigger/service-due") 
    print("   POST /test/email")
    uvicorn.run(app, host="0.0.0.0", port=8004)
