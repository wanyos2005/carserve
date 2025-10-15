# 🚗 Insurance Service API Documentation

## Overview

The enhanced Insurance Service provides comprehensive insurance management capabilities including policy management, claims processing, risk scoring, and partner integration.

**Base URL**: `http://localhost:8005/insurance`

## 🏗️ Architecture

### Enhanced Models
- **Insurance_Policy**: Enhanced with premium tracking, coverage details, and status management
- **Insurance_Claim**: Complete claims management with evidence and processing workflow
- **Risk_Score**: Vehicle and driver risk scoring with detailed factor breakdown
- **Insurance_Partner**: Partner management for insurance companies
- **Data_Feed_Log**: Real-time data feed tracking to partners

## 📋 API Endpoints

### 1. Policy Management

#### Create Policy
```http
POST /insurance/policies
Content-Type: application/json

{
  "owner_id": 123,
  "vehicle_id": "vehicle-uuid",
  "provider_id": "partner-uuid",
  "insurance_type": "comprehensive",
  "commencement_date": "2024-01-01T00:00:00Z",
  "expiry_date": "2024-12-31T23:59:59Z",
  "premium_amount": 50000,
  "coverage_details": {
    "coverage_amount": 1000000,
    "third_party_liability": 500000,
    "personal_accident": 100000
  },
  "deductible_amount": 10000,
  "policy_number": "POL-20241201-ABC12345"
}
```

#### Get Policies
```http
GET /insurance/policies?owner_id=123&status=active&skip=0&limit=50
```

#### Get Specific Policy
```http
GET /insurance/policies/{policy_id}
```

#### Update Policy
```http
PUT /insurance/policies/{policy_id}
Content-Type: application/json

{
  "premium_amount": 55000,
  "status": "active"
}
```

#### Delete Policy
```http
DELETE /insurance/policies/{policy_id}
```

### 2. Policy Renewal Management

#### Get Expiring Policies
```http
GET /insurance/policies/expiring?days_ahead=30
```

#### Renew Policy
```http
POST /insurance/policies/{policy_id}/renew
Content-Type: application/json

{
  "new_expiry_date": "2025-12-31T23:59:59Z",
  "new_premium_amount": 55000
}
```

#### Cancel Policy
```http
POST /insurance/policies/{policy_id}/cancel
Content-Type: application/json

{
  "cancellation_reason": "Vehicle sold"
}
```

### 3. Claims Management

#### Create Claim
```http
POST /insurance/claims
Content-Type: application/json

{
  "policy_id": "policy-uuid",
  "vehicle_id": "vehicle-uuid",
  "user_id": 123,
  "claim_type": "accident",
  "incident_date": "2024-12-01T10:30:00Z",
  "description": "Rear-end collision on Mombasa Road",
  "estimated_cost": 150000,
  "evidence_files": ["photo1.jpg", "photo2.jpg"],
  "repair_quotes": [
    {
      "provider_id": "garage-uuid",
      "provider_name": "AutoFix Garage",
      "estimated_cost": 150000,
      "quote_date": "2024-12-01T14:00:00Z"
    }
  ]
}
```

#### Get Claims
```http
GET /insurance/claims?user_id=123&status=submitted&skip=0&limit=50
```

#### Get Specific Claim
```http
GET /insurance/claims/{claim_id}
```

#### Update Claim
```http
PUT /insurance/claims/{claim_id}
Content-Type: application/json

{
  "status": "under_review",
  "assigned_adjuster": "adjuster@insurance.com"
}
```

#### Upload Evidence
```http
POST /insurance/claims/{claim_id}/evidence
Content-Type: multipart/form-data

files: [file1.jpg, file2.pdf, file3.mp4]
```

#### Approve Claim
```http
POST /insurance/claims/{claim_id}/approve
Content-Type: application/json

{
  "approved_amount": 140000,
  "review_notes": "Approved after review of evidence"
}
```

#### Reject Claim
```http
POST /insurance/claims/{claim_id}/reject
Content-Type: application/json

{
  "review_notes": "Insufficient evidence provided"
}
```

### 4. Risk Scoring

#### Calculate Risk Score
```http
POST /insurance/risk/calculate/{vehicle_id}?user_id=123
```

**Response:**
```json
{
  "id": "risk-score-uuid",
  "vehicle_id": "vehicle-uuid",
  "user_id": 123,
  "vehicle_risk_score": 75,
  "driver_risk_score": 85,
  "combined_risk_score": 79,
  "risk_factors": {
    "vehicle_factors": {
      "age_risk": 10,
      "mileage_risk": 5,
      "service_risk": 8,
      "fuel_type_risk": 2
    },
    "driver_factors": {
      "punctuality_risk": 5,
      "frequency_risk": 3,
      "claims_risk": 0,
      "maintenance_risk": 7
    }
  },
  "scoring_algorithm_version": "1.0",
  "data_points_used": {
    "vehicle_data": {
      "vehicle_age": 5,
      "mileage": 50000,
      "fuel_type": "petrol",
      "service_logs_count": 12
    },
    "driver_data": {
      "total_services": 12,
      "recent_services": 3,
      "claims_count": 0
    }
  },
  "last_updated": "2024-12-01T15:30:00Z",
  "created_at": "2024-12-01T15:30:00Z"
}
```

#### Get Risk Score
```http
GET /insurance/risk/{vehicle_id}?user_id=123
```

#### Get User Risk Scores
```http
GET /insurance/risk/user/{user_id}
```

#### Update Risk Score
```http
POST /insurance/risk/update/{vehicle_id}?user_id=123
```

### 5. Insurance Partner Management

#### Create Partner
```http
POST /insurance/partners
Content-Type: application/json

{
  "name": "Kenya Insurance Company",
  "code": "KIC",
  "api_endpoint": "https://api.kic.co.ke",
  "webhook_url": "https://api.kic.co.ke/webhooks",
  "supports_quotes": true,
  "supports_claims": true,
  "supports_data_feeds": true,
  "commission_rate": 10,
  "contact_info": {
    "email": "partnerships@kic.co.ke",
    "phone": "+254 20 123 4567"
  },
  "supported_coverage_types": ["comprehensive", "third_party", "fire_theft"]
}
```

#### Get Partners
```http
GET /insurance/partners?active_only=true
```

#### Get Specific Partner
```http
GET /insurance/partners/{partner_id}
```

### 6. Insurance Marketplace

#### Get Quotes
```http
POST /insurance/quotes
Content-Type: application/json

{
  "vehicle_id": "vehicle-uuid",
  "user_id": 123,
  "coverage_type": "comprehensive",
  "coverage_amount": 1000000,
  "deductible_amount": 10000
}
```

**Response:**
```json
{
  "quotes": [
    {
      "partner_id": "partner-uuid",
      "partner_name": "Kenya Insurance Company",
      "premium_amount": 50000,
      "coverage_details": {
        "coverage_type": "comprehensive",
        "coverage_amount": 1000000,
        "deductible": 10000
      },
      "deductible_amount": 10000,
      "quote_valid_until": "2024-12-31T23:59:59Z",
      "terms_and_conditions": "Standard terms and conditions apply"
    }
  ],
  "request_id": "quote-request-uuid",
  "generated_at": "2024-12-01T15:30:00Z"
}
```

## 🔧 Risk Scoring Algorithm

### Vehicle Risk Factors (0-100 scale, where 100 is lowest risk)

1. **Age Factor (0-30 points risk)**
   - 2 points per year of vehicle age
   - Maximum 30 points risk

2. **Mileage Factor (0-25 points risk)**
   - 1 point per 2000km
   - Maximum 25 points risk

3. **Service History Factor (0-25 points risk)**
   - Based on service punctuality and frequency
   - Recent services (within 6 months) reduce risk
   - Overdue services increase risk

4. **Fuel Type Factor (0-10 points risk)**
   - Diesel: +5 points risk
   - Electric/Hybrid: -5 points risk (lower risk)
   - Petrol: 0 points risk

### Driver Risk Factors (0-100 scale, where 100 is lowest risk)

1. **Service Punctuality (0-30 points risk)**
   - Based on on-time service completion
   - Excellent (90%+): 0 points risk
   - Good (70-89%): 10 points risk
   - Fair (50-69%): 20 points risk
   - Poor (<50%): 30 points risk

2. **Service Frequency (0-20 points risk)**
   - Based on regular maintenance intervals
   - Regular service history: 5 points risk
   - Irregular service: 20 points risk

3. **Claims History (0-25 points risk)**
   - Based on previous claims
   - No claims: 0 points risk
   - Multiple claims: up to 25 points risk

4. **Maintenance Quality (0-25 points risk)**
   - Based on service documentation and comprehensiveness
   - Excellent maintenance: 0 points risk
   - Poor maintenance: 25 points risk

### Combined Risk Score
- **Vehicle Risk**: 60% weight
- **Driver Risk**: 40% weight
- **Final Score**: Weighted average of both scores

## 📊 Data Flow Integration

### Service Completion Feed
When a service is completed, the system automatically:
1. Updates vehicle mileage and service history
2. Recalculates risk scores
3. Sends data feed to relevant insurance partners
4. Logs the feed delivery status

### Claim Processing Workflow
1. **Submission**: User submits claim with evidence
2. **Review**: Adjuster reviews claim and evidence
3. **Approval/Rejection**: Claim is approved or rejected
4. **Payment**: Approved claims are processed for payment
5. **Partner Notification**: Insurance partner is notified of claim status

## 🚀 Getting Started

### 1. Database Setup
```bash
cd backend/insurance_service
python create_insurance_tables.py
```

### 2. Start Service
```bash
docker compose up insurance-service
```

### 3. Test API
Visit: `http://localhost:8005/docs`

### 4. Create First Policy
```bash
curl -X POST "http://localhost:8005/insurance/policies" \
  -H "Content-Type: application/json" \
  -d '{
    "owner_id": 123,
    "vehicle_id": "vehicle-uuid",
    "provider_id": "partner-uuid",
    "insurance_type": "comprehensive",
    "premium_amount": 50000
  }'
```

## 🔗 Integration with Other Services

### Vehicle Service Integration
- Fetches vehicle data for risk scoring
- Updates mileage and specifications
- Tracks vehicle age and condition

### Booking Service Integration
- Retrieves service history for risk assessment
- Tracks service punctuality and quality
- Monitors maintenance patterns

### User Service Integration
- Links policies to user accounts
- Tracks user behavior patterns
- Manages user-specific risk factors

## 📈 Future Enhancements

1. **AI-Powered Claim Processing**
   - Automated claim assessment
   - Fraud detection algorithms
   - Predictive claim cost estimation

2. **Real-time Telematics Integration**
   - OBD device data integration
   - Driving behavior analysis
   - Usage-based insurance models

3. **Blockchain Integration**
   - Immutable service records
   - Smart contract automation
   - Decentralized claim processing

4. **Advanced Analytics**
   - Predictive risk modeling
   - Market trend analysis
   - Personalized pricing algorithms

---

*This API documentation covers the enhanced insurance service capabilities. For more details, visit the interactive API documentation at `/docs` when the service is running.*
