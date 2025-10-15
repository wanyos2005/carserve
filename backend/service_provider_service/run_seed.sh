#!/bin/bash

# Seed script runner for service provider database
# This script runs the seed_data.py script to populate the database

echo "🌱 Starting database seeding process..."
echo "=================================="

# Change to the service provider directory
cd "$(dirname "$0")"

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 is not installed or not in PATH"
    exit 1
fi

# Check if virtual environment exists
if [ -d "venv" ]; then
    echo "📦 Activating virtual environment..."
    source venv/bin/activate
elif [ -d "../venv" ]; then
    echo "📦 Activating parent virtual environment..."
    source ../venv/bin/activate
else
    echo "⚠️  No virtual environment found, using system Python"
fi

# Run the seed script
echo "🚀 Running seed script..."
python3 seed_data.py

# Check exit status
if [ $? -eq 0 ]; then
    echo "✅ Seeding completed successfully!"
else
    echo "❌ Seeding failed!"
    exit 1
fi
