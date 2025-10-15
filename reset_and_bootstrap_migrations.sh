#!/usr/bin/env bash
set -euo pipefail
COMPOSE="docker compose -f docker-compose.prod.yml"
$COMPOSE down
$COMPOSE up -d postgres
mkdir -p backups
docker compose exec postgres pg_dump -U AdminDb -d car_platform > backups/car_platform_$(date +%F_%H%M).sql || true
for SCHEMA in bookings vehicles service_providers insurance expense; do
  docker compose exec postgres psql -U AdminDb -d car_platform -c "DROP SCHEMA IF EXISTS ${SCHEMA} CASCADE; CREATE SCHEMA ${SCHEMA} AUTHORIZATION \"AdminDb\";"
done
rm -f backend/booking_service/alembic/versions/*.py || true
rm -f backend/vehicle_service/alembic/versions/*.py || true
rm -f backend/service_provider_service/alembic/versions/*.py || true
rm -f backend/insurance_service/alembic/versions/*.py || true
rm -f backend/expenses_service/alembic/versions/*.py || true
$COMPOSE build booking-service vehicle-service service-provider insurance-service expenses-service
$COMPOSE run --rm --no-deps booking-service sh -c "alembic revision --autogenerate -m 'initial' && alembic upgrade head"
$COMPOSE run --rm --no-deps vehicle-service sh -c "alembic revision --autogenerate -m 'initial' && alembic upgrade head"
$COMPOSE run --rm --no-deps service-provider sh -c "alembic revision --autogenerate -m 'initial' && alembic upgrade head"
$COMPOSE run --rm --no-deps insurance-service sh -c "alembic revision --autogenerate -m 'initial' && alembic upgrade head"
$COMPOSE run --rm --no-deps expenses-service sh -c "alembic revision --autogenerate -m 'initial' && alembic upgrade head"
docker compose exec postgres psql -U AdminDb -d car_platform -c "\dt bookings.*"
docker compose exec postgres psql -U AdminDb -d car_platform -c "\dt vehicles.*"
docker compose exec postgres psql -U AdminDb -d car_platform -c "\dt service_providers.*"
docker compose exec postgres psql -U AdminDb -d car_platform -c "\dt insurance.*"
docker compose exec postgres psql -U AdminDb -d car_platform -c "\dt expense.*"
$COMPOSE up -d --force-recreate
$COMPOSE ps
