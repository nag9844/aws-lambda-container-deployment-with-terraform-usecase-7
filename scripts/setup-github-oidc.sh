#!/bin/bash

# GitHub OIDC Setup Script for AWS
# This script helps set up GitHub OIDC integration with AWS

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed. Please install it first."
    exit 1
fi

# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
print_status "AWS Account ID: ${AWS_ACCOUNT_ID}"

# Get GitHub repository information
read -p "Enter your GitHub username: " GITHUB_USERNAME
read -p "Enter your GitHub repository name: " GITHUB_REPO
read -p "Enter your Terraform state S3 bucket name: " TERRAFORM_STATE_BUCKET

print_status "Setting up GitHub OIDC for ${GITHUB_USERNAME}/${GITHUB_REPO}"

# Create OIDC Identity Provider
print_status "Creating OIDC Identity Provider..."
OIDC_PROVIDER_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"

if aws iam get-open-id-connect-provider --open-id-connect-provider-arn "${OIDC_PROVIDER_ARN}" >/dev/null 2>&1; then
    print_warning "OIDC provider already exists"
else
    aws iam create-open-id-connect-provider \
        --url https://token.actions.githubusercontent.com \
        --client-id-list sts.amazonaws.com \
        --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
        --thumbprint-list 1c58a3a8518e8759bf075b76b750d4f2df264fcd
    print_success "OIDC provider created"
fi

# Create trust policy
cat > /tmp/github-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "${OIDC_PROVIDER_ARN}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:${GITHUB_USERNAME}/${GITHUB_REPO}:*"
        }
      }
    }
  ]
}
EOF

# Create IAM role
ROLE_NAME="GitHubActionsRole-${GITHUB_REPO}"
print_status "Creating IAM role: ${ROLE_NAME}"

if aws iam get-role --role-name "${ROLE_NAME}" >/dev/null 2>&1; then
    print_warning "Role already exists, updating trust policy"
    aws iam update-assume-role-policy \
        --role-name "${ROLE_NAME}" \
        --policy-document file:///tmp/github-trust-policy.json
else
    aws iam create-role \
        --role-name "${ROLE_NAME}" \
        --assume-role-policy-document file:///tmp/github-trust-policy.json \
        --description "Role for GitHub Actions OIDC for ${GITHUB_REPO}"
    print_success "IAM role created"
fi

# Attach PowerUser policy
print_status "Attaching PowerUserAccess policy..."
aws iam attach-role-policy \
    --role-name "${ROLE_NAME}" \
    --policy-arn arn:aws:iam::aws:policy/PowerUserAccess

# Create custom policy for Terraform state
cat > /tmp/terraform-state-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket",
        "s3:GetBucketVersioning"
      ],
      "Resource": [
        "arn:aws:s3:::${TERRAFORM_STATE_BUCKET}",
        "arn:aws:s3:::${TERRAFORM_STATE_BUCKET}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:PassRole"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "iam:PassedToService": [
            "lambda.amazonaws.com",
            "apigateway.amazonaws.com",
            "logs.amazonaws.com"
          ]
        }
      }
    }
  ]
}
EOF

print_status "Creating Terraform state policy..."
aws iam put-role-policy \
    --role-name "${ROLE_NAME}" \
    --policy-name "TerraformStatePolicy" \
    --policy-document file:///tmp/terraform-state-policy.json

# Create S3 bucket if it doesn't exist
print_status "Checking S3 bucket: ${TERRAFORM_STATE_BUCKET}"
if aws s3api head-bucket --bucket "${TERRAFORM_STATE_BUCKET}" 2>/dev/null; then
    print_warning "S3 bucket already exists"
else
    print_status "Creating S3 bucket..."
    aws s3 mb "s3://${TERRAFORM_STATE_BUCKET}"
    
    # Enable versioning
    aws s3api put-bucket-versioning \
        --bucket "${TERRAFORM_STATE_BUCKET}" \
        --versioning-configuration Status=Enabled
    
    # Enable server-side encryption
    aws s3api put-bucket-encryption \
        --bucket "${TERRAFORM_STATE_BUCKET}" \
        --server-side-encryption-configuration '{
            "Rules": [
                {
                    "ApplyServerSideEncryptionByDefault": {
                        "SSEAlgorithm": "AES256"
                    }
                }
            ]
        }'
    
    print_success "S3 bucket created and configured"
fi

# Clean up temporary files
rm -f /tmp/github-trust-policy.json /tmp/terraform-state-policy.json

# Output configuration for GitHub
ROLE_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ROLE_NAME}"

print_success "Setup completed successfully!"
echo
print_status "GitHub Repository Configuration:"
echo "Add the following variables to your GitHub repository:"
echo
echo "Repository Variables (Settings > Secrets and Variables > Actions > Variables):"
echo "AWS_ROLE_ARN: ${ROLE_ARN}"
echo "TERRAFORM_STATE_BUCKET: ${TERRAFORM_STATE_BUCKET}"
echo
echo "Environment Variables (for each environment: dev, staging, prod):"
echo "AWS_ROLE_ARN: ${ROLE_ARN}"
echo "TERRAFORM_STATE_BUCKET: ${TERRAFORM_STATE_BUCKET}"
echo
print_status "You can now run GitHub Actions workflows!"