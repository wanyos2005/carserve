# Quick Diagnostic Commands for EC2

Run these commands directly on your EC2 instance (via SSH or AWS SSM Session Manager):

```bash
# 1. Check if containers are running
docker ps | grep -E "gateway|nginx"

# 2. Check if port 80 is exposed
docker port gateway 2>/dev/null

# 3. Test nginx from inside container
docker exec gateway curl -s http://localhost/health

# 4. Test user service from nginx
docker exec gateway curl -s http://user-service:8001/health

# 5. Check if port 80 is listening on host
sudo ss -tlnp | grep ":80 " || sudo netstat -tlnp | grep ":80 "

# 6. Test from host
curl -s http://localhost/health

# 7. Check nginx logs
docker logs gateway --tail 20
```

## Most Important: Fix AWS Security Group First!

Before running diagnostics, **fix the Security Group**:
1. AWS Console → EC2 → Your Instance → Security Tab → Security Group
2. Edit Inbound Rules → Add Rule:
   - Type: HTTP
   - Port: 80
   - Source: 0.0.0.0/0
3. Save Rules

Then test from your browser: `http://16.16.124.14/health`

