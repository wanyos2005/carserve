# App Download Prompt Integration Guide

## Overview
This guide explains how to integrate the app download prompt feature into your car platform. When a mechanic or fuel station logs a service for a customer who doesn't have your app, the system will automatically send them a personalized message encouraging them to download the app.

## How It Works

### 1. Service Logging Trigger
When a service provider (mechanic, fuel station, etc.) logs a service for a customer:
- The system checks if the customer has the app installed
- If not, it triggers an app download prompt alert
- The alert is sent via SMS, email, and WhatsApp

### 2. Alert Content
The alert includes:
- Personalized message mentioning the service provider and service type
- Clear value proposition (track service history, maintenance reminders, exclusive offers)
- Discount code for immediate incentive (default: "FIRST10" for 10% off)
- Direct app store links for both Android and iOS

## Integration Steps

### Step 1: Update Service Provider Service
When a service is logged, call the alert service:

```python
# In your service provider service
import requests

def log_service_for_customer(service_data):
    # Your existing service logging logic
    service_id = create_service_log(service_data)
    
    # Check if customer has app (implement your logic)
    customer_has_app = check_customer_has_app(service_data['customer_id'])
    
    if not customer_has_app:
        # Trigger app download prompt
        alert_response = requests.post(
            "http://alert-service:8000/alerts/trigger/app-download-prompt",
            json={
                "user_id": service_data['customer_id'],
                "vehicle_info": f"{service_data['vehicle_make']} {service_data['vehicle_model']}",
                "service_provider_name": service_data['provider_name'],
                "service_type": service_data['service_type'],
                "discount_code": "FIRST10"  # Optional, defaults to FIRST10
            }
        )
        
        if alert_response.status_code == 200:
            print(f"App download prompt sent to customer {service_data['customer_id']}")
    
    return service_id
```

### Step 2: Update Booking Service
Similarly, in your booking service:

```python
# In your booking service
def create_booking(booking_data):
    # Your existing booking creation logic
    booking_id = create_booking_record(booking_data)
    
    # Check if customer has app
    customer_has_app = check_customer_has_app(booking_data['customer_id'])
    
    if not customer_has_app:
        # Trigger app download prompt
        trigger_app_download_prompt(
            user_id=booking_data['customer_id'],
            vehicle_info=booking_data['vehicle_info'],
            service_provider_name=booking_data['provider_name'],
            service_type=booking_data['service_type']
        )
    
    return booking_id
```

## API Endpoint

### POST `/alerts/trigger/app-download-prompt`

**Request Body:**
```json
{
    "user_id": 123,
    "vehicle_info": "Toyota Camry 2020",
    "service_provider_name": "AutoCare Garage",
    "service_type": "Oil Change",
    "discount_code": "FIRST10"
}
```

**Response:**
```json
{
    "message": "App download prompt triggered successfully",
    "alert_id": "alert-uuid-here",
    "user_id": 123,
    "discount_code": "FIRST10"
}
```

## Alert Message Template

The system uses this template for the alert message:

```
🎉 Great news! {service_provider_name} has logged a {service_type} service for your vehicle {vehicle_info}. Download our app to track your service history, get maintenance reminders, and access exclusive offers. Use code '{discount_code}' for 10% off your next service!
```

## Configuration

### App Store Links
Update the app store links in `services/alert_service.py`:

```python
"app_store_links": {
    "android": "https://play.google.com/store/apps/details?id=com.yourcompany.carapp",
    "ios": "https://apps.apple.com/app/your-car-app/id123456789"
}
```

### Discount Codes
You can customize discount codes per service provider or service type:

```python
# Different codes for different providers
discount_codes = {
    "mechanic": "MECH10",
    "fuel_station": "FUEL15",
    "car_wash": "WASH20"
}
```

## Best Practices

### 1. User Detection
Implement a robust method to detect if a user has your app:

```python
# Use the AppDetectionService
from services.app_detection_service import AppDetectionService

def check_customer_has_app(customer_id):
    detection_service = AppDetectionService(db)
    return await detection_service.check_customer_has_app(customer_id)
```

**Detection Methods Used:**
- ✅ **FCM Token** (Primary indicator - from user_service.tbl_auth.fcm_token)
- ✅ **User Verification** (verified=true, is_guest=false)
- ✅ **Guest User Detection** (is_guest=true users get prompts)
- ✅ **Rate Limiting** (7-day cooldown between prompts)

### 2. Rate Limiting
Avoid spamming customers with multiple prompts:

```python
# Use the AppDetectionService for smart rate limiting
detection_service = AppDetectionService(db)
should_send = await detection_service.should_send_app_prompt(customer_id)

if should_send:
    # Trigger app download prompt
    await trigger_app_download_prompt(...)
```

**Smart Rate Limiting Logic:**
- ✅ **7-day cooldown** between prompts
- ✅ **FCM token check** (no prompt if app installed)
- ✅ **Guest user targeting** (only guests get prompts)
- ✅ **Verification status** (verified users less likely to need prompts)

### 3. Personalization
Customize messages based on service type:

```python
service_messages = {
    "oil_change": "Keep your engine running smoothly with our app!",
    "fuel": "Track your fuel efficiency and save money!",
    "repair": "Never miss important maintenance with our reminders!"
}
```

## Testing

### Test the Integration
```bash
# Test the endpoint directly
curl -X POST "http://localhost:8000/alerts/trigger/app-download-prompt" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": 123,
    "vehicle_info": "Toyota Camry 2020",
    "service_provider_name": "Test Garage",
    "service_type": "Oil Change"
  }'
```

### Test with Different Scenarios
1. **New customer** - Should receive prompt
2. **Existing app user** - Should not receive prompt
3. **Recent prompt sent** - Should not receive duplicate
4. **Different service types** - Should customize message

## Monitoring

### Track Success Metrics
- App download rate after prompt
- Conversion rate from prompt to app installation
- Customer engagement with discount codes
- Service provider satisfaction

### Analytics
Monitor these metrics:
- Number of prompts sent
- App downloads attributed to prompts
- Discount code usage
- Customer retention after app download

## Troubleshooting

### Common Issues
1. **Alert not sent** - Check alert service logs
2. **Wrong message** - Verify template variables
3. **Duplicate prompts** - Implement rate limiting
4. **Wrong channels** - Check alert configuration

### Debug Steps
1. Check alert service health: `GET /health`
2. Verify alert rules: `GET /rules`
3. Check alert logs: `GET /alerts`
4. Test notification delivery

## Future Enhancements

### 1. A/B Testing
Test different message templates and discount codes:

```python
# Different templates for different customer segments
templates = {
    "premium": "Exclusive offer for premium customers...",
    "regular": "Get 10% off your next service...",
    "new": "Welcome! Download our app for special benefits..."
}
```

### 2. Smart Timing
Send prompts at optimal times:

```python
# Send during business hours
# Avoid weekends for certain services
# Consider timezone differences
```

### 3. Progressive Incentives
Increase incentives for repeat non-downloaders:

```python
incentives = {
    "first_prompt": "10% off",
    "second_prompt": "15% off",
    "third_prompt": "20% off + free service"
}
```

This integration will help you grow your user base by converting service customers into app users, following the same strategies used by successful companies like Uber, Lyft, and Airbnb.
