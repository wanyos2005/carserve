# Oracle Cloud Always Free Tier Deployment Guide

This guide will help you deploy your Car Platform backend to Oracle Cloud using the Always Free tier with ARM A1 instances (much more powerful than GCP's e2-micro).

## Prerequisites

1. **Oracle Cloud Account**: Sign up at [oracle.com/cloud](https://oracle.com/cloud)
2. **Domain Name**: You'll need a domain for SSL certificates
3. **External Databases**: We'll use free managed services (Neon + Upstash)

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

## Step 2: Create Oracle Cloud Account

1. Go to [oracle.com/cloud](https://oracle.com/cloud)
2. Click "Start for free"
3. Fill in your details (usually easier than GCP verification)
4. Verify your email and phone number
5. Add a payment method (required but won't be charged for Always Free resources)

## Step 3: Create ARM A1 Instance

### Using Oracle Cloud Console:
1. Go to **Compute** → **Instances**
2. Click **"Create Instance"**
3. Configure:
   - **Name**: `car-platform-vm`
   - **Image**: Oracle Linux 8 or Ubuntu 22.04 LTS
   - **Shape**: **VM.Standard.A1.Flex** (ARM-based)
   - **OCPU count**: 4 (maximum for Always Free)
   - **Memory**: 24 GB (maximum for Always Free)
   - **Boot volume**: 200 GB (Always Free limit)
   - **Networking**: Use default VCN
   - **SSH Keys**: Add your public SSH key

### Key advantages over GCP:
- **4 ARM cores** vs 1 vCPU
- **24 GB RAM** vs 1 GB RAM
- **200 GB storage** vs 30 GB
- **10 TB egress** vs 1 GB

## Step 4: Configure Security Lists

1. Go to **Networking** → **Virtual Cloud Networks**
2. Click on your VCN → **Security Lists**
3. Click **"Default Security List"**
4. Add these ingress rules:
   - **Source**: 0.0.0.0/0, **IP Protocol**: TCP, **Port**: 22 (SSH)
   - **Source**: 0.0.0.0/0, **IP Protocol**: TCP, **Port**: 80 (HTTP)
   - **Source**: 0.0.0.0.0, **IP Protocol**: TCP, **Port**: 443 (HTTPS)

## Step 5: Deploy Your Application

1. **SSH into your instance**:
   ```bash
   ssh opc@<your-instance-ip>
   # or
   ssh ubuntu@<your-instance-ip>
   ```

2. **Clone your repository**:
   ```bash
   sudo mkdir -p /opt/car-platform
   sudo chown $USER:$USER /opt/car-platform
   cd /opt/car-platform
   git clone https://github.com/wanyos2005/carserve.git .
   ```

3. **Set up environment**:
   ```bash
   cp env.oracle.example .env
   nano .env  # Edit with your actual values
   ```

4. **Bootstrap the system**:
   ```bash
   chmod +x oracle-bootstrap.sh
   ./oracle-bootstrap.sh
   ```

5. **Deploy**:
   ```bash
   chmod +x oracle-deploy.sh
   ./oracle-deploy.sh
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

Point your domain's A record to your instance's public IP:
```bash
# Get your instance's public IP from Oracle Console
# Or run: curl -s ifconfig.me
```

## Step 8: Test Your Deployment

1. **Check service health**:
   ```bash
   curl https://yourdomain.com/health
   curl https://yourdomain.com/users/health
   ```

2. **View logs**:
   ```bash
   docker-compose -f docker-compose.oracle.yml logs -f
   ```

## Monitoring and Maintenance

### View Service Status
```bash
sudo systemctl status car-platform
docker-compose -f docker-compose.oracle.yml ps
```

### Monitor Resources
```bash
htop  # CPU and memory usage
df -h # Disk usage
```

### Backup Database
```bash
/opt/car-platform/backup.sh
```

### Update Application
```bash
cd /opt/car-platform
git pull
./oracle-deploy.sh
```

### View Logs
```bash
# All services
docker-compose -f docker-compose.oracle.yml logs -f

# Specific service
docker-compose -f docker-compose.oracle.yml logs -f user-service
```

## Cost Optimization

### Always Free Tier Limits
- **Compute**: 4 OCPUs + 24 GB RAM (ARM A1)
- **Block Storage**: 200 GB total
- **Networking**: 10 TB egress per month
- **Load Balancer**: 10 Mbps

### To Minimize Costs
1. Use external managed databases (Neon/Upstash) instead of self-hosted
2. Monitor usage in Oracle Console
3. Set up billing alerts
4. Use the ARM A1 shape (more efficient than x86)

## Troubleshooting

### Common Issues

1. **Out of memory**: The A1 has 24GB RAM, so this is unlikely, but monitor with:
   ```bash
   free -h
   docker stats
   ```

2. **Services not starting**: Check logs:
   ```bash
   docker-compose -f docker-compose.oracle.yml logs service-name
   ```

3. **SSL certificate issues**: Ensure your domain points to the instance's IP and wait for DNS propagation.

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

1. **SSH Access**: Restrict SSH to your IP only in security lists
2. **Firewall**: Only open necessary ports (22, 80, 443)
3. **Updates**: Regularly update the system and containers
4. **Secrets**: Store sensitive data in environment variables, not in code
5. **Backups**: Set up automated backups for your database

## Next Steps

Once your basic deployment is working:

1. **Set up monitoring**: Use Oracle Cloud Monitoring for alerts
2. **Implement CI/CD**: Use Oracle Cloud DevOps for automated deployments
3. **Add load balancing**: Use Oracle Load Balancer for high availability
4. **Scale up**: The A1 instance can handle significant traffic

## Support

- **Oracle Documentation**: [docs.oracle.com](https://docs.oracle.com)
- **Neon Documentation**: [neon.tech/docs](https://neon.tech/docs)
- **Upstash Documentation**: [upstash.com/docs](https://upstash.com/docs)

## Comparison: Oracle vs GCP Always Free

| Feature | Oracle A1 | GCP e2-micro |
|---------|-----------|--------------|
| CPU | 4 ARM cores | 1 vCPU |
| RAM | 24 GB | 1 GB |
| Storage | 200 GB | 30 GB |
| Network | 10 TB/month | 1 GB/month |
| Cost | $0 | $0 |
| Performance | Excellent | Limited |

Oracle's ARM A1 instance is significantly more powerful and suitable for production workloads.
