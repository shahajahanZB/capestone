#!/bin/bash

# Blue-Green Deployment Script
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"
NGINX_CONF="/etc/nginx/sites-available/default"
LOG_FILE="/var/log/app/deployment.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Check if container is healthy
check_health() {
    local container_name=$1
    local max_attempts=30
    local attempt=0

    log "${BLUE}Checking health of $container_name...${NC}"

    while [ $attempt -lt $max_attempts ]; do
        if docker ps --filter "name=$container_name" --filter "health=healthy" | grep -q "$container_name"; then
            log "${GREEN}\u2705 $container_name is healthy${NC}"
            return 0
        fi

        log "${YELLOW}\u23f3 Waiting for $container_name to be healthy (attempt $((attempt + 1))/$max_attempts)${NC}"
        sleep 10
        attempt=$((attempt + 1))
    done

    log "${RED}\u274c $container_name failed health check${NC}"
    return 1
}

# Get current active deployment
get_active_deployment() {
    if docker ps --filter "name=frontend-blue" --filter "status=running" | grep -q "frontend-blue"; then
        echo "blue"
    elif docker ps --filter "name=frontend-green" --filter "status=running" | grep -q "frontend-green"; then
        echo "green"
    else
        echo "none"
    fi
}

# Update Nginx configuration
update_nginx_config() {
    local deployment=$1
    local backend_port=$2
    local frontend_port=$3

    log "${BLUE}Updating Nginx configuration for $deployment deployment...${NC}"

    # Backup current config
    sudo cp "$NGINX_CONF" "$NGINX_CONF.backup.$(date +%s)"

    # Create new config
    sudo tee "$NGINX_CONF" > /dev/null << EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name _;

    # Frontend proxy
    location / {
        proxy_pass http://localhost:$frontend_port;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_cache_bypass \$http_upgrade;

        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Backend API proxy
    location /api {
        proxy_pass http://localhost:$backend_port;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Backend health check
    location /health {
        proxy_pass http://localhost:$backend_port/health;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    # Gzip compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
}

# Health check endpoint for load balancer
server {
    listen 8080;
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

    # Test Nginx configuration
    if sudo nginx -t; then
        log "${GREEN}\u2705 Nginx configuration test passed${NC}"
        sudo systemctl reload nginx
        log "${GREEN}\u2705 Nginx reloaded successfully${NC}"
    else
        log "${RED}\u274c Nginx configuration test failed, restoring backup${NC}"
        sudo cp "$NGINX_CONF.backup.$(date +%s)" "$NGINX_CONF"
        return 1
    fi
}

# Main deployment function
deploy() {
    local current_deployment=$(get_active_deployment)
    local target_deployment
    local target_backend_port
    local target_frontend_port

    log "${BLUE}Starting Blue-Green deployment...${NC}"
    log "${BLUE}Current active deployment: $current_deployment${NC}"

    # Determine target deployment
    if [ "$current_deployment" = "blue" ] || [ "$current_deployment" = "none" ]; then
        target_deployment="green"
        target_backend_port="8001"
        target_frontend_port="3001"
    else
        target_deployment="blue"
        target_backend_port="8000"
        target_frontend_port="3000"
    fi

    log "${BLUE}Target deployment: $target_deployment${NC}"

    # Start new deployment
    log "${BLUE}Starting $target_deployment deployment...${NC}"

    if [ "$target_deployment" = "green" ]; then
        docker-compose --profile green -f "$COMPOSE_FILE" up -d
    else
        docker-compose -f "$COMPOSE_FILE" up -d backend-blue frontend-blue
    fi

    # Wait for services to be healthy
    if ! check_health "backend-$target_deployment"; then
        log "${RED}\u274c Backend $target_deployment failed to start healthy${NC}"
        exit 1
    fi

    if ! check_health "frontend-$target_deployment"; then
        log "${RED}\u274c Frontend $target_deployment failed to start healthy${NC}"
        exit 1
    fi

    # Update Nginx to point to new deployment
    if ! update_nginx_config "$target_deployment" "$target_backend_port" "$target_frontend_port"; then
        log "${RED}\u274c Failed to update Nginx configuration${NC}"
        exit 1
    fi

    # Wait a bit for traffic to stabilize
    log "${BLUE}Waiting for traffic to stabilize...${NC}"
    sleep 30

    # Health check the new deployment through Nginx
    if curl -f http://localhost/health > /dev/null 2>&1; then
        log "${GREEN}\u2705 New deployment is accessible through Nginx${NC}"
    else
        log "${RED}\u274c New deployment is not accessible through Nginx${NC}"
        exit 1
    fi

    # Stop old deployment if it exists
    if [ "$current_deployment" != "none" ]; then
        log "${BLUE}Stopping old $current_deployment deployment...${NC}"

        if [ "$current_deployment" = "blue" ]; then
            docker-compose -f "$COMPOSE_FILE" stop backend-blue frontend-blue
            docker-compose -f "$COMPOSE_FILE" rm -f backend-blue frontend-blue
        else
            docker-compose --profile green -f "$COMPOSE_FILE" stop
            docker-compose --profile green -f "$COMPOSE_FILE" rm -f
        fi

        log "${GREEN}\u2705 Old $current_deployment deployment stopped and removed${NC}"
    fi

    # Clean up old Docker images
    log "${BLUE}Cleaning up old Docker images...${NC}"
    docker image prune -f

    log "${GREEN}\ud83c\udf89 Blue-Green deployment completed successfully!${NC}"
    log "${GREEN}\ud83c\udf10 Active deployment: $target_deployment${NC}"
    log "${GREEN}\ud83d\udd17 Application URL: http://$(curl -s ifconfig.me)${NC}"
}

# Rollback function
rollback() {
    log "${YELLOW}\ud83d\udd04 Starting rollback...${NC}"

    local current_deployment=$(get_active_deployment)

    if [ "$current_deployment" = "none" ]; then
        log "${RED}\u274c No active deployment found to rollback from${NC}"
        exit 1
    fi

    # Determine rollback target
    if [ "$current_deployment" = "blue" ]; then
        target_deployment="green"
    else
        target_deployment="blue"
    fi

    # Check if rollback target exists
    if ! docker ps -a --filter "name=backend-$target_deployment" | grep -q "backend-$target_deployment"; then
        log "${RED}\u274c Rollback target ($target_deployment) not found${NC}"
        exit 1
    fi

    log "${BLUE}Rolling back from $current_deployment to $target_deployment...${NC}"

    # Start rollback target
    if [ "$target_deployment" = "green" ]; then
        docker-compose --profile green -f "$COMPOSE_FILE" start
        target_backend_port="8001"
        target_frontend_port="3001"
    else
        docker-compose -f "$COMPOSE_FILE" start backend-blue frontend-blue
        target_backend_port="8000"
        target_frontend_port="3000"
    fi

    # Update Nginx configuration
    if update_nginx_config "$target_deployment" "$target_backend_port" "$target_frontend_port"; then
        log "${GREEN}\u2705 Rollback completed successfully${NC}"
    else
        log "${RED}\u274c Rollback failed${NC}"
        exit 1
    fi
}

# Show status function
status() {
    local current_deployment=$(get_active_deployment)

    echo -e "${BLUE}=== Deployment Status ===${NC}"
    echo -e "Active deployment: ${GREEN}$current_deployment${NC}"
    echo

    echo -e "${BLUE}=== Running Containers ===${NC}"
    docker ps --filter "label=service" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo

    echo -e "${BLUE}=== Nginx Status ===${NC}"
    sudo systemctl status nginx --no-pager -l
    echo

    echo -e "${BLUE}=== Application Health ===${NC}"
    if curl -f http://localhost/health > /dev/null 2>&1; then
        echo -e "${GREEN}\u2705 Application is healthy${NC}"
    else
        echo -e "${RED}\u274c Application is not healthy${NC}"
    fi
}

# Main script logic
case "$1" in
    deploy)
        deploy
        ;;
    rollback)
        rollback
        ;;
    status)
        status
        ;;
    *)
        echo "Usage: $0 {deploy|rollback|status}"
        echo "  deploy   - Deploy new version using blue-green strategy"
        echo "  rollback - Rollback to previous version"
        echo "  status   - Show current deployment status"
        exit 1
        ;;
esac
