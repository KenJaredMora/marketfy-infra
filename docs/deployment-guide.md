# Marketfy AWS Deployment Guide

Complete guide to deploying Marketfy to AWS using Terraform, Docker, and ECS.

## 📋 Prerequisites

### 1. Tools Installation

Install the following on your Windows machine:

- **Docker Desktop**: https://www.docker.com/products/docker-desktop/
- **Terraform**: https://developer.hashicorp.com/terraform/install
- **AWS CLI v2**: https://aws.amazon.com/cli/
- **Git**: https://git-scm.com/downloads

Verify installations:
```powershell
docker --version
terraform --version
aws --version
git --version
```

### 2. AWS Account Setup

#### 2.1 Create AWS Account
- Sign up at https://aws.amazon.com/
- Verify you're eligible for free tier (12 months)

#### 2.2 Create IAM User (IMPORTANT - Don't use root!)

1. Go to IAM Console → Users → Create User
2. User name: `marketfy-terraform`
3. Select: "Programmatic access"
4. Attach policies:
   - `AdministratorAccess` (for learning)
   - **Production**: Create custom policy with minimal permissions
5. Save the Access Key ID and Secret Access Key

#### 2.3 Enable MFA (STRONGLY RECOMMENDED)
- Go to IAM → Your User → Security Credentials
- Enable MFA device
- Use Google Authenticator or Authy

### 3. Configure AWS CLI

```powershell
aws configure
```

Enter:
- AWS Access Key ID: (from step 2.2)
- AWS Secret Access Key: (from step 2.2)
- Default region: `us-east-1`
- Default output: `json`

Test configuration:
```powershell
aws sts get-caller-identity
```

---

## 🔒 Security Configuration

### 1. Generate Strong Secrets

Generate JWT Secret (PowerShell):
```powershell
-join ((48..57) + (65..90) + (97..122) | Get-Random -Count 64 | ForEach-Object {[char]$_})
```

Generate DB Password (PowerShell):
```powershell
-join ((48..57) + (65..90) + (97..122) + (33,35,37,38,42,43,45,61) | Get-Random -Count 32 | ForEach-Object {[char]$_})
```

### 2. Get Your Public IP (for security group)

```powershell
(Invoke-WebRequest -Uri "https://checkip.amazonaws.com").Content.Trim()
```

Save this IP - you'll need it for `allowed_cidr_blocks`.

---

## 🐳 Step 1: Test Locally with Docker

Before deploying to AWS, test everything works locally.

### 1.1 Build and Run Locally

```powershell
cd "C:\Users\Kenyon Jared Zamora\Downloads\Proyecto Deloitte Java\marketfy-infra"

# Build and start all services
docker-compose up --build
```

### 1.2 Verify Services

- Angular Frontend: http://localhost:4200
- React Frontend: http://localhost:5173
- API Backend: http://localhost:3000
- API Health Check: http://localhost:3000/health

### 1.3 Test the Application

1. Open Angular or React frontend
2. Register a new account
3. Login
4. Browse products
5. Add items to cart and wishlist
6. Create an order

If everything works, proceed to AWS deployment!

### 1.4 Stop Local Services

```powershell
docker-compose down
```

---

## ☁️ Step 2: Create AWS Infrastructure

### 2.1 Configure Terraform Variables

```powershell
cd terraform

# Copy example file
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
notepad terraform.tfvars
```

**IMPORTANT**: Fill in:
- `owner_email`: Your email
- `db_password`: Strong password (generated in security step)
- `jwt_secret`: Strong secret (generated in security step)
- `allowed_cidr_blocks`: Your IP address `/32` (from security step)

### 2.2 Initialize Terraform

```powershell
terraform init
```

### 2.3 Plan Infrastructure

```powershell
terraform plan -out=tfplan
```

Review the plan carefully. You should see resources like:
- VPC and subnets
- Security groups
- RDS database (PostgreSQL)
- ECR repositories
- ECS cluster
- ALB (load balancer)
- IAM roles

### 2.4 Apply Infrastructure

```powershell
terraform apply tfplan
```

This will take 10-15 minutes. Terraform will create:
- ✅ Networking (VPC, subnets, route tables)
- ✅ Database (RDS PostgreSQL)
- ✅ Container registry (ECR)
- ✅ ECS cluster
- ✅ Load balancer
- ✅ Security groups
- ✅ IAM roles

**IMPORTANT**: Save the outputs! You'll need them for the next steps.

---

## 📦 Step 3: Build and Push Docker Images

### 3.1 Login to ECR

Get your AWS Account ID:
```powershell
$AWS_ACCOUNT_ID = (aws sts get-caller-identity --query Account --output text)
$AWS_REGION = "us-east-1"

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | `
  docker login --username AWS --password-stdin "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"
```

### 3.2 Build and Push Backend API

```powershell
cd "C:\Users\Kenyon Jared Zamora\Downloads\Proyecto Deloitte Java"

# Get ECR URLs from Terraform output
$API_ECR_URL = (cd marketfy-infra/terraform && terraform output -raw ecr_api_url)

# Build
docker build -t marketfy-api:latest `
  -f marketfy-infra/docker/api/Dockerfile `
  marketfy-api

# Tag
docker tag marketfy-api:latest "${API_ECR_URL}:v1"
docker tag marketfy-api:latest "${API_ECR_URL}:latest"

# Push
docker push "${API_ECR_URL}:v1"
docker push "${API_ECR_URL}:latest"
```

### 3.3 Build and Push Angular Frontend

```powershell
$ANGULAR_ECR_URL = (cd marketfy-infra/terraform && terraform output -raw ecr_angular_url)

docker build -t marketfy-angular:latest `
  -f marketfy-infra/docker/angular/Dockerfile `
  marketfy

docker tag marketfy-angular:latest "${ANGULAR_ECR_URL}:v1"
docker tag marketfy-angular:latest "${ANGULAR_ECR_URL}:latest"

docker push "${ANGULAR_ECR_URL}:v1"
docker push "${ANGULAR_ECR_URL}:latest"
```

### 3.4 Build and Push React Frontend

```powershell
$REACT_ECR_URL = (cd marketfy-infra/terraform && terraform output -raw ecr_react_url)

docker build -t marketfy-react:latest `
  -f marketfy-infra/docker/react/Dockerfile `
  marketfy-react

docker tag marketfy-react:latest "${REACT_ECR_URL}:v1"
docker tag marketfy-react:latest "${REACT_ECR_URL}:latest"

docker push "${REACT_ECR_URL}:v1"
docker push "${REACT_ECR_URL}:latest"
```

---

## 🚀 Step 4: Deploy ECS Services

After images are pushed, Terraform will automatically deploy the ECS services.

If you need to update services after initial deployment:

```powershell
cd marketfy-infra/terraform
terraform apply
```

---

## 🌐 Step 5: Access Your Application

### 5.1 Get ALB DNS Name

```powershell
cd terraform
$ALB_DNS = (terraform output -raw alb_dns_name)
Write-Host "Application URL: http://$ALB_DNS"
```

### 5.2 Access the Application

- **Angular**: `http://<ALB_DNS>/`
- **React**: `http://<ALB_DNS>/react`
- **API**: `http://<ALB_DNS>/api/health`

### 5.3 Test the Deployment

1. Open the Angular or React frontend
2. Register and login
3. Test all functionality
4. Verify database persistence (logout and login again)

---

## 🔧 Troubleshooting

### Services Not Starting

Check ECS service events:
```powershell
aws ecs describe-services `
  --cluster marketfy-cluster `
  --services marketfy-api `
  --query 'services[0].events[0:5]'
```

### Database Connection Issues

Check RDS endpoint:
```powershell
cd terraform
terraform output rds_endpoint
```

Verify security groups allow ECS → RDS traffic.

### 502 Bad Gateway

- Task not healthy → Check logs
- Health check failing → Verify health endpoint
- Security group misconfiguration → Check ECS SG allows ALB traffic

### View Logs

```powershell
# Get log stream name
aws logs describe-log-streams `
  --log-group-name /ecs/marketfy-api `
  --order-by LastEventTime `
  --descending `
  --limit 1

# View logs
aws logs tail /ecs/marketfy-api --follow
```

---

## 💰 Cost Management

### Monitor Costs

1. Go to AWS Cost Explorer
2. Set up billing alerts:
   - AWS Console → Billing → Budgets
   - Create budget: $10/month
   - Set up email alerts

### Free Tier Limits

**First 12 months**:
- EC2 t3.micro: 750 hours/month
- RDS t3.micro: 750 hours/month
- ALB: 750 hours/month
- Data transfer: 15 GB/month

**Always Free**:
- CloudWatch: 10 custom metrics
- Lambda: 1M requests/month
- DynamoDB: 25 GB storage

### Reduce Costs

For development:
- Stop services when not in use
- Use `desired_count = 0` in Terraform
- Delete unused resources

---

## 🔐 Security Best Practices

### ✅ Implemented

- [x] No hardcoded credentials
- [x] Security groups with minimal access
- [x] Private subnets for database
- [x] IAM roles with least privilege
- [x] Container running as non-root user
- [x] Health checks enabled
- [x] CloudTrail enabled (optional)

### 🔒 Additional Recommendations

1. **Enable HTTPS**:
   - Get ACM certificate
   - Set `enable_https = true`
   - Force HTTPS redirect

2. **Restrict IP Access**:
   - Update `allowed_cidr_blocks` to your IP only
   - Use VPN for remote access

3. **Enable AWS WAF**:
   - Set `enable_waf = true`
   - Add rate limiting rules

4. **Regular Updates**:
   - Keep Docker images updated
   - Apply security patches
   - Monitor AWS Security Hub

5. **Backup Database**:
   - Enable automated RDS backups
   - Test restore procedures

6. **Secrets Management**:
   - Migrate to AWS Secrets Manager
   - Rotate secrets regularly

---

## 🧹 Cleanup

To avoid charges, destroy all resources when done:

```powershell
cd marketfy-infra/terraform

# Preview what will be deleted
terraform plan -destroy

# Destroy all resources
terraform destroy
```

**IMPORTANT**: This will delete:
- All ECS services and tasks
- RDS database (and all data!)
- Load balancer
- VPC and networking
- ECR images

Make sure to backup any important data first!

---

## 📚 Next Steps

### Production Deployment

1. **Domain Name**:
   - Register domain (Route53, CloudFlare, etc.)
   - Create ACM certificate
   - Configure DNS records

2. **CI/CD Pipeline**:
   - Set up GitHub Actions
   - Automate build and deploy
   - Add automated tests

3. **Monitoring**:
   - CloudWatch dashboards
   - X-Ray tracing
   - Custom metrics

4. **High Availability**:
   - Multiple availability zones
   - Auto-scaling policies
   - Read replicas for database

5. **Performance**:
   - CloudFront CDN
   - ElastiCache for Redis
   - Database query optimization

---

## 🆘 Support

If you encounter issues:

1. Check CloudWatch logs
2. Review Terraform plan output
3. Verify security group rules
4. Check AWS service quotas
5. Review this guide's troubleshooting section

For AWS-specific issues, see AWS documentation or AWS Support.

---

**Happy Deploying! 🚀**
