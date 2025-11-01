#!/usr/bin/env python3
"""Quick script to check JWT secret key values"""
from core.config import JWT_SECRET_KEY, ALGORITHM

print(f"JWT_SECRET_KEY: {JWT_SECRET_KEY}")
print(f"JWT_SECRET_KEY length: {len(JWT_SECRET_KEY)}")
print(f"Algorithm: {ALGORITHM}")

