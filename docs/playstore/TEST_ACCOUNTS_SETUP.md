# 🧪 Test Accounts Setup for Google Play Review

## Overview

Your app has **two distinct user types** with different features:

1. **Normal Users (Car Owners)** - No provider link
   - Service booking
   - Insurance marketplace
   - Expense tracking
   - Social hub
   - Vehicle management

2. **Provider Users** - Linked to a service provider
   - Provider dashboard
   - Booking management
   - Provider analytics
   - Provider loyalty settings
   - **Plus** all normal user features

**Google Play reviewers should test BOTH account types** to review all functionality.

---

## ✅ Test Accounts Configured

### Account 1: Normal User (Car Owner)
- **Email**: `playstore.review@driveon.com`
- **Type**: Car Owner (no provider link)
- **Features**: All customer-facing features

### Account 2: Provider User
- **Email**: `provider.review@driveon.com`
- **Type**: Provider (linked to provider)
- **Features**: Provider dashboard + all customer features

---

## 🔧 Implementation Details

### Current Configuration

In `backend/user_service/routes/users.py`:

```python
TEST_ACCOUNTS = {
    "playstore.review@driveon.com": None,  # Normal user (car owner)
    "provider.review@driveon.com": "test-provider-id",  # Provider-linked user
    "test.review@driveon.com": None,  # Normal user
    "google.review@driveon.com": None,  # Normal user
    "review@driveon.com": None,  # Normal user
}
```

### How It Works

1. **Normal User Account** (`playstore.review@driveon.com`):
   - `provider_id = None` → User has no provider link
   - Accesses customer features only
   - Frontend shows: Car Owner UI

2. **Provider Account** (`provider.review@driveon.com`):
   - `provider_id = "test-provider-id"` → User linked to provider
   - Accesses provider dashboard + customer features
   - Frontend shows: Provider UI

---

## ⚠️ Important: Update Provider ID

**You need to replace `"test-provider-id"` with a REAL provider ID from your database!**

### Option 1: Use Existing Provider

1. **Find an existing provider ID:**
   ```sql
   SELECT id FROM service_providers.providers LIMIT 1;
   ```

2. **Update the code:**
   ```python
   TEST_ACCOUNTS = {
       "playstore.review@driveon.com": None,
       "provider.review@driveon.com": "your-actual-provider-id-here",  # ← Update this
       ...
   }
   ```

### Option 2: Create a Test Provider

1. **Create a test provider via API or database:**
   ```sql
   INSERT INTO service_providers.providers (id, name, category_id, is_registered)
   VALUES ('test-provider-review', 'Test Provider for Review', 1, true);
   ```

2. **Use that ID:**
   ```python
   "provider.review@driveon.com": "test-provider-review",
   ```

---

## 📋 Play Console Instructions

Use this in **App Access** section:

```
APP ACCESS INSTRUCTIONS FOR GOOGLE PLAY REVIEW

Authentication Method: Email + OTP (One-Time Password)

Our app supports two user types with different features:
1. Normal Users (Car Owners) - Book services, manage insurance, track expenses
2. Provider Users - Provider dashboard, manage bookings, provider-specific features

TEST ACCOUNTS:

Account 1 - Normal User (Car Owner):
Email: playstore.review@driveon.com
User Type: Car Owner (no provider link)
Features: Service booking, insurance marketplace, expense tracking, social hub

Account 2 - Provider User:
Email: provider.review@driveon.com
User Type: Provider (linked to a service provider)
Features: Provider dashboard, booking management, provider analytics, all car owner features

STEP-BY-STEP ACCESS INSTRUCTIONS:

For Normal User (playstore.review@driveon.com):
1. Launch the DriveOn app
2. On the login screen, enter: playstore.review@driveon.com
3. Tap "Send OTP" or "Get Verification Code"
4. Enter any 6-digit code (e.g., 000000, 123456, or any numbers)
5. Tap "Verify" or "Submit"
6. You will have access to:
   - Service booking and management
   - Insurance marketplace
   - Expense tracking
   - Social hub
   - Vehicle management

For Provider User (provider.review@driveon.com):
1. Launch the DriveOn app
2. On the login screen, enter: provider.review@driveon.com
3. Tap "Send OTP" or "Get Verification Code"
4. Enter any 6-digit code (e.g., 000000, 123456, or any numbers)
5. Tap "Verify" or "Submit"
6. You will have access to:
   - Provider dashboard
   - Booking management
   - Provider analytics
   - Provider loyalty settings
   - All normal user features (service booking, insurance, etc.)

IMPORTANT NOTES:
- Both test accounts accept any OTP code for verification
- These accounts are configured specifically for Google Play review
- All app features are accessible after authentication
- No payment or subscription required for testing
- The app does not require any external devices or services
- Please test both account types to review all app functionality

If you encounter any issues accessing the app, please contact us at: support@driveon.com
```

---

## 🧪 Testing Both Accounts

### Test Normal User Account

```bash
# 1. Send OTP (optional)
curl -X POST http://your-api/users/send-code \
  -H "Content-Type: application/json" \
  -d '{"email": "playstore.review@driveon.com"}'

# 2. Verify with any code
curl -X POST http://your-api/users/verify-code \
  -H "Content-Type: application/json" \
  -d '{
    "email": "playstore.review@driveon.com",
    "code": "000000"
  }'

# Should return token and user with provider_id: null
```

### Test Provider Account

```bash
# 1. Send OTP (optional)
curl -X POST http://your-api/users/send-code \
  -H "Content-Type: application/json" \
  -d '{"email": "provider.review@driveon.com"}'

# 2. Verify with any code
curl -X POST http://your-api/users/verify-code \
  -H "Content-Type: application/json" \
  -d '{
    "email": "provider.review@driveon.com",
    "code": "000000"
  }'

# Should return token and user with provider_id: "test-provider-id" (or your actual provider ID)
```

### Verify User Type

```bash
# Get user info (use token from above)
curl -X GET http://your-api/users/me \
  -H "Authorization: Bearer YOUR_TOKEN"

# Check:
# - Normal user: "provider_id": null, "role": "user"
# - Provider user: "provider_id": "test-provider-id", "role": "provider"
```

---

## ✅ Checklist Before Submission

- [ ] Updated `provider.review@driveon.com` with real provider ID
- [ ] Tested normal user account (no provider link)
- [ ] Tested provider account (with provider link)
- [ ] Verified normal user sees customer features only
- [ ] Verified provider user sees provider dashboard + customer features
- [ ] Both accounts accept any OTP code
- [ ] Instructions updated in Play Console
- [ ] Support email provided

---

## 🔄 Adding More Test Accounts

To add more test accounts:

```python
TEST_ACCOUNTS = {
    "playstore.review@driveon.com": None,  # Normal user
    "provider.review@driveon.com": "your-provider-id",  # Provider user
    "another.normal@driveon.com": None,  # Another normal user
    "another.provider@driveon.com": "another-provider-id",  # Another provider
}
```

---

## 📞 Support

If you need help:
1. Finding a provider ID from your database
2. Creating a test provider
3. Testing the accounts
4. Updating the configuration

Contact: support@driveon.com

---

**Both test accounts are ready! Make sure to update the provider ID before deploying! 🚀**

