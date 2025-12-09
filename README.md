# Marketfy Infrastructure Project

AWS deployment infrastructure for Marketfy e-commerce platform using Terraform, Docker, and ECS.

## 🌐 Current Deployment

**Status**: ✅ Production Active

- **Load Balancer**: [marketfy-alb-646939327.us-east-1.elb.amazonaws.com](http://marketfy-alb-1492993669.us-east-1.elb.amazonaws.com)

        Note: For security purposes just reacheable with IP.

- **Region**: us-east-1
- **Cluster**: marketfy-cluster
- **Database**

**Services Running:**

- ✅ API Service (marketfy-api-service)
- ✅ Angular Service (marketfy-angular-service)
- ✅ React Service (marketfy-react-service)

**Demo Credentials:**

- Email: `demo@marketfy.test`
- Password: `password123`

---

## 🏗️ Architecture

- **Backend**: NestJS API (marketfy-api)
- **Frontend 1**: Angular SPA (marketfy)
- **Frontend 2**: React SPA (marketfy-react)
- **Database**: PostgreSQL (RDS)
- **Container Registry**: AWS ECR
- **Compute**: ECS on EC2 (t3.micro - free tier eligible)
- **Load Balancer**: Application Load Balancer
- **Infrastructure as Code**: Terraform

## 🔒 Security Features

- ✅ No hardcoded credentials
- ✅ AWS Secrets Manager for sensitive data
- ✅ Security groups with minimal permissions
- ✅ HTTPS/TLS encryption
- ✅ Private subnets for database
- ✅ IAM roles with least privilege
- ✅ CloudTrail enabled for auditing

## 📁 Project Structure

```md
marketfy-infra/
├── terraform/           # Terraform IaC
│   ├── main.tf
│   ├── providers.tf
│   ├── variables.tf
│   ├── vpc.tf
│   ├── rds.tf
│   ├── ecr.tf
│   ├── ecs.tf
│   ├── alb.tf
│   ├── security.tf
│   └── outputs.tf
├── docker/             # Dockerfiles
│   ├── api/
│   ├── angular/
│   └── react/
├── scripts/            # Deployment scripts
│   ├── build-push.ps1
│   └── deploy.ps1
└── docs/              # Documentation
    └── deployment-guide.md
```

## 🚀 Quick Start

See [docs/deployment-guide.md](docs/deployment-guide.md) for detailed instructions.

## ⚠️ Important Security Notes

1. **Never commit `.env` files or `.tfvars` files**
2. **Use AWS Secrets Manager** for all sensitive data
3. **Enable MFA** on your AWS account
4. **Use IAM user with minimal permissions** (not root)
5. **Enable CloudTrail** for audit logging
6. **Review security groups** before applying

## 💰 Cost Estimation

### Current Deployment

**Actual Resources Deployed:**

- **2x EC2 t3.micro** - ECS container instances (running 24/7)
- **1x RDS db.t3.micro** - PostgreSQL database, 20GB gp3 storage, Single-AZ
- **1x Application Load Balancer** - Internet-facing ALB
- **3x ECS Services** - API, Angular, React (1 task each, EC2 launch type)
- **3x ECR Repositories** - Docker image storage (~500MB total)
- **CloudWatch Logs** - Application logs with 7-day retention
- **VPC** - 2 Availability Zones, public & private subnets
- **No NAT Gateways** - Cost optimization applied

### Monthly Cost Breakdown (US East 1)

| Service | Configuration | Free Tier | After Free Tier | Cost/Month |
|---------|--------------|-----------|-----------------|------------|
| **EC2 Instances** | 2x t3.micro (730 hrs × 2) | 750 hrs free | 710 hrs | ~$5.11 |
| **RDS PostgreSQL** | db.t3.micro + 20GB gp3 | 750 hrs + 20GB free | - | ~$0.00 |
| **Application Load Balancer** | 1 ALB + LCUs | 750 hrs + 15 LCUs | Minimal traffic | ~$16.20 |
| **Data Transfer OUT** | ~5GB/month | 1GB free | 4GB | ~$0.36 |
| **CloudWatch Logs** | ~1GB/month, 7-day retention | 5GB free | - | ~$0.00 |
| **ECR Storage** | ~500MB | 500MB free | - | ~$0.00 |
| **ECS (EC2)** | 3 services, 3 tasks | Free | - | ~$0.00 |

### Cost Summary

**With AWS Free Tier (first 12 months):**

- Monthly Cost: **~$21.67** (primarily ALB)
- Annual Cost: **~$260**

**After AWS Free Tier Expires:**

- EC2: 2x t3.micro × 730 hours × $0.0104/hr = **~$15.18**
- RDS: db.t3.micro × 730 hours × $0.017/hr = **~$12.41**
- RDS Storage: 20GB × $0.133/GB = **~$2.66**
- ALB: 730 hours × $0.0225/hr = **~$16.43**
- ALB LCUs: ~0.5 LCU × $0.008 × 730 = **~$2.92**
- Data Transfer: 5GB × $0.09/GB = **~$0.45**
- CloudWatch Logs: 1GB × $0.50/GB = **~$0.50**
- **Monthly Total: ~$50.55**
- **Annual Total: ~$606**

### Cost Optimization Applied ✅

- ✅ **No NAT Gateways** - Saves ~$32.40/month per AZ
- ✅ **Single-AZ RDS** - Saves ~$15/month vs Multi-AZ
- ✅ **ECS on EC2** - Free ECS, only pay for EC2
- ✅ **t3.micro instances** - Free tier eligible
- ✅ **Short log retention** - 7 days instead of 30+

**Potential savings: ~$79/month applied!**
