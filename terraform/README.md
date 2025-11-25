# Marketfy AWS Infrastructure with Terraform

Este directorio contiene la infraestructura como código (IaC) para desplegar Marketfy en AWS.

## 📋 Prerequisitos

1. **AWS CLI** instalado y configurado

   ```bash
   aws configure
   ```

2. **Terraform** instalado (versión >= 1.0)

   ```bash
   terraform version
   ```

3. **Docker** instalado y funcionando

   ```bash
   docker --version
   ```

4. **Imágenes Docker** construidas localmente

   ```bash
   cd ../
   docker-compose build
   ```

## 🏗️ Archivos de Infraestructura

```md
terraform/
├── providers.tf       # AWS provider configuration
├── variables.tf       # Input variables
├── vpc.tf            # VPC, subnets, NAT gateways
├── security.tf       # Security groups
├── rds.tf           # PostgreSQL database
├── ecr.tf           # Container registries
├── iam.tf           # IAM roles and policies
├── alb.tf           # Application Load Balancer
├── ecs.tf           # ECS cluster and services
└── outputs.tf       # Output values
```

## 🚀 Pasos de Deployment

### 1. Inicializar Terraform

```bash
cd terraform
terraform init
```

### 2. Crear archivo terraform.tfvars

Crea un archivo `terraform.tfvars` con tus valores:

```hcl
# terraform.tfvars (NO commitear este archivo!)
aws_region    = "us-east-1"
project_name  = "marketfy"
environment   = "prod"
owner_email   = "tu-email@ejemplo.com"

# Database (se generará password automáticamente)
db_username = "marketfy_user"

# JWT Secret (generar uno seguro)
jwt_secret = "tu-jwt-secret-muy-largo-y-aleatorio"

# Opcional: Habilitar HTTPS (requiere certificado ACM)
enable_https         = false
acm_certificate_arn  = ""

# Opcional: GitHub Actions
enable_github_actions = false
github_repo          = ""  # ej: "usuario/marketfy"
```

### 3. Planear el Deployment

```bash
terraform plan
```

Revisa cuidadosamente todos los recursos que se crearán.

### 4. Aplicar la Infraestructura

```bash
terraform apply
```

Confirma con `yes` cuando se te pregunte.

⏱️ **Tiempo estimado:** 15-20 minutos

### 5. Subir Imágenes Docker a ECR

Después de que Terraform complete, ejecuta:

```bash
# Obtener comandos de login de ECR (se muestran en outputs)
terraform output deployment_instructions
```

O manualmente:

```bash
# Get ECR URLs from outputs
API_REPO=$(terraform output -raw ecr_api_repository_url)
ANGULAR_REPO=$(terraform output -raw ecr_angular_repository_url)
REACT_REPO=$(terraform output -raw ecr_react_repository_url)

# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $API_REPO

# Tag images
docker tag marketfy-infra-api:latest $API_REPO:latest
docker tag marketfy-infra-angular:latest $ANGULAR_REPO:latest
docker tag marketfy-infra-react:latest $REACT_REPO:latest

# Push images
docker push $API_REPO:latest
docker push $ANGULAR_REPO:latest
docker push $REACT_REPO:latest
```

### 6. Forzar Deployment de ECS

```bash
CLUSTER=$(terraform output -raw ecs_cluster_name)

aws ecs update-service --cluster $CLUSTER --service marketfy-api-service --force-new-deployment
aws ecs update-service --cluster $CLUSTER --service marketfy-angular-service --force-new-deployment
aws ecs update-service --cluster $CLUSTER --service marketfy-react-service --force-new-deployment
```

### 7. Ejecutar Migraciones de Base de Datos

```bash
# Opción 1: Ejecutar tarea ECS one-time
aws ecs run-task \
  --cluster $CLUSTER \
  --task-definition marketfy-api \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx]}" \
  --overrides '{
    "containerOverrides": [{
      "name": "api",
      "command": ["npx", "prisma", "migrate", "deploy"]
    }]
  }'

# Opción 2: Ejecutar desde container en ejecución
TASK_ARN=$(aws ecs list-tasks --cluster $CLUSTER --service-name marketfy-api-service --query 'taskArns[0]' --output text)
aws ecs execute-command \
  --cluster $CLUSTER \
  --task $TASK_ARN \
  --container api \
  --interactive \
  --command "npx prisma migrate deploy"
```

### 8. (Opcional) Seed Database

```bash
# Solo para ambientes de desarrollo/demo
aws ecs execute-command \
  --cluster $CLUSTER \
  --task $TASK_ARN \
  --container api \
  --interactive \
  --command "npm run seed"
```

## 🌐 Acceder a la Aplicación

Obtén la URL del Load Balancer:

```bash
terraform output load_balancer_dns
```

Accede a:

- **Angular:** http://[LOAD_BALANCER_DNS]/
- **React:** http://[LOAD_BALANCER_DNS]/react
- **API:** http://[LOAD_BALANCER_DNS]/api
- **Health:** http://[LOAD_BALANCER_DNS]/health

## 📊 Monitoreo

### Ver Logs

```bash
# Ver logs de todos los servicios
aws logs tail /ecs/marketfy --follow

# Ver logs de un servicio específico
aws logs tail /ecs/marketfy --follow --filter-pattern "api"
aws logs tail /ecs/marketfy --follow --filter-pattern "angular"
aws logs tail /ecs/marketfy --follow --filter-pattern "react"
```

### Verificar Estado de Servicios

```bash
CLUSTER=$(terraform output -raw ecs_cluster_name)

# Ver servicios
aws ecs list-services --cluster $CLUSTER

# Ver detalles de un servicio
aws ecs describe-services --cluster $CLUSTER --services marketfy-api-service

# Ver tasks en ejecución
aws ecs list-tasks --cluster $CLUSTER --service-name marketfy-api-service
```

### CloudWatch Dashboards

Accede a CloudWatch en la consola de AWS para ver métricas de:

- ECS Cluster
- ALB
- RDS
- Container Insights

## 🔐 Secretos

La contraseña de la base de datos se genera automáticamente y se guarda en AWS Secrets Manager.

Para obtenerla:

```bash
aws secretsmanager get-secret-value --secret-id marketfy-db-password --query SecretString --output text | jq .
```

## 💰 Costos Estimados (us-east-1)

| Recurso | Configuración | Costo Mensual Aprox. |
|---------|--------------|---------------------|
| **RDS PostgreSQL** | db.t3.micro, 20GB | $15/mes |
| **ECS Fargate (API)** | 0.25 vCPU, 0.5GB | $10-15/mes |
| **ECS Fargate (Frontends)** | 0.25 vCPU, 0.5GB x2 | $10-15/mes |
| **ALB** | 1 ALB | $18/mes |
| **NAT Gateway** | 1 NAT x AZ | $32/mes |
| **Data Transfer** | Variable | $5-10/mes |
| **CloudWatch Logs** | 5GB | $3/mes |
| **ECR Storage** | 1GB | $0.10/mes |
| **Total Estimado** | | **~$93-108/mes** |

### Optimizaciones de Costo

1. **Deshabilitar NAT Gateway** (perderás internet desde private subnets)

   ```hcl
   enable_nat_gateway = false
   ```

   Ahorro: $32/mes

2. **Usar Fargate Spot** (no incluido en esta versión)
   Ahorro: ~30-50%

3. **Reducir retention de logs**

   ```hcl
   # En cloudwatch_log_group
   retention_in_days = 3  # En vez de 7
   ```

   Ahorro: ~$1-2/mes

## 🧪 Testing

### Health Checks

```bash
ALB_DNS=$(terraform output -raw load_balancer_dns)

# API Health
curl http://$ALB_DNS/health

# Angular
curl http://$ALB_DNS/

# React
curl http://$ALB_DNS/react
```

### Load Testing

```bash
# Instalar hey (load testing tool)
# brew install hey  # macOS
# go install github.com/rakyll/hey@latest  # Go

# Test API
hey -n 1000 -c 10 http://$ALB_DNS/health
```

## 🔄 CI/CD con GitHub Actions

Si habilitaste `enable_github_actions = true`, configura GitHub Actions:

1. Agrega estos secretos a tu repo de GitHub:
   - `AWS_REGION`: us-east-1
   - `AWS_ROLE_ARN`: (del output `github_actions_role_arn`)

2. Crea `.github/workflows/deploy.yml`:

```yaml
name: Deploy to AWS

on:
  push:
    branches: [main]

permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          aws-region: ${{ secrets.AWS_REGION }}

      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v1

      - name: Build and push Docker images
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
        run: |
          docker build -t $ECR_REGISTRY/marketfy-api:latest ./api
          docker push $ECR_REGISTRY/marketfy-api:latest
          # Repeat for angular and react...

      - name: Update ECS services
        run: |
          aws ecs update-service --cluster marketfy-cluster --service marketfy-api-service --force-new-deployment
```

## 🗑️ Destruir Infraestructura

⚠️ **CUIDADO:** Esto eliminará TODOS los recursos incluyendo la base de datos.

```bash
# Eliminar protección de eliminación si está habilitada
terraform apply -var="enable_deletion_protection=false"

# Destruir todo
terraform destroy
```

Si tienes problemas con recursos que no se eliminan:

```bash
# Forzar eliminación de ECR repositories
aws ecr delete-repository --repository-name marketfy-api --force
aws ecr delete-repository --repository-name marketfy-angular --force
aws ecr delete-repository --repository-name marketfy-react --force

# Luego destroy de nuevo
terraform destroy
```

## 📚 Recursos Adicionales

- [Documentación de Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/bestpracticesguide/intro.html)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)

## 🐛 Troubleshooting

### ECS Tasks no inician

```bash
# Ver eventos del servicio
aws ecs describe-services --cluster marketfy-cluster --services marketfy-api-service

# Ver logs del container que falla
aws logs tail /ecs/marketfy --follow --filter-pattern "ERROR"
```

### No puedo conectar a RDS

- Verifica security groups
- Verifica que NAT Gateway esté funcionando
- Verifica que las subnets privadas tengan ruta a NAT

### ALB retorna 503

- Verifica que los targets estén healthy
- Revisa health check configuration
- Ver logs de ALB en CloudWatch

### Costos inesperados

```bash
# Ver estimación de costos
aws ce get-cost-and-usage \
  --time-period Start=2025-11-01,End=2025-11-30 \
  --granularity MONTHLY \
  --metrics UnblendedCost \
  --group-by Type=SERVICE
```

## 🆘 Support

Si tienes problemas:

1. Revisa los logs de CloudWatch
2. Verifica el estado en la consola de AWS
3. Revisa el archivo `DEPLOYMENT-SUMMARY.md` en el directorio raíz
4. Consulta `SECURITY.md` para security best practices

---

**Última actualización:** 2025-11-18
**Terraform Version:** >= 1.0
**AWS Provider Version:** >= 5.0
