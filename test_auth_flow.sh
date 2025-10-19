#!/bin/bash

# Test script for authentication flow
# This script helps test the /send-code endpoint to verify the fix

echo "Testing authentication flow..."
echo "================================"

# Test the send-code endpoint
echo "1. Testing /users/send-code endpoint..."
response=$(curl -s -w "\nHTTP_CODE:%{http_code}\n" \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com"}' \
  http://localhost/users/send-code)

echo "Response: $response"

# Extract HTTP code
http_code=$(echo "$response" | grep "HTTP_CODE:" | cut -d: -f2)
echo "HTTP Status Code: $http_code"

if [ "$http_code" = "200" ]; then
    echo "✅ SUCCESS: /send-code endpoint is working correctly"
else
    echo "❌ FAILED: /send-code endpoint returned HTTP $http_code"
    echo "This indicates the nginx routing fix may not be working properly"
fi

echo ""
echo "2. Testing /users/verify-code endpoint (this will fail with invalid code, but should reach the service)..."
response2=$(curl -s -w "\nHTTP_CODE:%{http_code}\n" \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","code":"1234"}' \
  http://localhost/users/verify-code)

echo "Response: $response2"

# Extract HTTP code
http_code2=$(echo "$response2" | grep "HTTP_CODE:" | cut -d: -f2)
echo "HTTP Status Code: $http_code2"

if [ "$http_code2" = "401" ]; then
    echo "✅ SUCCESS: /verify-code endpoint is working correctly (returned 401 for invalid code)"
elif [ "$http_code2" = "502" ] || [ "$http_code2" = "503" ]; then
    echo "❌ FAILED: /verify-code endpoint returned HTTP $http_code2 - connection issue"
else
    echo "✅ SUCCESS: /verify-code endpoint is reachable (returned HTTP $http_code2)"
fi

echo ""
echo "3. Testing health endpoint..."
health_response=$(curl -s -w "\nHTTP_CODE:%{http_code}\n" http://localhost/health)
echo "Health Response: $health_response"

echo ""
echo "Test completed. If you see connection refused errors, the nginx configuration needs to be reloaded."
echo "Run: docker compose restart gateway"
