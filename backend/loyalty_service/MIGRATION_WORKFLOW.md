# Database Migration Development Workflow

This guide outlines the complete development cycle for database migrations, from local development to production deployment.

## 📋 Overview

The workflow follows these stages:
1. **Development** - Make model changes and generate migration locally
2. **Local Testing** - Test migration on local database
3. **Code Review** - Review migration file before committing
4. **Staging/Test Environment** - Test on staging database (if available)
5. **Production Deployment** - Apply migration to production

---

## 🔄 Complete Workflow Example

### Scenario: Adding a new column `referral_code` to `loyalty_accounts` table

---

## Step 1: Development (Local)

### 1.1 Make Model Changes

Edit your model file:
```python
# backend/loyalty_service/models/loyalty.py

class LoyaltyAccount(Base):
    __tablename__ = "loyalty_accounts"
    __table_args__ = {"schema": "loyalty"}
    
    # ... existing columns ...
    
    # NEW: Add referral code column
    referral_code = Column(String(50), nullable=True, unique=True, index=True)
```

### 1.2 Generate Migration

```bash
# Make sure your local services are running
docker compose up -d

# Generate migration
docker compose exec loyalty-service alembic revision --autogenerate -m "add_referral_code_to_loyalty_accounts"
```

### 1.3 Review Generated Migration

**ALWAYS review the generated migration file!** Autogenerate can miss things or make incorrect assumptions.

```bash
# Check what was generated
cat backend/loyalty_service/alembic/versions/<new_revision>_add_referral_code_to_loyalty_accounts.py
```

**Things to check:**
- ✅ Correct table and column names
- ✅ Correct data types and constraints
- ✅ Indexes are created if needed
- ✅ Default values are appropriate
- ✅ No unintended changes to other tables
- ✅ Foreign keys are correct

### 1.4 Test Migration Locally (Upgrade)

```bash
# Check current migration status
docker compose exec loyalty-service alembic current

# Apply migration
docker compose exec loyalty-service alembic upgrade head

# Verify it worked
docker compose exec loyalty-service alembic current
```

### 1.5 Test Migration Locally (Downgrade - Rollback Test)

**Always test rollback!** This ensures you can recover if something goes wrong.

```bash
# Rollback one migration
docker compose exec loyalty-service alembic downgrade -1

# Verify rollback worked
docker compose exec loyalty-service alembic current

# Re-apply migration
docker compose exec loyalty-service alembic upgrade head
```

### 1.6 Test Application Code

```bash
# Start your application
docker compose up -d loyalty-service

# Test the new column works in your code
# - Create a loyalty account with referral_code
# - Query by referral_code
# - Update referral_code
# - Run your tests
```

### 1.7 Update Application Code

Make sure your application code uses the new column:

```python
# backend/loyalty_service/crud/loyalty.py

def create_loyalty_account(db: Session, user_id: int, referral_code: str = None):
    account = LoyaltyAccount(
        user_id=user_id,
        referral_code=referral_code,  # NEW
        # ... other fields
    )
    db.add(account)
    db.commit()
    return account
```

---

## Step 2: Code Review & Commit

### 2.1 Commit Migration File

```bash
# Add migration file
git add backend/loyalty_service/alembic/versions/<revision>_add_referral_code_to_loyalty_accounts.py

# Add model changes
git add backend/loyalty_service/models/loyalty.py

# Add application code changes
git add backend/loyalty_service/crud/loyalty.py

# Commit
git commit -m "feat: add referral_code column to loyalty_accounts table"
```

### 2.2 Push to Repository

```bash
git push origin feature/add-referral-code
```

### 2.3 Create Pull Request

In your PR, include:
- Description of the change
- Migration file preview
- Testing steps
- Rollback plan (if needed)

---

## Step 3: Staging/Test Environment (If Available)

If you have a staging environment, test there first:

```bash
# SSH into staging server
ssh user@staging-server

# Navigate to project
cd carserve

# Pull latest code
git pull origin main

# Run migration on staging
docker compose -f docker-compose.staging.yml exec loyalty-service alembic upgrade head

# Verify migration
docker compose -f docker-compose.staging.yml exec loyalty-service alembic current

# Test application functionality
# Run integration tests, smoke tests, etc.
```

---

## Step 4: Production Deployment

### 4.1 Pre-Deployment Checklist

- [ ] Migration tested locally (upgrade & downgrade)
- [ ] Application code tested with new schema
- [ ] Code reviewed and approved
- [ ] Backup production database (if possible)
- [ ] Check production database current state
- [ ] Plan rollback strategy
- [ ] Schedule deployment during low-traffic period (if breaking changes)

### 4.2 Deploy to Production

```bash
# SSH into production VM
ssh ubuntu@ip-172-31-15-187

# Navigate to project
cd carserve

# Pull latest code
git pull origin main

# Check current migration status
docker compose -f docker-compose.aws.yml exec loyalty-service alembic current

# IMPORTANT: Check if database is in expected state
docker compose -f docker-compose.aws.yml exec loyalty-service alembic history

# Apply migration
docker compose -f docker-compose.aws.yml exec loyalty-service alembic upgrade head

# Verify migration applied
docker compose -f docker-compose.aws.yml exec loyalty-service alembic current
```

### 4.3 Verify Production Migration

```bash
# Check table structure
docker compose -f docker-compose.aws.yml exec postgres psql -U AdminDb -d car_platform -c "\d loyalty.loyalty_accounts"

# Test a query (if safe)
docker compose -f docker-compose.aws.yml exec loyalty-service python -c "
from core.db import get_db
from models.loyalty import LoyaltyAccount
db = next(get_db())
accounts = db.query(LoyaltyAccount).limit(1).all()
print('✅ Query successful')
"
```

### 4.4 Monitor Application

```bash
# Check service logs
docker compose -f docker-compose.aws.yml logs -f loyalty-service

# Monitor for errors
# Test critical endpoints
```

---

## Step 5: Rollback (If Needed)

If something goes wrong, rollback immediately:

```bash
# Rollback one migration
docker compose -f docker-compose.aws.yml exec loyalty-service alembic downgrade -1

# Verify rollback
docker compose -f docker-compose.aws.yml exec loyalty-service alembic current

# Check application logs
docker compose -f docker-compose.aws.yml logs loyalty-service
```

---

## 🛠️ Useful Commands Reference

### Check Migration Status
```bash
# Current revision
docker compose exec loyalty-service alembic current

# Migration history
docker compose exec loyalty-service alembic history

# Show pending migrations
docker compose exec loyalty-service alembic heads
```

### Generate Migration
```bash
# Autogenerate from models
docker compose exec loyalty-service alembic revision --autogenerate -m "description"

# Create empty migration (for manual SQL)
docker compose exec loyalty-service alembic revision -m "description"
```

### Apply Migrations
```bash
# Apply all pending migrations
docker compose exec loyalty-service alembic upgrade head

# Apply specific revision
docker compose exec loyalty-service alembic upgrade <revision>

# Apply one migration
docker compose exec loyalty-service alembic upgrade +1
```

### Rollback Migrations
```bash
# Rollback one migration
docker compose exec loyalty-service alembic downgrade -1

# Rollback to specific revision
docker compose exec loyalty-service alembic downgrade <revision>

# Rollback to base (careful!)
docker compose exec loyalty-service alembic downgrade base
```

### View SQL (Without Executing)
```bash
# See SQL that would be executed
docker compose exec loyalty-service alembic upgrade head --sql

# See downgrade SQL
docker compose exec loyalty-service alembic downgrade -1 --sql
```

---

## ⚠️ Best Practices

### 1. Always Review Autogenerated Migrations
- Autogenerate can miss things
- It may generate unnecessary changes
- Check for data migrations (if needed)

### 2. Test Both Upgrade and Downgrade
- Always test rollback before production
- Ensure downgrade works correctly

### 3. Never Modify Applied Migrations
- Once a migration is applied to production, never modify it
- Create a new migration to fix issues

### 4. Use Transactions for Data Migrations
```python
def upgrade():
    # Schema changes are automatically transactional
    op.add_column('table', sa.Column('new_col', sa.String()))
    
    # For data migrations, wrap in transaction
    connection = op.get_bind()
    with connection.begin():
        connection.execute(sa.text("UPDATE table SET new_col = 'default'"))
```

### 5. Handle Large Tables Carefully
- For large tables, consider:
  - Adding columns as nullable first, then backfill, then make NOT NULL
  - Using `ALTER TABLE ... ADD COLUMN ... NOT NULL DEFAULT ...` (PostgreSQL 11+)
  - Running during low-traffic periods

### 6. Backup Before Production
```bash
# If you have backup capability
pg_dump $DATABASE_URL > backup_$(date +%Y%m%d_%H%M%S).sql
```

### 7. Document Breaking Changes
- If migration breaks existing functionality, document it
- Provide migration path for users/data

### 8. Test with Production-like Data
- If possible, test migrations on a copy of production data
- This catches issues with real data patterns

---

## 🚨 Common Pitfalls to Avoid

1. **Forgetting to test rollback** - Always test downgrade
2. **Not reviewing autogenerated migrations** - Always review!
3. **Modifying applied migrations** - Never do this
4. **Not testing application code** - Test after migration
5. **Running migrations during peak traffic** - Schedule appropriately
6. **Not backing up** - Always backup before production migrations
7. **Assuming migrations are idempotent** - They're not always
8. **Not checking current state** - Always check `alembic current` first

---

## 📝 Migration File Template

When creating manual migrations:

```python
"""add_referral_code_to_loyalty_accounts

Revision ID: abc123def456
Revises: 4b256f9ea6f3
Create Date: 2025-01-15 10:30:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

# revision identifiers
revision: str = 'abc123def456'
down_revision: Union[str, None] = '4b256f9ea6f3'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

def upgrade() -> None:
    """Add referral_code column to loyalty_accounts."""
    op.add_column(
        'loyalty_accounts',
        sa.Column('referral_code', sa.String(length=50), nullable=True),
        schema='loyalty'
    )
    op.create_index(
        op.f('ix_loyalty_loyalty_accounts_referral_code'),
        'loyalty_accounts',
        ['referral_code'],
        unique=True,
        schema='loyalty'
    )

def downgrade() -> None:
    """Remove referral_code column from loyalty_accounts."""
    op.drop_index(
        op.f('ix_loyalty_loyalty_accounts_referral_code'),
        table_name='loyalty_accounts',
        schema='loyalty'
    )
    op.drop_column('loyalty_accounts', 'referral_code', schema='loyalty')
```

---

## 🔗 Related Documentation

- [Alembic Documentation](https://alembic.sqlalchemy.org/)
- [SQLAlchemy Migrations Guide](https://docs.sqlalchemy.org/en/20/core/metadata.html)

