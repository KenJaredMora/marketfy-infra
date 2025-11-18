# ============================================
# Marketfy Infrastructure Variables
# ============================================

# Basic Configuration
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "marketfy"
}

variable "owner_email" {
  description = "Owner email for resource tagging"
  type        = string
}

# Networking
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

# Database Configuration
variable "db_name" {
  description = "Database name"
  type        = string
  default     = "marketfy"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro" # Free tier eligible
}

# Application Configuration
variable "jwt_secret" {
  description = "JWT secret for authentication"
  type        = string
  sensitive   = true
}

variable "api_port" {
  description = "API service port"
  type        = number
  default     = 3000
}

# ECS Configuration
variable "ecs_instance_type" {
  description = "EC2 instance type for ECS"
  type        = string
  default     = "t3.micro" # Free tier eligible
}

variable "ecs_desired_capacity" {
  description = "Desired number of ECS instances"
  type        = number
  default     = 1
}

variable "ecs_max_capacity" {
  description = "Maximum number of ECS instances"
  type        = number
  default     = 2
}

# Task Configuration
variable "api_cpu" {
  description = "CPU units for API task"
  type        = number
  default     = 256
}

variable "api_memory" {
  description = "Memory (MB) for API task"
  type        = number
  default     = 512
}

variable "frontend_cpu" {
  description = "CPU units for frontend tasks"
  type        = number
  default     = 128
}

variable "frontend_memory" {
  description = "Memory (MB) for frontend tasks"
  type        = number
  default     = 256
}

# Domain Configuration (optional)
variable "domain_name" {
  description = "Domain name for the application (optional)"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS (optional)"
  type        = string
  default     = ""
}

# Enable/Disable Features
variable "enable_https" {
  description = "Enable HTTPS on ALB"
  type        = bool
  default     = false # Set to true if you have a certificate
}

variable "enable_cloudtrail" {
  description = "Enable CloudTrail for auditing"
  type        = bool
  default     = true
}

variable "enable_waf" {
  description = "Enable AWS WAF for additional security"
  type        = bool
  default     = false
}

# IP Whitelist (for additional security)
variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the application"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Allow all by default, restrict in production
}

variable "admin_cidr_blocks" {
  description = "CIDR blocks allowed SSH access to ECS instances"
  type        = list(string)
  default     = [] # No SSH access by default
}
