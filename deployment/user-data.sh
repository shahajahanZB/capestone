#!/bin/bash
set -e

# Update system
apt-get update && apt-get upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker ubuntu

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/download/v2.21.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install Nginx
apt-get install -y nginx

# Install Certbot
apt-get install -y certbot python3-certbot-nginx

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# Install CloudWatch agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i amazon-cloudwatch-agent.deb

# Create application directory
mkdir -p /home/ubuntu/app
chown ubuntu:ubuntu /home/ubuntu/app

# Create deployment directory
mkdir -p /home/ubuntu/deployment
chown ubuntu:ubuntu /home/ubuntu/deployment

# Configure Docker daemon to start on boot
systemctl enable docker
systemctl start docker

# Create log directories
mkdir -p /var/log/app
chown ubuntu:ubuntu /var/log/app

echo "\u2705 Instance setup completed successfully!"
