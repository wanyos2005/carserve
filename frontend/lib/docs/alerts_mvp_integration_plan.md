# MVP Integration Plan: Smart Mobility Companion

## Overview
This document outlines the MVP implementation plan for Our App, focusing on core alerting features that provide immediate value with minimal consumer friction.

## Core MVP Features (Phase 1)

### 1. Insurance Expiry Reminders
**User Value**: Never miss insurance renewal deadlines
**Implementation**:
- User inputs: Insurance provider, policy number, expiry date, renewal amount
- Alert triggers: 30 days, 7 days, 1 day before expiry
- Channels: In-app notification, SMS, email
- Action: Direct link to insurance partner portal or renewal booking

### 2. Service Reminders
**User Value**: Proactive maintenance scheduling
**Implementation**:
- User inputs: Vehicle details (make, model, year), last service date, mileage
- Alert triggers: Based on mileage intervals (5K, 10K, 15K km) or time (6 months)
- Channels: In-app notification, SMS
- Action: Book service with nearby partner garages

### 3. Promotional Alerts
**User Value**: Relevant offers and discounts
**Implementation**:
- User preferences: Service types, location radius, frequency
- Alert triggers: Partner promotions, seasonal offers, user behavior patterns
- Channels: In-app notification, email
- Action: Direct booking or discount code application

## Technical Architecture

### Backend Services
```
[Flutter App] → [FastAPI Gateway] → [Alert Service] → [Notification Service]
                                    ↓
                              [Redis Streams] → [Rules Engine] → [Provider APIs]
```

### Database Schema (PostgreSQL)
```sql
-- Users and Vehicles
users (id, email, phone, preferences)
vehicles (id, user_id, make, model, year, last_service_date, mileage)

-- Insurance
insurance_policies (id, user_id, provider, policy_number, expiry_date, amount)

-- Alerts
alerts (id, user_id, type, message, status, created_at, sent_at)
alert_preferences (user_id, channel, frequency, types)

-- Providers
providers (id, name, type, location, contact, services)
```

### Alert Rules Engine
```python
# Example rule structure
class AlertRule:
    type: str  # 'insurance_expiry', 'service_due', 'promotional'
    trigger_conditions: dict
    message_template: str
    channels: list
    priority: int
```

## Google Maps API Analysis

### Pricing (2024)
- **Free Tier**: $200 monthly credit
- **Dynamic Maps**: $7 per 1,000 requests
- **Static Maps**: $2 per 1,000 requests
- **Places API**: $17 per 1,000 requests
- **Geocoding**: $5 per 1,000 requests

### MVP Decision: **DEFER Google Maps**
**Rationale**:
- MVP focuses on alerts, not location-based features
- $200 free tier = ~28,500 dynamic map requests/month
- For MVP: Use simple location input (city/area) instead of precise mapping
- Add Maps integration in Phase 2 when location features become critical

### Alternative for MVP
- **Location Input**: City/area selection from predefined list
- **Provider Discovery**: Text-based search with distance approximation
- **Future**: Integrate Maps when adding "Find Nearby Services" feature

## Implementation Roadmap (3 Months)

### Month 1: Core Infrastructure
**Week 1-2: Backend Foundation**
- [ ] FastAPI services setup (users, vehicles, insurance, alerts)
- [ ] PostgreSQL schema implementation
- [ ] Redis Streams for event processing
- [ ] Basic authentication and user management

**Week 3-4: Alert System**
- [ ] Rules engine for insurance/service reminders
- [ ] Notification service (FCM + SMS via Twilio)
- [ ] Alert preferences and user settings
- [ ] Basic provider management

### Month 2: Frontend & Integration
**Week 1-2: Flutter App Core**
- [ ] User onboarding flow
- [ ] Vehicle registration
- [ ] Insurance policy input
- [ ] Alert preferences screen

**Week 3-4: Provider Integration**
- [ ] Provider listing and search
- [ ] Booking flow for services
- [ ] Insurance partner integration
- [ ] Promotional alerts system

### Month 3: Polish & Launch
**Week 1-2: Testing & Optimization**
- [ ] End-to-end testing
- [ ] Performance optimization
- [ ] Alert delivery testing
- [ ] User feedback collection

**Week 3-4: Launch Preparation**
- [ ] App store submission
- [ ] Provider onboarding
- [ ] Marketing materials
- [ ] Launch monitoring

## Cost Analysis (Monthly)

### Infrastructure
- **Backend Hosting**: $50-100 (VPS/cloud)
- **Database**: $30-50 (PostgreSQL hosting)
- **Redis**: $20-30 (Redis Cloud)
- **SMS**: $0.01-0.05 per SMS (Twilio)
- **Push Notifications**: Free (FCM)

### APIs (Deferred)
- **Google Maps**: $0 (deferred to Phase 2)
- **Total MVP Cost**: ~$100-180/month

## Success Metrics

### User Engagement
- Alert open rates > 60%
- Service booking conversion > 15%
- Insurance renewal completion > 80%

### Business Metrics
- Provider partner acquisition: 10+ in first month
- User retention: 70% after 30 days
- Revenue per user: $5-10/month (through bookings)

## Risk Mitigation

### Technical Risks
- **Alert Delivery**: Implement retry logic and fallback channels
- **Provider Integration**: Start with manual booking, automate later
- **Scalability**: Use Redis for caching and queue management

### Business Risks
- **User Adoption**: Focus on clear value proposition in onboarding
- **Provider Onboarding**: Create simple partner portal
- **Competition**: Emphasize proactive alerts vs reactive booking

## Phase 2 Roadmap (Post-MVP)
- Google Maps integration for location-based features
- OBD-II device integration for automatic mileage tracking
- AI-powered maintenance predictions
- Trip-based assistance and emergency services
- Advanced analytics and insights

## Next Steps
1. **Immediate**: Set up development environment and basic FastAPI structure
2. **Week 1**: Implement user and vehicle management APIs
3. **Week 2**: Build alert rules engine and notification service
4. **Week 3**: Create Flutter app with core screens
5. **Week 4**: Integrate with first insurance partner for testing

This MVP approach delivers immediate value through smart alerts while keeping costs low and avoiding complex integrations until user demand is proven.
