# ==================================
# Automation for Database Seeding
# ==================================

# Variable to control automatic seeding
variable "auto_seed_database" {
  description = "Automatically seed database after infrastructure creation"
  type        = bool
  default     = true
}

# Wait for ECS services to be stable before seeding
resource "null_resource" "wait_for_services" {
  count = var.auto_seed_database ? 1 : 0

  depends_on = [
    aws_ecs_service.api,
    aws_ecs_service.angular,
    aws_ecs_service.react,
    aws_db_instance.marketfy
  ]

  provisioner "local-exec" {
    command = <<-EOT
      Write-Host "Waiting for ECS services to stabilize..." -ForegroundColor Yellow
      Start-Sleep -Seconds 60

      Write-Host "Checking API health..." -ForegroundColor Yellow
      $healthy = $false
      for ($i = 1; $i -le 30; $i++) {
        try {
          $response = Invoke-WebRequest -Uri "http://${aws_lb.marketfy.dns_name}/api/health" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
          if ($response.StatusCode -eq 200) {
            Write-Host "API is healthy!" -ForegroundColor Green
            $healthy = $true
            break
          }
        } catch {
          Write-Host "Attempt $i/30: Waiting for API..." -ForegroundColor Gray
          Start-Sleep -Seconds 10
        }
      }
      if (-not $healthy) {
        Write-Host "Warning: API health check timed out" -ForegroundColor Yellow
      }
    EOT

    interpreter = ["PowerShell", "-Command"]
  }

  triggers = {
    # Re-run if RDS endpoint changes (new database)
    db_endpoint = aws_db_instance.marketfy.endpoint
    # Re-run if ALB DNS changes
    alb_dns = aws_lb.marketfy.dns_name
    # Force re-run on every apply (optional, remove if you don't want this)
    always_run = timestamp()
  }
}

# Run database seed via ECS task
resource "null_resource" "seed_database" {
  count = var.auto_seed_database ? 1 : 0

  depends_on = [null_resource.wait_for_services]

  provisioner "local-exec" {
    command = <<-EOT
      echo "Starting database seed..."

      # Run seed task
      $taskArn = aws ecs run-task `
        --cluster ${aws_ecs_cluster.marketfy.name} `
        --task-definition ${aws_ecs_task_definition.api.family}:${aws_ecs_task_definition.api.revision} `
        --region ${var.aws_region} `
        --count 1 `
        --launch-type EC2 `
        --overrides '{\"containerOverrides\":[{\"name\":\"api\",\"command\":[\"sh\",\"-c\",\"cd /app && npx tsx prisma/seed.ts\"]}]}' `
        --query 'tasks[0].taskArn' `
        --output text

      if ($taskArn) {
        echo "Seed task started: $taskArn"
        echo "Waiting for seed to complete..."

        # Wait for task to complete (max 5 minutes)
        $startTime = Get-Date
        $timeout = 300

        while ($true) {
          $elapsed = ((Get-Date) - $startTime).TotalSeconds
          if ($elapsed -gt $timeout) {
            echo "Timeout waiting for seed task"
            break
          }

          $status = aws ecs describe-tasks `
            --cluster ${aws_ecs_cluster.marketfy.name} `
            --tasks $taskArn `
            --region ${var.aws_region} `
            --query 'tasks[0].lastStatus' `
            --output text

          if ($status -eq "STOPPED") {
            $exitCode = aws ecs describe-tasks `
              --cluster ${aws_ecs_cluster.marketfy.name} `
              --tasks $taskArn `
              --region ${var.aws_region} `
              --query 'tasks[0].containers[0].exitCode' `
              --output text

            if ($exitCode -eq "0") {
              echo "✅ Database seeded successfully!"
            } else {
              echo "❌ Seed task failed with exit code: $exitCode"
            }
            break
          }

          echo "Seed task status: $status (elapsed: $([int]$elapsed)s)"
          Start-Sleep -Seconds 10
        }
      } else {
        echo "Failed to start seed task"
      }
    EOT

    interpreter = ["PowerShell", "-Command"]
  }

  triggers = {
    # Re-run when database changes
    db_endpoint = aws_db_instance.marketfy.endpoint
    # Re-run on every apply (remove if you want to seed only once)
    always_run = timestamp()
  }
}

# Output to confirm automation status
output "automation_enabled" {
  description = "Status of automation features"
  value = {
    auto_seed_database   = var.auto_seed_database
    ecr_force_delete     = false
    ecr_images_preserved = "Docker images in ECR will NOT be deleted on terraform destroy"
  }
}
