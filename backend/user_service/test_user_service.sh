#!/bin/bash

# ==========================================
# User Service Tester Script
# ------------------------------------------
# This script lets you:
#   - Register a new user
#   - Login as an existing user
#   - Call /users/me using the token
# ==========================================

BASE_URL="http://localhost:8000/users"

echo "=========================================="
echo "🚗 Car Maintenance Platform - User Service"
echo "=========================================="
echo "What would you like to do?"
echo "1) Register"
echo "2) Login"
read -p "Choose an option (1 or 2): " ACTION

# Ask user for email and password
read -p "Enter email: " EMAIL
read -sp "Enter password: " PASSWORD
echo ""  # new line after password input

if [ "$ACTION" == "1" ]; then
  # ===============================
  # Registration flow
  # ===============================
  read -p "Enter role (customer/garage_admin): " ROLE

  echo "🔹 Registering user..."
  REGISTER_RESPONSE=$(curl -s -X POST $BASE_URL/register \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$EMAIL\", \"password\":\"$PASSWORD\", \"role\":\"$ROLE\"}")

  echo "Register response: $REGISTER_RESPONSE"
fi

# ===============================
# Login flow
# ===============================
echo "🔹 Logging in..."
LOGIN_RESPONSE=$(curl -s -X POST $BASE_URL/login \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$EMAIL\", \"password\":\"$PASSWORD\"}")

echo "Login response: $LOGIN_RESPONSE"

# Extract token using jq (you need jq installed: sudo apt install jq)
TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.access_token')

if [ "$TOKEN" == "null" ] || [ -z "$TOKEN" ]; then
  echo "❌ Login failed, no token received"
  exit 1
fi

echo "✅ Got token!"

# ===============================
# Call /users/me
# ===============================
echo "🔹 Fetching user profile (/users/me)..."
ME_RESPONSE=$(curl -s -X GET $BASE_URL/me \
  -H "Authorization: Bearer $TOKEN")

echo "Me response: $ME_RESPONSE"
