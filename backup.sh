#!/bin/bash

# Database Backup Script for Car Platform
# This script creates automated backups of the PostgreSQL database

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
BACKUP_DIR="./backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="car_platform_backup_${DATE}.sql"
RETENTION_DAYS=30

# Load environment variables
if [ -f ".env" ]; then
    export $(cat .env | grep -v '^#' | xargs)
else
    print_error ".env file not found!"
    exit 1
fi

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

print_status "Starting database backup..."

# Check if PostgreSQL container is running
if ! docker-compose -f docker-compose.prod.yml ps postgres | grep -q "Up"; then
    print_error "PostgreSQL container is not running!"
    exit 1
fi

# Create backup
print_status "Creating backup: $BACKUP_FILE"
docker-compose -f docker-compose.prod.yml exec -T postgres pg_dump \
    -U "$DB_USER" \
    -h localhost \
    -p 5432 \
    "$DB_NAME" > "$BACKUP_DIR/$BACKUP_FILE"

# Check if backup was successful
if [ $? -eq 0 ] && [ -f "$BACKUP_DIR/$BACKUP_FILE" ]; then
    print_status "Backup created successfully: $BACKUP_DIR/$BACKUP_FILE"
    
    # Compress backup
    print_status "Compressing backup..."
    gzip "$BACKUP_DIR/$BACKUP_FILE"
    print_status "Backup compressed: $BACKUP_DIR/$BACKUP_FILE.gz"
    
    # Get backup size
    BACKUP_SIZE=$(du -h "$BACKUP_DIR/$BACKUP_FILE.gz" | cut -f1)
    print_status "Backup size: $BACKUP_SIZE"
    
else
    print_error "Backup failed!"
    exit 1
fi

# Clean up old backups
print_status "Cleaning up backups older than $RETENTION_DAYS days..."
find "$BACKUP_DIR" -name "car_platform_backup_*.sql.gz" -type f -mtime +$RETENTION_DAYS -delete

# List current backups
print_status "Current backups:"
ls -lh "$BACKUP_DIR"/car_platform_backup_*.sql.gz 2>/dev/null || print_warning "No backups found"

print_status "Backup process completed successfully!"
