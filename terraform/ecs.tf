# ==================================
# ECS Cluster on EC2 (Free-tier friendly)
# ==================================

# ECS Cluster
resource "aws_ecs_cluster" "marketfy" {
  name = "${var.project_name}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.project_name}-cluster"
  }
}

# CloudWatch Log Group for ECS
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project_name}"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-ecs-logs"
  }
}

# ==================================
# EC2 Capacity (ASG + Capacity Provider)
# ==================================

# ECS-optimized Amazon Linux 2 AMI
data "aws_ami" "ecs_al2" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}

# Launch Template for ECS instances
resource "aws_launch_template" "ecs" {
  name_prefix   = "${var.project_name}-ecs-"
  image_id      = data.aws_ami.ecs_al2.id
  instance_type = var.ecs_instance_type

  vpc_security_group_ids = [aws_security_group.ecs_tasks.id]

  iam_instance_profile {
    # Usa el instance profile "ecsInstanceRole" (AWS managed) que debes crear una sola vez
    name = "ecsInstanceRole"
  }

  user_data = base64encode(<<EOF
#!/bin/bash
echo ECS_CLUSTER=${aws_ecs_cluster.marketfy.name} >> /etc/ecs/ecs.config
EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-ecs-instance"
    }
  }
}

# Auto Scaling Group for ECS instances
resource "aws_autoscaling_group" "ecs_asg" {
  name                      = "${var.project_name}-ecs-asg"
  desired_capacity          = var.ecs_desired_capacity
  max_size                  = var.ecs_max_capacity
  min_size                  = 1
  vpc_zone_identifier       = aws_subnet.public[*].id
  protect_from_scale_in     = true  # Required for ECS managed termination protection

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = "true"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ECS Capacity Provider linked to ASG
resource "aws_ecs_capacity_provider" "ecs_cp" {
  name = "${var.project_name}-capacity"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.ecs_asg.arn

    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 100
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 1
    }

    managed_termination_protection = "ENABLED"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Attach Capacity Provider to ECS Cluster
resource "aws_ecs_cluster_capacity_providers" "marketfy" {
  cluster_name       = aws_ecs_cluster.marketfy.name
  capacity_providers = [aws_ecs_capacity_provider.ecs_cp.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_cp.name
    weight            = 100
  }
}

# ==================================
# Task Definitions (EC2, no Fargate)
# ==================================

# API Task Definition (Nest)
resource "aws_ecs_task_definition" "api" {
  family                   = "${var.project_name}-api"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  cpu                      = var.api_cpu
  memory                   = var.api_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "api"
      image     = "${aws_ecr_repository.api.repository_url}:latest"
      essential = true

      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "NODE_ENV"
          value = "production"
        },
        {
          name  = "PORT"
          value = "3000"
        },
        {
          name  = "DATABASE_URL"
          value = "postgresql://${var.db_username}:${urlencode(random_password.db_password.result)}@${aws_db_instance.marketfy.address}:5432/${var.db_name}?schema=public"
        },
        {
          name  = "JWT_SECRET"
          value = var.jwt_secret
        },
        {
          name  = "FRONTEND_URL"
          value = "http://${aws_lb.marketfy.dns_name}"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "api"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1"]
        interval    = 30
        timeout     = 10
        retries     = 5
        startPeriod = 120
      }
    }
  ])

  tags = {
    Name = "${var.project_name}-api-task"
  }
}

# Angular Task Definition
resource "aws_ecs_task_definition" "angular" {
  family                   = "${var.project_name}-angular"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  cpu                      = var.frontend_cpu
  memory                   = var.frontend_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "angular"
      image     = "${aws_ecr_repository.angular.repository_url}:latest"
      essential = true

      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "angular"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost/ || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 30
      }
    }
  ])

  tags = {
    Name = "${var.project_name}-angular-task"
  }
}

# React Task Definition
resource "aws_ecs_task_definition" "react" {
  family                   = "${var.project_name}-react"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  cpu                      = var.frontend_cpu
  memory                   = var.frontend_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "react"
      image     = "${aws_ecr_repository.react.repository_url}:latest"
      essential = true

      portMappings = [
        {
          containerPort = 80
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "react"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost/ || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 30
      }
    }
  ])

  tags = {
    Name = "${var.project_name}-react-task"
  }
}

# ==================================
# ECS Services (EC2 + Capacity Provider)
# ==================================

# API Service
resource "aws_ecs_service" "api" {
  name            = "${var.project_name}-api-service"
  cluster         = aws_ecs_cluster.marketfy.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = var.api_desired_count

  # Usamos Capacity Provider (no launch_type FARGATE)
  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_cp.name
    weight            = 100
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "api"
    container_port   = 3000
  }

  depends_on = [
    aws_lb_listener.http,
    aws_db_instance.marketfy
  ]

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  tags = {
    Name = "${var.project_name}-api-service"
  }
}

# Angular Service
resource "aws_ecs_service" "angular" {
  name            = "${var.project_name}-angular-service"
  cluster         = aws_ecs_cluster.marketfy.id
  task_definition = aws_ecs_task_definition.angular.arn
  desired_count   = var.frontend_desired_count

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_cp.name
    weight            = 100
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.angular.arn
    container_name   = "angular"
    container_port   = 80
  }

  depends_on = [
    aws_lb_listener.http,
    aws_ecs_service.api
  ]

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  tags = {
    Name = "${var.project_name}-angular-service"
  }
}

# React Service
resource "aws_ecs_service" "react" {
  name            = "${var.project_name}-react-service"
  cluster         = aws_ecs_cluster.marketfy.id
  task_definition = aws_ecs_task_definition.react.arn
  desired_count   = var.frontend_desired_count

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.ecs_cp.name
    weight            = 100
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.react.arn
    container_name   = "react"
    container_port   = 80
  }

  depends_on = [
    aws_lb_listener.http,
    aws_ecs_service.api
  ]

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  tags = {
    Name = "${var.project_name}-react-service"
  }
}

# ==================================
# (Opcional) Auto Scaling for API (kept, but now EC2-backed)
# ==================================

resource "aws_appautoscaling_target" "api" {
  max_capacity       = var.api_max_count
  min_capacity       = var.api_min_count
  resource_id        = "service/${aws_ecs_cluster.marketfy.name}/${aws_ecs_service.api.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "api_cpu" {
  name               = "${var.project_name}-api-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.api.resource_id
  scalable_dimension = aws_appautoscaling_target.api.scalable_dimension
  service_namespace  = aws_appautoscaling_target.api.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_policy" "api_memory" {
  name               = "${var.project_name}-api-memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.api.resource_id
  scalable_dimension = aws_appautoscaling_target.api.scalable_dimension
  service_namespace  = aws_appautoscaling_target.api.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = 80.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}
