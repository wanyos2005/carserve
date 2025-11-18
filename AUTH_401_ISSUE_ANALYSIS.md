# 401 Authentication Error Analysis

## Problem Summary
Some users are getting 401 errors when their OTP is valid, while others can log in successfully. The logs show:
- `POST /users/verify-code` returns 401 (even with valid OTP)
- `GET /users/me` returns 401 (after verification)

## Root Causes Identified

### 🔴 **CRITICAL: JWT Library Mismatch**

**Issue**: The backend uses **two different JWT libraries** for encoding and decoding:

1. **Token Creation** (`backend/user_service/core/security.py`):
   ```python
   import jwt  # PyJWT library
   return jwt.encode(to_encode, JWT_SECRET_KEY, algorithm=ALGORITHM)
   ```

2. **Token Validation** (`backend/user_service/routes/users.py`):
   ```python
   from jose import jwt, JWTError  # python-jose library
   payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
   ```

**Impact**: PyJWT and python-jose may encode/decode tokens differently, causing tokens created with one library to fail validation with the other. This is **inconsistent behavior** that could affect some users but not others depending on:
- Token format differences
- Encoding/decoding edge cases
- Library version differences

**Fix**: Use the **same JWT library** for both encoding and decoding.

---

### 🔴 **CRITICAL: Secret Key Variable Mismatch**

**Issue**: Different secret key variables are used:

1. **Token Creation** uses: `JWT_SECRET_KEY`
2. **Token Validation** uses: `SECRET_KEY`

While `config.py` sets them to the same value:
```python
SECRET_KEY = os.getenv("SECRET_KEY") or os.getenv("JWT_SECRET_KEY", "supersecret")
JWT_SECRET_KEY = SECRET_KEY
```

**Potential Issues**:
- If environment variables are set differently in different environments
- If one service reads from a different config source
- Race conditions during initialization

**Fix**: Use the same variable name consistently, or ensure they're always synchronized.

---

### 🟡 **OTP Verification Flow Issues**

**Issue**: Looking at the verification code flow:

1. OTP is checked and deleted immediately after use (line 258)
2. If verification fails after OTP deletion, user can't retry
3. Multiple OTP requests could create race conditions

**Potential Scenarios**:
- User requests new OTP → old OTP still in DB → user enters old code → fails
- User enters correct code but token creation fails → OTP already deleted → can't retry
- Concurrent requests with same email could cause issues

---

### 🟡 **Frontend Token Handling**

**Issue**: In `auth_service.dart`, when verification fails:

```dart
final result = await ApiService.post("/users/verify-code", {...});
if (result != null) {
  final token = result['access_token'];
  await StorageService.setToken(token);
  // ...
}
return false;
```

**Problems**:
1. If `verify-code` returns 401, `result` is `null`, so token is never saved
2. But old/invalid tokens from previous sessions might still be in storage
3. Subsequent `/users/me` calls use the old invalid token → 401 errors
4. No cleanup of invalid tokens on 401 responses

---

### 🟡 **Missing Error Handling**

**Issue**: The frontend doesn't handle 401 responses properly:

```dart
if (response.statusCode >= 200 && response.statusCode < 300) {
  return response.body.isNotEmpty ? jsonDecode(response.body) : null;
}
return null;  // 401 returns null, but doesn't clear invalid tokens
```

**Fix**: On 401 responses, clear stored tokens and redirect to login.

---

## Recommended Fixes

### 1. **Fix JWT Library Consistency** (HIGHEST PRIORITY)

**Option A: Use python-jose everywhere** (Recommended - FastAPI standard)
```python
# backend/user_service/core/security.py
from jose import jwt, JWTError
from core.config import SECRET_KEY, ALGORITHM, JWT_ACCESS_TOKEN_EXPIRE_MINUTES

def create_access_token(data: dict, expires_delta: timedelta = None):
    to_encode = data.copy()
    expire = datetime.utcnow() + (expires_delta or timedelta(minutes=JWT_ACCESS_TOKEN_EXPIRE_MINUTES))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
```

**Option B: Use PyJWT everywhere**
```python
# backend/user_service/routes/users.py
import jwt  # PyJWT
from jwt import InvalidTokenError

def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    try:
        payload = jwt.decode(token, JWT_SECRET_KEY, algorithms=[ALGORITHM])
        # ...
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")
```

### 2. **Standardize Secret Key Usage**

```python
# Always use SECRET_KEY (or always use JWT_SECRET_KEY)
# Update both files to use the same variable
```

### 3. **Improve Frontend Error Handling**

```dart
// In ApiService
static Future<dynamic> post(String path, dynamic body) async {
  final token = await _getToken();
  final response = await http.post(...);
  
  if (response.statusCode == 401) {
    // Clear invalid token
    await StorageService.clearToken();
    await StorageService.clearUser();
    return null;
  }
  
  if (response.statusCode >= 200 && response.statusCode < 300) {
    return response.body.isNotEmpty ? jsonDecode(response.body) : null;
  }
  return null;
}
```

### 4. **Add Better OTP Validation**

- Don't delete OTP until token is successfully created
- Add transaction handling
- Add better error messages

### 5. **Add Logging**

Add detailed logging to track:
- Which users are affected
- Token creation vs validation failures
- OTP validation attempts

---

## Testing Checklist

After fixes:
- [ ] Test OTP verification with valid codes
- [ ] Test OTP verification with expired codes
- [ ] Test OTP verification with invalid codes
- [ ] Test token validation after successful login
- [ ] Test concurrent OTP requests
- [ ] Test with different user accounts
- [ ] Verify tokens work across all services
- [ ] Check logs for any remaining 401 errors

---

## Immediate Action Items

1. **Fix JWT library mismatch** (Critical - affects all users)
2. **Standardize secret key usage** (Critical - security issue)
3. **Add frontend token cleanup on 401** (High - improves UX)
4. **Add better error logging** (Medium - helps debug remaining issues)

