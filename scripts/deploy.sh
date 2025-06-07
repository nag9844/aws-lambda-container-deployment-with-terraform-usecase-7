#!/bin/bash

# Deployment script for the Hello World Lambda application
# Usage: ./scripts/deploy.sh [environment]

set -e

# Configuration
ENVIRONMENT=${1:-dev}
PROJECT_NAME="hello-world-lambda"
AWS_REGION=${AWS_REGION:-ap-south-1}

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    echo "Invalid environment. Use: dev, staging, or prod"
    exit 1
fi

echo "Deploying $PROJECT_NAME to $ENVIRONMENT environment..."

# Check if AWS CLI is configured
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "AWS CLI not configured. Please run 'aws configure' first."
    exit 1
fi

# Check if required secrets are set
if [[ -z "$TF_STATE_BUCKET" ]]; then
    echo "Required environment variables not set:"
    echo "   TF_STATE_BUCKET"
    exit 1
fi

# Initialize Terraform
echo "🔧 Initializing Terraform..."
cd terraform
terraform init \
    -backend-config="bucket=$TF_STATE_BUCKET" \
    -backend-config="key=hello-world-lambda/$ENVIRONMENT/terraform.tfstate" \
    -backend-config="region=$AWS_REGION" 

# Plan Terraform changes
echo "Planning Terraform changes..."
terraform plan \
    -var-file="environments/$ENVIRONMENT/terraform.tfvars" \
    -out="tfplan-$ENVIRONMENT"

# Ask for confirmation
read -p "Do you want to apply these changes? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    exit 1
fi

# Apply Terraform changes
echo "Applying Terraform changes..."
terraform apply "tfplan-$ENVIRONMENT"

# Get outputs
echo "Getting deployment outputs..."
ECR_URI=$(terraform output -raw ecr_repository_uri)
API_URL=$(terraform output -raw api_gateway_url)
LAMBDA_NAME=$(terraform output -raw lambda_function_name)

echo "Infrastructure deployed successfully!"
echo ""
echo "Deployment Details:"
echo "Environment: $ENVIRONMENT"
echo "ECR Repository: $ECR_URI"
echo "API Gateway URL: $API_URL"
echo "Lambda Function: $LAMBDA_NAME"

cd ..

# Build and push Docker image
echo "Building and pushing Docker image..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_URI

docker build -t $PROJECT_NAME .
docker tag $PROJECT_NAME:latest $ECR_URI:latest
docker push $ECR_URI:latest

# Update Lambda function
echo "⚡ Updating Lambda function..."
aws lambda update-function-code \
    --function-name $LAMBDA_NAME \
    --image-uri $ECR_URI:latest \
    --region $AWS_REGION

# Wait for update to complete
echo "Waiting for Lambda update to complete..."
aws lambda wait function-updated \
    --function-name $LAMBDA_NAME \
    --region $AWS_REGION

# Test the deployment
echo "Testing deployment..."
RESPONSE=$(aws lambda invoke \
    --function-name $LAMBDA_NAME \
    --payload '{}' \
    --cli-binary-format raw-in-base64-out \
    response.json)

if grep -q "Hello World" response.json; then
    echo "Lambda function test passed!"
else
    echo "Lambda function test failed!"
    cat response.json
    exit 1
fi

# Test API Gateway
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$API_URL")
if [ "$HTTP_STATUS" -eq 200 ]; then
    echo "API Gateway test passed!"
else
    echo "API Gateway test failed with status: $HTTP_STATUS"
fi

echo ""
echo "Deployment completed successfully!"
echo "Your application is available at: $API_URL"
echo ""
echo "Monitoring:"
echo "- CloudWatch Logs: https://console.aws.amazon.com/cloudwatch/home?region=$AWS_REGION#logsV2:log-groups/log-group/%2Faws%2Flambda%2F$LAMBDA_NAME"
echo "- X-Ray Traces: https://console.aws.amazon.com/xray/home?region=$AWS_REGION#/service-map"
echo "- CloudWatch Dashboard: Available in AWS Console"

# Cleanup temporary files
rm -f response.json tfplan-$ENVIRONMENT