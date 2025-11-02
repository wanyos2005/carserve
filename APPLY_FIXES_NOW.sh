#!/bin/bash
# Quick fix script to apply resource limits after SSH recovery

echo "=== Fixing Git Permissions ==="
# Fix ownership of git directory
sudo chown -R ubuntu:ubuntu ~/carserve/.git
sudo chown -R ubuntu:ubuntu ~/carserve

echo "=== Pulling Latest Changes ==="
cd ~/carserve
git pull

echo "=== Checking Current Container Status ==="
docker compose -f docker-compose.aws.yml ps

echo "=== Stopping All Containers ==="
docker compose -f docker-compose.aws.yml down

echo "=== Waiting 10 seconds for cleanup ==="
sleep 10

echo "=== Verifying Containers Stopped ==="
docker ps -a | head -5

echo "=== Restarting with Resource Limits ==="
docker compose -f docker-compose.aws.yml up -d

echo "=== Waiting 30 seconds for startup ==="
sleep 30

echo "=== Checking Container Status ==="
docker compose -f docker-compose.aws.yml ps

echo "=== Checking Memory Usage ==="
free -h

echo "=== Container Resource Usage ==="
docker stats --no-stream | head -15

echo "=== Testing Health Endpoint ==="
curl -s http://localhost/health || echo "Health check failed - containers may still be starting"

echo ""
echo "=== DONE ==="
echo "Monitor with: docker compose -f docker-compose.aws.yml logs -f"
echo "Or check status: docker compose -f docker-compose.aws.yml ps"

