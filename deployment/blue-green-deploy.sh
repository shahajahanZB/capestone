#!/bin/bash

# Frontend Blue-Green Deployment Script (backend removed)
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

log() { echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"; }

get_active_deployment() {
    if docker ps --filter "name=frontend-blue" --filter "status=running" | grep -q "frontend-blue"; then
        echo "blue"
    elif docker ps --filter "name=frontend-green" --filter "status=running" | grep -q "frontend-green"; then
        echo "green"
    else
        echo "none"
    fi
}

update_nginx_config() {
    local deployment=$1
    local frontend_port=$2

    log "${BLUE}Updating Nginx configuration for $deployment deployment...${NC}"
    sudo cp "$NGINX_CONF" "$NGINX_CONF.backup.$(date +%s)"

    sudo tee "$NGINX_CONF" > /dev/null << EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name _;

    location / {
        proxy_pass http://localhost:$frontend_port;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_cache_bypass \$http_upgrade;

        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
}

server {
    listen 8080;
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
EOF

    if sudo nginx -t; then
        sudo systemctl reload nginx
        log "${GREEN}\u2705 Nginx reloaded successfully${NC}"
        return 0
    else
        log "${RED}\u274c Nginx configuration test failed${NC}"
        return 1
    fi
}

start_frontend() {
    local target=$1
    if [ "$target" = "green" ]; then
        docker-compose --profile green -f "$COMPOSE_FILE" up -d
    else
        docker-compose -f "$COMPOSE_FILE" up -d frontend-blue
    fi
}

check_health() {
    local name=$1
    local max_attempts=30
    local attempt=0
    while [ $attempt -lt $max_attempts ]; do
        if docker ps --filter "name=$name" --filter "health=healthy" | grep -q "$name"; then
            return 0
        fi
        sleep 5
        attempt=$((attempt+1))
    done
    return 1
}

deploy() {
    local current=$(get_active_deployment)
    local target
    local target_frontend_port

    if [ "$current" = "blue" ] || [ "$current" = "none" ]; then
        target="green"
        target_frontend_port=3001
    else
        target="blue"
        target_frontend_port=3000
    fi

    log "${BLUE}Starting frontend deployment to $target...${NC}"

    start_frontend "$target"

    if ! check_health "frontend-$target"; then
        log "${RED}\u274c Frontend $target failed health check${NC}"
        exit 1
    fi

    if ! update_nginx_config "$target" "$target_frontend_port"; then
        exit 1
    fi

    sleep 20

    if curl -f http://localhost/health > /dev/null 2>&1; then
        log "${GREEN}\u2705 New deployment is accessible through Nginx${NC}"
    else
        log "${RED}\u274c New deployment is not accessible through Nginx${NC}"
        exit 1
    fi

    # Stop old deployment
    if [ "$current" != "none" ]; then
        if [ "$current" = "blue" ]; then
            docker-compose -f "$COMPOSE_FILE" stop frontend-blue
            docker-compose -f "$COMPOSE_FILE" rm -f frontend-blue
        else
            docker-compose --profile green -f "$COMPOSE_FILE" stop
            docker-compose --profile green -f "$COMPOSE_FILE" rm -f
        fi
    fi

    docker image prune -f
    log "${GREEN}\ud83c\udf89 Frontend deployment completed successfully!${NC}"
}

rollback() {
    local current=$(get_active_deployment)
    if [ "$current" = "none" ]; then
        log "${RED}\u274c No active deployment found to rollback from${NC}"
        exit 1
    fi

    if [ "$current" = "blue" ]; then
        target="green"
        docker-compose --profile green -f "$COMPOSE_FILE" start
    else
        target="blue"
        docker-compose -f "$COMPOSE_FILE" start frontend-blue
    fi

    if update_nginx_config "$target" "$([ "$target" = "green" ] && echo 3001 || echo 3000)"; then
        log "${GREEN}\u2705 Rollback completed successfully${NC}"
    else
        log "${RED}\u274c Rollback failed${NC}"
        exit 1
    fi
}

status() {
    local current=$(get_active_deployment)
    echo -e "${BLUE}=== Deployment Status ===${NC}"
    echo -e "Active deployment: ${GREEN}$current${NC}"
    echo
    docker ps --filter "label=service" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

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
        exit 1
        ;;
esac
