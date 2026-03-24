## Restarts payment-service and send a POST request with only a row sms/unparseable 
docker compose restart payment-service 2>&1 && sleep 5 && curl -s -w "\nHTTP %{http_code}" -X POST http://192.168.0.104:8000/payment-service/mpesa/transactions -H "Content-Type: application/json" -d '{"raw_sms":"Your M-PESA account balance is Ksh2,500.00. 17/03/26"}'

## testing payment delivery logic

docker compose -f docker-compose.aws.yml exec postgres psql -U AdminDb -d car_platform -c "SELECT wdl.status, wdl.http_status, wdl.error, wdl.attempt_number, wdl.created_at 
FROM payments.webhook_delivery_logs wdl
JOIN payments.mpesa_transactions t ON wdl.transaction_id = t.id
WHERE t.transaction_code IN ('TESTPIPE01','TESTPIPE02')
ORDER BY wdl.created_at DESC;"


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

or:
curl -X POST http://173.249.12.47/payment-service/mpesa/transactions \
  -H "Content-Type: application/json" \
  -d '{
    "transaction_code": "TESTPIPE01",
    "raw_sms": "TESTPIPE01 Confirmed. You have received Ksh500.00 from TEST USER 0712345678 on 18/3/2026 at 10:00 AM. New M-PESA balance is Ksh1,000.00.",
    "amount": 500.00,
    "transaction_type": "received",
    "provider_id": "20aaf88e-1723-4e0f-aafb-5372a1bd09fb",
    "source": "sms_reader"
  }'

=== 
To see exactly what DriveOn sends to their endpoints, check the delivery logs after running the curl:


docker compose -f docker-compose.aws.yml exec postgres psql -U AdminDb -d car_platform -c"SELECT wdl.id, ws.callback_url, wdl.status, wdl.http_status, wdl.error, wdl.request_payload, wdl.attempted_at
FROM payments.webhook_delivery_logs wdl
JOIN payments.webhook_subscriptions ws ON wdl.subscription_id = ws.id
JOIN payments.mpesa_transactions t ON wdl.transaction_id = t.id
WHERE t.transaction_code = 'TESTPIPE03'
ORDER BY wdl.attempted_at DESC;"

docker compose -f docker-compose.aws.yml logs payment-worker --tail=50
===
webhooks in db check
docker compose -f docker-compose.aws.yml exec postgres psql -U AdminDb -d car_platform -c \
"SELECT id, provider_id, label, callback_url, is_active FROM payments.webhook_subscriptions;"



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
# 1.1  ssh inside
ssh root@
# 1.2 Update system
apt update && apt upgrade -y
# 1.3 Install Docker
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
newgrp docker

apt install -y docker-compose-plugin

# 1.4. Verify
docker --version && docker compose version

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


---copying local file to online server:
scp C:\systemc\car\.env root@173.249.12.47:/home/carserve/.env
--- updating a value in that file
sed -i 's/ENVIRONMENT=development/ENVIRONMENT=production/' /home/carserve/.env
sed -i 's/LOG_LEVEL=DEBUG/LOG_LEVEL=INFO/' /home/carserve/.env
sed -i 's|ALLOWED_ORIGINS=.*|ALLOWED_ORIGINS=http://173.2.......,http://localhost:8000|' /home/carserve/.en

scp C:\systemc\car\nginx.aws.conf root@173.....7:/home/carserve/nginx.aws.conf

sanity check:
curl -s http://173....47/service-providers/ | head -c 200

=== 
if the server has got firewalld running, you can allow a port 80:
firewall-cmd --add-port=80/tcp --permanent
firewall-cmd --reload


=== 
to create a view:
docker compose -f docker-compose.aws.yml exec postgres \
  psql -U username -d car_platform -c "
CREATE OR REPLACE VIEW service_providers.services_with_categories AS
SELECT 
    s.id            AS service_id,
    s.name          AS service_name,
    s.description   AS service_description,
    s.requirements  AS service_requirements,
    s.created_at    AS service_created_at,
    s.category_id   AS service_category_id,
    sc.name         AS service_category_name
FROM service_providers.services s
LEFT JOIN service_providers.service_categories sc
  ON s.category_id = sc.id;
"

Check if the provider was actually saved:


docker compose -f docker-compose.aws.yml exec postgres psql -U AdminDb -d car_platform -c "
SELECT id, name, is_registered, created_at 
FROM service_providers.providers 
ORDER BY created_at DESC LIMIT 10;"


====
setting up ssl:
full plan once you have a domain (e.g. api.driveon.app):

Step 1 — Point domain to VPS
Add an A record in your domain registrar's DNS:


Type: A
Name: api (or @)
Value: 173.249.12.47
TTL: 300
Wait for DNS propagation (5–30 mins).

Step 2 — Install Certbot on VPS


apt update && apt install -y certbot python3-certbot-nginx
Step 3 — Stop nginx temporarily and get certificate


docker compose -f docker-compose.aws.yml stop nginx
certbot certonly --standalone -d api.driveon.app
docker compose -f docker-compose.aws.yml start nginx
Certbot saves certs to /etc/letsencrypt/live/api.driveon.app/.

Step 4 — Update nginx.aws.conf to add HTTPS listener and mount certs into the nginx container.

Step 5 — Update docker-compose.aws.yml to mount the letsencrypt directory into nginx and expose port 443.

Step 6 — Update Flutter app — change base URL from http://173.249.12.47 to https://api.driveon.app.

Step 7 — Auto-renew — Let's Encrypt certs expire every 90 days. Add a cron job:


certbot renew --pre-hook "docker compose -f /home/carserve/docker-compose.aws.yml stop nginx" \
              --post-hook "docker compose -f /home/carserve/


===
generating ssh for github
ssh-keygen -t rsa -b 4096 -C "github-actions-deploy" -f ~/.ssh/id_rsa -N ""

==
Then authorize it for login:


cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

get it:
cat ~/.ssh/id_rsa

## confirm if vps is not using new code:
The VPS hasn't pulled the latest code. Check:

cd /home/carserve && git status && git log --oneline -3

## Check if the payment-service can actually connect to Redis:


docker compose -f docker-compose.aws.yml exec payment-service python -c "from celery_app import celery_app; print(celery_app.connection().connect())"
## check all Redis keys (not just the celery list — it might be using a different key):


docker compose -f docker-compose.aws.yml exec redis redis-cli keys "*"

##  Now test sending a task directly from the payment-service container:


docker compose -f docker-compose.aws.yml exec payment-service python -c "
from celery_app import celery_app
result = celery_app.send_task('dispatch_webhooks', args=['test-id-123'])
print('Task ID:', result.id)

## testing reachability of a:
curl -v --max-time 10 https://demofms.efikas.co.ke/Mekven/nyolaSms -X POST -H "Content-Type: application/json" -d '{"test": true}' 2>&1
