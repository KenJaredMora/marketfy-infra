# ==================================
# Build and Push Docker Images to ECR
# ==================================
# Run this script BEFORE terraform apply to ensure images exist

param(
    [string]$Region = "us-east-1",
    [string]$ProjectName = "marketfy"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Building and Pushing Docker Images to ECR" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get ECR repository URLs
Write-Host "Getting ECR repository URLs..." -ForegroundColor Yellow
$apiRepo = aws ecr describe-repositories --repository-names "$ProjectName-api" --region $Region --query 'repositories[0].repositoryUri' --output text 2>$null
$angularRepo = aws ecr describe-repositories --repository-names "$ProjectName-angular" --region $Region --query 'repositories[0].repositoryUri' --output text 2>$null
$reactRepo = aws ecr describe-repositories --repository-names "$ProjectName-react" --region $Region --query 'repositories[0].repositoryUri' --output text 2>$null

if (-not $apiRepo) {
    Write-Host "❌ ECR repositories not found. Run 'terraform apply' first to create them." -ForegroundColor Red
    exit 1
}

Write-Host "✅ Found ECR repositories:" -ForegroundColor Green
Write-Host "   API:     $apiRepo" -ForegroundColor Gray
Write-Host "   Angular: $angularRepo" -ForegroundColor Gray
Write-Host "   React:   $reactRepo" -ForegroundColor Gray
Write-Host ""

# Check if images already exist
Write-Host "Checking for existing images..." -ForegroundColor Yellow
$apiImageExists = aws ecr describe-images --repository-name "$ProjectName-api" --region $Region --query 'imageDetails[?imageTags[?contains(@, `latest`)]]' --output text 2>$null
$angularImageExists = aws ecr describe-images --repository-name "$ProjectName-angular" --region $Region --query 'imageDetails[?imageTags[?contains(@, `latest`)]]' --output text 2>$null
$reactImageExists = aws ecr describe-images --repository-name "$ProjectName-react" --region $Region --query 'imageDetails[?imageTags[?contains(@, `latest`)]]' --output text 2>$null

if ($apiImageExists -and $angularImageExists -and $reactImageExists) {
    Write-Host "✅ All images already exist in ECR with 'latest' tag" -ForegroundColor Green
    Write-Host ""
    $response = Read-Host "Do you want to rebuild and push anyway? (y/N)"
    if ($response -ne "y") {
        Write-Host "Skipping image build. Using existing images." -ForegroundColor Yellow
        exit 0
    }
}

# Login to ECR
Write-Host "Logging in to ECR..." -ForegroundColor Yellow
$ecrRegistry = $apiRepo.Split('/')[0]
$loginPassword = aws ecr get-login-password --region $Region
if (-not $loginPassword) {
    Write-Host "❌ Failed to get ECR login password" -ForegroundColor Red
    exit 1
}
$loginPassword | docker login --username AWS --password-stdin $ecrRegistry
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to login to ECR" -ForegroundColor Red
    exit 1
}
Write-Host "✅ Logged in to ECR" -ForegroundColor Green
Write-Host ""

# Set base directory
$baseDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

# Build and push API image
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Building API Docker Image" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
docker build -t marketfy-api:latest -f "$baseDir\marketfy-infra\docker\api\Dockerfile" "$baseDir\angular-project\marketfy-api"
if ($LASTEXITCODE -ne 0) { Write-Host "❌ Failed to build API image" -ForegroundColor Red; exit 1 }

docker tag marketfy-api:latest "$apiRepo:latest"
docker push "$apiRepo:latest"
if ($LASTEXITCODE -ne 0) { Write-Host "❌ Failed to push API image" -ForegroundColor Red; exit 1 }
Write-Host "✅ API image pushed successfully" -ForegroundColor Green
Write-Host ""

# Build and push Angular image
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Building Angular Docker Image" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
docker build -t marketfy-angular:latest -f "$baseDir\marketfy-infra\docker\angular\Dockerfile" "$baseDir\angular-project\marketfy"
if ($LASTEXITCODE -ne 0) { Write-Host "❌ Failed to build Angular image" -ForegroundColor Red; exit 1 }

docker tag marketfy-angular:latest "$angularRepo:latest"
docker push "$angularRepo:latest"
if ($LASTEXITCODE -ne 0) { Write-Host "❌ Failed to push Angular image" -ForegroundColor Red; exit 1 }
Write-Host "✅ Angular image pushed successfully" -ForegroundColor Green
Write-Host ""

# Build and push React image
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Building React Docker Image" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
docker build -t marketfy-react:latest -f "$baseDir\marketfy-infra\docker\react\Dockerfile" "$baseDir\marketfy-react"
if ($LASTEXITCODE -ne 0) { Write-Host "❌ Failed to build React image" -ForegroundColor Red; exit 1 }

docker tag marketfy-react:latest "$reactRepo:latest"
docker push "$reactRepo:latest"
if ($LASTEXITCODE -ne 0) { Write-Host "❌ Failed to push React image" -ForegroundColor Red; exit 1 }
Write-Host "✅ React image pushed successfully" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Green
Write-Host "✅ All images built and pushed successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "You can now run: terraform apply" -ForegroundColor Cyan
