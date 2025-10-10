# 🔐 Environment Variables and Secrets Management Guide

## Overview

This guide covers all environment variables and secrets needed for the CI/CD pipeline.

## GitHub Repository Secrets

### Required Secrets

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `AWS_ROLE_ARN` | IAM Role ARN for GitHub Actions | `arn:aws:iam::123456789012:role/github-actions-role` |
| `AWS_REGION` | AWS Region for deployment | `us-east-1` |
| `EC2_SSH_KEY` | Private SSH key for EC2 access | `-----BEGIN OPENSSH PRIVATE KEY-----\n...` |

### Optional Secrets

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `DOMAIN_NAME` | Your domain name for SSL | `example.com` |
| `UPTIME_ROBOT_API_KEY` | UptimeRobot API key for monitoring | `ur123456-abcdef0123456789` |
| `ALERT_EMAIL` | Email for CloudWatch alerts | `admin@example.com` |

## Environment Files

### Backend (.env)
```bash
# Application
ENVIRONMENT=production
PORT=8000
DEBUG=false
LOG_LEVEL=INFO

# Database (if using)
DATABASE_URL=postgresql://user:pass@localhost:5432/dbname

# External APIs
API_KEY=your-api-key-here
SECRET_KEY=your-secret-key-here
```

### Frontend (.env)
```bash
# Application
NODE_ENV=production
PORT=3000

# API Configuration
API_BASE_URL=http://localhost:8000
FRONTEND_URL=http://localhost:3000

# External Services
ANALYTICS_ID=your-analytics-id
```

## Docker Environment Variables

### Backend Container
```yaml
environment:
  - ENVIRONMENT=production
  - PORT=8000
  - DATABASE_URL=${DATABASE_URL}
  - SECRET_KEY=${SECRET_KEY}
```

### Frontend Container
```yaml
environment:
  - NODE_ENV=production
  - PORT=3000
  - API_BASE_URL=http://backend:8000
```

## AWS Systems Manager Parameter Store (Advanced)

For production environments, consider using AWS Systems Manager Parameter Store:

```bash
# Store secrets
aws ssm put-parameter \
  --name "/fullstack-cicd/database/url" \
  --value "postgresql://..." \
  --type "SecureString"

# Retrieve in application
DATABASE_URL=$(aws ssm get-parameter \
  --name "/fullstack-cicd/database/url" \
  --with-decryption \
  --query 'Parameter.Value' \
  --output text)
```

## Security Best Practices

1. **Never commit secrets to Git**
2. **Use different secrets for different environments**
3. **Rotate secrets regularly**
4. **Use least privilege access**
5. **Monitor secret usage**
6. **Use encrypted storage**

## Local Development

Create `.env.local` files for local development:

```bash
# backend/.env.local
DATABASE_URL=postgresql://localhost:5432/dev_db
DEBUG=true
LOG_LEVEL=DEBUG

# frontend/.env.local
API_BASE_URL=http://localhost:8000
NODE_ENV=development
```

Add to `.gitignore`:
```
.env.local
.env.production
.env.*.local
```
