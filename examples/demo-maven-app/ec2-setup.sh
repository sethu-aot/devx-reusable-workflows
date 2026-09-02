#!/bin/bash
# EC2 Instance Setup Script for demo-maven-app
# Run this script on the EC2 instance (i-07c20def55d6e203b) to prepare it for deployments

set -euo pipefail

echo "========================================="
echo "EC2 Instance Setup for DevX Deployments"
echo "========================================="

# Update system
echo "📦 Updating system packages..."
sudo yum update -y

# Install Docker (if not already installed)
if ! command -v docker &> /dev/null; then
    echo "🐳 Installing Docker..."
    sudo yum install -y docker
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker ec2-user
    echo "✅ Docker installed"
else
    echo "✅ Docker already installed"
fi

# Install Docker Compose (if not already installed)
if ! command -v docker-compose &> /dev/null; then
    echo "🔧 Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "✅ Docker Compose installed"
else
    echo "✅ Docker Compose already installed"
fi

# Install AWS CLI v2 (if not already installed)
if ! command -v aws &> /dev/null; then
    echo "☁️  Installing AWS CLI v2..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
    echo "✅ AWS CLI installed"
else
    echo "✅ AWS CLI already installed"
fi

# Create application directory
echo "📁 Creating application directory..."
sudo mkdir -p /app
sudo chown ec2-user:ec2-user /app
cd /app

# Create docker-compose.yaml for demo-maven-app
echo "📝 Creating docker-compose.yaml..."
cat > /app/docker-compose.yaml <<'EOF'
version: '3.8'

services:
  demo-maven-app:
    image: nexus-docker.example.com/docker-hosted/demo-maven-app:latest
    container_name: demo-maven-app
    ports:
      - "8080:8080"
    environment:
      - SPRING_PROFILES_ACTIVE=prod
      - JAVA_OPTS=-Xmx512m -Xms256m
    restart: unless-stopped
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/actuator/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
EOF

echo "✅ docker-compose.yaml created"

# Create Nexus credentials file for Docker login
echo "🔐 Setting up Nexus registry authentication..."
echo "NOTE: You'll need to manually configure Nexus credentials"
echo "Run: docker login nexus-docker.example.com"
echo "Username: <NEXUS_USERNAME>"
echo "Password: <NEXUS_PASSWORD>"

# Verify installations
echo ""
echo "========================================="
echo "✅ Setup Complete! Verifying installations..."
echo "========================================="
echo "Docker version: $(docker --version)"
echo "Docker Compose version: $(docker-compose --version)"
echo "AWS CLI version: $(aws --version)"
echo ""
echo "📋 Next Steps:"
echo "1. Logout and login again (or run: newgrp docker)"
echo "2. Configure Nexus credentials: docker login nexus-docker.example.com"
echo "3. Test deployment: cd /app && docker-compose up -d"
echo "4. Verify health: curl http://localhost:8080/actuator/health"
echo ""
echo "🚀 Instance is ready for automated deployments!"
