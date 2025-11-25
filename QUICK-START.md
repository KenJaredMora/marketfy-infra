# Quick Start - Destroy & Recreate Infrastructure

## ✅ Automation is NOW Active

We can now destroy and recreate our infrastructure with just one command.

---

## 🎯 What's Automated

✅ **ECR Images Preserved** - Docker images stay in ECR (cost: ~$0.05/month)
✅ **Database Auto-Seeding** - 30 products + 2 demo users created automatically
✅ **Service Deployment** - ECS pulls images and starts services automatically
✅ **Health Checks** - Waits for API to be ready before seeding

---

## 💰 Destroy Infrastructure (Save Credits)

**Option 1: Automated (Recommended)*

```powershell
cd "C:\Users\Kenyon Jared Zamora\Downloads\Proyecto Deloitte Java\marketfy-infra\scripts"

# Run automated destroy script
.\destroy-infrastructure.ps1
```

**Option 2: Manual (if you prefer)*

```powershell
cd "C:\Users\Kenyon Jared Zamora\Downloads\Proyecto Deloitte Java\marketfy-infra\terraform"

# Destroy everything
terraform destroy

# Type: yes when prompted
# Note: May require manual cleanup of ECS services and EC2 instances
```

**After destroy:**

- Monthly cost: ~$0.05 (just ECR storage)
- Docker images: Still in ECR ✅
- Source code: Safe on our machine ✅
- Terraform state: Preserved ✅

---

## 🚀 Recreate Infrastructure (Demo Time)

```powershell
cd "C:\Users\Kenyon Jared Zamora\Downloads\Proyecto Deloitte Java\marketfy-infra\terraform"

# Recreate everything
terraform apply

# Type: yes when prompted
```

**What happens automatically:**

1. Creates infrastructure (EC2, RDS, ALB, VPC) ~3 min
2. Waits for services to stabilize ~1 min
3. Seeds database with 30 products ~1 min
4. Services are ready! ~5 min total

**If seeding fails:**

```powershell
cd ..\scripts
.\seed-database.ps1
```

**Access our apps:**

- Angular: <http://marketfy-alb-646939327.us-east-1.elb.amazonaws.com/angular/>
- React: <http://marketfy-alb-646939327.us-east-1.elb.amazonaws.com/react/>
- API: <http://marketfy-alb-646939327.us-east-1.elb.amazonaws.com/api/>

**Demo credentials:**

- Email: <demo@marketfy.test>
- Password: password123

---

## 🔧 Troubleshooting

### If Database Seed Fails

The automation tries to seed automatically, but if it fails, we can run manually:

```powershell
cd "C:\Users\Kenyon Jared Zamora\Downloads\Proyecto Deloitte Java\marketfy-infra\terraform"

$CLUSTER = terraform output -raw ecs_cluster_name

aws ecs run-task `
  --cluster $CLUSTER `
  --task-definition marketfy-api:1 `
  --region us-east-1 `
  --count 1 `
  --launch-type EC2 `
  --overrides '{\"containerOverrides\":[{\"name\":\"api\",\"command\":[\"sh\",\"-c\",\"cd /app && npx tsx prisma/seed.ts\"]}]}'
```

### Check Automation Status

```powershell
cd marketfy-infra/terraform
terraform output automation_enabled
```

### Verify Database Has Products

```powershell
$ALB = terraform output -raw load_balancer_dns
curl "http://$ALB/api/products?limit=5"
```

---

## 📊 Cost Comparison

| Scenario | Monthly Cost | Use Case |
|----------|--------------|----------|
| **Always Running** | ~$21.67 | Production or daily use |
| **Destroy Nightly** | ~$0.05 | Daily development |
| **Destroy After Demo** | ~$0.05 | Occasional demos |

**Recommendation:** Destroy after each use, recreate when needed (saves ~$21/month)

---

## ⚡ Quick Commands

```powershell
# Destroy (save credits) - AUTOMATED
cd scripts
.\destroy-infrastructure.ps1

# Recreate (demo time)
cd ../terraform
terraform apply

# Check status
terraform output automation_enabled

# View products
curl "http://$(terraform output -raw load_balancer_dns)/api/products?limit=5"

# Open frontends
$ALB = terraform output -raw load_balancer_dns
Start-Process "http://$ALB/angular/"
Start-Process "http://$ALB/react/"
```

---

## 🎓 Example Workflow

### Monday Morning (Start Week)

```powershell
cd marketfy-infra/terraform
terraform apply  # Creates everything in ~5 minutes
```

### Friday Evening (Save Credits)

```powershell
cd marketfy-infra/scripts
.\destroy-infrastructure.ps1  # Automated destroy, keeps images
```

### Cost This Week

- 5 days × 24 hours × (5/30) × $21.67 = ~$3.61
- ECR storage: $0.05
- **Total: ~$3.66 for the week**

vs keeping it running all week: ~$21.67 × (7/30) = ~$5.06

**Savings: ~$1.40/week** ($6/month)

---

## ✅ What's Protected

Our project is safe:

- ✅ All source code (local)
- ✅ Docker images (ECR - preserved)
- ✅ Terraform state (local)
- ✅ All configuration files
- ✅ Documentation

Only infrastructure resources are destroyed (EC2, RDS, etc.)

---

## 📝 Summary

**Destroy:** `.\scripts\destroy-infrastructure.ps1`

- Cost: $0/month
- Time: ~2-3 minutes
- Fully automated - no manual steps!

**Recreate:** `terraform apply`

- Cost: ~$21.67/month (when running)
- Time: ~5 minutes
- Database: Auto-seeded
- Ready to demo!

---

**We're all set!** Destroy when not using, recreate when needed.
