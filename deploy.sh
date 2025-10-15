#!/bin/bash

# Production Deployment Script for Car Platform Backend
# This script deploys the backend services in production mode

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

# Check if .env file exists
if [ ! -f ".env" ]; then
    print_warning ".env file not found!"
    print_info "Creating .env file from template..."
    cp env.prod.example .env
    
    # Generate a random JWT secret
    if command -v openssl &> /dev/null; then
        JWT_SECRET=$(openssl rand -base64 32)
        sed -i "s/your_jwt_secret_key_here/$JWT_SECRET/" .env
        print_status "Generated random JWT secret key"
    fi
    
    print_warning "Please edit .env file with your production values before continuing"
    print_info "Run: nano .env"
    print_info "Then run this script again"
    exit 1
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    print_error "Docker is not running. Please start Docker and try again."
    exit 1
fi

# Resolve Docker Compose command (v2 preferred)
if command -v docker &> /dev/null && docker compose version &> /dev/null; then
    COMPOSE="docker compose"
elif command -v docker-compose &> /dev/null; then
    COMPOSE="docker-compose"
else
    print_error "Docker Compose is not installed. Please install Docker Compose (v2 'docker compose' preferred)."
    exit 1
fi

print_status "Starting production deployment..."

# Create necessary directories
print_status "Creating necessary directories..."
mkdir -p backups
mkdir -p ssl
mkdir -p monitoring/grafana/dashboards
mkdir -p monitoring/grafana/datasources

# Generate SSL certificates if they don't exist
# ssl certificates is like the keys to the door of the server, it is used to encrypt the traffic between the server and the client
# ensuring that the traffic is not intercepted by anyone else, like a hacker or a malicious user.
if [ ! -f "ssl/cert.pem" ] || [ ! -f "ssl/key.pem" ]; then
    print_warning "SSL certificates not found. Generating self-signed certificates..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout ssl/key.pem \
        -out ssl/cert.pem \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
    print_status "Self-signed SSL certificates generated."
fi

# Stop any existing containers
print_status "Stopping existing containers..."
$COMPOSE -f docker-compose.prod.yml down --remove-orphans

# Build and start services
print_status "Building service images..."
$COMPOSE -f docker-compose.prod.yml build

# Start infra first (so migrations can connect without being gated by healthchecks)
print_status "Starting infrastructure (postgres, redis)..."
$COMPOSE -f docker-compose.prod.yml up -d postgres redis

print_status "Waiting for Postgres to accept connections..."
sleep 8

# Run database migrations as short-lived tasks (independent of healthchecks)
print_status "Running database migrations (one-off containers)..."
$COMPOSE -f docker-compose.prod.yml run --rm user-service alembic upgrade head || true
$COMPOSE -f docker-compose.prod.yml run --rm vehicle-service alembic upgrade head || true
$COMPOSE -f docker-compose.prod.yml run --rm service-provider alembic upgrade head || true
$COMPOSE -f docker-compose.prod.yml run --rm booking-service alembic upgrade head || true
$COMPOSE -f docker-compose.prod.yml run --rm insurance-service alembic upgrade head || true
$COMPOSE -f docker-compose.prod.yml run --rm alert-service alembic upgrade head || true
$COMPOSE -f docker-compose.prod.yml run --rm expenses-service alembic upgrade head || true

print_status "Migrations completed. Starting all services..."
$COMPOSE -f docker-compose.prod.yml up -d

print_status "Waiting for services to report healthy..."
sleep 20

print_status "Current service status:"
$COMPOSE -f docker-compose.prod.yml ps

# Show running services
print_status "Deployment completed! Running services:"
$COMPOSE -f docker-compose.prod.yml ps

print_status "Services are available at:"
print_status "  - API Gateway: https://localhost"
print_status "  - Prometheus: http://localhost:9090"
print_status "  - Grafana: http://localhost:3000 (admin/your_grafana_password)"

print_status "To view logs: $COMPOSE -f docker-compose.prod.yml logs -f [service-name]"
print_status "To stop services: $COMPOSE -f docker-compose.prod.yml down"
