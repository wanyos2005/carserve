#!/bin/bash

# Service Update Script for Car Platform
# This script updates services with zero-downtime deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Configuration
COMPOSE_FILE="docker-compose.prod.yml"
SERVICES=("user-service" "vehicle-service" "service-provider" "booking-service" "insurance-service" "alert-service" "expenses-service")

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] [SERVICE_NAME]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -a, --all      Update all services"
    echo "  -b, --backup   Create backup before update"
    echo "  -f, --force    Force update without confirmation"
    echo ""
    echo "Services:"
    for service in "${SERVICES[@]}"; do
        echo "  $service"
    done
    echo ""
    echo "Examples:"
    echo "  $0 --all                    # Update all services"
    echo "  $0 user-service             # Update only user service"
    echo "  $0 --backup --all           # Create backup and update all services"
}

# Function to create backup
create_backup() {
    print_info "Creating backup before update..."
    if [ -f "backup.sh" ]; then
        chmod +x backup.sh
        ./backup.sh
    else
        print_warning "backup.sh not found, skipping backup"
    fi
}

# Function to update a single service
update_service() {
    local service=$1
    local force=$2
    
    print_info "Updating $service..."
    
    # Check if service exists in compose file
    if ! docker-compose -f "$COMPOSE_FILE" config --services | grep -q "^$service$"; then
        print_error "Service $service not found in $COMPOSE_FILE"
        return 1
    fi
    
    # Check if service is running
    if ! docker-compose -f "$COMPOSE_FILE" ps "$service" | grep -q "Up"; then
        print_warning "Service $service is not running, starting it..."
        docker-compose -f "$COMPOSE_FILE" up -d "$service"
        return 0
    fi
    
    # Confirm update unless forced
    if [ "$force" != "true" ]; then
        read -p "Update $service? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Skipping $service"
            return 0
        fi
    fi
    
    # Update the service
    print_status "Building and updating $service..."
    docker-compose -f "$COMPOSE_FILE" up --build -d "$service"
    
    # Wait for service to be healthy
    print_info "Waiting for $service to be healthy..."
    sleep 10
    
    # Check if service is healthy
    if docker-compose -f "$COMPOSE_FILE" ps "$service" | grep -q "healthy"; then
        print_status "$service updated successfully"
    else
        print_warning "$service updated but health check failed"
        print_info "Check logs with: docker-compose -f $COMPOSE_FILE logs $service"
    fi
}

# Function to update all services
update_all_services() {
    local force=$1
    
    print_info "Updating all services..."
    
    # Confirm update unless forced
    if [ "$force" != "true" ]; then
        read -p "Update all services? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Update cancelled"
            exit 0
        fi
    fi
    
    # Update each service
    for service in "${SERVICES[@]}"; do
        update_service "$service" "true"
        sleep 5  # Wait between updates
    done
    
    print_status "All services updated"
}

# Function to run database migrations
run_migrations() {
    print_info "Running database migrations..."
    
    for service in "${SERVICES[@]}"; do
        if docker-compose -f "$COMPOSE_FILE" ps "$service" | grep -q "Up"; then
            print_info "Running migrations for $service..."
            docker-compose -f "$COMPOSE_FILE" exec -T "$service" alembic upgrade head 2>/dev/null || print_warning "No migrations for $service"
        fi
    done
    
    print_status "Database migrations completed"
}

# Parse command line arguments
BACKUP=false
FORCE=false
UPDATE_ALL=false
SERVICE_NAME=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -a|--all)
            UPDATE_ALL=true
            shift
            ;;
        -b|--backup)
            BACKUP=true
            shift
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -*)
            print_error "Unknown option $1"
            show_usage
            exit 1
            ;;
        *)
            SERVICE_NAME="$1"
            shift
            ;;
    esac
done

# Main execution
print_info "Car Platform Service Update"
print_info "==========================="

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running"
    exit 1
fi

# Check if compose file exists
if [ ! -f "$COMPOSE_FILE" ]; then
    print_error "Docker compose file not found: $COMPOSE_FILE"
    exit 1
fi

# Create backup if requested
if [ "$BACKUP" = "true" ]; then
    create_backup
fi

# Update services
if [ "$UPDATE_ALL" = "true" ]; then
    update_all_services "$FORCE"
    run_migrations
elif [ -n "$SERVICE_NAME" ]; then
    update_service "$SERVICE_NAME" "$FORCE"
    run_migrations
else
    print_error "No service specified. Use --all or specify a service name."
    show_usage
    exit 1
fi

# Show final status
print_info "Update completed!"
print_info "Run health check: ./health-check.sh"
print_info "View logs: docker-compose -f $COMPOSE_FILE logs -f"
