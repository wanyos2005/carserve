# Database Migrations

This directory contains SQL migration files for the car platform database.

## Migration Naming Convention

- `001_initial_schema.sql` - Initial database setup
- `002_add_user_preferences.sql` - Add user preferences table
- `003_update_vehicle_schema.sql` - Update vehicle schema
- etc.

## How to Apply Migrations

### Option 1: Using Neon Dashboard (Recommended for now)
1. Copy the SQL content from the migration file
2. Paste it into Neon SQL Editor
3. Execute the SQL

### Option 2: Using psql (Future)
```bash
psql $DATABASE_URL -f migrations/001_initial_schema.sql
```

### Option 3: Using Docker (Future)
```bash
docker compose -f docker-compose.oracle.yml run --rm postgres psql $DATABASE_URL -f /migrations/001_initial_schema.sql
```

## Migration History

| Version | File | Description | Applied Date |
|---------|------|-------------|--------------|
| 001 | `001_initial_schema.sql` | Initial database schema for all services | 2025-10-18 |

## Best Practices

1. **Always backup** before applying migrations
2. **Test migrations** on a copy of production data first
3. **Use transactions** for complex migrations
4. **Document changes** in the migration file header
5. **Version control** all migration files
6. **Never modify** applied migrations (create new ones instead)

## Rollback Strategy

For each migration, consider creating a rollback script:
- `001_initial_schema_rollback.sql` - Drops all tables and schemas

## Future Enhancements

- [ ] Automated migration runner script
- [ ] Migration status tracking table
- [ ] Integration with CI/CD pipeline
- [ ] Rollback automation
