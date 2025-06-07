#!/bin/bash

# Script to fix Lambda functions that need to be converted to container images
# Usage: ./scripts/fix-lambda-package-type.sh [environment]

set -e

# Configuration
ENVIRONMENT=${1:-prod}
PROJECT_NAME="hello-world-lambda"
AWS_REGION=${AWS_REGION:-ap-south-1}

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    echo "❌ Invalid environment. Use: dev, staging, or prod"
    exit 1
fi

FUNCTION_NAME="${PROJECT_NAME}-${ENVIRONMENT}-hello-world"

echo "🔧 Fixing Lambda function package type for: $FUNCTION_NAME"
echo "Environment: $ENVIRONMENT"
echo "Region: $AWS_REGION"

# Check if AWS CLI is configured
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ AWS CLI not configured. Please run 'aws configure' first."
    exit 1
fi

# Check if function exists
if ! aws lambda get-function --function-name "$FUNCTION_NAME" --region "$AWS_REGION" >/dev/null 2>&1; then
    echo "❌ Function $FUNCTION_NAME does not exist."
    echo "💡 Deploy infrastructure first using Terraform."
    exit 1
fi

# Get current function configuration
echo "📋 Getting current function configuration..."
CURRENT_CONFIG=$(aws lambda get-function-configuration --function-name "$FUNCTION_NAME" --region "$AWS_REGION")
CURRENT_PACKAGE_TYPE=$(echo "$CURRENT_CONFIG" | jq -r '.PackageType // "Zip"')
CURRENT_ROLE=$(echo "$CURRENT_CONFIG" | jq -r '.Role')
CURRENT_VPC_CONFIG=$(echo "$CURRENT_CONFIG" | jq -r '.VpcConfig // {}')
CURRENT_ENVIRONMENT=$(echo "$CURRENT_CONFIG" | jq -r '.Environment // {}')

echo "Current package type: $CURRENT_PACKAGE_TYPE"

if [ "$CURRENT_PACKAGE_TYPE" = "Image" ]; then
    echo "✅ Function already uses container images. No changes needed."
    exit 0
fi

echo "⚠️ Function uses Zip package type and needs to be recreated."
echo "🔄 This will require destroying and recreating the function."

# Get ECR repository URI
ECR_REPO_NAME="${PROJECT_NAME}-hello-world"
if ! aws ecr describe-repositories --repository-names "$ECR_REPO_NAME" --region "$AWS_REGION" >/dev/null 2>&1; then
    echo "❌ ECR repository $ECR_REPO_NAME does not exist."
    echo "💡 Create it first or run the build workflow."
    exit 1
fi

ECR_URI=$(aws ecr describe-repositories --repository-names "$ECR_REPO_NAME" --region "$AWS_REGION" --query 'repositories[0].repositoryUri' --output text)
echo "🐳 ECR URI: $ECR_URI"

# Confirm with user
echo ""
echo "⚠️  WARNING: This will delete and recreate the Lambda function!"
echo "All current function code and configuration will be replaced."
echo ""
read -p "Do you want to continue? (type 'yes' to confirm): " -r
if [[ ! $REPLY =~ ^yes$ ]]; then
    echo "❌ Operation cancelled."
    exit 1
fi

# Delete the existing function
echo "🗑️  Deleting existing function..."
aws lambda delete-function --function-name "$FUNCTION_NAME" --region "$AWS_REGION"

# Wait a moment for deletion to complete
echo "⏳ Waiting for deletion to complete..."
sleep 10

# Recreate function with Image package type
echo "🔄 Creating new function with container image..."

# Extract VPC configuration if it exists
VPC_CONFIG=""
if [ "$CURRENT_VPC_CONFIG" != "null" ] && [ "$CURRENT_VPC_CONFIG" != "{}" ]; then
    SUBNET_IDS=$(echo "$CURRENT_VPC_CONFIG" | jq -r '.SubnetIds[]' | tr '\n' ',' | sed 's/,$//')
    SECURITY_GROUP_IDS=$(echo "$CURRENT_VPC_CONFIG" | jq -r '.SecurityGroupIds[]' | tr '\n' ',' | sed 's/,$//')
    
    if [ ! -z "$SUBNET_IDS" ] && [ ! -z "$SECURITY_GROUP_IDS" ]; then
        VPC_CONFIG="--vpc-config SubnetIds=$SUBNET_IDS,SecurityGroupIds=$SECURITY_GROUP_IDS"
    fi
fi

# Extract environment variables if they exist
ENV_VARS=""
if [ "$CURRENT_ENVIRONMENT" != "null" ] && [ "$CURRENT_ENVIRONMENT" != "{}" ]; then
    ENV_VARS_JSON=$(echo "$CURRENT_ENVIRONMENT" | jq -r '.Variables // {}')
    if [ "$ENV_VARS_JSON" != "{}" ]; then
        ENV_VARS="--environment Variables={ENVIRONMENT=$ENVIRONMENT,PROJECT_NAME=$PROJECT_NAME}"
    fi
fi

# Create the new function
aws lambda create-function \
    --function-name "$FUNCTION_NAME" \
    --role "$CURRENT_ROLE" \
    --package-type Image \
    --code ImageUri="$ECR_URI:latest" \
    --timeout 30 \
    --memory-size 256 \
    --tracing-config Mode=Active \
    --region "$AWS_REGION" \
    $VPC_CONFIG \
    $ENV_VARS

# Wait for function to be active
echo "⏳ Waiting for function to be active..."
aws lambda wait function-active --function-name "$FUNCTION_NAME" --region "$AWS_REGION"

echo "✅ Function recreated successfully with container image support!"

# Test the function
echo "🧪 Testing the recreated function..."
RESPONSE=$(aws lambda invoke \
    --function-name "$FUNCTION_NAME" \
    --payload '{}' \
    --cli-binary-format raw-in-base64-out \
    response.json \
    --region "$AWS_REGION")

echo "Lambda Response:"
cat response.json
echo ""

# Cleanup
rm -f response.json

echo "🎉 Lambda function package type fix completed!"
echo ""
echo "💡 Next steps:"
echo "1. Run your CI/CD pipeline to deploy the latest container image"
echo "2. Update your Terraform state if needed: terraform refresh"