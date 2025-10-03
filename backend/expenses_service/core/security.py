#Vehicle_Service/core/security.py
# This module handles JWT token decoding and user authentication.
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
import jwt
from core.config import SECRET_KEY, ALGORITHM

# Adjust tokenUrl if your gateway exposes it under a different path
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="users/login")

def decode_access_token(token: str) -> dict:
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
            headers={"WWW-Authenticate": "Bearer"},
        )

def get_current_user_id(token: str = Depends(oauth2_scheme)) -> str:
    payload = decode_access_token(token)
    sub = payload.get("sub")
    if not sub:
        raise HTTPException(status_code=401, detail="Invalid token payload")
    return sub

def get_current_user_role(token: str = Depends(oauth2_scheme)) -> str:
    payload = decode_access_token(token)
    return payload.get("role", "user")
