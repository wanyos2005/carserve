# Provider Rating Flow - Complete Documentation

## Overview
When a provider bulk logs services through `provider_log_service_page.dart`, the system triggers a multi-path rating process that gives users multiple opportunities to rate the provider.

---

## Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. PROVIDER SUBMITS BULK SERVICE LOGS                          │
│    (provider_log_service_page.dart)                             │
└───────────────────────┬─────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. FRONTEND: BookingService.createBulkServiceLogs()            │
│    - Sends logs payload to backend                              │
└───────────────────────┬─────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. BACKEND: POST /service-logs/bulk                             │
│    (booking_service/routers/service_logs.py)                   │
│    - Creates ServiceLog records in database                     │
│    - Triggers rating alerts (async)                             │
│    - Awards loyalty points (async)                              │
│    - Returns created logs                                       │
└───────────────────────┬─────────────────────────────────────────┘
                        │
                        ├─────────────────────┐
                        │                     │
                        ▼                     ▼
        ┌───────────────────────┐  ┌──────────────────────────────┐
        │ 4A. IMMEDIATE UI      │  │ 4B. ASYNC ALERT CREATION     │
        │    PROMPT             │  │    (Fire-and-forget)         │
        └───────────────────────┘  └──────────────────────────────┘
                        │                     │
                        │                     ▼
                        │          ┌──────────────────────────────┐
                        │          │ _trigger_rating_requests()  │
                        │          │ Groups by (user_id,          │
                        │          │  provider_id) to avoid      │
                        │          │  duplicates                 │
                        │          └──────────────┬─────────────┘
                        │                         │
                        │                         ▼
                        │          ┌──────────────────────────────┐
                        │          │ POST /alerts/trigger/       │
                        │          │  rating-request              │
                        │          │ (alert_service)             │
                        │          └──────────────┬─────────────┘
                        │                         │
                        │                         ▼
                        │          ┌──────────────────────────────┐
                        │          │ AlertService.                │
                        │          │ trigger_rating_request()     │
                        │          │ - Creates Alert record       │
                        │          │ - Type: RATING_REQUEST       │
                        │          │ - Channels: IN_APP, PUSH     │
                        │          │ - Action URL: /rate?...      │
                        │          └──────────────┬─────────────┘
                        │                         │
                        │                         ▼
                        │          ┌──────────────────────────────┐
                        │          │ Celery Task: deliver_alert  │
                        │          │ - Sends via Notification    │
                        │          │   Service                   │
                        │          │ - Push notification to user  │
                        │          │ - Stores in-app alert       │
                        │          └──────────────┬─────────────┘
                        │                         │
                        │                         ▼
                        │          ┌──────────────────────────────┐
                        │          │ USER RECEIVES                │
                        │          │ - Push notification          │
                        │          │ - In-app alert               │
                        │          │ - Can tap to rate            │
                        │          └──────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────────┐
│ 5. FRONTEND: _showRatingDialog()                                │
│    (provider_log_service_page.dart)                             │
│    - Shows star rating (1-5)                                    │
│    - Optional comment field                                     │
│    - User can rate immediately or skip                          │
└───────────────────────┬─────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────────┐
│ 6. USER SUBMITS RATING                                           │
│    ProviderService.rateProvider()                               │
│    - POST /service-providers/{provider_id}/ratings              │
│    - Rating: 1-5 stars                                          │
│    - Optional comment                                           │
└───────────────────────┬─────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────────┐
│ 7. BACKEND: CREATE RATING                                        │
│    (service_provider_service/routes/providers.py)               │
│    - Creates ProviderRating record                              │
│    - Recalculates provider average rating                        │
│    - Updates Provider.rating field                               │
└─────────────────────────────────────────────────────────────────┘
```

---

## Detailed Step-by-Step Flow

### Step 1: Provider Logs Services (Frontend)
**File:** `frontend/lib/pages/ProviderPages/provider_log_service_page.dart`

```dart
// User fills form and submits
await BookingService.createBulkServiceLogs(logsPayload);
```

**Payload includes:**
- `provider_id`: Provider who logged the service
- `user_id`: Guest user ID (created if doesn't exist)
- `vehicle_id`: Vehicle being serviced
- `service_id`, `service_name`: Services performed
- `cost`: Cost of services
- `performed_at`: When service was done

---

### Step 2: Backend Receives Bulk Logs
**File:** `backend/booking_service/routers/service_logs.py`

**Endpoint:** `POST /service-logs/bulk`

**Process:**
1. Creates multiple `ServiceLog` records in database
2. **Triggers rating alerts** (async, fire-and-forget)
3. Awards loyalty points (async)
4. Returns created logs

**Key Code:**
```python
@router.post("/bulk", response_model=List[ServiceLog])
def create_bulk_logs(payloads: List[ServiceLogCreate], db: Session = Depends(get_db)):
    logs = create_bulk_service_logs(db, payloads)
    
    # Trigger rating requests for each user/provider pair
    try:
        _trigger_rating_requests_for_logs(logs)
    except Exception as e:
        print(f"Warning: Failed to trigger rating requests: {e}")
    
    return logs
```

---

### Step 3: Rating Alert Trigger (Backend)
**File:** `backend/booking_service/routers/service_logs.py`

**Function:** `_trigger_rating_requests_for_logs()`

**Process:**
1. Groups logs by `(user_id, provider_id)` to avoid duplicate alerts
2. For each unique pair, calls alert service:
   ```python
   payload = {
       "user_id": user_id,
       "provider_id": provider_id,
       "log_id": sample_log.id,
       "title": "Rate your service provider",
       "message": "How was your recent service? Please rate your provider.",
   }
   httpx.post(f"{alert_service_url}/alerts/trigger/rating-request", json=payload)
   ```

---

### Step 4A: Immediate UI Rating Prompt (Frontend)
**File:** `frontend/lib/pages/ProviderPages/provider_log_service_page.dart`

**After successful log creation:**
```dart
try {
  final me = await AuthService.getMe();
  final userId = (me is Map) ? (me as Map)["id"] as int? : null;
  if (userId != null) {
    await _showRatingDialog(
      userId: userId, 
      providerId: widget.providerId
    );
  }
} catch (_) {}
```

**Dialog Features:**
- 5-star rating selector
- Optional comment field
- "Skip" or "Submit" buttons
- Closes automatically after submission

---

### Step 4B: Async Alert Creation (Backend → Notification)
**File:** `backend/alert_service/routes/alerts.py`

**Endpoint:** `POST /alerts/trigger/rating-request`

**Process:**
1. `AlertService.trigger_rating_request()` creates alert
2. Alert type: `RATING_REQUEST`
3. Channels: `IN_APP`, `PUSH`
4. Action URL: `/rate?provider_id={provider_id}&log_id={log_id}`
5. Enqueues Celery task for delivery

**Notification Service:**
- Sends push notification via FCM
- Stores in-app alert for user to see later
- User can tap notification to navigate to rating screen

---

### Step 5: User Rates Provider

**Option A: Immediate Dialog (from Step 4A)**
- User rates right after provider logs service
- Most convenient path

**Option B: From Notification (from Step 4B)**
- User receives push/in-app notification later
- Taps notification → navigates to rating screen
- Uses `FCMService.onNavigate` hook to handle deep link

**Option C: From Alert Action URL**
- In-app alert shows with "Rate now" button
- User taps button → navigates to rating screen

---

### Step 6: Submit Rating (Frontend)
**File:** `frontend/lib/services/provider_service.dart`

```dart
await ProviderService.rateProvider(
  providerId: providerId,
  rating: selected,  // 1-5
  comment: commentCtrl.text.trim().isEmpty ? null : commentCtrl.text.trim(),
  userId: userId,
  bookingId: bookingId,  // Optional
);
```

**API Call:** `POST /service-providers/{provider_id}/ratings`

---

### Step 7: Backend Processes Rating
**File:** `backend/service_provider_service/routes/providers.py`

**Endpoint:** `POST /service-providers/{provider_id}/ratings`

**Process:**
1. Validates provider exists
2. Creates `ProviderRating` record:
   - `provider_id`, `user_id`, `rating` (1-5), `comment`, `booking_id` (optional)
3. **Recalculates provider's average rating:**
   ```python
   avg = db.query(func.avg(ProviderRating.rating))
       .filter(ProviderRating.provider_id == provider_id)
       .scalar()
   provider.rating = round(float(avg or 0.0), 1)
   ```
4. Returns created rating

---

## Key Features

### 1. **Dual Rating Paths**
- **Immediate:** Dialog shown right after submission (best UX)
- **Delayed:** Push/in-app notification for later rating (catches users who close app)

### 2. **Deduplication**
- Groups by `(user_id, provider_id)` to prevent multiple alerts per submission
- Only one alert per user/provider combination

### 3. **Provider Rating Update**
- Average rating recalculated automatically
- Stored in `Provider.rating` field (Numeric(2,1))
- Used for display in provider listings

### 4. **Rating Storage**
- Individual ratings stored in `provider_ratings` table
- Includes: rating (1-5), comment, user_id, booking_id (optional), timestamp
- Can query ratings for a provider: `GET /service-providers/{provider_id}/ratings`

---

## User Experience Flow

### Scenario 1: User Rates Immediately
1. Provider submits bulk logs
2. ✅ Success message shown
3. ⭐ Rating dialog appears immediately
4. User rates 5 stars, adds comment
5. Dialog closes, returns to previous screen

### Scenario 2: User Skips Immediate Rating
1. Provider submits bulk logs
2. ✅ Success message shown
3. ⭐ Rating dialog appears
4. User clicks "Skip"
5. Later: Push notification received
6. User taps notification → Rating screen opens
7. User rates provider

### Scenario 3: User Closes App
1. Provider submits bulk logs
2. Backend creates alert
3. User closes app
4. Later: Push notification received
5. User opens app from notification
6. Rating screen opens automatically
7. User rates provider

---

## API Endpoints Used

1. **Create Bulk Logs:** `POST /service-logs/bulk`
2. **Trigger Rating Alert:** `POST /alerts/trigger/rating-request`
3. **Submit Rating:** `POST /service-providers/{provider_id}/ratings`
4. **Get Provider Ratings:** `GET /service-providers/{provider_id}/ratings`

---

## Database Tables

### `service_providers.provider_ratings`
- `id`: UUID
- `provider_id`: Foreign key to providers
- `user_id`: Integer (user who rated)
- `booking_id`: Optional (if rating from booking)
- `rating`: Integer (1-5)
- `comment`: Text (optional)
- `created_at`: Timestamp

### `service_providers.providers`
- `rating`: Numeric(2,1) - Average rating (updated automatically)

---

## Error Handling

- **Rating alert failures:** Logged but don't block service logging
- **Rating submission failures:** Shown to user, but don't break flow
- **Missing user/provider:** Validation in backend prevents invalid ratings
- **Duplicate ratings:** Backend allows multiple ratings (user can rate again if they want)

---

## Future Enhancements

1. **Rating Limits:** Prevent duplicate ratings within X days
2. **Rating Moderation:** Review comments before public display
3. **Rating Analytics:** Track rating trends over time
4. **Provider Response:** Allow providers to respond to ratings
5. **Rating Incentives:** Award points for leaving ratings

