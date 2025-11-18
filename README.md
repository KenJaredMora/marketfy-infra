# Marketfy Infrastructure

AWS deployment infrastructure for Marketfy e-commerce platform using Terraform, Docker, and ECS.

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

```
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

Using AWS Free Tier (first 12 months):
- EC2 t3.micro: Free (750 hours/month)
- RDS t3.micro: Free (750 hours/month)
- ALB: Free (750 hours/month + 15 LCUs)
- ECR: 500 MB free
- S3: 5 GB free

**Estimated monthly cost after free tier**: ~$30-50/month

## 📝 License

UNLICENSED - Private project
