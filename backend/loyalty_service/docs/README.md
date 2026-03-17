# Loyalty Service Documentation

This directory contains comprehensive documentation for the Loyalty Service.

## 📚 Documentation Index

### Core Implementation
- **[LOYALTY_SERVICE_IMPLEMENTATION.md](./LOYALTY_SERVICE_IMPLEMENTATION.md)** - Complete service implementation guide, API endpoints, and architecture

### Points Calculation & Flow
- **[LOYALTY_POINTS_FLOW.md](./LOYALTY_POINTS_FLOW.md)** - Detailed explanation of how points are calculated and awarded, from service log to points balance
- **[LOYALTY_TIER_SYSTEMS_EXPLANATION.md](./LOYALTY_TIER_SYSTEMS_EXPLANATION.md)** - Explanation of the two-tier system (Provider Participation Tiers vs User Loyalty Tiers)
- **[WHY_TWO_TIER_SYSTEMS.md](./WHY_TWO_TIER_SYSTEMS.md)** - Business rationale and technical explanation for having separate provider and user tier systems

### Provider Participation
- **[LOYALTY_PROVIDER_PARTICIPATION_MODEL.md](./LOYALTY_PROVIDER_PARTICIPATION_MODEL.md)** - Provider opt-in model, billing plans, and participation workflows

### Billing & Finance
- **[LOYALTY_BILLING_EXPLANATION.md](./LOYALTY_BILLING_EXPLANATION.md)** - Comprehensive billing system explanation
- **[BILLING_SIMPLE_EXPLANATION.md](./BILLING_SIMPLE_EXPLANATION.md)** - Simplified billing overview
- **[BILLING_FLOW_VISUAL.md](./BILLING_FLOW_VISUAL.md)** - Visual flow diagrams for billing processes

### Frontend Integration
- **[FRONTEND_LOYALTY_INTEGRATION_COMPLETE.md](./FRONTEND_LOYALTY_INTEGRATION_COMPLETE.md)** - Frontend implementation details and integration guide

---

## 🚀 Quick Start Guide

1. **Understanding the Service:** Start with [LOYALTY_SERVICE_IMPLEMENTATION.md](./LOYALTY_SERVICE_IMPLEMENTATION.md)
2. **How Points Work:** Read [LOYALTY_POINTS_FLOW.md](./LOYALTY_POINTS_FLOW.md)
3. **Provider Setup:** Review [LOYALTY_PROVIDER_PARTICIPATION_MODEL.md](./LOYALTY_PROVIDER_PARTICIPATION_MODEL.md)
4. **Billing Details:** Check [LOYALTY_BILLING_EXPLANATION.md](./LOYALTY_BILLING_EXPLANATION.md)

---

## 📖 Documentation Structure

```
docs/
├── README.md (this file)
├── Core Implementation
│   └── LOYALTY_SERVICE_IMPLEMENTATION.md
├── Points & Tiers
│   ├── LOYALTY_POINTS_FLOW.md
│   ├── LOYALTY_TIER_SYSTEMS_EXPLANATION.md
│   └── WHY_TWO_TIER_SYSTEMS.md
├── Provider Participation
│   └── LOYALTY_PROVIDER_PARTICIPATION_MODEL.md
├── Billing & Finance
│   ├── LOYALTY_BILLING_EXPLANATION.md
│   ├── BILLING_SIMPLE_EXPLANATION.md
│   └── BILLING_FLOW_VISUAL.md
└── Frontend
    └── FRONTEND_LOYALTY_INTEGRATION_COMPLETE.md
```

---

## 🔗 Related Documentation

- Main service README: [../README.md](../README.md)
- API Routes: [../routers/loyalty.py](../routers/loyalty.py)
- Models: [../models/loyalty.py](../models/loyalty.py)
- CRUD Operations: [../crud/loyalty.py](../crud/loyalty.py)
- Points Calculator: [../services/points_calculator.py](../services/points_calculator.py)

---

## 📝 Notes

All documentation files were moved from the project root to maintain better organization and service-specific documentation structure.

Step 1 — Start only the services you need

cd c:/systemc/car
docker-compose up -d postgres redis payment-service
This avoids starting all 15 containers.

Step 2 — Run migrations

docker-compose exec payment-service alembic upgrade head
Step 3 — Open Swagger UI
Go to http://localhost:8010/docs — FastAPI generates this automatically. You can test every endpoint from the browser.

Step 4 — Get a free webhook test URL
Go to https://webhook.site — it gives you a unique URL like:


https://webhook.site/abc-123-xyz
Every POST sent to it shows up live on screen. Use this as your callback_url when testing webhook subscriptions — no need to build a receiver.

Step 5 — Test flow in Swagger

1. POST /webhooks/subscribe
   { "callback_url": "https://webhook.site/your-unique-url", "provider_id": "test-provider" }

2. POST /mpesa/transactions
   { "raw_message": "RA12B3C4DE5 Confirmed. Ksh1,000.00 received from JOHN DOE..." }

3. Check webhook.site — you should see the incoming POST