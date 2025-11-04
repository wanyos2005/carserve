# FCM Token Registration & Alert Delivery Flow

## How FCM Tokens Work in Your System

### 1. **FCM Token Storage**
- Each user has an `fcm_token` field in the database (`users.tbl_auth.fcm_token`)
- The token is **device-specific** but **user-linked**
- When a user logs in, their FCM token is registered and stored in the database

### 2. **Token Registration Flow**
```
User Logs In
  ↓
FCM Service Initializes
  ↓
Gets Device FCM Token (from Firebase/Google)
  ↓
Registers Token with Backend: POST /users/{user_id}/fcm-token
  ↓
Backend Stores: user.fcm_token = "device_token"
```

### 3. **Alert Delivery Flow**
```
Alert Created for User
  ↓
NotificationService.send_alert() called
  ↓
For PUSH channel:
  - Looks up user's FCM token: GET /users/{user_id}/fcm-token
  - Sends notification to that token via Firebase
  ↓
FCM Delivers to Device (even if app is closed)
```

---

## Testing Flow with One Device

### ✅ **YES, it will work!** Here's why:

### Scenario:
1. **Logout** → No user logged in
2. **Login as Provider** → FCM token registered for `provider_user_id`
3. **Perform Bulk Service Log** → Alert created for `guest_user_id`
4. **Logout as Provider** → Provider's token still in DB (but not used)
5. **Login as Guest User** → FCM token registered for `guest_user_id`
6. **Alert Delivery** → Backend looks up `guest_user_id`'s token → Found! → Sends notification

### Key Points:

1. **Token is User-Specific**: Each user_id has their own FCM token in the database
   - Provider logs in → Token stored for provider's user_id
   - Guest logs in → Token stored for guest's user_id
   - **Same device, different tokens (or same token linked to different users)**

2. **Token Registration Happens on Login**: When guest user logs in, FCM automatically:
   - Gets device token
   - Registers it with backend linked to guest user's ID
   - Token is stored in database

3. **Alert Delivery is Time-Independent**: 
   - Alert is created → Stored in database
   - When delivery happens → Backend looks up user's FCM token
   - If token exists → Push notification sent
   - If no token → Push fails, but in-app alert still stored

---

## What Happens in Your Test Scenario

### Step-by-Step:

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Provider Logs In                                         │
│    - FCM gets device token: "ABC123"                        │
│    - Registers: POST /users/5/fcm-token                     │
│    - Database: provider_user_id=5, fcm_token="ABC123"       │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. Provider Logs Services                                   │
│    - Creates guest user: guest_user_id=10                   │
│    - Creates alert for guest_user_id=10                     │
│    - Alert stored in database (status=PENDING)               │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. Provider Logs Out                                        │
│    - Provider's token still in DB (not deleted)             │
│    - But no longer "active" for this session                 │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. Guest User Logs In                                        │
│    - FCM gets device token: "ABC123" (same device,           │
│      might be same or different token)                       │
│    - Registers: POST /users/10/fcm-token                     │
│    - Database: guest_user_id=10, fcm_token="ABC123"          │
│    - ✅ Guest user now has FCM token registered!            │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 5. Alert Delivery (Happens Automatically)                    │
│    - Celery task: deliver_alert(alert_id)                   │
│    - Looks up: GET /users/10/fcm-token                        │
│    - Finds token: "ABC123"                                   │
│    - Sends push notification via FCM                        │
│    - ✅ Guest user receives notification!                    │
└─────────────────────────────────────────────────────────────┘
```

---

## Important Considerations

### ✅ **Will Work:**
- **In-App Alerts**: Always work (stored in database, fetched when user logs in)

### ⚠️ **Push Notification Timing Issue:**

**CRITICAL**: If alert is created before guest user logs in, push notification will fail silently!

1. **Alert Created Before Guest Logs In:**
   ```
   Service logged → Alert created for guest_user_id=10
   Celery task runs IMMEDIATELY → deliver_alert(alert.id)
   Looks up FCM token → ❌ No token found (guest hasn't logged in)
   Push notification → Logs as FAILED, returns gracefully
   Alert status → DELIVERED (because IN_APP succeeded)
   Guest logs in later → ✅ Can see in-app alert
   ❌ BUT: Push notification was already attempted and failed
   ```

2. **What This Means:**
   - ✅ **In-app alerts always work** (stored in DB, fetched on login)
   - ❌ **Push notifications only work if guest logs in FIRST** (before service is logged)
   - ⚠️ **No automatic retry** when guest user registers FCM token later

2. **Same Device, Multiple Users:**
   - **Same Token**: Device might return same FCM token for different users
   - **Different Token**: Device might return different token (if app reinstalled, etc.)
   - **Both Work**: Backend stores token per user_id, so it doesn't matter

3. **Token Expiration:**
   - FCM tokens can expire or become invalid
   - If token is invalid, push notification fails
   - In-app alerts still work

---

## Best Testing Strategy

### ✅ **Recommended Flow (Guaranteed Push Notification):**
1. ✅ **Login as Guest User FIRST** (before service is logged)
   - This ensures FCM token is registered
   - Alert will be delivered immediately when created

2. ✅ **Login as Provider** (in separate device or logout/login)
   - Perform bulk service log
   - Alert created for guest user

3. ✅ **Guest User receives push notification immediately** ✅
   - Can also see in-app alert in notifications

### ⚠️ **Alternative Flow (In-App Only - No Push):**
1. ✅ **Login as Provider**
2. ✅ **Perform bulk service log** (creates alert for guest)
3. ✅ **Logout as Provider**
4. ✅ **Login as Guest User** (registers FCM token)
5. ❌ **Push notification was already attempted and failed** (no retry)
6. ✅ **Guest CAN see in-app alert** (fetched from database)
7. ❌ **Guest will NOT receive push notification** (already attempted)

### 🔧 **Solution for Production:**
See `FCM_RETRY_SOLUTION.md` for implementing retry mechanism when FCM token is registered.

---

## How to Verify It's Working

### Check FCM Token Registration:
```sql
-- Check if guest user has FCM token
SELECT id, name, fcm_token 
FROM users.tbl_auth 
WHERE id = {guest_user_id};
```

### Check Alert Creation:
```sql
-- Check if alert was created
SELECT id, user_id, type, status, created_at
FROM alerts.alerts
WHERE user_id = {guest_user_id}
AND type = 'rating_request';
```

### Check Alert Delivery:
- Look at backend logs for `deliver_alert` task
- Check if FCM token was found
- Check if push notification was sent

---

## Summary

### ⚠️ **Important Discovery:**

**You're correct** - there's a timing issue with push notifications!

### Current Behavior:
- ✅ **In-app alerts**: Always work (stored in DB, fetched when user logs in)
- ✅ **Push notifications**: Work ONLY if guest user logs in BEFORE service is logged
- ❌ **Push notifications**: FAIL if guest user logs in AFTER service is logged (no retry mechanism)

### The Issue:
- Alert is created → Celery task runs immediately
- If no FCM token exists → Push fails silently
- When guest logs in later → Token is registered, but alert was already attempted
- No automatic retry when token becomes available

### For Testing:
**Best approach**: Login as guest user FIRST, then perform service log
- This ensures FCM token exists when alert is created
- Push notification will be delivered immediately

**Alternative**: Login as guest user AFTER service log
- In-app alert will work ✅
- Push notification will be missed ❌

### For Production:
See `FCM_RETRY_SOLUTION.md` for implementing retry mechanism when FCM token is registered.

