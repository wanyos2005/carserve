#!/bin/bash

# Health Check Script for Car Platform Services
# This script checks the health of all services and provides a status report

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

# Configuration
COMPOSE_FILE="docker-compose.prod.yml"
TIMEOUT=10

print_info "Car Platform Health Check"
print_info "========================="

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

# Function to check service health
check_service() {
    local service_name=$1
    local health_endpoint=$2
    local port=$3
    
    print_info "Checking $service_name..."
    
    # Check if container is running
    if docker-compose -f "$COMPOSE_FILE" ps "$service_name" | grep -q "Up"; then
        print_status "$service_name container is running"
        
        # Check health endpoint if provided
        if [ -n "$health_endpoint" ] && [ -n "$port" ]; then
            if curl -f -s --max-time $TIMEOUT "http://localhost:$port$health_endpoint" > /dev/null 2>&1; then
                print_status "$service_name health endpoint is responding"
            else
                print_warning "$service_name health endpoint is not responding"
            fi
        fi
    else
        print_error "$service_name container is not running"
    fi
}

# Function to check database connectivity
check_database() {
    print_info "Checking database connectivity..."
    
    if docker-compose -f "$COMPOSE_FILE" exec -T postgres pg_isready -U "$DB_USER" -d "$DB_NAME" > /dev/null 2>&1; then
        print_status "PostgreSQL is ready and accepting connections"
    else
        print_error "PostgreSQL is not ready"
    fi
}

# Function to check Redis connectivity
check_redis() {
    print_info "Checking Redis connectivity..."
    
    if docker-compose -f "$COMPOSE_FILE" exec -T redis redis-cli ping > /dev/null 2>&1; then
        print_status "Redis is responding to ping"
    else
        print_error "Redis is not responding"
    fi
}

# Function to check disk space
check_disk_space() {
    print_info "Checking disk space..."
    
    DISK_USAGE=$(df -h . | awk 'NR==2 {print $5}' | sed 's/%//')
    if [ "$DISK_USAGE" -lt 80 ]; then
        print_status "Disk usage is healthy: ${DISK_USAGE}%"
    elif [ "$DISK_USAGE" -lt 90 ]; then
        print_warning "Disk usage is getting high: ${DISK_USAGE}%"
    else
        print_error "Disk usage is critical: ${DISK_USAGE}%"
    fi
}

# Function to check memory usage
check_memory() {
    print_info "Checking memory usage..."
    
    # Get total memory usage of containers
    MEMORY_USAGE=$(docker stats --no-stream --format "table {{.MemUsage}}" | tail -n +2 | awk '{sum += $1} END {print sum}')
    print_info "Total container memory usage: ${MEMORY_USAGE}"
}

# Load environment variables if .env exists
if [ -f ".env" ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Run health checks
echo
check_disk_space
echo
check_memory
echo
check_database
echo
check_redis
echo

# Check all services
check_service "user-service" "/health" "8001"
check_service "vehicle-service" "/health" "8002"
check_service "service-provider" "/health" "8003"
check_service "booking-service" "/health" "8004"
check_service "insurance-service" "/health" "8005"
check_service "alert-service" "/health" "8006"
check_service "expenses-service" "/health" "8007"
check_service "gateway" "/health" "80"

echo
print_info "Checking background workers..."
if docker-compose -f "$COMPOSE_FILE" ps alert-worker | grep -q "Up"; then
    print_status "Alert worker is running"
else
    print_error "Alert worker is not running"
fi

if docker-compose -f "$COMPOSE_FILE" ps alert-beat | grep -q "Up"; then
    print_status "Alert beat scheduler is running"
else
    print_error "Alert beat scheduler is not running"
fi

echo
print_info "Checking monitoring services..."
if docker-compose -f "$COMPOSE_FILE" ps prometheus | grep -q "Up"; then
    print_status "Prometheus is running"
else
    print_warning "Prometheus is not running (optional)"
fi

if docker-compose -f "$COMPOSE_FILE" ps grafana | grep -q "Up"; then
    print_status "Grafana is running"
else
    print_warning "Grafana is not running (optional)"
fi

echo
print_info "Health check completed!"
print_info "For detailed logs, run: docker-compose -f $COMPOSE_FILE logs [service-name]"
