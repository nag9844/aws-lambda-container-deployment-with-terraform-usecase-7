#!/bin/bash

# Script to update Lambda function with container image
# Usage: ./scripts/update-lambda-image.sh [environment] [ecr-uri]

set -e

# Configuration
ENVIRONMENT=${1:-dev}
ECR_URI=${2}
PROJECT_NAME="hello-world-lambda"
AWS_REGION=${AWS_REGION:-ap-south-1}

# Validate inputs
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    echo "Invalid environment. Use: dev, staging, or prod"
    exit 1
fi

if [[ -z "$ECR_URI" ]]; then
    echo "ECR URI is required"
    echo "Usage: $0 <environment> <ecr-uri>"
    exit 1
fi

LAMBDA_FUNCTION_NAME="${PROJECT_NAME}-${ENVIRONMENT}-hello-world"

echo "Updating Lambda function to use container image..."
echo "Function: $LAMBDA_FUNCTION_NAME"
echo "Image: $ECR_URI:latest"

# Update Lambda function to use container image
aws lambda update-function-configuration \
    --function-name "$LAMBDA_FUNCTION_NAME" \
    --package-type Image \
    --region "$AWS_REGION"

# Wait for the configuration update to complete
echo "Waiting for configuration update..."
aws lambda wait function-updated \
    --function-name "$LAMBDA_FUNCTION_NAME" \
    --region "$AWS_REGION"

# Update the function code with the container image
echo "Updating function code with container image..."
aws lambda update-function-code \
    --function-name "$LAMBDA_FUNCTION_NAME" \
    --image-uri "$ECR_URI:latest" \
    --region "$AWS_REGION"

# Wait for the code update to complete
echo "Waiting for code update..."
aws lambda wait function-updated \
    --function-name "$LAMBDA_FUNCTION_NAME" \
    --region "$AWS_REGION"

echo "Lambda function updated successfully!"

# Test the function
echo "Testing the updated function..."
RESPONSE=$(aws lambda invoke \
    --function-name "$LAMBDA_FUNCTION_NAME" \
    --payload '{}' \
    --cli-binary-format raw-in-base64-out \
    response.json \
    --region "$AWS_REGION")

echo "Lambda Response:"
cat response.json
echo ""

# Cleanup
rm -f response.json

echo "🎉 Lambda function update completed!"