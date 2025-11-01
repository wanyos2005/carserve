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

## Common Mistakes

1. ❌ Only opening port 22 (SSH) - missing port 80
2. ❌ Opening port 80 only to specific IP when you need public access
3. ❌ Wrong security group attached to the instance
4. ❌ Multiple security groups with conflicting rules
5. ❌ NACL blocking traffic (less common)

