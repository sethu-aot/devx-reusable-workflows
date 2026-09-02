#!/bin/bash
# EC2 Setup Script for Demo Python App
# This script prepares an EC2 instance for Docker-based Python deployments

set -euo pipefail

echo "========================================="
echo "EC2 Setup for Demo Python App"
echo "========================================="

# Update system packages
echo "Updating system packages..."
sudo yum update -y

# Install Docker
echo "Installing Docker..."
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user

# Install Docker Compose
echo "Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installations
echo "Verifying installations..."
docker --version
docker-compose --version

# Create app directory
echo "Creating application directory..."
sudo mkdir -p /app
sudo chown ec2-user:ec2-user /app

# Copy docker-compose.yaml to EC2 instance
echo "Please manually copy docker-compose.yaml to /app/docker-compose.yaml on the EC2 instance"
echo ""
echo "Example: scp -i <key.pem> docker-compose.yaml ec2-user@<instance-ip>:/app/"

# Configure Docker to log in to Nexus registry
echo ""
echo "========================================="
echo "IMPORTANT: Manual Docker Login Required"
echo "========================================="
echo "After this script completes, run the following command to authenticate with Nexus:"
echo ""
echo "  docker login nexus-docker.example.com"
echo ""
echo "Enter your Nexus credentials when prompted."
echo "This creates ~/.docker/config.json for automated pulls."
echo ""
echo "========================================="
echo "Done!"
echo "========================================="
echo ""
echo "Next Steps:"
echo "1. Copy docker-compose.yaml to /app/ on the EC2 instance"
echo "2. Log in to Docker registry: docker login nexus-docker.example.com"
echo "3. Configure GitHub Secrets:"
echo "   - NEXUS_USERNAME"
echo "   - NEXUS_PASSWORD"
echo "   - SSH_PRIVATE_KEY (for SSH deployment method)"
echo "4. Trigger deployment via GitHub Actions"
echo ""
echo "The deployment will:"
echo "  1. SSH into the instance"
echo "  2. Pull the latest image from Nexus"
echo "  3. Deploy using docker-compose"
echo "  4. Verify health at http://<instance-ip>:5000/health"
