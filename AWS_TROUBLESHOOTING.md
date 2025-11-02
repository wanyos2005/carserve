# AWS EC2 Connection Troubleshooting Guide

## Problem: Cannot Access Public IP (Connection Timeout)

If you're getting `ERR_CONNECTION_TIMED_OUT` when accessing `http://16.16.124.14/users/health`, this is almost certainly an **AWS Security Group** issue.

## Quick Fix: Configure Security Group

### Step 1: Access Your EC2 Instance Security Group

1. Go to **AWS Console** → **EC2** → **Instances**
2. Select your EC2 instance (the one with IP `16.16.124.14`)
3. Click on the **Security** tab
4. Click on the **Security Group** link (e.g., `sg-xxxxx`)

### Step 2: Add Inbound Rule for HTTP

1. In the Security Group page, click **Edit inbound rules**
2. Click **Add rule**
3. Configure:
   - **Type**: HTTP
   - **Protocol**: TCP
   - **Port range**: 80
   - **Source**: `0.0.0.0/0` (for public access) OR `Your-IP/32` (for your IP only - more secure)
   - **Description**: "Allow HTTP from internet"
4. Click **Save rules**

### Step 3: Verify the Rule

Your inbound rules should include:
- **SSH (22)** - for your IP only (recommended)
- **HTTP (80)** - from `0.0.0.0/0` or your specific IP
- **HTTPS (443)** - if you plan to use SSL (optional for now)

### Step 4: Test Connection

Wait 30-60 seconds for the rule to propagate, then test:
```bash
curl http://16.16.124.14/health
# Should return: "healthy"
```

## Additional Troubleshooting Steps

### Check if Nginx Container is Running

SSH into your EC2 instance and run:
```bash
docker ps | grep gateway
# or
docker ps | grep nginx
```

Should show the nginx container running on port 80:80.

### Check if Port 80 is Listening

On your EC2 instance:
```bash
sudo netstat -tlnp | grep :80
# or
sudo ss -tlnp | grep :80
```

Should show something like:
```
tcp   0.0.0.0:80    0.0.0.0:*    LISTEN    <pid>/nginx
```

### Check Docker Compose Status

```bash
cd /home/ubuntu/carserve
docker compose -f docker-compose.aws.yml ps
```

All containers should show as "healthy" or "running".

### Check Nginx Container Logs

```bash
docker logs gateway
# or
docker logs $(docker ps -q -f name=nginx)
```

Look for any errors or startup issues.

### Verify Nginx Config is Loaded

```bash
docker exec gateway nginx -t
# Should return: "nginx: configuration file /etc/nginx/nginx.conf test is successful"
```

### Test from Inside the Container

```bash
docker exec gateway curl http://localhost/health
# Should return: "healthy"
```

### Test Internal Service Connection

```bash
docker exec gateway curl http://user-service:8001/health
# Should return service health status
```

## Network ACL Check (Less Common Issue)

If Security Group is correct but still not working:

1. Go to **VPC** → **Network ACLs**
2. Find the NACL associated with your subnet
3. Ensure **Inbound Rules** allow:
   - **Rule #**: 100
   - **Type**: HTTP (80)
   - **Protocol**: TCP (6)
   - **Port Range**: 80
   - **Source**: 0.0.0.0/0
   - **Allow/Deny**: Allow

## Firewall on EC2 Instance (If Applicable)

If you're using UFW (Ubuntu Firewall):

```bash
sudo ufw status
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw reload
```

## Expected Behavior After Fix

Once the Security Group is configured correctly:

1. ✅ `http://16.16.124.14/health` → Returns "healthy"
2. ✅ `http://16.16.124.14/users/health` → Returns user service health
3. ✅ All other endpoints accessible via the public IP

## Security Best Practices

For production, consider:

1. **Limit SSH Access**: Only allow port 22 from your specific IP (`Your-IP/32`)
2. **Use HTTPS**: Set up SSL/TLS and only expose port 443 publicly
3. **Web Application Firewall**: Consider AWS WAF for additional protection
4. **Rate Limiting**: Already configured in nginx, but verify it's working

## Problem: 504 Gateway Timeout & SSH Hanging

### Symptoms
- Getting `504 Gateway Time-out` from nginx
- SSH connection establishes but hangs after handshake
- Instance appears unresponsive

### Root Cause: Resource Exhaustion on t3.small

A **t3.small** instance has only **2GB RAM**. Running 11+ Docker containers without resource limits can cause:
- Memory exhaustion (OOM kills)
- System swap thrashing
- Services becoming unresponsive
- SSH hanging due to system overload

### Solution: Apply Resource Limits

The `docker-compose.aws.yml` file has been updated with resource limits. You need to:

#### Step 1: Recover Access Using AWS Systems Manager (SSM)

If SSH is hanging, use AWS Systems Manager Session Manager:

1. Go to **AWS Console** → **EC2** → **Instances**
2. Select your instance
3. Click **Connect** → **Session Manager** tab
4. Click **Connect**

#### Step 2: Restart Containers with Resource Limits

Once connected via SSM, run:

```bash
# Navigate to project directory (adjust path if different)
cd ~/car  # or wherever your docker-compose.aws.yml is located

# Pull latest configuration (if using git)
git pull  # optional

# Stop all containers
docker compose -f docker-compose.aws.yml down

# Restart with new resource limits
docker compose -f docker-compose.aws.yml up -d

# Monitor startup
docker compose -f docker-compose.aws.yml ps
```

#### Step 3: Monitor Resource Usage

```bash
# Check memory usage
free -h

# Check container memory usage
docker stats --no-stream

# Check system load
top
# or
htop  # if installed
```

#### Step 4: Verify Services are Running

```bash
# Check all containers are running
docker compose -f docker-compose.aws.yml ps

# Test nginx health endpoint
curl http://localhost/health

# Test a service endpoint
curl http://localhost/users/health
```

### Alternative: Recover via AWS Console (When SSM is Unavailable)

If SSM Agent is not online, you need to reboot the instance via AWS Console:

#### Step 1: Reboot the Instance

1. Go to **AWS Console** → **EC2** → **Instances**
2. Select your instance (check the box next to it)
3. Click **Instance state** dropdown → **Reboot instance**
4. Confirm the reboot
5. Wait **3-5 minutes** for the instance to fully restart

#### Step 2: Verify Instance Status

After waiting, check:
- **Status checks**: Should show "2/2 checks passed"
- **Instance state**: Should show "running"

#### Step 3: Try SSH Again

Once the instance is running, try SSH again:

```powershell
ssh -i "C:\Users\Peter Wanyonyi\Downloads\fastapi-key.pem.pem" ubuntu@16.16.124.14
```

If SSH still hangs, wait 1-2 more minutes and try again (services may still be starting).

#### Step 4: Apply Resource Limits (CRITICAL - Do This Immediately!)

**⚠️ IMPORTANT**: Apply the fixes **immediately** after SSH works, or the instance will exhaust memory again!

Once you're connected via SSH:

```bash
# 1. Navigate to your project directory
cd ~/car
# or wherever your docker-compose.aws.yml file is located

# 2. Pull latest changes (if using git)
git pull
# OR manually upload the updated docker-compose.aws.yml file

# 3. Stop all containers
docker compose -f docker-compose.aws.yml down

# 4. Verify they're stopped
docker ps -a

# 5. Restart with resource limits
docker compose -f docker-compose.aws.yml up -d

# 6. Monitor startup (watch for errors)
docker compose -f docker-compose.aws.yml ps
docker compose -f docker-compose.aws.yml logs -f --tail=50
```

#### Step 5: Verify Services are Running

```bash
# Check all containers
docker compose -f docker-compose.aws.yml ps

# Should see all services as "running" or "healthy"
# If any are restarting, check logs:
docker compose -f docker-compose.aws.yml logs <service-name>

# Test health endpoint
curl http://localhost/health

# Check memory usage
free -h
docker stats --no-stream
```

#### Alternative: Stop and Start Instance (If Reboot Doesn't Work)

If reboot doesn't resolve it:

1. **AWS Console** → **EC2** → **Instances**
2. Select instance → **Instance state** → **Stop instance**
3. Wait for instance to fully stop (status: "stopped")
4. **Instance state** → **Start instance**
5. Wait **5-7 minutes** for full boot and services to start
6. Try SSH again

**Note**: Stopping/starting changes the public IP unless you're using an Elastic IP. Check the new IP in the console.

#### If You Can't Access via SSH After Reboot

If SSH still doesn't work after reboot:

1. **Check Security Group**: Ensure port 22 is open for your IP
2. **Check Instance Status**: Ensure all status checks pass
3. **Check CloudWatch Logs**: 
   - Go to **CloudWatch** → **Logs** → **Log groups**
   - Look for `/var/log/syslog` or system logs
4. **Try EC2 Instance Connect** (if enabled):
   - **EC2 Console** → Select instance → **Connect** → **EC2 Instance Connect** tab

### Resource Allocation Summary

The updated configuration allocates:
- **PostgreSQL**: 384M limit (256M reserved)
- **Redis**: 128M limit (64M reserved)
- **Nginx**: 128M limit (64M reserved)
- **8 Microservices**: 256M each (128M reserved each)
- **Alert Workers**: 128M + 64M (64M + 32M reserved)

**Total Reserved**: ~1.5GB, leaving ~500MB for OS and overhead

### Preventing Future Issues

1. **Monitor CloudWatch**: Set up alarms for CPU and memory
2. **Consider Upgrading**: If traffic grows, upgrade to t3.medium (4GB) or t3.large (8GB)
3. **Use Autoscaling**: Set up Auto Scaling Groups for production
4. **Enable Swap**: Add swap space as emergency buffer (not recommended for production)

## Common Mistakes

1. ❌ Only opening port 22 (SSH) - missing port 80
2. ❌ Opening port 80 only to specific IP when you need public access
3. ❌ Wrong security group attached to the instance
4. ❌ Multiple security groups with conflicting rules
5. ❌ NACL blocking traffic (less common)
6. ❌ Running too many containers on t3.small without resource limits
7. ❌ Not monitoring resource usage until instance becomes unresponsive

