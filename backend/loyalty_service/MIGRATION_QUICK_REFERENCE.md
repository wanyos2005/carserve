# Migration Quick Reference

Quick commands for common migration tasks.

## 🔍 Check Status

```bash
# Current migration version
docker compose exec loyalty-service alembic current

# All migration history
docker compose exec loyalty-service alembic history

# Pending migrations
docker compose exec loyalty-service alembic heads
```

## ➕ Create Migration

```bash
# Auto-generate from model changes
docker compose exec loyalty-service alembic revision --autogenerate -m "description"

# Create empty migration (for manual SQL)
docker compose exec loyalty-service alembic revision -m "description"
```

## ⬆️ Apply Migrations

```bash
# Apply all pending (LOCAL)
docker compose exec loyalty-service alembic upgrade head

# Apply all pending (PRODUCTION)
docker compose -f docker-compose.aws.yml exec loyalty-service alembic upgrade head

# Apply specific revision
docker compose exec loyalty-service alembic upgrade <revision>

# Apply one step forward
docker compose exec loyalty-service alembic upgrade +1
```

## ⬇️ Rollback Migrations

```bash
# Rollback one step
docker compose exec loyalty-service alembic downgrade -1

# Rollback to specific revision
docker compose exec loyalty-service alembic downgrade <revision>

# Rollback all (DANGEROUS!)
docker compose exec loyalty-service alembic downgrade base
```

## 👀 Preview SQL (Without Executing)

```bash
# See upgrade SQL
docker compose exec loyalty-service alembic upgrade head --sql

# See downgrade SQL
docker compose exec loyalty-service alembic downgrade -1 --sql
```

## 🧪 Testing Workflow

```bash
# 1. Generate migration
docker compose exec loyalty-service alembic revision --autogenerate -m "my_change"

# 2. Review migration file
cat backend/loyalty_service/alembic/versions/<revision>_my_change.py

# 3. Test upgrade
docker compose exec loyalty-service alembic upgrade head

# 4. Test downgrade
docker compose exec loyalty-service alembic downgrade -1

# 5. Re-apply
docker compose exec loyalty-service alembic upgrade head
```

## 🚀 Production Deployment

```bash
# 1. Check current state
docker compose -f docker-compose.aws.yml exec loyalty-service alembic current

# 2. Apply migration
docker compose -f docker-compose.aws.yml exec loyalty-service alembic upgrade head

# 3. Verify
docker compose -f docker-compose.aws.yml exec loyalty-service alembic current

# 4. Check table structure
docker compose -f docker-compose.aws.yml exec postgres psql -U AdminDb -d car_platform -c "\d loyalty.loyalty_accounts"
```

## 🔄 Common Scenarios

### Add a Column
```python
# In model
new_column = Column(String(50), nullable=True)

# Migration will auto-generate:
op.add_column('table_name', sa.Column('new_column', sa.String(length=50), nullable=True), schema='loyalty')
```

### Remove a Column
```python
# Remove from model, then autogenerate
# Or manually:
op.drop_column('table_name', 'column_name', schema='loyalty')
```

### Add Index
```python
op.create_index('ix_table_column', 'table_name', ['column_name'], schema='loyalty')
```

### Add Foreign Key
```python
op.create_foreign_key(
    'fk_name',
    'source_table',
    'target_table',
    ['source_column'],
    ['target_column'],
    source_schema='loyalty',
    referent_schema='loyalty'
)
```

### Rename Column
```python
op.rename_column('table_name', 'old_name', 'new_name', schema='loyalty')
```

### Change Column Type
```python
op.alter_column(
    'table_name',
    'column_name',
    type_=sa.String(length=100),
    existing_type=sa.String(length=50),
    schema='loyalty'
)
```

## ⚠️ Emergency Rollback

```bash
# If production migration fails
docker compose -f docker-compose.aws.yml exec loyalty-service alembic downgrade -1

# Check status
docker compose -f docker-compose.aws.yml exec loyalty-service alembic current

# Check logs
docker compose -f docker-compose.aws.yml logs loyalty-service
```

## 📋 Pre-Deployment Checklist

- [ ] Migration tested locally (upgrade ✓)
- [ ] Migration tested locally (downgrade ✓)
- [ ] Application code tested
- [ ] Migration file reviewed
- [ ] Current production state checked
- [ ] Backup created (if possible)
- [ ] Rollback plan ready
- [ ] Low-traffic window scheduled (if needed)

