#!/bin/bash

# ==================================
# Manual Database Seeding Script
# ==================================

REGION="us-east-1"
CLUSTER="marketfy-cluster"

echo "========================================"
echo "Database Seeding Script"
echo "========================================"
echo ""

# Get terraform directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$(dirname "$SCRIPT_DIR")/terraform"

cd "$TERRAFORM_DIR" || exit 1

# Get ALB DNS
echo "Getting infrastructure info..."
ALB=$(terraform output -raw load_balancer_dns 2>/dev/null)
if [ -z "$ALB" ]; then
    echo "Error: Infrastructure not found. Run 'terraform apply' first."
    exit 1
fi

# Get task definition revision
REVISION=$(aws ecs describe-task-definition --task-definition marketfy-api --region $REGION --query 'taskDefinition.revision' --output text 2>/dev/null)
if [ -z "$REVISION" ]; then
    echo "Error: Task definition not found."
    exit 1
fi

echo "  Task definition: marketfy-api:$REVISION"
echo "  ALB: $ALB"
echo ""

# Run seed task
echo "Starting seed task..."
TASK_ARN=$(aws ecs run-task \
    --cluster $CLUSTER \
    --task-definition marketfy-api:$REVISION \
    --region $REGION \
    --count 1 \
    --launch-type EC2 \
    --overrides '{"containerOverrides":[{"name":"api","command":["sh","-c","cd /app && npx tsx prisma/seed.ts"]}]}' \
    --query 'tasks[0].taskArn' \
    --output text)

if [ -z "$TASK_ARN" ]; then
    echo "Error: Failed to start seed task"
    exit 1
fi

echo "  Task started: $TASK_ARN"
echo ""

# Wait for completion
echo "Waiting for seed to complete (max 60 seconds)..."
sleep 5

MAX_WAIT=60
WAITED=0

while [ $WAITED -lt $MAX_WAIT ]; do
    STATUS=$(aws ecs describe-tasks \
        --cluster $CLUSTER \
        --tasks $TASK_ARN \
        --region $REGION \
        --query 'tasks[0].lastStatus' \
        --output text)

    if [ "$STATUS" = "STOPPED" ]; then
        EXIT_CODE=$(aws ecs describe-tasks \
            --cluster $CLUSTER \
            --tasks $TASK_ARN \
            --region $REGION \
            --query 'tasks[0].containers[0].exitCode' \
            --output text)

        if [ "$EXIT_CODE" = "0" ]; then
            echo "  ✓ Seed task completed successfully!"
            break
        else
            echo "  ✗ Seed task failed (exit code: $EXIT_CODE)"
            exit 1
        fi
    fi

    sleep 5
    WAITED=$((WAITED + 5))
    echo "  Status: $STATUS (${WAITED}s elapsed)"
done

if [ $WAITED -ge $MAX_WAIT ]; then
    echo "  Timeout waiting for seed task"
fi

echo ""

# Verify database has products
echo "Verifying database..."
sleep 2

TOTAL=$(curl -s "http://$ALB/api/products?limit=1" | grep -o '"total":[0-9]*' | cut -d: -f2)

if [ -n "$TOTAL" ] && [ "$TOTAL" -gt 0 ]; then
    echo "  ✓ Database has $TOTAL products"
    echo ""
    echo "========================================"
    echo "✓ Database Seeded Successfully!"
    echo "========================================"
    echo ""
    echo "You can now access:"
    echo "  Angular: http://$ALB/angular/"
    echo "  React:   http://$ALB/react/"
    echo "  API:     http://$ALB/api/"
    echo ""
    echo "Login credentials:"
    echo "  Email:    demo@marketfy.test"
    echo "  Password: password123"
else
    echo "  Warning: Database appears empty"
    echo "  Check logs for errors"
fi

echo ""
exit 0
