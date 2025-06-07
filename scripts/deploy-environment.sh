#!/bin/bash

# Script to deploy infrastructure for a specific environment
# Usage: ./scripts/deploy-environment.sh <environment> <action>

set -e

ENVIRONMENT=${1:-dev}
ACTION=${2:-apply}
PROJECT_NAME="hello-world-lambda"
REGION="ap-south-1"

if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    echo "❌ Invalid environment. Use: dev, staging, or prod"
    exit 1
fi

if [[ ! "$ACTION" =~ ^(plan|apply|destroy)$ ]]; then
    echo "❌ Invalid action. Use: plan, apply, or destroy"
    exit 1
fi

echo "🚀 ${ACTION^} infrastructure for environment: ${ENVIRONMENT}"

cd terraform

# Initialize Terraform
echo "📋 Initializing Terraform..."
terraform init

# Validate configuration
echo "✅ Validating Terraform configuration..."
terraform validate

case $ACTION in
    plan)
        echo "📋 Planning infrastructure changes..."
        terraform plan -var-file=environments/${ENVIRONMENT}/terraform.tfvars
        ;;
    apply)
        echo "📋 Planning infrastructure changes..."
        terraform plan -var-file=environments/${ENVIRONMENT}/terraform.tfvars -out=tfplan.binary
        
        echo "🚀 Applying infrastructure changes..."
        terraform apply -auto-approve tfplan.binary
        
        echo "📊 Infrastructure outputs:"
        terraform output
        ;;
    destroy)
        echo "⚠️  Planning destruction..."
        terraform plan -destroy -var-file=environments/${ENVIRONMENT}/terraform.tfvars
        
        read -p "Are you sure you want to destroy the ${ENVIRONMENT} environment? (yes/no): " confirm
        if [[ $confirm == "yes" ]]; then
            echo "🔥 Destroying infrastructure..."
            terraform destroy -var-file=environments/${ENVIRONMENT}/terraform.tfvars -auto-approve
            echo "✅ Infrastructure destroyed successfully"
        else
            echo "❌ Destruction cancelled"
            exit 1
        fi
        ;;
esac

echo "✅ ${ACTION^} completed successfully for environment: ${ENVIRONMENT}"