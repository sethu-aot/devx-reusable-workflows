#!/bin/bash
# EC2 Setup Script for Demo Node.js App
# This script prepares an EC2 instance for Docker-based Node.js deployments

set -euo pipefail

echo "========================================="
echo "EC2 Setup for Demo Node.js App"
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

# Install AWS CLI v2 (for SSM and potential ECR integration)
echo "Installing AWS CLI v2..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf awscliv2.zip aws

# Install SSM Agent (if not already installed)
echo "Verifying SSM Agent installation..."
if ! sudo systemctl is-active --quiet amazon-ssm-agent; then
  echo "Installing SSM Agent..."
  sudo yum install -y amazon-ssm-agent
  sudo systemctl enable amazon-ssm-agent
  sudo systemctl start amazon-ssm-agent
else
  echo "SSM Agent already running"
fi

echo ""
echo "========================================="
echo "Setup Complete!"
echo "========================================="
echo ""
echo "Next Steps:"
echo "1. Copy docker-compose.yaml to /app/ on the EC2 instance"
echo "2. Log in to Docker registry: docker login nexus-docker.example.com"
echo "3. Configure GitHub Secrets:"
echo "   - NEXUS_USERNAME"
echo "   - NEXUS_PASSWORD"
echo "4. Trigger the CI/CD pipeline"
echo ""
echo "The deployment will use SSM to manage the instance."
echo "Ensure the instance has the SSM IAM role attached."
echo ""
