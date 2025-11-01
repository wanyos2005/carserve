#!/bin/bash

# Script to initialize all database schemas and run Alembic migrations
# This script creates all schemas, stamps head, and upgrades to head for each service
# Assumes tables don't exist in the database but alembic versions exist in folders

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Database connection details (from .env or docker-compose)
DB_HOST="${DB_HOST:-postgres}"
DB_PORT="${DB_PORT:-5432}"
DB_NAME="${DB_NAME:-car_platform}"
DB_USER="${DB_USER:-AdminDb}"
DB_PASSWORD="${DB_PASSWORD:-Ngojakwanza}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Database Schema & Migration Initializer${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $2"
    else
        echo -e "${RED}✗${NC} $2"
    fi
}

# Function to run SQL command in postgres container
run_sql() {
    docker exec postgres psql -U "$DB_USER" -d "$DB_NAME" -c "$1" > /dev/null 2>&1
}

# Step 1: Create all schemas
echo -e "${YELLOW}Step 1: Creating database schemas...${NC}"

SCHEMAS=(
    "users"
    "vehicles"
    "service_providers"
    "bookings"
    "insurance"
    "expenses"
    "alerts"
    "social"
)

for schema in "${SCHEMAS[@]}"; do
    if run_sql "CREATE SCHEMA IF NOT EXISTS $schema;"; then
        print_status 0 "Schema '$schema' created/verified"
    else
        print_status 1 "Failed to create schema '$schema'"
    fi
done

echo ""

# Step 2: Run migrations for each service
echo -e "${YELLOW}Step 2: Running Alembic migrations for each service...${NC}"

SERVICES=(
    "user-service:users"
    "vehicle-service:vehicles"
    "service-provider:service_providers"
    "booking-service:bookings"
    "insurance-service:insurance"
    "expenses-service:expenses"
    "alert-service:alerts"
    "social-service:social"
)

for service_config in "${SERVICES[@]}"; do
    IFS=':' read -r service_name schema_name <<< "$service_config"
    
    echo ""
    echo -e "${BLUE}Processing $service_name (schema: $schema_name)...${NC}"
    
    # Check if container is running
    if ! docker ps --format '{{.Names}}' | grep -q "^${service_name}$"; then
        echo -e "${YELLOW}⚠ Container '$service_name' is not running. Skipping...${NC}"
        continue
    fi
    
    # Step 2a: Stamp head (mark current DB state as being at head version)
    echo "  → Stamping head..."
    if docker exec "$service_name" alembic stamp head > /dev/null 2>&1; then
        print_status 0 "Stamped head for $service_name"
    else
        echo -e "${YELLOW}  ⚠ Warning: stamp head failed (might be normal if no migrations exist)${NC}"
    fi
    
    # Step 2b: Autogenerate (create migration if models differ from DB)
    echo "  → Running autogenerate..."
    if docker exec "$service_name" alembic revision --autogenerate -m "Auto-generated migration" > /dev/null 2>&1; then
        print_status 0 "Autogenerate completed for $service_name"
    else
        echo -e "${YELLOW}  ⚠ Warning: autogenerate failed (might be normal if no changes)${NC}"
    fi
    
    # Step 2c: Upgrade head (apply all migrations)
    echo "  → Upgrading to head..."
    if docker exec "$service_name" alembic upgrade head 2>&1; then
        print_status 0 "Upgraded $service_name to head"
    else
        print_status 1 "Failed to upgrade $service_name"
    fi
done

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Migration process completed!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Next steps:"
echo "  1. Verify tables were created: docker exec postgres psql -U $DB_USER -d $DB_NAME -c '\dn'"
echo "  2. Check specific schema tables: docker exec postgres psql -U $DB_USER -d $DB_NAME -c '\dt schema_name.*'"
echo "  3. Check alembic versions: docker exec postgres psql -U $DB_USER -d $DB_NAME -c 'SELECT * FROM schema_name.alembic_version;'"
echo ""

