# Database Migration Instructions for Provider Rating Feature

## Overview
This migration adds:
1. **Provider Ratings Table** in `service_providers` schema
2. **New AlertType Enum Values** (`APP_DOWNLOAD_PROMPT`, `RATING_REQUEST`) in `alerts` schema

## Step 1: Create Migration for Service Provider Service

```bash
# Navigate to service provider service directory
cd backend/service_provider_service

# Create a new migration (auto-generate from models)
docker-compose exec service-provider alembic revision --autogenerate -m "add_provider_ratings_table"

# Or if running locally:
alembic revision --autogenerate -m "add_provider_ratings_table"
```

This will create a new migration file in `alembic/versions/` that should include:
- Creating the `provider_ratings` table with columns: id, provider_id, user_id, booking_id, rating, comment, created_at

## Step 2: Create Migration for Alert Service Enum Update

**Note:** If you have multiple migration heads, first merge them:
```bash
docker-compose exec alert-service alembic heads  # Check for multiple heads
docker-compose exec alert-service alembic merge -m "merge_initial_migrations" <head1> <head2>
```

**If tables already exist but migrations aren't marked as applied:**
```bash
# Stamp the existing migrations
docker-compose exec alert-service alembic stamp <revision_id>
```

Then create the enum migration:
```bash
# Navigate to alert service directory
cd backend/alert_service

# Create a new migration (manual - enum changes need manual SQL)
docker-compose exec alert-service alembic revision -m "add_rating_request_and_app_download_alert_types"

# Or if running locally:
alembic revision -m "add_rating_request_and_app_download_alert_types"
```

The migration file has already been created with the correct enum update logic that checks if values exist before adding them.

## Step 3: Run the Migrations

### Option A: Using Docker Compose (Recommended)

```bash
# Run service provider migration
docker-compose exec service-provider alembic upgrade head

# Run alert service migration
docker-compose exec alert-service alembic upgrade head
```

### Option B: Run Both at Once

```bash
# Service provider
cd backend/service_provider_service
docker-compose exec service-provider alembic upgrade head

# Alert service
cd backend/alert_service
docker-compose exec alert-service alembic upgrade head
```

### Option C: Using a Script (if you have one)

If you have a migration script, you can use it:
```bash
./apply_migration.sh
```

## Step 4: Verify Migrations

### Check Service Provider Migration
```bash
docker-compose exec postgres psql -U AdminDb -d car_platform -c "\d service_providers.provider_ratings"
```

### Check Alert Type Enum
```bash
docker-compose exec postgres psql -U AdminDb -d car_platform -c "SELECT unnest(enum_range(NULL::alerts.alerttype));"
```

You should see:
- `insurance_expiry`
- `service_due`
- `promotional`
- `maintenance_reminder`
- `claim_update`
- `payment_reminder`
- `app_download_prompt` ← NEW
- `rating_request` ← NEW

## Troubleshooting

### If enum values already exist
The `IF NOT EXISTS` clause will prevent errors, but if you get duplicate value errors, you can check:
```sql
SELECT enumlabel FROM pg_enum WHERE enumtypid = 'alerts.alerttype'::regtype;
```

### If migration fails
1. Check the migration status: `docker-compose exec alert-service alembic current`
2. Check for conflicts: `docker-compose exec alert-service alembic heads`
3. Rollback if needed: `docker-compose exec alert-service alembic downgrade -1`

## Notes

- The `provider_ratings` table will be created in the `service_providers` schema
- The enum updates are in the `alerts` schema
- PostgreSQL enum values cannot be removed easily, so downgrade for enum is a no-op
- Make sure your services are running before executing migrations

