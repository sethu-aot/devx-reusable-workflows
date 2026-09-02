# EC2 Deployment Setup Guide for Demo Node.js App

This guide walks you through setting up EC2-based deployments for the Node.js app using **AWS Systems Manager (SSM)** instead of SSH.

## Prerequisites

- AWS EC2 instance (Amazon Linux 2/2023)
- Instance must have **SSM Agent** installed and running
- Instance must have an **IAM role** with `AmazonSSMManagedInstanceCore` policy
- GitHub Secrets configured in the repository

## 1. Prepare the EC2 Instance

### Step 1: Run the Setup Script on Your EC2 Instance

SSH into your EC2 instance and run the setup script:

```bash
# Copy the script to the instance
scp -i <your-key.pem> ec2-setup.sh ec2-user@<instance-ip>:~/

# SSH into the instance
ssh -i <your-key.pem> ec2-user@<instance-ip>

# Run the setup script
chmod +x ec2-setup.sh
./ec2-setup.sh
```

This script installs:
- Docker & Docker Compose
- AWS CLI v2
- SSM Agent (if not present)
- Creates `/app` directory

### Step 2: Copy docker-compose.yaml to the Instance

```bash
# From your local machine
scp -i <your-key.pem> docker-compose.yaml ec2-user@<instance-ip>:/app/
```

### Step 3: Log in to Nexus Docker Registry

SSH into the instance and authenticate with Nexus:

```bash
ssh -i <your-key.pem> ec2-user@<instance-ip>

# Log in to the Nexus registry
docker login nexus-docker.example.com

# Enter your Nexus credentials when prompted
# Username: <your-nexus-username>
# Password: <your-nexus-password>
```

This creates `~/.docker/config.json` for authenticated pulls.

### Step 4: Configure GitHub Actions IAM Role (Runner)

The IAM role assumed by GitHub Actions (`GitHubActionsRole`) needs permission to send commands via SSM.

#### For Linux / MacOS / Git Bash:
```bash
cat <<EOF > ssm-runner-policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": ["ssm:SendCommand"],
            "Resource": [
                "arn:aws:ec2:ca-central-1:123456789012:instance/i-07c20def55d6e203b",
                "arn:aws:ssm:ca-central-1::document/AWS-RunShellScript"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssm:GetCommandInvocation",
                "ssm:ListCommandInvocations",
                "ssm:DescribeInstanceInformation"
            ],
            "Resource": "*"
        }
    ]
}
EOF

aws iam put-role-policy \
  --role-name GitHubActionsRole \
  --policy-name GitHubActionsSSMPolicy \
  --policy-document file://ssm-runner-policy.json
```

#### For Windows CMD / PowerShell:
1. Create a file named `ssm-runner-policy.json` with this content:
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": ["ssm:SendCommand"],
            "Resource": [
                "arn:aws:ec2:ca-central-1:123456789012:instance/i-07c20def55d6e203b",
                "arn:aws:ssm:ca-central-1::document/AWS-RunShellScript"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssm:GetCommandInvocation",
                "ssm:ListCommandInvocations",
                "ssm:DescribeInstanceInformation"
            ],
            "Resource": "*"
        }
    ]
}
```

2. Run this command:
```cmd
aws iam put-role-policy ^
  --role-name GitHubActionsRole ^
  --policy-name GitHubActionsSSMPolicy ^
  --policy-document file://ssm-runner-policy.json
```

## 2. Configure GitHub Secrets

Add the following secrets to your GitHub repository (`demo-nodejs-app`):

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `NEXUS_USERNAME` | Nexus registry username | `admin` |
| `NEXUS_PASSWORD` | Nexus registry password | `your-secure-password` |

**Note:** These secrets are automatically passed from the repository to the CD orchestrator and then to the EC2 deployment module via `secrets: inherit`.

## 3. Update devx-config.yaml (Already Done)

The `devx-config.yaml` has been configured for EC2 SSM deployment:

```yaml
deployment:
  target: ec2
  environments:
    dev:
      deploy_method: ssm        # Using SSM instead of SSH
      target_type: instance-ids
      instance_ids: i-07c20def55d6e203b  # Update with your instance ID
      docker_compose_path: /app/docker-compose.yaml
      service_name: demo-nodejs-app
```

**Important:** Update `instance_ids` with your actual EC2 instance ID.

## 4. Verify SSM Configuration

Ensure your EC2 instance is registered with SSM:

```bash
# From your local machine with AWS CLI configured
aws ssm describe-instance-information \
  --filters "Key=InstanceIds,Values=i-07c20def55d6e203b" \
  --region ca-central-1
```

You should see your instance listed with `PingStatus: Online`.

## 5. Trigger Deployment

### Option 1: Automated CI/CD

Push a commit to trigger the full CI/CD pipeline:

```bash
git add .
git commit -m "test: Trigger Node.js EC2 deployment"
git push origin main
```

### Option 2: Manual CD Trigger

Go to **Actions** → **CD Pipeline** → **Run workflow**:
- Environment: `dev`
- Image URI: (leave empty to use latest from CI)

## 6. Verify Deployment

After the pipeline completes:

1. **Check GitHub Actions Summary** for deployment status and health check results
2. **Access the application:**
   ```bash
   curl http://<instance-public-ip>:3000/health
   ```

Expected response:
```json
{
  "status": "ok",
  "timestamp": "2024-xx-xxTxx:xx:xx.xxxZ"
}
```

## Key Differences from Maven App

| Aspect | Maven App | Node.js App |
|--------|-----------|-------------|
| **Deploy Method** | SSH | **SSM** |
| **Port** | 8080 | **3000** |
| **Registry** | Cloudflare Tunnel (Maven) | **Cloudflare Tunnel (Node.js)** |
| **Health Endpoint** | `/actuator/health` | **/health** |
| **Auth** | Manual SSH key setup | **IAM role + SSM** |

## Troubleshooting

### SSM Connection Issues

If SSM can't connect to the instance:

1. **Check IAM role:**
   ```bash
   aws ec2 describe-iam-instance-profile-associations \
     --filters "Name=instance-id,Values=i-07c20def55d6e203b"
   ```

2. **Verify SSM Agent status:**
   ```bash
   # On the EC2 instance
   sudo systemctl status amazon-ssm-agent
   ```

3. **Check SSM connectivity:**
   ```bash
   aws ssm start-session --target i-07c20def55d6e203b
   ```

### Docker Login Issues

If you see `401 Unauthorized` during deployment:

1. Ensure `NEXUS_USERNAME` and `NEXUS_PASSWORD` secrets are set
2. Verify the secrets are correct by testing manually:
   ```bash
   docker login nexus-docker.example.com -u <username> -p <password>
   ```

### Health Check Failures

If health checks fail:

1. Check if the container is running:
   ```bash
   docker ps
   docker logs demo-nodejs-app
   ```

2. Test the health endpoint locally on the instance:
   ```bash
   curl http://localhost:3000/health
   ```

## Next Steps

Once deployment is successful:
- Configure auto-rollback settings in `devx-config.yaml`
- Set up CloudWatch alarms for the instance
- Consider adding a load balancer for production
