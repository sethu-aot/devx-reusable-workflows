# EC2 Instance Setup Guide for DevX Deployments

## Instance Information
- **Instance ID**: `i-07c20def55d6e203b`
- **Name**: `devx-reusable-workflow-deployment-test`
- **VPC**: `vpc-0aeb7c80c193556fc` (formsflow-poc-vpc)
- **Region**: `ca-central-1`

## Prerequisites Checklist

Before running the first deployment, ensure the EC2 instance has:

### 1. Docker & Docker Compose
```bash
# Check if installed
docker --version
docker-compose --version

# If not installed, run the setup script
chmod +x ec2-setup.sh
./ec2-setup.sh
```

### 2. Nexus Registry Authentication
The instance needs to be authenticated to pull images from Nexus:

```bash
# Login to Nexus Docker registry
docker login nexus-docker.example.com

# Enter credentials when prompted:
# Username: <NEXUS_USERNAME>
# Password: <NEXUS_PASSWORD>
```

> **Note**: This login persists in `~/.docker/config.json` and will be used by automated deployments.

### 3. Application Directory Structure
```bash
# Verify /app directory exists
ls -la /app

# Should contain:
# - docker-compose.yaml (created by setup script)
```

### 4. Security Group Configuration
Ensure the security group allows:
- **Port 22 (SSH)**: For GitHub Actions to connect
- **Port 8080 (HTTP)**: For application access and health checks

### 5. GitHub Actions SSH Access
The CI/CD pipeline needs SSH access to the instance. Ensure:

1. **SSH_PRIVATE_KEY secret** is configured in GitHub repository secrets
2. The corresponding **public key** is in `~/.ssh/authorized_keys` on the EC2 instance
3. SSH service is running: `sudo systemctl status sshd`

## Quick Setup Commands

Run these commands on the EC2 instance:

```bash
# 1. Run the setup script (if not already done)
cd ~
curl -O https://raw.githubusercontent.com/YOUR_ORG/DevOps-Pipeline/main/demo-maven-app/ec2-setup.sh
chmod +x ec2-setup.sh
./ec2-setup.sh

# 2. Logout and login (to apply docker group membership)
exit
# SSH back in

# 3. Login to Nexus
docker login nexus-docker.example.com
# Enter credentials

# 4. Verify docker-compose.yaml
cat /app/docker-compose.yaml

# 5. Test manual deployment (optional)
cd /app
docker-compose pull demo-maven-app
docker-compose up -d demo-maven-app

# 6. Verify application
curl http://localhost:8080/actuator/health

# 7. Stop test deployment (pipeline will manage it)
docker-compose down
```

## Automated Deployment Flow

Once setup is complete, the CI/CD pipeline will:

1. **Build** the Maven application
2. **Push** Docker image to Nexus
3. **Deploy** to EC2 via SSH:
   - SSH into the instance
   - Pull the new image from Nexus
   - Update `docker-compose.override.yml` with new image tag
   - Restart the service with `docker-compose up -d`
4. **Health Check** the application at `http://<PUBLIC_IP>:8080/actuator/health`
5. **Rollback** automatically if health check fails

## Troubleshooting

### Issue: SSH connection fails
```bash
# Check SSH service
sudo systemctl status sshd

# Check security group allows port 22 from GitHub Actions IPs
# Verify SSH key is in authorized_keys
cat ~/.ssh/authorized_keys
```

### Issue: Docker pull fails
```bash
# Re-authenticate to Nexus
docker login nexus-docker.example.com

# Test pull manually
docker pull nexus-docker.example.com/docker-hosted/demo-maven-app:latest
```

### Issue: Application won't start
```bash
# Check docker logs
docker-compose logs demo-maven-app

# Check if port 8080 is available
sudo netstat -tlnp | grep 8080
```

## Next Steps

After setup is complete:
1. Commit and push changes to trigger CI/CD
2. Monitor the GitHub Actions workflow
3. Verify deployment success via health check
4. Access application at `http://<PUBLIC_IP>:8080`
