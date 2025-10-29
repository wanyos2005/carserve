#!/bin/bash

echo "🔒 Applying security hardening to all services..."

# Services to harden (excluding user-service which is already done)
services=("vehicle-service" "service-provider" "booking-service" "insurance-service" "alert-service" "expenses-service" "social-service" "alert-worker" "alert-beat" "gateway" "prometheus" "grafana")

for service in "${services[@]}"; do
    echo "Hardening $service..."
    
    # Find the service section and add security hardening after restart: unless-stopped
    sed -i "/^  $service:/,/^  [a-zA-Z]/ {
        /restart: unless-stopped/a\\
    # Security hardening\\
    security_opt:\\
      - no-new-privileges:true\\
    read_only: true\\
    tmpfs:\\
      - /tmp\\
      - /var/tmp\\
    user: \"1000:1000\"\\
    cap_drop:\\
      - ALL\\
    cap_add:\\
      - NET_BIND_SERVICE\\
    logging:\\
      driver: \"json-file\"\\
      options:\\
        max-size: \"10m\"\\
        max-file: \"3\"
    }" docker-compose.oracle.yml
done

echo "✅ Security hardening applied to all services"
