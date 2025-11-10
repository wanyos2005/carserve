# 🔧 Test Account Troubleshooting Guide

## Issue: Test Account Not Working (401 Error)

If you're getting a 401 error when trying to login with test accounts, follow these steps:

---

## ✅ Step 1: Verify Code Changes Are Deployed

The test account bypass code must be deployed to your server. Check:

1. **Is the code committed?**
   ```bash
   git status
   git log --oneline -5  # Check recent commits
   ```

2. **Is the service restarted?**
   - If using Docker: `docker-compose restart user-service`
   - If using direct deployment: Restart the Python service
   - Check logs to see if service restarted: `docker-compose logs user-service`

3. **Check if TEST_ACCOUNTS exists in the code:**
   ```bash
   grep -n "TEST_ACCOUNTS" backend/user_service/routes/users.py
   ```

---

## 🔍 Step 2: Check Debug Logs

With the debug logging added, you should see output like:

```
DEBUG: verify_code called with email: provider.review@driveon.com (normalized: provider.review@driveon.com)
DEBUG: OTP code provided: 000000
DEBUG: Not a test account: provider.review@driveon.com (normalized: provider.review@driveon.com)
DEBUG: Available test accounts: ['playstore.review@driveon.com', 'provider.review@driveon.com', ...]
```

**What to look for:**
- If you see "Not a test account" → The email matching is failing
- If you see "Test account detected" → The check is working, but something else is wrong
- If you see "Processing test account verification" → The test account path is being executed

---

## 🐛 Common Issues

### Issue 1: Code Not Deployed

**Symptoms:**
- No DEBUG logs appear
- 401 error immediately

**Solution:**
```bash
# Rebuild and restart the service
cd backend/user_service
docker-compose restart user-service
# OR
docker-compose up -d --build user-service
```

### Issue 2: Email Format Mismatch

**Symptoms:**
- DEBUG logs show "Not a test account"
- Email looks correct but doesn't match

**Solution:**
Check for:
- Extra spaces: `"provider.review@driveon.com "` vs `"provider.review@driveon.com"`
- Case sensitivity: Should be handled, but check anyway
- Special characters: Make sure email is exactly as configured

**Fix:**
```python
# In routes/users.py, verify exact match:
TEST_ACCOUNTS = {
    "provider.review@driveon.com": "test-provider-id",  # No spaces, exact match
}
```

### Issue 3: Service Not Restarted

**Symptoms:**
- Old code still running
- Changes not taking effect

**Solution:**
```bash
# Force restart
docker-compose restart user-service

# Or rebuild
docker-compose up -d --build user-service

# Verify restart
docker-compose logs user-service | tail -20
```

### Issue 4: Database User Already Exists

**Symptoms:**
- Test account was created before with different settings
- User exists but not linked properly

**Solution:**
```sql
-- Check if user exists
SELECT id, email, verified FROM users WHERE email = 'provider.review@driveon.com';

-- Check provider link
SELECT * FROM provider_user_links WHERE user_id = (SELECT id FROM users WHERE email = 'provider.review@driveon.com');

-- If needed, delete and recreate
DELETE FROM provider_user_links WHERE user_id = (SELECT id FROM users WHERE email = 'provider.review@driveon.com');
DELETE FROM users WHERE email = 'provider.review@driveon.com';
```

---

## 🧪 Testing Steps

### 1. Test with Debug Logs

```bash
# Watch logs in real-time
docker-compose logs -f user-service

# In another terminal, try to login
# You should see DEBUG output
```

### 2. Test Direct API Call

```bash
# Send OTP (optional for test accounts)
curl -X POST http://localhost:8001/send-code \
  -H "Content-Type: application/json" \
  -d '{"email": "provider.review@driveon.com"}'

# Verify with any code
curl -X POST http://localhost:8001/verify-code \
  -H "Content-Type: application/json" \
  -d '{
    "email": "provider.review@driveon.com",
    "code": "000000"
  }'
```

**Expected Response:**
```json
{
  "access_token": "eyJ...",
  "token_type": "bearer"
}
```

**If 401 Error:**
- Check logs for DEBUG output
- Verify email is in TEST_ACCOUNTS
- Check if service restarted

---

## 🔧 Quick Fix: Force Test Account

If the test account check isn't working, you can temporarily force it:

```python
# In routes/users.py, modify verify_code:
@router.post("/verify-code", response_model=Token)
def verify_code(req: VerifyCodeRequest, db: Session = Depends(get_db)):
    email_lower = req.email.lower().strip()
    
    # TEMPORARY: Force test account for debugging
    FORCE_TEST_ACCOUNTS = [
        "provider.review@driveon.com",
        "playstore.review@driveon.com",
    ]
    
    if email_lower in [e.lower() for e in FORCE_TEST_ACCOUNTS]:
        print(f"FORCE: Treating {req.email} as test account")
        # ... rest of test account logic
```

---

## ✅ Verification Checklist

Before reporting the issue, verify:

- [ ] Code changes are committed to git
- [ ] Service has been restarted/rebuilt
- [ ] DEBUG logs appear when trying to login
- [ ] Email exactly matches TEST_ACCOUNTS entry
- [ ] No extra spaces or characters in email
- [ ] Database doesn't have conflicting user record
- [ ] Service logs show the request reaching verify_code endpoint

---

## 📝 What to Report

If still not working, provide:

1. **Debug logs output:**
   ```bash
   docker-compose logs user-service | grep DEBUG
   ```

2. **Exact email used:**
   - Copy-paste the exact email from your login attempt

3. **TEST_ACCOUNTS configuration:**
   ```python
   # From routes/users.py
   print(TEST_ACCOUNTS)
   ```

4. **Service restart confirmation:**
   - When was the service last restarted?
   - Did you see "Application startup complete" in logs?

---

## 🚀 Quick Reset

If nothing works, try a complete reset:

```bash
# 1. Stop service
docker-compose stop user-service

# 2. Remove container
docker-compose rm -f user-service

# 3. Rebuild
docker-compose build user-service

# 4. Start
docker-compose up -d user-service

# 5. Check logs
docker-compose logs -f user-service
```

Then try logging in again and check the DEBUG output.

---

**After fixing, remove debug print statements for production!**

