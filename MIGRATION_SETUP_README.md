# Database Schema and Migration Setup Guide

## Overview

This script initializes all database schemas and runs Alembic migrations for all microservices when:
- Alembic migration files exist in the codebase
- But database tables haven't been created yet
- You need to create all schemas and apply migrations

## What the Script Does

1. **Creates All Schemas** (if they don't exist):
   - `users` (for user-service)
   - `vehicles` (for vehicle-service)
   - `service_providers` (for service-provider)
   - `bookings` (for booking-service)
   - `insurance` (for insurance-service)
   - `expenses` (for expenses-service)
   - `alerts` (for alert-service)
   - `social` (for social-service)

2. **For Each Service**:
   - **Upgrade Head**: Applies all existing migrations to create tables
   - **Autogenerate**: Checks if models differ from database (creates new migration if needed)
   - **Upgrade Head Again**: Applies any newly generated migration
   - **Stamp Head**: Ensures the alembic_version table is correctly set

## Usage

### On Your EC2 VM

1. **SSH into your EC2 instance**:
   ```bash
   ssh -i your-key.pem ubuntu@16.16.124.14
   ```

2. **Navigate to your project directory**:
   ```bash
   cd /home/ubuntu/carserve
   ```

3. **Pull the latest code** (if you committed the script):
   ```bash
   git pull
   ```

4. **Make the script executable**:
   ```bash
   chmod +x init-all-schemas-and-migrations-docker-compose.sh
   ```

5. **Ensure all containers are running**:
   ```bash
   docker-compose -f docker-compose.aws.yml ps
   ```

6. **Run the migration script**:
   ```bash
   ./init-all-schemas-and-migrations-docker-compose.sh
   ```

   Or specify a different compose file:
   ```bash
   COMPOSE_FILE=docker-compose.yml ./init-all-schemas-and-migrations-docker-compose.sh
   ```

## What to Expect

The script will:
- ✅ Show green checkmarks for successful operations
- ⚠️ Show yellow warnings for non-critical issues
- ✗ Show red X for failures

Example output:
```
========================================
Database Schema & Migration Initializer
Using: docker-compose.aws.yml
========================================

Step 1: Creating database schemas...
✓ Schema 'users' created/verified
✓ Schema 'vehicles' created/verified
...

Step 2: Running Alembic migrations for each service...

Processing user-service (schema: users)...
  → Upgrading to head (creating tables from migrations)...
✓ Upgraded user-service to head
    Running upgrade -> abc123, create users table
  → Running autogenerate (checking for model changes)...
✓ No model changes detected for user-service
  → Final stamp head (ensuring version table is correct)...
✓ Version table synchronized for user-service
...
```

## Verification

After running the script, verify the setup:

### 1. List All Schemas
```bash
docker-compose -f docker-compose.aws.yml exec postgres psql -U AdminDb -d car_platform -c '\dn'
```

### 2. Check Tables in a Specific Schema
```bash
# For users schema
docker-compose -f docker-compose.aws.yml exec postgres psql -U AdminDb -d car_platform -c '\dt users.*'

# For bookings schema
docker-compose -f docker-compose.aws.yml exec postgres psql -U AdminDb -d car_platform -c '\dt bookings.*'
```

### 3. Check Alembic Version
```bash
docker-compose -f docker-compose.aws.yml exec postgres psql -U AdminDb -d car_platform -c 'SELECT * FROM users.alembic_version;'
```

### 4. Check All Alembic Versions
```bash
for schema in users vehicles service_providers bookings insurance expenses alerts social; do
  echo "=== $schema ==="
  docker-compose -f docker-compose.aws.yml exec postgres psql -U AdminDb -d car_platform -c "SELECT * FROM $schema.alembic_version;" 2>/dev/null || echo "No version table yet"
done
```

## Troubleshooting

### Container Not Running
If you see "Container 'service-name' is not running":
```bash
# Start all services
docker-compose -f docker-compose.aws.yml up -d

# Check status
docker-compose -f docker-compose.aws.yml ps
```

### Migration Errors
If a service fails to migrate:

1. **Check the container logs**:
   ```bash
   docker-compose -f docker-compose.aws.yml logs user-service | tail -50
   ```

2. **Check if alembic is installed**:
   ```bash
   docker-compose -f docker-compose.aws.yml exec user-service alembic --version
   ```

3. **Manually run migration for a specific service**:
   ```bash
   docker-compose -f docker-compose.aws.yml exec user-service alembic upgrade head
   ```

### Database Connection Issues
If schema creation fails:

1. **Verify postgres container is running**:
   ```bash
   docker-compose -f docker-compose.aws.yml ps postgres
   ```

2. **Test database connection**:
   ```bash
   docker-compose -f docker-compose.aws.yml exec postgres psql -U AdminDb -d car_platform -c "SELECT 1;"
   ```

3. **Check .env file**:
   ```bash
   # Verify DB credentials match
   cat .env | grep -E "DB_|DATABASE_"
   ```

## Alternative: Manual Migration per Service

If you prefer to migrate services one at a time:

```bash
# 1. Create schema manually
docker-compose -f docker-compose.aws.yml exec postgres psql -U AdminDb -d car_platform -c "CREATE SCHEMA IF NOT EXISTS users;"

# 2. Run migration for specific service
docker-compose -f docker-compose.aws.yml exec user-service alembic upgrade head

# 3. Check result
docker-compose -f docker-compose.aws.yml exec postgres psql -U AdminDb -d car_platform -c '\dt users.*'
```

## Notes

- The script uses `docker-compose exec` to run commands inside containers
- Each service has its own `alembic.ini` and migration files
- Each service uses its own schema in PostgreSQL
- The `alembic_version` table is created in each schema to track migrations separately
- If autogenerate creates a new migration, it will be automatically applied

