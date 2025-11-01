#!/bin/bash

# Fix alert-service multiple heads issue
# Run this inside the alert-service container

echo "Fixing alert-service migration heads..."

# Option 1: Merge the heads (recommended if both migrations are needed)
docker compose -f docker-compose.aws.yml exec alert-service alembic merge heads -m "Merge multiple heads"

# Option 2: Or if you want to keep only one migration, you can:
# 1. Check current heads:
# docker compose -f docker-compose.aws.yml exec alert-service alembic heads
# 
# 2. Merge them:
# docker compose -f docker-compose.aws.yml exec alert-service alembic merge -m "Merge heads" 37f1fda05547 8a8549c1b995
# 
# 3. Or stamp to a specific head if one is correct:
# docker compose -f docker-compose.aws.yml exec alert-service alembic stamp 37f1fda05547

# Then upgrade
echo "Upgrading to head..."
docker compose -f docker-compose.aws.yml exec alert-service alembic upgrade head

echo "Done!"

