# EC2 Setup Guide for Demo Python App

## Prerequisites
- EC2 instance running Amazon Linux 2 or similar
- Security group allowing inbound traffic on port 5000
- SSH access to the instance
- Nexus registry credentials

## Setup Steps

### 1. Run the Setup Script on EC2
```bash
# Upload and run the setup script
scp -i <your-key.pem> ec2-setup.sh ec2-user@<instance-ip>:~/
ssh -i <your-key.pem> ec2-user@<instance-ip>
chmod +x ec2-setup.sh
./ec2-setup.sh
```

### 2. Copy Docker Compose File
```bash
scp -i <your-key.pem> docker-compose.yaml ec2-user@<instance-ip>:/app/
```

### 3. Authenticate Docker with Nexus
```bash
ssh -i <your-key.pem> ec2-user@<instance-ip>
docker login nexus-docker.example.com
# Enter your Nexus credentials when prompted
```

### 4. Configure GitHub Secrets
Add the following secrets to your repository:
- `NEXUS_USERNAME`: Your Nexus registry username
- `NEXUS_PASSWORD`: Your Nexus registry password
- `SSH_PRIVATE_KEY`: Private SSH key for EC2 access

### 5. Update Security Group
Ensure your EC2 security group allows:
- Port 22 (SSH) from GitHub Actions runner IPs
- Port 5000 (Python app) from your network

## Deployment
Once configured, push to main branch to trigger deployment:
```bash
git add .
git commit -m "Configure Python app for EC2 deployment"
git push origin main
```

## Verification
After deployment, verify the app is running:
```bash
curl http://<instance-ip>:5000/health
```

Expected response:
```json
{
  "status": "healthy",
  "message": "Python API is running"
}
```

## Troubleshooting
- Check container logs: `docker-compose -f /app/docker-compose.yaml logs`
- Verify image pull: `docker images | grep demo-python-app`
- Check container status: `docker ps -a`
