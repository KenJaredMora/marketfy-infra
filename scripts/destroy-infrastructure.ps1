param(
    [switch]$SkipConfirmation = $false
)

$Region = "us-east-1"
$ClusterName = "marketfy-cluster"
$AsgName = "marketfy-ecs-asg"

Write-Host "========================================"
Write-Host "Marketfy Infrastructure Destroy Script"
Write-Host "========================================"
Write-Host ""

if (-not $SkipConfirmation)
{
    Write-Host "This will destroy ALL infrastructure" -ForegroundColor Yellow
    Write-Host "ECR images will be preserved" -ForegroundColor Green
    Write-Host ""
    $response = Read-Host "Continue? (yes/no)"
    if ($response -ne "yes")
    {
        Write-Host "Cancelled" -ForegroundColor Yellow
        exit 0
    }
}

Write-Host ""
Write-Host "Starting destruction..." -ForegroundColor Cyan
Write-Host ""

# Step 1: Delete ECS services
Write-Host "[1/5] Deleting ECS services..." -ForegroundColor Yellow
aws ecs delete-service --cluster $ClusterName --service marketfy-api-service --force --region $Region 2>$null | Out-Null
aws ecs delete-service --cluster $ClusterName --service marketfy-angular-service --force --region $Region 2>$null | Out-Null
aws ecs delete-service --cluster $ClusterName --service marketfy-react-service --force --region $Region 2>$null | Out-Null
Write-Host "  Done" -ForegroundColor Green
Write-Host ""

# Step 2: Configure ASG
Write-Host "[2/5] Configuring ASG..." -ForegroundColor Yellow
aws autoscaling update-auto-scaling-group --auto-scaling-group-name $AsgName --desired-capacity 0 --min-size 0 --max-size 0 --region $Region 2>$null | Out-Null
Write-Host "  Done" -ForegroundColor Green
Write-Host ""

# Step 3: Terminate instances
Write-Host "[3/5] Terminating instances..." -ForegroundColor Yellow
$instances = aws ec2 describe-instances --filters "Name=tag:aws:autoscaling:groupName,Values=$AsgName" "Name=instance-state-name,Values=running,pending" --region $Region --query 'Reservations[*].Instances[*].InstanceId' --output text 2>$null
if ($instances)
{
    $instanceIds = $instances -split '\s+'
    aws ec2 terminate-instances --instance-ids $instanceIds --region $Region 2>$null | Out-Null
    Write-Host "  Waiting 60s..." -ForegroundColor Gray
    Start-Sleep -Seconds 60
}
Write-Host "  Done" -ForegroundColor Green
Write-Host ""

# Step 4: Wait
Write-Host "[4/5] Waiting for cleanup..." -ForegroundColor Yellow
Start-Sleep -Seconds 15
Write-Host "  Done" -ForegroundColor Green
Write-Host ""

# Step 5: Terraform destroy
Write-Host "[5/5] Running terraform destroy..." -ForegroundColor Yellow
Write-Host ""
$terraformDir = Join-Path (Split-Path -Parent $PSScriptRoot) "terraform"
Push-Location $terraformDir
terraform destroy -auto-approve
$exitCode = $LASTEXITCODE
Pop-Location

Write-Host ""
if ($exitCode -eq 0)
{
    Write-Host "========================================"
    Write-Host "Infrastructure Destroyed!" -ForegroundColor Green
    Write-Host "========================================"
}
else
{
    Write-Host "========================================"
    Write-Host "Completed with warnings" -ForegroundColor Yellow
    Write-Host "========================================"
}

Write-Host ""
exit $exitCode
