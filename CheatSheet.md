## Restarts payment-service and send a POST request with only a row sms/unparseable 
docker compose restart payment-service 2>&1 && sleep 5 && curl -s -w "\nHTTP %{http_code}" -X POST http://192.168.0.104:8000/payment-service/mpesa/transactions -H "Content-Type: application/json" -d '{"raw_sms":"Your M-PESA account balance is Ksh2,500.00. 17/03/26"}'

## testing payment delivery logic

curl -X POST http://192.168.0.104:8000/payment-service/mpesa/transactions \
  -H "Content-Type: application/json" \
  -d '{
    "transaction_code": "TESTPIPE01",
    "raw_sms": "TESTPIPE01 Confirmed. You have received Ksh500.00 from TEST USER 0712345678 on 17/3/2026 at 10:00 AM. New M-PESA balance is Ksh1,000.00.",
    "amount": 500.00,
    "transaction_type": "received",
    "provider_id": "9a8b23c3-fb15-42bc-83a9-f239b0050bdb",
    "source": "sms_reader"
  }'

## when you want to tell the location of the docker-compose in the EC2 instance:
sudo find / -name "docker-compose.aws.yml" 2>/dev/null

## switching to correct user
sudo su - ubuntu


## building new images and running migrations:
# Build and push payment-service image (first time only)
docker build -t ghcr.io/wanyos2005/payment-service:latest ./backend/payment_service
docker push ghcr.io/wanyos2005/payment-service:latest

# Start payment-service + reload nginx
docker compose -f docker-compose.aws.yml up -d payment-service payment-worker
docker compose -f docker-compose.aws.yml restart nginx

# Run migrations
git pull --rebase origin main

docker compose -f docker-compose.aws.yml exec payment-service python -c "
from core.db import Base, engine
from sqlalchemy import text
with engine.connect() as conn:
    conn.execute(text('CREATE SCHEMA IF NOT EXISTS payments'))
    conn.commit()
Base.metadata.create_all(bind=engine)
print('Migrations done')
"
======
setting up new server
======
ssh root@
# 1. Install Docker
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
newgrp docker

# 2. Clone the repo
git clone https://github.com/wanyos2005/carserve.git
cd carserve

# 3. Set up environment variables
cp .env.example .env   # then edit .env with your DB password, secrets, etc.

# 4. Pull all images and start containers
docker compose -f docker-compose.aws.yml pull
docker compose -f docker-compose.aws.yml up -d

# 5. Run all schema creation + migrations
bash init-all-schemas-and-migrations-docker-compose.sh
