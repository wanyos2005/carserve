#!/usr/bin/env python3
"""
Seed Default Alert Rules for MVP
Based on the alerts_mvp_integration_plan.md
"""

import asyncio #this is used to run the async functions
from sqlalchemy.orm import Session
from core.db import get_db, engine
from models.alert import AlertRule, AlertType
from datetime import datetime

def create_default_alert_rules():
    """Create the core MVP alert rules"""
    
    # Get database session
    db = next(get_db())
    
    try:
        # 1. Insurance Expiry Reminders
        insurance_rule = AlertRule(
            id="insurance-expiry-rule",
            name="Insurance Expiry Reminder",
            description="Reminds users when their insurance is about to expire",
            alert_type=AlertType.INSURANCE_EXPIRY, #remember this was an enum in the models/alert.py file
            trigger_conditions={
                "days_before_expiry": [30, 7, 1],
                "check_frequency": "daily"
            },
            message_template="Your insurance policy expires in {days} day(s). Renew now to avoid penalties and stay protected.",
            title_template="Insurance Expires in {days} day(s)",
            channels=["in_app", "email", "sms"],#
            priority=3,
            is_active=True,
            created_by="system",
            version="1.0"
        )
        
        # 2. Service Due Reminders
        service_rule = AlertRule(
            id="service-due-rule", 
            name="Service Due Reminder",
            description="Reminds users when their vehicle service is due",
            alert_type=AlertType.SERVICE_DUE,
            trigger_conditions={
                "mileage_intervals": [5000, 10000, 15000],
                "time_intervals": [6],  # months
                "check_frequency": "daily"
            },
            message_template="Your vehicle service is due. You've driven {mileage} km since last service. Book your appointment now.",
            title_template="Service Due - {mileage} km",
            channels=["in_app", "email"],
            priority=2,
            is_active=True,
            created_by="system",
            version="1.0"
        )
        
        # 3. Maintenance Reminders
        maintenance_rule = AlertRule(
            id="maintenance-reminder-rule",
            name="Maintenance Reminder", 
            description="General maintenance reminders based on vehicle age and usage",
            alert_type=AlertType.MAINTENANCE_REMINDER,
            trigger_conditions={
                "maintenance_types": ["oil_change", "filter_replacement", "tyre_rotation"],
                "check_frequency": "weekly"
            },
            message_template="Time for {maintenance_type}. Keep your vehicle in top condition.",
            title_template="Maintenance Due: {maintenance_type}",
            channels=["in_app", "email"],
            priority=2,
            is_active=True,
            created_by="system",
            version="1.0"
        )
        
        # 4. Promotional Alerts
        promotional_rule = AlertRule(
            id="promotional-rule",
            name="Promotional Alerts",
            description="Relevant offers and discounts from partner providers",
            alert_type=AlertType.PROMOTIONAL,
            trigger_conditions={
                "user_preferences": ["service_types", "location_radius"],
                "partner_promotions": True,
                "check_frequency": "daily"
            },
            message_template="Special offer: {offer_description}. Valid until {expiry_date}.",
            title_template="🎉 Special Offer: {provider_name}",
            channels=["in_app", "email"],
            priority=1,
            is_active=True,
            created_by="system",
            version="1.0"
        )
        
        # 5. Payment Reminders
        payment_rule = AlertRule(
            id="payment-reminder-rule",
            name="Payment Reminder",
            description="Reminds users about upcoming payments for services or insurance",
            alert_type=AlertType.PAYMENT_REMINDER,
            trigger_conditions={
                "days_before_payment": [7, 3, 1],
                "check_frequency": "daily"
            },
            message_template="Payment reminder: {payment_type} of {amount} is due in {days} day(s).",
            title_template="Payment Due: {payment_type}",
            channels=["in_app", "email", "sms"],
            priority=3, 
            is_active=True,
            created_by="system",
            version="1.0"
        )
        
        # 6. App Download Prompt
        app_download_rule = AlertRule(
            id="app-download-prompt-rule",
            name="App Download Prompt",
            description="Prompts car owners to download the app when a service is logged for them",
            alert_type=AlertType.APP_DOWNLOAD_PROMPT,
            trigger_conditions={
                "service_logged": True,
                "user_has_app": False,
                "check_frequency": "immediate"
            },
            message_template="🎉 Great news! A service has been logged for your vehicle {vehicle_info}. Download our app to track your service history, get maintenance reminders, and access exclusive offers. Get 10% off your next service when you download!",
            title_template="📱 Download Our App - Get 10% Off!",
            channels=["sms", "email", "whatsapp"],
            priority=2,
            is_active=True,
            created_by="system",
            version="1.0"
        )
        
        # 7. Claim Update Notifications
        claim_update_rule = AlertRule(
            id="claim-update-rule",
            name="Claim Update Notification",
            description="Notifies users about updates to their insurance claims",
            alert_type=AlertType.CLAIM_UPDATE,
            trigger_conditions={
                "claim_statuses": ["submitted", "under_review", "approved", "rejected", "paid"],
                "check_frequency": "real_time"
            },
            message_template="Your insurance claim #{claim_number} status has been updated to: {status}. {additional_info}",
            title_template="Claim Update: {claim_number}",
            channels=["in_app", "email", "sms"],
            priority=2,
            is_active=True,
            created_by="system",
            version="1.0"
        )
        
        # 8. Vehicle Registration Expiry
        registration_expiry_rule = AlertRule(
            id="registration-expiry-rule",
            name="Vehicle Registration Expiry",
            description="Reminds users when their vehicle registration is about to expire",
            alert_type=AlertType.MAINTENANCE_REMINDER,
            trigger_conditions={
                "days_before_expiry": [60, 30, 14, 7],
                "check_frequency": "daily"
            },
            message_template="Your vehicle registration expires in {days} day(s). Renew at NTSA to avoid penalties.",
            title_template="Registration Expires in {days} day(s)",
            channels=["in_app", "email", "sms"],
            priority=3,
            is_active=True,
            created_by="system",
            version="1.0"
        )
        
        # 9. Driver License Expiry
        license_expiry_rule = AlertRule(
            id="license-expiry-rule",
            name="Driver License Expiry",
            description="Reminds users when their driver license is about to expire",
            alert_type=AlertType.MAINTENANCE_REMINDER,
            trigger_conditions={
                "days_before_expiry": [90, 60, 30, 14],
                "check_frequency": "daily"
            },
            message_template="Your driver license expires in {days} day(s). Renew at NTSA to stay legal on the road.",
            title_template="License Expires in {days} day(s)",
            channels=["in_app", "email", "sms"],
            priority=3,
            is_active=True,
            created_by="system",
            version="1.0"
        )
        
        # Add all rules to database
        rules = [insurance_rule, service_rule, maintenance_rule, promotional_rule, payment_rule, app_download_rule, claim_update_rule, registration_expiry_rule, license_expiry_rule]
        
        for rule in rules:
            # Check if rule already exists
            existing = db.query(AlertRule).filter(AlertRule.id == rule.id).first()
            if not existing:
                db.add(rule)
                print(f"✅ Created rule: {rule.name}")
            else:
                print(f"⚠️  Rule already exists: {rule.name}")
        
        db.commit()
        print("\n🎉 Default alert rules created successfully!")
        
        return True
        
    except Exception as e:
        print(f"❌ Error creating alert rules: {e}")
        db.rollback()
        return False
    finally:
        db.close()

if __name__ == "__main__":
    print("🌱 Seeding Default Alert Rules for MVP...")
    print("=" * 50)
    
    success = create_default_alert_rules()
    
    if success:
        print("\n📋 Created Rules:")
        print("1. Insurance Expiry Reminders (30, 7, 1 days)")
        print("2. Service Due Reminders (mileage & time-based)")
        print("3. Maintenance Reminders (oil, filters, tyres)")
        print("4. Promotional Alerts (partner offers)")
        print("5. Payment Reminders (insurance, services)")
        print("6. App Download Prompts (when service is logged)")
        print("7. Claim Update Notifications (real-time)")
        print("8. Vehicle Registration Expiry (60, 30, 14, 7 days)")
        print("9. Driver License Expiry (90, 60, 30, 14 days)")
        print("\n🚀 Ready for MVP testing!")
    else:
        print("\n❌ Failed to create alert rules. Check database connection.")
