# OTP Verification Bugs - Why Some Users Fail

## The Real Problem

Looking at the logs, the 401 error happens on `POST /users/verify-code`, which means **OTP validation is failing**, not token validation. This explains why it works for some users but not others.

## Critical Bugs Found

### 🔴 **BUG #1: Multiple OTP Race Condition**

**The Problem:**
```python
# When sending OTP - NO cleanup of old OTPs
otp_entry = OTP(email=req.email, code=code, expires_at=expires_at)
db.add(otp_entry)  # Just adds new OTP, doesn't delete old ones
db.commit()

# When verifying OTP - Gets MOST RECENT OTP
otp_entry = (
    db.query(OTP)
    .filter(OTP.email == email_lower, OTP.code == req.code)
    .order_by(OTP.created_at.desc())  # Gets newest first
    .first()
)
```

**Scenario that causes failure:**
1. User requests OTP #1 → receives code "1234"
2. User doesn't see email, requests OTP #2 → receives code "5678"
3. User finally sees email #1, enters "1234"
4. Query finds OTP #2 (most recent) with code "5678"
5. "1234" ≠ "5678" → **401 error!**

**Why it works for some users:**
- Users who enter the code before requesting a new one → ✅ Works
- Users who request multiple OTPs → ❌ Fails if they enter an old code

---

### 🔴 **BUG #2: String Comparison Issues**

**The Problem:**
```python
.filter(OTP.email == email_lower, OTP.code == req.code)
```

**Potential issues:**
1. **Whitespace**: If user enters " 1234 " or code is stored with spaces
2. **Leading zeros**: Code "0123" vs "123" (though generate_otp(4) should prevent this)
3. **Type mismatch**: If code is stored as int somewhere (unlikely but possible)

**Why it works for some users:**
- Users who copy-paste code exactly → ✅ Works
- Users who type code with spaces → ❌ Might fail
- Users with auto-formatting keyboards → ❌ Might fail

---

### 🔴 **BUG #3: No OTP Cleanup**

**The Problem:**
- Old OTPs are never deleted (except when used)
- Expired OTPs accumulate in database
- Multiple valid OTPs can exist simultaneously

**Impact:**
- Database bloat
- Confusion about which OTP is valid
- Race conditions

---

### 🟡 **BUG #4: Email Normalization Inconsistency**

**The Problem:**
```python
# When sending OTP
otp_entry = OTP(email=req.email, code=code, ...)  # Uses req.email as-is

# When verifying OTP
email_lower = req.email.lower().strip()  # Normalizes email
.filter(OTP.email == email_lower, ...)  # Compares normalized
```

**Potential issue:**
- If `req.email` in send-code has different casing than in verify-code
- If email has trailing/leading spaces in one but not the other

**Why it works for most users:**
- Most users use consistent email format → ✅ Works
- Users with email formatting issues → ❌ Might fail

---

## Why JWT Library Mismatch Wasn't the Main Issue

The JWT library mismatch I fixed earlier is still a valid issue, but it's **not causing the 401 on `/users/verify-code`** because:

1. The 401 happens **before** any token is created
2. Token creation only happens **after** OTP validation succeeds
3. The JWT issue would affect `/users/me` calls, not `/users/verify-code`

However, the JWT fix is still important for token validation after successful login.

---

## Recommended Fixes

### 1. **Clean up old OTPs when sending new one** (CRITICAL)

```python
@router.post("/send-code")
def send_code(req: SendCodeRequest, ...):
    email_lower = req.email.lower().strip()
    
    # ✅ DELETE old OTPs for this email first
    old_otps = db.query(OTP).filter(OTP.email == email_lower).all()
    for otp in old_otps:
        db.delete(otp)
    db.commit()
    
    # Then create new OTP
    code = generate_otp(4)
    expires_at = datetime.utcnow() + timedelta(minutes=5)
    otp_entry = OTP(email=email_lower, code=code, expires_at=expires_at)
    db.add(otp_entry)
    db.commit()
    # ...
```

### 2. **Normalize email when storing OTP** (IMPORTANT)

```python
# Always store normalized email
otp_entry = OTP(email=email_lower, code=code, expires_at=expires_at)
```

### 3. **Normalize code when verifying** (IMPORTANT)

```python
# Normalize code input
code_normalized = req.code.strip()

otp_entry = (
    db.query(OTP)
    .filter(OTP.email == email_lower, OTP.code == code_normalized)
    .order_by(OTP.created_at.desc())
    .first()
)
```

### 4. **Better error messages** (HELPFUL)

```python
# Check if code exists but doesn't match
existing_otps = db.query(OTP).filter(OTP.email == email_lower).all()
if existing_otps:
    # Code exists but doesn't match - more helpful error
    raise HTTPException(status_code=401, detail="Invalid code. Please request a new code.")
else:
    raise HTTPException(status_code=401, detail="No code found. Please request a new code.")
```

### 5. **Clean up expired OTPs periodically** (MAINTENANCE)

Add a background job to delete expired OTPs periodically.

---

## Testing Scenarios

After fixes, test:
- [ ] Request OTP, enter immediately → ✅ Should work
- [ ] Request OTP #1, request OTP #2, enter OTP #1 → ❌ Should fail with clear message
- [ ] Request OTP #1, request OTP #2, enter OTP #2 → ✅ Should work
- [ ] Enter code with spaces " 1234 " → ✅ Should work (after normalization)
- [ ] Enter expired code → ❌ Should fail with "Code expired"
- [ ] Enter invalid code → ❌ Should fail with clear message

