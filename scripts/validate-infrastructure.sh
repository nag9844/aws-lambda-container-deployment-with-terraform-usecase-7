#!/bin/bash

# Script to validate Terraform infrastructure
# Usage: ./scripts/validate-infrastructure.sh <environment>

set -e

ENVIRONMENT=${1:-dev}

echo "🔍 Validating Terraform infrastructure for environment: ${ENVIRONMENT}"

cd terraform

# Format check
echo "📝 Checking Terraform formatting..."
terraform fmt -check -recursive

# Initialize Terraform
echo "📋 Initializing Terraform..."
terraform init -backend-config=backend-configs/${ENVIRONMENT}.hcl

# Validate configuration
echo "✅ Validating Terraform configuration..."
terraform validate

# Plan infrastructure
echo "📋 Planning infrastructure changes..."
terraform plan -var-file=environments/${ENVIRONMENT}/terraform.tfvars

echo "✅ Validation complete for environment: ${ENVIRONMENT}"