#!/bin/bash

# AWS EC2 Connection Diagnostic Script
# Run this on your EC2 instance to verify internal setup

echo "========================================="
echo "AWS EC2 Connection Diagnostic"
echo "========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
    else
        echo -e "${RED}✗${NC} $2"
    fi
}

echo "1. Checking Docker containers..."
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "NAME|gateway|nginx"
print_status $? "Docker containers running"

echo ""
echo "2. Checking if nginx container is listening on port 80..."
if docker ps | grep -q "gateway\|nginx"; then
    print_status 0 "Nginx container found"
    docker port gateway 2>/dev/null | grep -q "80" && print_status 0 "Port 80 mapped" || print_status 1 "Port 80 NOT mapped"
else
    print_status 1 "Nginx container not found"
fi

echo ""
echo "3. Testing nginx config..."
docker exec gateway nginx -t 2>&1
print_status $? "Nginx configuration valid"

echo ""
echo "4. Testing nginx health endpoint from inside container..."
HEALTH_RESPONSE=$(docker exec gateway curl -s http://localhost/health 2>&1)
if echo "$HEALTH_RESPONSE" | grep -q "healthy"; then
    print_status 0 "Health endpoint responds: $HEALTH_RESPONSE"
else
    print_status 1 "Health endpoint failed: $HEALTH_RESPONSE"
fi

echo ""
echo "5. Testing user service connection from nginx..."
USER_HEALTH=$(docker exec gateway curl -s http://user-service:8001/health 2>&1)
if [ $? -eq 0 ]; then
    print_status 0 "User service reachable from nginx"
else
    print_status 1 "User service NOT reachable: $USER_HEALTH"
fi

echo ""
echo "6. Checking if port 80 is listening on host..."
if command -v netstat &> /dev/null; then
    netstat -tlnp 2>/dev/null | grep ":80 " && print_status 0 "Port 80 listening on host" || print_status 1 "Port 80 NOT listening on host"
elif command -v ss &> /dev/null; then
    ss -tlnp 2>/dev/null | grep ":80 " && print_status 0 "Port 80 listening on host" || print_status 1 "Port 80 NOT listening on host"
else
    echo -e "${YELLOW}⚠${NC} Cannot check port 80 (netstat/ss not available)"
fi

echo ""
echo "7. Checking nginx logs (last 10 lines)..."
echo "--- Nginx Error Log ---"
docker logs gateway 2>&1 | tail -10

echo ""
echo "8. Testing from host (if curl available)..."
if command -v curl &> /dev/null; then
    HOST_HEALTH=$(curl -s http://localhost/health 2>&1)
    if echo "$HOST_HEALTH" | grep -q "healthy"; then
        print_status 0 "Can reach nginx from host: $HOST_HEALTH"
    else
        print_status 1 "Cannot reach nginx from host: $HOST_HEALTH"
    fi
else
    echo -e "${YELLOW}⚠${NC} curl not available, skipping host test"
fi

echo ""
echo "========================================="
echo "Diagnostic Complete"
echo "========================================="
echo ""
echo "If all internal tests pass but you still can't access from internet:"
echo "  → This is an AWS Security Group issue"
echo "  → Follow instructions in AWS_TROUBLESHOOTING.md"
echo ""
echo "To check your public IP:"
echo "  curl -s ifconfig.me"
echo "  or check AWS Console → EC2 → Instances"
echo ""

