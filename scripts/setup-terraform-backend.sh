#!/bin/bash

# Script to set up Terraform backend resources (S3 bucket only)
# This should be run once before using Terraform

set -e

# Configuration
PROJECT_NAME="hello-world-lambda"
AWS_REGION="ap-south-1"
BUCKET_NAME="${PROJECT_NAME}-terraform-state-$(date +%s)"

echo "Setting up Terraform backend resources..."
echo "Project: $PROJECT_NAME"
echo "Region: $AWS_REGION"
echo "S3 Bucket: $BUCKET_NAME"

# Create S3 bucket for Terraform state
echo "Creating S3 bucket..."
aws s3api create-bucket \
    --bucket "$BUCKET_NAME" \
    --region "$AWS_REGION" \
    --create-bucket-configuration LocationConstraint="$AWS_REGION"

# Enable versioning on the bucket (required for lockfile)
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

echo "Terraform backend resources created successfully!"
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
echo "    use_lockfile   = true"
echo "    encrypt        = true"
echo "  }"
echo "}"