#!/bin/bash

# Environment Setup Script for Car Platform
# This script sets up the environment configuration for production

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

print_info "Car Platform Environment Setup"
print_info "=============================="

# Check if .env already exists
if [ -f ".env" ]; then
    print_warning ".env file already exists!"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Keeping existing .env file"
        exit 0
    fi
fi

# Copy template to .env
print_status "Creating .env file from template..."
cp env.prod.example .env

print_status ".env file created successfully!"

print_info ""
print_info "Next steps:"
print_info "1. Edit the .env file with your production values:"
print_info "   nano .env"
print_info ""
print_info "2. Important variables to configure:"
print_info "   - DB_PASSWORD: Strong database password"
print_info "   - JWT_SECRET_KEY: Random secret key for JWT tokens"
print_info "   - SMTP_PASSWORD: Gmail app password"
print_info "   - AT_API_KEY: Africa's Talking API key"
print_info "   - GRAFANA_PASSWORD: Grafana admin password"
print_info ""
print_info "3. Deploy with:"
print_info "   ./deploy.sh"
print_info ""

# Generate a random JWT secret if not set
if grep -q "your_jwt_secret_key_here" .env; then
    JWT_SECRET=$(openssl rand -base64 32)
    sed -i "s/your_jwt_secret_key_here/$JWT_SECRET/" .env
    print_status "Generated random JWT secret key"
fi

print_status "Environment setup completed!"
