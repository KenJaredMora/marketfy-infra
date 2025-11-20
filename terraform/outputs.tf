# ==================================
# Terraform Outputs
# ==================================

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.marketfy.id
}

output "vpc_cidr" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.marketfy.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = aws_subnet.private[*].id
}

# RDS Outputs
output "database_endpoint" {
  description = "RDS database endpoint"
  value       = aws_db_instance.marketfy.endpoint
  sensitive   = true
}

output "database_name" {
  description = "RDS database name"
  value       = aws_db_instance.marketfy.db_name
}

output "database_username" {
  description = "RDS database username"
  value       = aws_db_instance.marketfy.username
  sensitive   = true
}

output "database_secret_arn" {
  description = "ARN of the Secrets Manager secret containing database credentials"
  value       = aws_secretsmanager_secret.db_password.arn
}

# ECR Outputs
output "ecr_api_repository_url" {
  description = "URL of the API ECR repository"
  value       = aws_ecr_repository.api.repository_url
}

output "ecr_angular_repository_url" {
  description = "URL of the Angular ECR repository"
  value       = aws_ecr_repository.angular.repository_url
}

output "ecr_react_repository_url" {
  description = "URL of the React ECR repository"
  value       = aws_ecr_repository.react.repository_url
}

# ALB Outputs
output "load_balancer_dns" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.marketfy.dns_name
}

output "load_balancer_zone_id" {
  description = "Zone ID of the Application Load Balancer"
  value       = aws_lb.marketfy.zone_id
}

output "load_balancer_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.marketfy.arn
}

# Application URLs
output "angular_url" {
  description = "URL for Angular frontend"
  value       = "http://${aws_lb.marketfy.dns_name}/"
}

output "react_url" {
  description = "URL for React frontend"
  value       = "http://${aws_lb.marketfy.dns_name}/react"
}

output "api_url" {
  description = "URL for API backend"
  value       = "http://${aws_lb.marketfy.dns_name}/api"
}

output "api_health_url" {
  description = "URL for API health check"
  value       = "http://${aws_lb.marketfy.dns_name}/health"
}

# ECS Outputs
output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.marketfy.name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.marketfy.arn
}

output "ecs_api_service_name" {
  description = "Name of the API ECS service"
  value       = aws_ecs_service.api.name
}

output "ecs_angular_service_name" {
  description = "Name of the Angular ECS service"
  value       = aws_ecs_service.angular.name
}

output "ecs_react_service_name" {
  description = "Name of the React ECS service"
  value       = aws_ecs_service.react.name
}

# CloudWatch Logs
output "cloudwatch_log_group" {
  description = "CloudWatch log group for ECS"
  value       = aws_cloudwatch_log_group.ecs.name
}

# IAM Outputs
output "ecs_task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution.arn
}

output "ecs_task_role_arn" {
  description = "ARN of the ECS task role"
  value       = aws_iam_role.ecs_task.arn
}

# Security Group Outputs
output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "ecs_tasks_security_group_id" {
  description = "ID of the ECS tasks security group"
  value       = aws_security_group.ecs_tasks.id
}

output "rds_security_group_id" {
  description = "ID of the RDS security group"
  value       = aws_security_group.rds.id
}

# GitHub Actions (if enabled)
output "github_actions_role_arn" {
  description = "ARN of the GitHub Actions IAM role"
  value       = var.enable_github_actions ? aws_iam_role.github_actions[0].arn : null
}

# Deployment Instructions
output "deployment_instructions" {
  description = "Quick deployment instructions"
  value = <<-EOT
    ========================================
    Marketfy Deployment Information
    ========================================

    1. Push Docker Images to ECR:

    aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.api.repository_url}

    docker tag marketfy-infra-api:latest ${aws_ecr_repository.api.repository_url}:latest
    docker push ${aws_ecr_repository.api.repository_url}:latest

    docker tag marketfy-infra-angular:latest ${aws_ecr_repository.angular.repository_url}:latest
    docker push ${aws_ecr_repository.angular.repository_url}:latest

    docker tag marketfy-infra-react:latest ${aws_ecr_repository.react.repository_url}:latest
    docker push ${aws_ecr_repository.react.repository_url}:latest

    2. Update ECS Services:

    aws ecs update-service --cluster ${aws_ecs_cluster.marketfy.name} --service ${aws_ecs_service.api.name} --force-new-deployment
    aws ecs update-service --cluster ${aws_ecs_cluster.marketfy.name} --service ${aws_ecs_service.angular.name} --force-new-deployment
    aws ecs update-service --cluster ${aws_ecs_cluster.marketfy.name} --service ${aws_ecs_service.react.name} --force-new-deployment

    3. Access Your Applications:

    Angular: http://${aws_lb.marketfy.dns_name}/
    React:   http://${aws_lb.marketfy.dns_name}/react
    API:     http://${aws_lb.marketfy.dns_name}/api
    Health:  http://${aws_lb.marketfy.dns_name}/health

    4. View Logs:

    aws logs tail /ecs/${var.project_name} --follow --filter-pattern "api"

    5. Database Credentials:

    aws secretsmanager get-secret-value --secret-id ${aws_secretsmanager_secret.db_password.name} --query SecretString --output text | jq .

    ========================================
  EOT
}

# Summary Output
output "deployment_summary" {
  description = "Deployment summary"
  value = {
    region              = var.aws_region
    vpc_id              = aws_vpc.marketfy.id
    load_balancer_dns   = aws_lb.marketfy.dns_name
    database_endpoint   = aws_db_instance.marketfy.endpoint
    ecs_cluster         = aws_ecs_cluster.marketfy.name
    log_group           = aws_cloudwatch_log_group.ecs.name
    ecr_api_url         = aws_ecr_repository.api.repository_url
    ecr_angular_url     = aws_ecr_repository.angular.repository_url
    ecr_react_url       = aws_ecr_repository.react.repository_url
  }
}
