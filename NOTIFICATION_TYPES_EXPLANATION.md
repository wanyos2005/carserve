# In-App vs Push Notifications - Complete Guide

## Overview
The alert system uses **two complementary notification channels** to ensure users receive alerts through multiple means.

---

## 1. In-App Notifications

### What They Are
- **Stored in database** (in the `alerts` table)
- **Fetched by the app** when user opens it or polls the API
- **Persistent** - remain available until user marks them as read
- **No internet required** to view (once fetched)

### How They Work
1. Backend creates an `Alert` record with `status=PENDING`
2. Alert is marked as `SENT` when stored
3. Frontend periodically calls: `GET /alerts?user_id={id}`
4. App displays alerts in a notification center/badge
5. User can tap to view details and mark as read

### Advantages
- ✅ Works even if push notifications are disabled
- ✅ Can be viewed later (persistent)
- ✅ No delivery failures (stored in DB)
- ✅ Can show in-app notification center/badge count

### Disadvantages
- ❌ Requires user to open app to see them
- ❌ Not real-time (requires polling)
- ❌ May miss time-sensitive alerts

### Example Flow
```
Backend creates alert → Alert stored in DB → 
User opens app → App fetches alerts → 
Shows notification badge → User taps → Views alert
```

---

## 2. Push Notifications

### What They Are
- **Real-time notifications** sent directly to device
- **Firebase Cloud Messaging (FCM)** delivers them
- **Appears even when app is closed**
- **System-level notifications** (OS handles display)

### How They Work
1. Backend sends notification via FCM API
2. FCM delivers to device (Android/iOS)
3. OS displays notification in notification tray
4. User taps notification → App opens → Navigates to action

### Advantages
- ✅ Real-time (instant delivery)
- ✅ Works even when app is closed
- ✅ Gets user's attention immediately
- ✅ Can include action buttons
- ✅ System-level (more noticeable)

### Disadvantages
- ❌ Requires internet connection
- ❌ Can be disabled by user in OS settings
- ❌ Delivery can fail (invalid tokens, network issues)
- ❌ Not persistent (if dismissed, may be lost)

### Example Flow
```
Backend sends via FCM → FCM delivers to device → 
OS shows notification → User taps → 
App opens → Navigates to rating screen
```

---

## 3. FCM Service Files Explained

### `frontend/lib/services/fcm_service.dart` (Flutter Client)

**Purpose:** Client-side FCM handling

**Responsibilities:**
1. **Token Management**
   - Requests notification permissions from user
   - Gets FCM device token from Firebase
   - Registers token with backend (`POST /users/{id}/fcm-token`)

2. **Receiving Notifications**
   - Handles **foreground** messages (app is open)
   - Handles **background** messages (app is closed)
   - Handles **notification taps** (user taps notification)

3. **Navigation**
   - Provides `onNavigate` hook for deep linking
   - Parses `action_url` from notification data
   - Routes user to appropriate screen (e.g., rating screen)

**Key Functions:**
```dart
initialize()              // Request permissions, get token, register with backend
_registerTokenWithBackend()  // Send token to backend for storing
_handleNotificationTap()     // Handle when user taps notification
_handleForegroundMessage()   // Handle notifications when app is open
```

**Flow:**
```
App starts → Request permissions → Get FCM token → 
Register token with backend → 
Listen for notifications → 
Handle taps/navigation
```

---

### `backend/alert_service/services/fcm_service.py` (Python Server)

**Purpose:** Server-side FCM message sending

**Responsibilities:**
1. **Firebase Admin SDK Setup**
   - Initializes Firebase Admin with service account credentials
   - Manages Firebase app instance

2. **Sending Notifications**
   - **Single device:** `send_notification()` - sends to one token
   - **Multiple devices:** `send_multicast_notification()` - sends to many tokens
   - **Topics:** `send_topic_notification()` - broadcasts to topic subscribers

3. **Topic Management**
   - `subscribe_to_topic()` - Add tokens to topics
   - `unsubscribe_from_topic()` - Remove tokens from topics

**Key Functions:**
```python
initialize()                    # Setup Firebase Admin SDK
send_notification()             # Send to single device
send_multicast_notification()  # Send to multiple devices
send_topic_notification()       # Broadcast to topic
subscribe_to_topic()            # Subscribe tokens to topic
```

**Flow:**
```
NotificationService needs to send → 
Calls FCMService.send_notification() → 
FCMService uses Firebase Admin SDK → 
Sends to FCM servers → 
FCM delivers to device
```

---

## 4. How They Work Together

### Complete Rating Alert Flow

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Backend Creates Alert                                    │
│    AlertService.create_alert() → Alert stored in DB        │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ├─────────────────────┐
                        │                     │
                        ▼                     ▼
        ┌───────────────────────────┐  ┌──────────────────────────┐
        │ 2A. IN-APP NOTIFICATION   │  │ 2B. PUSH NOTIFICATION     │
        │                           │  │                           │
        │ Alert stored in DB        │  │ NotificationService       │
        │ status = PENDING          │  │ calls FCMService          │
        │                           │  │                           │
        │ User opens app →          │  │ FCMService sends to       │
        │ GET /alerts →             │  │ Firebase servers          │
        │ Shows in notification     │  │                           │
        │ center/badge              │  │ FCM delivers to device   │
        │                           │  │                           │
        │ User taps → Views alert   │  │ OS shows notification     │
        │                           │  │                           │
        │ User taps notification →  │  │ User taps → App opens     │
        │ Navigates to rating       │  │                           │
        │ screen                    │  │ FCMService (Dart)         │
        │                           │  │ handles tap →             │
        │                           │  │ Navigates to rating       │
        │                           │  │ screen                    │
        └───────────────────────────┘  └──────────────────────────┘
```

---

## 5. When Each Is Used

### In-App Notifications
- ✅ **Always created** - Every alert goes to database
- ✅ **Fallback** - If push fails, user can still see in-app
- ✅ **History** - User can review past alerts
- ✅ **Settings** - User can mark as read/unread

### Push Notifications
- ✅ **Time-sensitive** - Rating requests, urgent alerts
- ✅ **User engagement** - Brings user back to app
- ✅ **Real-time** - Immediate delivery
- ⚠️ **Optional** - Can be disabled by user

---

## 6. Alert Channel Configuration

In your code, alerts specify which channels to use:

```python
AlertCreate(
    channels=[AlertChannel.IN_APP, AlertChannel.PUSH],  # Both!
    ...
)
```

**Rating Request Alert:**
- `IN_APP` - Stored in database, shown in notification center
- `PUSH` - Real-time notification sent via FCM

**Why Both?**
- **Push** = Immediate attention (user might be away)
- **In-App** = Persistent record (user can review later)

---

## 7. Code Flow Example: Rating Request

### Step 1: Alert Created (Backend)
```python
# backend/alert_service/services/alert_service.py
alert = AlertService.trigger_rating_request(
    user_id=123,
    provider_id="abc",
    log_id="log-xyz",
    channels=[AlertChannel.IN_APP, AlertChannel.PUSH]
)
```

### Step 2: Delivery Started (Backend)
```python
# backend/alert_service/services/notification_service.py
await NotificationService.send_alert(alert)

# For IN_APP:
# - Alert status set to SENT
# - Stored in database
# - User can fetch via API

# For PUSH:
# - Gets user's FCM token
# - Calls FCMService.send_notification()
# - FCM delivers to device
```

### Step 3: Push Notification Received (Frontend)
```dart
// frontend/lib/services/fcm_service.dart
FirebaseMessaging.onMessageOpenedApp.listen((message) {
  // User tapped notification
  final actionUrl = message.data['action_url'];
  // actionUrl = "/rate?provider_id=abc&log_id=log-xyz"
  
  if (FCMService.onNavigate != null) {
    FCMService.onNavigate!(actionUrl);  // Navigate to rating screen
  }
});
```

### Step 4: In-App Alert Fetched (Frontend)
```dart
// App periodically calls:
GET /alerts?user_id=123

// Response includes rating request alert
// App shows in notification center
// User taps → Navigates to rating screen
```

---

## 8. Key Differences Summary

| Feature | In-App | Push |
|---------|--------|------|
| **Storage** | Database | FCM servers |
| **Delivery** | On-demand (polling) | Real-time |
| **Persistence** | Yes (until read) | No (dismissed when cleared) |
| **Requires App Open** | Yes (to fetch) | No (OS handles) |
| **Internet Required** | Yes (to fetch) | Yes (to receive) |
| **User Control** | Can mark read/unread | Can disable in OS |
| **Best For** | History, non-urgent | Urgent, engagement |

---

## 9. Best Practices

### Use Both Channels
- **Always** create in-app alerts (database record)
- **Add push** for important/time-sensitive alerts

### Handle Failures Gracefully
- If push fails → In-app alert still available
- If user disables push → In-app still works
- If app is closed → Push notification works

### User Experience
- Push = "Get attention now"
- In-App = "Review later"
- Together = Best coverage

---

## 10. FCM Service Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Alert Service                            │
│  (Creates alerts, manages delivery)                         │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│              Notification Service                            │
│  (Orchestrates delivery to all channels)                    │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ├─────────────────────┐
                        │                     │
                        ▼                     ▼
        ┌──────────────────────────┐  ┌──────────────────────────┐
        │   IN-APP CHANNEL          │  │   PUSH CHANNEL           │
        │                           │  │                           │
        │ Alert stored in DB        │  │ FCMService (Python)       │
        │ Status = SENT             │  │ → Firebase Admin SDK      │
        │                           │  │ → FCM servers             │
        │ User fetches via API      │  │ → Device                  │
        │                           │  │                           │
        │                           │  │ FCMService (Dart)         │
        │                           │  │ → Receives notification   │
        │                           │  │ → Handles tap             │
        │                           │  │ → Navigates to screen     │
        └──────────────────────────┘  └──────────────────────────┘
```

---

## Summary

**In-App Notifications:**
- Database-stored alerts
- Fetched by app when user opens it
- Persistent, reviewable history
- Backend: Just stores in DB
- Frontend: Fetches via API

**Push Notifications:**
- Real-time OS notifications
- Delivered via FCM
- Works when app is closed
- Backend: Uses FCMService (Python) to send
- Frontend: Uses FCMService (Dart) to receive

**Both Together:**
- Maximum coverage
- Push for immediate attention
- In-app for persistence and history
- Rating alerts use both channels for best UX

