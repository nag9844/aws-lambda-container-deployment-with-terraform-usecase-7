#!/bin/bash

# Script to set up Terraform backend resources
# Usage: ./scripts/setup-backend.sh <environment>

set -e

ENVIRONMENT=${1:-dev}
PROJECT_NAME="hello-world-lambda"
REGION="ap-south-1"

BUCKET_NAME="${PROJECT_NAME}-terraform-state-${ENVIRONMENT}"
DYNAMODB_TABLE="${PROJECT_NAME}-terraform-locks-${ENVIRONMENT}"

echo "Setting up Terraform backend for environment: ${ENVIRONMENT}"

# Create S3 bucket for Terraform state
echo "Creating S3 bucket: ${BUCKET_NAME}"
aws s3api create-bucket \
    --bucket ${BUCKET_NAME} \
    --region ${REGION} \
    --create-bucket-configuration LocationConstraint=${REGION} || true

# Enable versioning on S3 bucket
echo "Enabling versioning on S3 bucket"
aws s3api put-bucket-versioning \
    --bucket ${BUCKET_NAME} \
    --versioning-configuration Status=Enabled

# Enable server-side encryption
echo "Enabling server-side encryption"
aws s3api put-bucket-encryption \
    --bucket ${BUCKET_NAME} \
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
echo "Blocking public access to S3 bucket"
aws s3api put-public-access-block \
    --bucket ${BUCKET_NAME} \
    --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# Create DynamoDB table for state locking
echo "Creating DynamoDB table: ${DYNAMODB_TABLE}"
aws dynamodb create-table \
    --table-name ${DYNAMODB_TABLE} \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --region ${REGION} || true

echo "Backend setup complete for environment: ${ENVIRONMENT}"
echo "S3 Bucket: ${BUCKET_NAME}"
echo "DynamoDB Table: ${DYNAMODB_TABLE}"