# GCP Always Free Tier Deployment Guide

This guide will help you deploy your Car Platform backend to Google Cloud Platform using the Always Free tier.

## Prerequisites

1. **Google Cloud Account**: Sign up at [cloud.google.com](https://cloud.google.com)
2. **Domain Name**: You'll need a domain for SSL certificates
3. **External Databases**: We'll use free managed services

## Step 1: Set Up External Databases (Free)

### Neon Postgres (Free Tier)
1. Go to [neon.tech](https://neon.tech) and sign up
2. Create a new project
3. Copy the connection string (it looks like: `postgresql://user:pass@ep-xxx.region.aws.neon.tech/dbname?sslmode=require`)
4. Save this as `NEON_DATABASE_URL` in your `.env` file

### Upstash Redis (Free Tier)
1. Go to [upstash.com](https://upstash.com) and sign up
2. Create a new Redis database
3. Copy the connection string (it looks like: `redis://default:pass@redis-xxx.upstash.io:6379`)
4. Save this as `UPSTASH_REDIS_URL` in your `.env` file

## Step 2: Create GCP Project

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project (e.g., "car-platform-backend")
3. Enable billing (required even for free tier)
4. Enable the Compute Engine API

## Step 3: Create VM Instance

### Using Cloud Console:
1. Go to Compute Engine > VM instances
2. Click "Create Instance"
3. Configure:
   - **Name**: `car-platform-vm`
   - **Region**: `us-west1` or `us-central1` (Always Free eligible)
   - **Machine type**: `e2-micro` (1 vCPU, 1 GB RAM)
   - **Boot disk**: Ubuntu 22.04 LTS, 30 GB standard persistent disk
   - **Firewall**: Allow HTTP and HTTPS traffic
   - **SSH Keys**: Add your public SSH key

### Using gcloud CLI:
```bash
# Install gcloud CLI first, then:
gcloud compute instances create car-platform-vm \
    --zone=us-west1-a \
    --machine-type=e2-micro \
    --image-family=ubuntu-2204-lts \
    --image-project=ubuntu-os-cloud \
    --boot-disk-size=30GB \
    --boot-disk-type=pd-standard \
    --tags=http-server,https-server \
    --metadata-from-file startup-script=gcp-bootstrap.sh
```

## Step 4: Configure Firewall

```bash
# Allow HTTP and HTTPS
gcloud compute firewall-rules create allow-http-https \
    --allow tcp:80,tcp:443 \
    --source-ranges 0.0.0.0/0 \
    --target-tags http-server,https-server
```

## Step 5: Deploy Your Application

1. **SSH into your VM**:
   ```bash
   gcloud compute ssh car-platform-vm --zone=us-west1-a
   ```

2. **Clone your repository**:
   ```bash
   cd /opt/car-platform
   git clone <your-repo-url> .
   ```

3. **Set up environment**:
   ```bash
   cp env.gcp.example .env
   nano .env  # Edit with your actual values
   ```

4. **Deploy**:
   ```bash
   chmod +x gcp-deploy.sh
   ./gcp-deploy.sh
   ```

## Step 6: Configure Domain and SSL

### Option A: Using Caddy (Recommended)
1. **Create Caddyfile**:
   ```bash
   sudo nano /etc/caddy/Caddyfile
   ```
   
   Add:
   ```
   yourdomain.com {
       reverse_proxy localhost:80
   }
   ```

2. **Start Caddy**:
   ```bash
   sudo systemctl enable caddy
   sudo systemctl start caddy
   ```

### Option B: Using Let's Encrypt with Nginx
1. Install certbot:
   ```bash
   sudo apt install certbot python3-certbot-nginx
   ```

2. Get certificate:
   ```bash
   sudo certbot --nginx -d yourdomain.com
   ```

## Step 7: Update DNS

Point your domain's A record to your VM's external IP:
```bash
# Get your VM's external IP
gcloud compute instances describe car-platform-vm \
    --zone=us-west1-a \
    --format='get(networkInterfaces[0].accessConfigs[0].natIP)'
```

## Step 8: Test Your Deployment

1. **Check service health**:
   ```bash
   curl https://yourdomain.com/health
   curl https://yourdomain.com/users/health
   ```

2. **View logs**:
   ```bash
   docker-compose -f docker-compose.gcp.yml logs -f
   ```

## Monitoring and Maintenance

### View Service Status
```bash
sudo systemctl status car-platform
docker-compose -f docker-compose.gcp.yml ps
```

### Backup Database
```bash
/opt/car-platform/backup.sh
```

### Update Application
```bash
cd /opt/car-platform
git pull
./gcp-deploy.sh
```

### View Logs
```bash
# All services
docker-compose -f docker-compose.gcp.yml logs -f

# Specific service
docker-compose -f docker-compose.gcp.yml logs -f user-service
```

## Cost Optimization

### Always Free Tier Limits
- **Compute Engine**: 1 e2-micro instance per month
- **Persistent Disk**: 30 GB standard persistent disk
- **Network**: 1 GB egress per month
- **Static IP**: Not included in free tier (≈$1.46/month)

### To Minimize Costs
1. Use external managed databases (Neon/Upstash) instead of self-hosted
2. Monitor usage in Cloud Console
3. Set up billing alerts
4. Use preemptible instances for non-critical workloads

## Troubleshooting

### Common Issues

1. **Out of memory**: The e2-micro has only 1GB RAM. Monitor with:
   ```bash
   free -h
   docker stats
   ```

2. **Services not starting**: Check logs:
   ```bash
   docker-compose -f docker-compose.gcp.yml logs service-name
   ```

3. **SSL certificate issues**: Ensure your domain points to the VM's IP and wait for DNS propagation.

4. **Database connection issues**: Verify your external database URLs are correct and accessible.

### Useful Commands

```bash
# Restart all services
sudo systemctl restart car-platform

# View resource usage
htop
docker stats

# Check disk space
df -h

# View system logs
journalctl -u car-platform -f
```

## Security Considerations

1. **SSH Access**: Restrict SSH to your IP only
2. **Firewall**: Only open necessary ports (22, 80, 443)
3. **Updates**: Regularly update the system and containers
4. **Secrets**: Store sensitive data in environment variables, not in code
5. **Backups**: Set up automated backups for your database

## Next Steps

Once your basic deployment is working:

1. **Set up monitoring**: Use Cloud Monitoring for alerts
2. **Implement CI/CD**: Use Cloud Build for automated deployments
3. **Add load balancing**: Use Cloud Load Balancer for high availability
4. **Scale up**: Move to larger instances as your traffic grows

## Support

- **GCP Documentation**: [cloud.google.com/docs](https://cloud.google.com/docs)
- **Neon Documentation**: [neon.tech/docs](https://neon.tech/docs)
- **Upstash Documentation**: [upstash.com/docs](https://upstash.com/docs)
