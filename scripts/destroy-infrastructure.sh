#!/bin/bash

# Script to safely destroy Terraform infrastructure
# Usage: ./scripts/destroy-infrastructure.sh <environment>

set -e

ENVIRONMENT=${1:-dev}
PROJECT_NAME="hello-world-lambda"
REGION="ap-south-1"

echo "🔥 Destroying infrastructure for environment: ${ENVIRONMENT}"
echo "⚠️  This will permanently delete all resources!"

# Confirm destruction
read -p "Are you sure you want to destroy the ${ENVIRONMENT} environment? (yes/no): " confirm
if [[ $confirm != "yes" ]]; then
    echo "❌ Destruction cancelled"
    exit 1
fi

cd terraform

# Initialize Terraform
echo "📋 Initializing Terraform..."
terraform init -backend-config=backend-configs/${ENVIRONMENT}.hcl

# Plan destruction
echo "📋 Planning destruction..."
terraform plan -destroy -var-file=environments/${ENVIRONMENT}/terraform.tfvars

# Confirm again before destruction
read -p "Proceed with destruction? (yes/no): " final_confirm
if [[ $final_confirm != "yes" ]]; then
    echo "❌ Destruction cancelled"
    exit 1
fi

# Destroy infrastructure
echo "🔥 Destroying infrastructure..."
terraform destroy -var-file=environments/${ENVIRONMENT}/terraform.tfvars -auto-approve

echo "✅ Infrastructure destroyed successfully for environment: ${ENVIRONMENT}"

# Optional: Clean up ECR images manually if needed
echo "🧹 Cleaning up ECR repository..."
ECR_REPO="${PROJECT_NAME}-${ENVIRONMENT}-app"
aws ecr delete-repository \
    --repository-name ${ECR_REPO} \
    --force \
    --region ${REGION} 2>/dev/null || echo "ECR repository already deleted or doesn't exist"

echo "🎉 Cleanup complete!"