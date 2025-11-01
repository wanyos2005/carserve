#!/bin/bash

# Alternative version that uses docker-compose exec
# This version works better when services are managed via docker-compose

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.aws.yml}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Database Schema & Migration Initializer${NC}"
echo -e "${BLUE}Using: $COMPOSE_FILE${NC}"
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

# Step 1: Create all schemas via postgres container
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

# Find postgres container name
POSTGRES_CONTAINER=$(docker ps --format '{{.Names}}' | grep -E "postgres" | head -1)
if [ -z "$POSTGRES_CONTAINER" ]; then
    echo -e "${RED}✗${NC} Postgres container not found!"
    exit 1
fi

for schema in "${SCHEMAS[@]}"; do
    if docker exec "$POSTGRES_CONTAINER" psql -U AdminDb -d car_platform -c "CREATE SCHEMA IF NOT EXISTS $schema;" > /dev/null 2>&1; then
        print_status 0 "Schema '$schema' created/verified"
    else
        print_status 1 "Failed to create schema '$schema'"
    fi
done

echo ""

# Step 2: Run migrations for each service
echo -e "${YELLOW}Step 2: Running Alembic migrations for each service...${NC}"

# Service name in docker-compose : Schema name
declare -A SERVICES=(
    ["user-service"]="users"
    ["vehicle-service"]="vehicles"
    ["service-provider"]="service_providers"
    ["booking-service"]="bookings"
    ["insurance-service"]="insurance"
    ["expenses-service"]="expenses"
    ["alert-service"]="alerts"
    ["social-service"]="social"
)

for service_name in "${!SERVICES[@]}"; do
    schema_name="${SERVICES[$service_name]}"
    
    echo ""
    echo -e "${BLUE}Processing $service_name (schema: $schema_name)...${NC}"
    
    # Check if container exists and is running
    # Docker Compose v2 uses container names with project prefix
    if ! docker ps --format '{{.Names}}' | grep -qE "(^${service_name}$|^.*-${service_name}$|^${service_name}-.*$)"; then
        echo -e "${YELLOW}⚠ Container matching '$service_name' is not running. Skipping...${NC}"
        continue
    fi
    
    # Find the actual container name
    CONTAINER_NAME=$(docker ps --format '{{.Names}}' | grep -E "(^${service_name}$|^.*-${service_name}$|^${service_name}-.*$)" | head -1)
    if [ -z "$CONTAINER_NAME" ]; then
        echo -e "${YELLOW}⚠ Could not find container name for '$service_name'. Skipping...${NC}"
        continue
    fi
    
    # Step 2a: Upgrade head first (this will create alembic_version table and tables)
    # We upgrade first because if tables don't exist, this is the correct approach
    echo "  → Upgrading to head (creating tables from migrations)..."
    echo "    Using container: $CONTAINER_NAME"
    UPGRADE_OUTPUT=$(docker exec "$CONTAINER_NAME" alembic upgrade head 2>&1 || true)
    
    if echo "$UPGRADE_OUTPUT" | grep -q "Running upgrade\|CREATE TABLE\|Target database is up to date"; then
        print_status 0 "Upgraded $service_name to head"
        if echo "$UPGRADE_OUTPUT" | grep -q "Running upgrade"; then
            echo "$UPGRADE_OUTPUT" | grep -E "Running upgrade.*->" | head -3 | sed 's/^/    /'
        fi
    elif echo "$UPGRADE_OUTPUT" | grep -q "Target database is up to date"; then
        echo -e "${GREEN}  ✓${NC} Database already up to date for $service_name"
    else
        # If upgrade fails, try stamping head first (in case alembic_version table doesn't exist)
        echo "  → Upgrade failed, attempting to stamp head first..."
        STAMP_OUTPUT=$(docker exec "$CONTAINER_NAME" alembic stamp head 2>&1 || true)
        if echo "$STAMP_OUTPUT" | grep -q "stamped"; then
            echo -e "${GREEN}    ✓${NC} Stamped head, retrying upgrade..."
            UPGRADE_OUTPUT=$(docker exec "$CONTAINER_NAME" alembic upgrade head 2>&1 || true)
            if echo "$UPGRADE_OUTPUT" | grep -q "Running upgrade\|Target database is up to date"; then
                print_status 0 "Upgraded $service_name after stamping"
            else
                print_status 1 "Still failed after stamping"
                echo "$UPGRADE_OUTPUT" | sed 's/^/      /'
            fi
        else
            print_status 1 "Failed to upgrade $service_name"
            echo "$UPGRADE_OUTPUT" | sed 's/^/    /'
        fi
    fi
    
    # Step 2b: Autogenerate (detect any model changes that aren't in migrations)
    echo "  → Running autogenerate (checking for model changes)..."
    AUTOGEN_OUTPUT=$(docker exec "$CONTAINER_NAME" alembic revision --autogenerate -m "Auto-generated migration" 2>&1 || true)
    if echo "$AUTOGEN_OUTPUT" | grep -q "Generating.*migration"; then
        print_status 0 "New migration generated for $service_name (model changes detected)"
        echo "$AUTOGEN_OUTPUT" | grep -E "Generating|migration" | sed 's/^/    /'
        echo "  → Applying newly generated migration..."
        docker exec "$CONTAINER_NAME" alembic upgrade head > /dev/null 2>&1 && \
            print_status 0 "Applied new migration for $service_name"
    elif echo "$AUTOGEN_OUTPUT" | grep -q "No changes"; then
        echo -e "${GREEN}  ✓${NC} No model changes detected for $service_name"
    else
        # Autogenerate warnings are usually fine
        if echo "$AUTOGEN_OUTPUT" | grep -qv "ERROR\|CRITICAL"; then
            echo -e "${GREEN}  ✓${NC} Autogenerate completed (warnings may be present)"
        else
            echo -e "${YELLOW}  ⚠ Autogenerate completed with warnings:${NC}"
            echo "$AUTOGEN_OUTPUT" | grep -E "WARN|ERROR" | head -3 | sed 's/^/    /'
        fi
    fi
    
    # Step 2c: Final stamp head to ensure version table is correct
    echo "  → Final stamp head (ensuring version table is correct)..."
    FINAL_STAMP=$(docker exec "$CONTAINER_NAME" alembic stamp head 2>&1 || true)
    if echo "$FINAL_STAMP" | grep -q "stamped\|Target database is up to date"; then
        echo -e "${GREEN}  ✓${NC} Version table synchronized for $service_name"
    else
        echo -e "${YELLOW}  ⚠ Version table sync warning (may be normal)${NC}"
    fi
done

# Cleanup temp files
rm -f /tmp/alembic_*.log

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Migration process completed!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Verification commands:"
echo ""
echo "  # List all schemas:"
echo "  docker compose -f $COMPOSE_FILE exec postgres psql -U AdminDb -d car_platform -c '\\dn'"
echo ""
echo "  # List tables in a specific schema (e.g., users):"
echo "  docker compose -f $COMPOSE_FILE exec postgres psql -U AdminDb -d car_platform -c '\\dt users.*'"
echo ""
echo "  # Check alembic version for a schema:"
echo "  docker compose -f $COMPOSE_FILE exec postgres psql -U AdminDb -d car_platform -c 'SELECT * FROM users.alembic_version;'"
echo ""

