# Complete Automation Guide - Marketfy Infrastructure

## 🎯 Goal Achieved

You can now:

1. ✅ **Destroy everything** with `terraform destroy`
2. ✅ **Recreate everything** with just `terraform apply`
3. ✅ **Database auto-seeds** automatically or manuall
4. ✅ **Docker images preserved** in ECR (no rebuilding needed)

---

## 🚀 How It Works

### What's Automated

| Feature | Status | How |
|---------|--------|-----|
| **ECR Images Preserved** | ✅ Automated | `force_delete = false` in ecr.tf |
| **Database Auto-Seed** | ✅ Automated | `automation.tf` with null_resource |
| **Service Deployment** | ✅ Automated | ECS pulls from ECR automatically |
| **Health Checks** | ✅ Automated | Script waits for API to be ready |

---

## 📋 Complete Workflow

### First Time Setup (One Time Only)

```powershell
# 1. Go to terraform directory
cd "C:\Users\Kenyon Jared Zamora\Downloads\Proyecto Deloitte Java\marketfy-infra\terraform"

# 2. Initialize Terraform
terraform init

# 3. Apply infrastructure (creates ECR repositories)
terraform apply
# Type: yes

# 4. Build and push Docker images (ONE TIME)
cd ../scripts
.\build-and-push-images.ps1

# 5. Apply again to start services with images
cd ../terraform
terraform apply
# Type: yes
```

**That's it! Database is automatically seeded.**

---

### Destroy Infrastructure (Save Credits)

**Automated Method (Recommended):**

```powershell
cd "C:\Users\Kenyon Jared Zamora\Downloads\Proyecto Deloitte Java\marketfy-infra\scripts"

# Run automated destroy script
.\destroy-infrastructure.ps1
```

**Manual Method (if needed):**

```powershell
cd "C:\Users\Kenyon Jared Zamora\Downloads\Proyecto Deloitte Java\marketfy-infra\terraform"

# Destroy everything (images stay in ECR!)
terraform destroy
# Type: yes
# Note: May require manual ECS service cleanup
```

**Cost after destroy: ~$0.05/month** (just ECR images)

---

### Recreate Infrastructure (Demo Time!)

```powershell
cd "C:\Users\Kenyon Jared Zamora\Downloads\Proyecto Deloitte Java\marketfy-infra\terraform"

# Just apply! Everything is automatic
terraform apply
# Type: yes

# Wait ~5 minutes...
```

**That's it!**

- ✅ Infrastructure created
- ✅ Services deployed from existing ECR images
- ✅ Database automatically seeded
- ✅ Ready to show in ~5 minutes

---

## 🔧 Configuration Options

### Disable Auto-Seeding (Optional)

If you don't want automatic database seeding:

```hcl
# In terraform.tfvars or terraform apply command
terraform apply -var="auto_seed_database=false"
```

### Change Seed Behavior

Edit `automation.tf` line 95:

```hcl
triggers = {
  db_endpoint = aws_db_instance.marketfy.endpoint
  # REMOVE this line to seed only once (not on every apply):
  always_run = timestamp()
}
```

---

## 📁 New Files Created

| File | Purpose |
|------|---------|
| `terraform/automation.tf` | Automatic database seeding logic |
| `scripts/build-and-push-images.ps1` | Helper script to push images |
| `AUTOMATION-GUIDE.md` | This file |

---

## 🔍 How Auto-Seeding Works

1. **Terraform creates infrastructure** (EC2, RDS, ALB, ECS)
2. **null_resource waits** for services to be healthy (60 seconds + health check)
3. **Seed task runs** via `aws ecs run-task` with seed command
4. **Script monitors** task status until completion
5. **Output shows** success or failure

### What Happens

```md
terraform apply
└── Create infrastructure
    └── Wait for services stable (60s)
        └── Check API health endpoint
            └── Run ECS task: npx tsx prisma/seed.ts
                └── Monitor task (max 5 min)
                    └── ✅ Database seeded!
```

---

## 💡 Understanding the Changes

### ECR Repositories (ecr.tf)

**Before:**

```hcl
resource "aws_ecr_repository" "api" {
  name = "marketfy-api"
  # Images deleted on terraform destroy
}
```

**After:**

```hcl
resource "aws_ecr_repository" "api" {
  name         = "marketfy-api"
  force_delete = false  # ← Images preserved!
}
```

### Database Seeding (automation.tf)

Uses Terraform's `null_resource` with `local-exec`:

- Runs PowerShell commands locally
- Executes AWS CLI to run ECS task
- Monitors seed task completion
- Triggers on database changes

---

## 🎯 Common Scenarios

### Scenario 1: First Deployment

```powershell
cd marketfy-infra/terraform
terraform init
terraform apply  # Creates ECR
cd ../scripts
.\build-and-push-images.ps1  # Push images (ONE TIME)
cd ../terraform
terraform apply  # Starts services + auto-seeds
```

**Time:** ~25 minutes (one time)

### Scenario 2: Daily Work (Destroy at Night)

```powershell
# End of day
terraform destroy  # Cost: $0

# Next morning
terraform apply    # Cost: $21/month, Ready in 5 min
```

**Time:** ~5 minutes

### Scenario 3: Demo Time

```powershell
# Before demo
terraform apply  # Everything automatic

# After demo
terraform destroy  # Save credits
```

**Time:** ~5 minutes to show, instant to destroy

---

## 📊 Cost Comparison

| Approach | Monthly Cost | Setup Time |
|----------|--------------|------------|
| **Always Running** | ~$21.67 | 0 min |
| **Destroy Nightly** | ~$0.05 | 5 min/day |
| **Destroy After Demo** | ~$0.05 | 5 min when needed |

**Recommended:** Destroy after each demo session

---

## 🛠️ Troubleshooting

### Issue: Seed Task Fails

**Check logs:**

```powershell
# Get recent seed task
$taskArn = aws ecs list-tasks --cluster marketfy-cluster --region us-east-1 --query 'taskArns[0]' --output text

# View logs
MSYS_NO_PATHCONV=1 aws logs tail /ecs/marketfy --region us-east-1 --since 10m | grep -i seed
```

### Issue: Images Not Found

**Solution:** Run build script once

```powershell
cd marketfy-infra/scripts
.\build-and-push-images.ps1
```

### Issue: Auto-Seed Runs Every Time

**Solution:** Remove `always_run` trigger in automation.tf:

```hcl
triggers = {
  db_endpoint = aws_db_instance.marketfy.endpoint
  # Remove this line:
  # always_run = timestamp()
}
```

---

## ✅ Verification Steps

After `terraform apply`:

```powershell
# 1. Check automation output
terraform output automation_enabled

# 2. Get ALB DNS
$ALB = terraform output -raw load_balancer_dns

# 3. Test API
curl "http://$ALB/api/health"

# 4. Test products (should return 30 items)
curl "http://$ALB/api/products?limit=5"

# 5. Check frontends
Start-Process "http://$ALB/angular/"
Start-Process "http://$ALB/react/"
```

---

## 📝 Summary

### What You Can Do Now

```powershell
# Save money (destroy everything) - AUTOMATED!
.\scripts\destroy-infrastructure.ps1

# Demo time (recreate everything automatically)
terraform apply
```

### What Happens Automatically

1. ✅ Infrastructure created (EC2, RDS, ALB)
2. ✅ Docker images pulled from ECR
3. ✅ Services deployed
4. ✅ Database seeded with 30 products
5. ✅ Ready to use in ~5 minutes

### What You Never Do Again

- ❌ Manually build Docker images (one time only)
- ❌ Manually push to ECR (one time only)
- ❌ Manually seed database (automatic)
- ❌ Manually force ECS deployment (automatic)
- ❌ Manually delete stuck ECS services (automated script)
- ❌ Manually terminate EC2 instances (automated script)

---

## 🎓 Best Practices

1. **First deployment:** Run build script once to push images
2. **Daily work:** Destroy when not using (save credits)
3. **Demo time:** Just `terraform apply` (5 minutes)
4. **Keep images:** ECR storage costs ~$0.05/month (worth it!)
5. **Monitor costs:** Check AWS billing dashboard weekly

---

## 🚀 Quick Reference

```powershell
# Create everything (auto-seeds DB)
cd terraform
terraform apply

# Destroy everything (keeps ECR images) - AUTOMATED!
cd ../scripts
.\destroy-infrastructure.ps1

# Rebuild images (if code changed)
.\build-and-push-images.ps1

# Check automation status
cd ../terraform
terraform output automation_enabled

# Disable auto-seed
terraform apply -var="auto_seed_database=false"
```

---
