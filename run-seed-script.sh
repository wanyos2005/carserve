#!/bin/bash

# Script to copy and run seed_data_final.py in the service-provider container

echo "Copying seed_data_final.py into container..."
docker compose -f docker-compose.aws.yml cp backend/service_provider_service/seed_data_final.py service-provider:/app/seed_data_final.py

echo "Running seed script..."
docker compose -f docker-compose.aws.yml exec service-provider python seed_data_final.py

echo "Done!"



















