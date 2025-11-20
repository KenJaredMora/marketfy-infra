# ==================================
# RDS PostgreSQL Configuration
# ==================================

# DB Subnet Group
resource "aws_db_subnet_group" "marketfy" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# DB Parameter Group
resource "aws_db_parameter_group" "marketfy" {
  name   = "${var.project_name}-postgres-params"
  family = "postgres16"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  parameter {
    name  = "log_duration"
    value = "1"
  }

  parameter {
    name  = "log_statement"
    value = "all"
  }

  tags = {
    Name = "${var.project_name}-postgres-params"
  }
}

# Random password for RDS
resource "random_password" "db_password" {
  length  = 32
  special = true
  # Avoid characters that might cause issues in connection strings
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Store DB password in Secrets Manager
resource "aws_secretsmanager_secret" "db_password" {
  name        = "${var.project_name}-db-password"
  description = "PostgreSQL database password for Marketfy"

  tags = {
    Name = "${var.project_name}-db-password"
  }
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
    engine   = "postgres"
    host     = aws_db_instance.marketfy.address
    port     = aws_db_instance.marketfy.port
    dbname   = var.db_name
  })
}

# RDS Instance
resource "aws_db_instance" "marketfy" {
  identifier = "${var.project_name}-db"

  # Engine
  engine         = "postgres"
  engine_version = "16.10"

  # Instance class and storage
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  # Database configuration
  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.marketfy.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  multi_az               = var.db_multi_az

  # Parameter and option groups
  parameter_group_name = aws_db_parameter_group.marketfy.name

  # Backup configuration
  backup_retention_period = var.db_backup_retention_days
  backup_window           = "03:00-04:00"  # 3-4 AM UTC
  maintenance_window      = "mon:04:00-mon:05:00"

  # Monitoring and logs
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  monitoring_interval             = 60
  monitoring_role_arn             = aws_iam_role.rds_monitoring.arn

  # Performance Insights
  performance_insights_enabled    = true
  performance_insights_retention_period = 7

  # Deletion protection
  deletion_protection       = var.enable_deletion_protection
  skip_final_snapshot       = !var.enable_deletion_protection
  final_snapshot_identifier = "${var.project_name}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  # Auto minor version upgrade
  auto_minor_version_upgrade = true

  # Copy tags to snapshots
  copy_tags_to_snapshot = true

  tags = {
    Name = "${var.project_name}-db"
  }

  lifecycle {
    ignore_changes = [
      final_snapshot_identifier,
    ]
  }
}

# IAM Role for Enhanced Monitoring
resource "aws_iam_role" "rds_monitoring" {
  name = "${var.project_name}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-rds-monitoring-role"
  }
}

# Attach AWS managed policy for RDS Enhanced Monitoring
resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# CloudWatch Alarms for RDS
resource "aws_cloudwatch_metric_alarm" "database_cpu" {
  alarm_name          = "${var.project_name}-db-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors RDS CPU utilization"
  alarm_actions       = []  # Add SNS topic ARN here for notifications

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.marketfy.id
  }

  tags = {
    Name = "${var.project_name}-db-cpu-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "database_storage" {
  alarm_name          = "${var.project_name}-db-free-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "5000000000"  # 5GB in bytes
  alarm_description   = "This metric monitors RDS free storage space"
  alarm_actions       = []  # Add SNS topic ARN here for notifications

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.marketfy.id
  }

  tags = {
    Name = "${var.project_name}-db-storage-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "database_connections" {
  alarm_name          = "${var.project_name}-db-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"  # Adjust based on your needs
  alarm_description   = "This metric monitors RDS database connections"
  alarm_actions       = []  # Add SNS topic ARN here for notifications

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.marketfy.id
  }

  tags = {
    Name = "${var.project_name}-db-connections-alarm"
  }
}
