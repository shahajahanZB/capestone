# 🔧 Troubleshooting Guide

## Common Issues and Solutions

### 1. GitHub Actions Failures

#### Error: "Unable to assume role"
```
Error: Could not assume role with OIDC: Not authorized to perform sts:AssumeRoleWithWebIdentity
```

**Solution:**
1. Verify AWS OIDC provider is created
2. Check IAM role trust policy includes correct repository
3. Ensure GitHub secrets are set correctly

#### Error: "Terraform state lock"
```
Error: Error acquiring the state lock
```

**Solution:**
- If you are using **local state**: ensure no other process is running `terraform apply` in the same working directory. You can remove stale lock files or run `terraform init` and retry.

- If you use **Terraform Cloud** (recommended for team workflows): unlock via the Terraform Cloud UI or use `terraform force-unlock LOCK_ID` from a CLI configured for Terraform Cloud.

- If you had previously configured an AWS DynamoDB lock table (older setups), you can remove the lock item manually — but this repository is configured to use a local backend by default now.

### 2. Docker Build Issues

#### Error: "Docker daemon not accessible"
```
Cannot connect to the Docker daemon at unix:///var/run/docker.sock
```

**Solution:**
```bash
# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker
```

#### Error: "No space left on device"
```
Error response from daemon: no space left on device
```

**Solution:**
```bash
# Clean up Docker
docker system prune -a -f
docker volume prune -f

# Check disk usage
df -h
docker system df
```

### 3. Deployment Issues

#### Error: "Health check failed"
```
❌ Backend blue failed health check
```

**Solution:**
```bash
# Check container logs
docker logs backend-blue --tail 50

# Check if service is actually running
curl -f http://localhost:8000/health

# Check container status
docker ps -a | grep backend
```

#### Error: "Image pull failed"
```
Error response from daemon: pull access denied
```

**Solution:**
```bash
# Re-login to GHCR
echo $GITHUB_TOKEN | docker login ghcr.io -u $USERNAME --password-stdin

# Check image exists
docker pull ghcr.io/your-org/backend:latest

# Check image permissions on GitHub
```

### 4. SSL/Nginx Issues

#### Error: "Certificate not found"
```
nginx: [emerg] cannot load certificate "/etc/letsencrypt/live/domain/fullchain.pem"
```

**Solution:**
```bash
# Check certificate status
sudo certbot certificates

# Renew certificate
sudo certbot renew --force-renewal

# Test Nginx config
sudo nginx -t
```

#### Error: "Port already in use"
```
nginx: [emerg] bind() to 0.0.0.0:80 failed (98: Address already in use)
```

**Solution:**
```bash
# Find process using port 80
sudo lsof -i :80
sudo netstat -tulpn | grep :80

# Kill conflicting process
sudo kill -9 PID

# Or stop Apache if running
sudo systemctl stop apache2
```

### 5. Terraform Issues

#### Error: "Invalid provider registry.terraform.io/..."
```
Error: Failed to query available provider packages
```

**Solution:**
```bash
# Clear Terraform cache
rm -rf .terraform/
rm .terraform.lock.hcl

# Re-initialize
terraform init
```

#### Error: "Resource already exists"
```
Error: ResourceAlreadyExistsException: The security group 'sg-...' already exists
```

**Solution:**
```bash
# Import existing resource
terraform import aws_security_group.web sg-existing-id

# Or destroy and recreate
terraform destroy -target=aws_security_group.web
terraform apply
```

### 6. Monitoring Issues

#### CloudWatch Agent Not Sending Metrics
```bash
# Check agent status
sudo systemctl status amazon-cloudwatch-agent

# Check configuration
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -a query

# Restart agent
sudo systemctl restart amazon-cloudwatch-agent
```

#### UptimeRobot Not Working
```bash
# Test API key
curl -X POST https://api.uptimerobot.com/v2/getAccountDetails \
  -d "api_key=YOUR_API_KEY" \
  -d "format=json"

# Check domain accessibility
curl -I https://your-domain.com
```

## Debugging Commands

### System Health
```bash
# Check system resources
htop
free -h
df -h
iostat 1 5

# Check running services
systemctl status docker
systemctl status nginx
systemctl status amazon-cloudwatch-agent
```

### Docker Debugging
```bash
# List all containers
docker ps -a

# Check container logs
docker logs container-name --tail 100 -f

# Execute into container
docker exec -it container-name /bin/bash

# Check container resources
docker stats

# Inspect container configuration
docker inspect container-name
```

### Network Debugging
```bash
# Check open ports
sudo netstat -tulpn
sudo ss -tulpn

# Test connectivity
curl -v http://localhost:3000/health
wget --spider http://localhost:8000/health

# Check DNS resolution
nslookup your-domain.com
dig your-domain.com
```

### Log Analysis
```bash
# Application logs
tail -f /var/log/app/deployment.log
tail -f /var/log/app/monitoring.log

# Nginx logs
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log

# System logs
journalctl -u docker -f
journalctl -u nginx -f
dmesg | tail -20
```

## Recovery Procedures

### Complete System Recovery
```bash
# 1. Stop all services
sudo systemctl stop nginx
docker-compose down

# 2. Clean up Docker
docker system prune -a -f

# 3. Restore from backup
# (Implement backup strategy first)

# 4. Redeploy
./blue-green-deploy.sh deploy
```

### Database Recovery (if applicable)
```bash
# Backup database
pg_dump dbname > backup.sql

# Restore database
psql dbname < backup.sql
```

### Rollback Procedure
```bash
# Quick rollback
./blue-green-deploy.sh rollback

# Manual rollback
docker-compose up -d previous-version
sudo nginx -s reload
```

## Prevention Strategies

1. **Monitoring**: Set up comprehensive monitoring
2. **Backups**: Regular automated backups
3. **Testing**: Thorough testing in staging environment
4. **Documentation**: Keep deployment procedures documented
5. **Alerts**: Set up alerts for critical failures
6. **Health Checks**: Implement proper health checks
7. **Graceful Degradation**: Design for failure scenarios

## Getting Help

1. **Check logs first**: Always start with application and system logs
2. **GitHub Issues**: Check repository issues for similar problems
3. **AWS Support**: Use AWS support for infrastructure issues
4. **Docker Documentation**: Comprehensive Docker troubleshooting guides
5. **Stack Overflow**: Community support for specific technical issues

## Emergency Contacts

- **On-call Engineer**: your-phone-number
- **AWS Support**: (if you have a support plan)
- **Domain Registrar**: for DNS issues
- **Monitoring Service**: UptimeRobot support

Remember: Always test fixes in a development environment first!
