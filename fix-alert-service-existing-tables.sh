#!/bin/bash

# Fix alert-service migration when tables already exist
# This stamps the migration since tables were created by startup code

echo "Checking if alert-service tables already exist..."

# Check if tables exist in the alerts schema
TABLE_EXISTS=$(docker compose -f docker-compose.aws.yml exec -T postgres psql -U AdminDb -d car_platform -t -c "
SELECT COUNT(*) FROM information_schema.tables 
WHERE table_schema = 'alerts' 
AND table_name IN ('alerts', 'alert_preferences', 'alert_rules', 'notification_logs');
" 2>/dev/null | tr -d ' ')

if [ "$TABLE_EXISTS" -ge "1" ]; then
    echo "✓ Tables already exist (created by startup code)"
    echo "Stamping migration to merged head..."
    
    # Get the merged head revision
    MERGED_HEAD=$(docker compose -f docker-compose.aws.yml exec -T alert-service alembic heads | grep -o '[a-f0-9]\{12\}' | head -1)
    
    if [ -n "$MERGED_HEAD" ]; then
        echo "Stamping to merged head: $MERGED_HEAD"
        docker compose -f docker-compose.aws.yml exec -T alert-service alembic stamp "$MERGED_HEAD"
        echo "✓ Migration stamped successfully"
    else
        echo "⚠ Could not find merged head, trying heads..."
        docker compose -f docker-compose.aws.yml exec -T alert-service alembic stamp heads
    fi
else
    echo "Tables don't exist, running migration..."
    docker compose -f docker-compose.aws.yml exec -T alert-service alembic upgrade head
fi

echo "Done!"





