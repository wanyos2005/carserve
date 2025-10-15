# Docker Migration Guide - Enhanced Partner Fields

## Overview

This guide shows how to run the Alembic migration for enhanced partner fields inside the Docker container using docker-compose.

## 🐳 Running Migrations in Docker

### 1. Check Current Migration Status

```bash
# Check current migration status
docker-compose exec insurance-service alembic current

# Check migration history
docker-compose exec insurance-service alembic history --verbose
```

### 2. Run the Enhanced Partner Fields Migration

```bash
# Run the migration to add enhanced partner fields
docker-compose exec insurance-service alembic upgrade head
```

### 3. Verify Migration Success

```bash
# Check that migration was applied
docker-compose exec insurance-service alembic current

# Verify the new columns exist
docker-compose exec insurance-service python -c "
from core.db import engine
from sqlalchemy import text
with engine.connect() as conn:
    result = conn.execute(text(\"\"\"
        SELECT column_name, data_type 
        FROM information_schema.columns 
        WHERE table_schema = 'insurance' 
        AND table_name = 'insurance_partners'
        AND column_name IN (
            'customer_rating', 'total_reviews', 'claims_processing_time', 
            'policy_validity_period', 'special_features', 'logo_url', 
            'website_url', 'established_year', 'market_share', 'awards'
        )
        ORDER BY column_name;
    \"\"\"))
    print('Enhanced partner columns:')
    for row in result:
        print(f'  ✅ {row[0]} ({row[1]})')
"
```

### 4. Test Enhanced Partner Data

```bash
# Test that enhanced data was added
docker-compose exec insurance-service python -c "
from core.db import get_db
from models.insurance import Insurance_Partner
db = next(get_db())
partners = db.query(Insurance_Partner).filter(
    Insurance_Partner.customer_rating.isnot(None)
).all()
print(f'Found {len(partners)} partners with enhanced data:')
for p in partners:
    rating = p.customer_rating / 10.0 if p.customer_rating else 0
    print(f'  🏢 {p.name}: {rating}/5.0 rating, {p.total_reviews} reviews')
"
```

## 🔄 Rollback Migration (if needed)

```bash
# Rollback to previous migration
docker-compose exec insurance-service alembic downgrade -1

# Or rollback to specific revision
docker-compose exec insurance-service alembic downgrade 1ed6d9d8ffb1
```

## 🧪 Test API Endpoints

### Test Enhanced Partner API

```bash
# Test getting partners with enhanced data
curl -X GET "http://localhost:8003/insurance/partners" \
  -H "accept: application/json"

# Test creating a new partner with enhanced data
curl -X POST "http://localhost:8003/insurance/partners" \
  -H "accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Enhanced Partner",
    "code": "TEP",
    "customer_rating": 4.5,
    "total_reviews": 100,
    "claims_processing_time": "24 hours",
    "special_features": ["Test feature 1", "Test feature 2"],
    "market_share": "5%"
  }'
```

## 🐳 Docker Compose Commands Reference

### Basic Container Management

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs insurance-service

# Execute shell in container
docker-compose exec insurance-service bash

# Stop services
docker-compose down
```

### Migration-Specific Commands

```bash
# Check migration status
docker-compose exec insurance-service alembic current

# Show migration history
docker-compose exec insurance-service alembic history

# Run specific migration
docker-compose exec insurance-service alembic upgrade 2a1b2c3d4e5f

# Create new migration (if needed)
docker-compose exec insurance-service alembic revision -m "description"

# Show SQL for migration (dry run)
docker-compose exec insurance-service alembic upgrade head --sql
```

## 🔍 Troubleshooting

### Common Issues

1. **Migration Already Applied**
   ```bash
   # Check current revision
   docker-compose exec insurance-service alembic current
   
   # If already at head, no action needed
   ```

2. **Database Connection Issues**
   ```bash
   # Check if database is running
   docker-compose ps
   
   # Check database logs
   docker-compose logs postgres
   ```

3. **Permission Issues**
   ```bash
   # Ensure proper permissions
   docker-compose exec insurance-service ls -la /app
   ```

### Debug Commands

```bash
# Check database connection
docker-compose exec insurance-service python -c "
from core.db import engine
try:
    with engine.connect() as conn:
        print('✅ Database connection successful')
except Exception as e:
    print(f'❌ Database connection failed: {e}')
"

# Check table structure
docker-compose exec insurance-service python -c "
from core.db import engine
from sqlalchemy import text
with engine.connect() as conn:
    result = conn.execute(text(\"\"\"
        SELECT column_name, data_type, is_nullable
        FROM information_schema.columns 
        WHERE table_schema = 'insurance' 
        AND table_name = 'insurance_partners'
        ORDER BY ordinal_position;
    \"\"\"))
    print('Insurance partners table structure:')
    for row in result:
        print(f'  {row[0]}: {row[1]} (nullable: {row[2]})')
"
```

## 📋 Complete Migration Workflow

```bash
# 1. Start services
docker-compose up -d

# 2. Wait for services to be ready
sleep 10

# 3. Check current migration status
docker-compose exec insurance-service alembic current

# 4. Run migration
docker-compose exec insurance-service alembic upgrade head

# 5. Verify migration
docker-compose exec insurance-service alembic current

# 6. Test enhanced data
docker-compose exec insurance-service python -c "
from core.db import get_db
from models.insurance import Insurance_Partner
db = next(get_db())
partners = db.query(Insurance_Partner).filter(
    Insurance_Partner.customer_rating.isnot(None)
).all()
print(f'✅ Migration successful! Found {len(partners)} enhanced partners')
"

# 7. Test API
curl -X GET "http://localhost:8003/insurance/partners" | jq '.[0] | {name, customer_rating, special_features}'
```

## 🎯 Expected Results

After successful migration, you should see:

1. **New columns added** to `insurance.insurance_partners` table
2. **Sample data populated** for KIC, APA, and CIC partners
3. **API responses** include enhanced fields like `customer_rating`, `special_features`, etc.
4. **Frontend** can now display rich partner information

## 🚀 Next Steps

1. **Test the frontend** - The enhanced partner data should now be available
2. **Add more partners** - Use the enhanced API to create partners with rich data
3. **Monitor performance** - Ensure the new fields don't impact query performance
4. **Update documentation** - Update API docs with new fields

## 📝 Notes

- The migration is **idempotent** - safe to run multiple times
- **Backward compatible** - existing functionality remains unchanged
- **Rollback available** - can revert if needed
- **Sample data included** - KIC, APA, CIC get enhanced data automatically
