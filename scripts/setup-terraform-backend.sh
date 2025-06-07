#!/bin/bash

# Script to set up Terraform backend resources (S3 bucket only)
# This should be run once before using Terraform

set -e

# Configuration
PROJECT_NAME="hello-world-lambda"
AWS_REGION="ap-south-1"
ACTION=${1:-create}
EXISTING_BUCKET=${2:-""}

echo "Setting up Terraform backend resources..."
echo "Project: $PROJECT_NAME"
echo "Region: $AWS_REGION"
echo "Action: $ACTION"

if [ "$ACTION" = "use-existing" ]; then
    if [ -z "$EXISTING_BUCKET" ]; then
        echo "Please provide existing bucket name: ./setup-terraform-backend.sh use-existing <bucket-name>"
        exit 1
    fi
    
    BUCKET_NAME="$EXISTING_BUCKET"
    echo "Using existing S3 Bucket: $BUCKET_NAME"
    
    # Check if bucket exists and is accessible
    if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
        echo "Bucket exists and is accessible"
    else
        echo "Bucket does not exist or is not accessible"
        exit 1
    fi
    
    # Enable versioning (if not already enabled)
    echo "Enabling S3 bucket versioning..."
    aws s3api put-bucket-versioning \
        --bucket "$BUCKET_NAME" \
        --versioning-configuration Status=Enabled
    
    # Enable encryption (if not already enabled)
    echo "Enabling S3 bucket encryption..."
    aws s3api put-bucket-encryption \
        --bucket "$BUCKET_NAME" \
        --server-side-encryption-configuration '{
            "Rules": [
                {
                    "ApplyServerSideEncryptionByDefault": {
                        "SSEAlgorithm": "AES256"
                    }
                }
            ]
        }' || echo "Encryption may already be configured"
    
    # Block public access
    echo "Blocking public access to S3 bucket..."
    aws s3api put-public-access-block \
        --bucket "$BUCKET_NAME" \
        --public-access-block-configuration \
        BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true || echo "Public access block may already be configured"

elif [ "$ACTION" = "create" ]; then
    BUCKET_NAME="${PROJECT_NAME}-terraform-state-$(date +%s)"
    echo "Creating new S3 Bucket: $BUCKET_NAME"
    
    # Create S3 bucket for Terraform state
    echo "Creating S3 bucket..."
    aws s3api create-bucket \
        --bucket "$BUCKET_NAME" \
        --region "$AWS_REGION" \
        --create-bucket-configuration LocationConstraint="$AWS_REGION"

    # Enable versioning on the bucket
    echo "Enabling S3 bucket versioning..."
    aws s3api put-bucket-versioning \
        --bucket "$BUCKET_NAME" \
        --versioning-configuration Status=Enabled

    # Enable encryption on the bucket
    echo "Enabling S3 bucket encryption..."
    aws s3api put-bucket-encryption \
        --bucket "$BUCKET_NAME" \
        --server-side-encryption-configuration '{
            "Rules": [
                {
                    "ApplyServerSideEncryptionByDefault": {
                        "SSEAlgorithm": "AES256"
                    }
                }
            ]
        }'

    # Block public access
    echo "Blocking public access to S3 bucket..."
    aws s3api put-public-access-block \
        --bucket "$BUCKET_NAME" \
        --public-access-block-configuration \
        BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

else
    echo "Invalid action. Use: create or use-existing"
    echo "Usage:"
    echo "  ./setup-terraform-backend.sh create"
    echo "  ./setup-terraform-backend.sh use-existing <bucket-name>"
    exit 1
fi

echo "Terraform backend resources configured successfully!"
echo ""
echo "Add this to your GitHub Secrets:"
echo "TF_STATE_BUCKET: $BUCKET_NAME"
echo ""
echo "Backend configuration for Terraform:"
echo "terraform {"
echo "  backend \"s3\" {"
echo "    bucket         = \"$BUCKET_NAME\""
echo "    key            = \"hello-world-lambda/\${var.environment}/terraform.tfstate\""
echo "    region         = \"$AWS_REGION\""
echo "    encrypt        = true"
echo "  }"
echo "}"
echo ""
echo "Bucket Configuration:"
aws s3api get-bucket-versioning --bucket "$BUCKET_NAME"
aws s3api get-bucket-encryption --bucket "$BUCKET_NAME" || echo "No encryption configuration found"