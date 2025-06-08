#!/bin/bash

# Deployment Script for AWS Lambda Container DevOps Solution
# This script automates the 3-step deployment process

set -e  # Exit on any error

# Configuration
PROJECT_NAME="hello-world-lambda"
ENVIRONMENT="dev"
AWS_REGION="ap-south-1"
IMAGE_TAG="latest"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    if ! command_exists aws; then
        print_error "AWS CLI is not installed"
        exit 1
    fi
    
    if ! command_exists terraform; then
        print_error "Terraform is not installed"
        exit 1
    fi
    
    if ! command_exists docker; then
        print_error "Docker is not installed"
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity >/dev/null 2>&1; then
        print_error "AWS credentials not configured"
        exit 1
    fi
    
    print_success "All prerequisites met"
}

# Step 1: Deploy ECR Repository
deploy_ecr() {
    print_status "Step 1: Deploying ECR Repository..."
    
    cd terraform/standalone/ecr
    
    # Initialize Terraform
    terraform init
    
    # Plan and Apply
    terraform plan -var="environment=${ENVIRONMENT}" -var="aws_region=${AWS_REGION}"
    terraform apply -auto-approve -var="environment=${ENVIRONMENT}" -var="aws_region=${AWS_REGION}"
    
    # Get ECR URI
    ECR_URI=$(terraform output -raw ecr_repository_uri)
    print_success "ECR Repository created: ${ECR_URI}"
    
    cd ../../..
}

# Step 2: Build and Push Docker Image
build_and_push_image() {
    print_status "Step 2: Building and pushing Docker image..."
    
    # Get ECR URI from Terraform output
    cd terraform/standalone/ecr
    ECR_URI=$(terraform output -raw ecr_repository_uri)
    cd ../../..
    
    # Login to ECR
    print_status "Logging into ECR..."
    aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_URI}
    
    # Build Docker image
    print_status "Building Docker image..."
    cd src
    docker build -t ${PROJECT_NAME}-${ENVIRONMENT} .
    
    # Tag for ECR
    print_status "Tagging image for ECR..."
    docker tag ${PROJECT_NAME}-${ENVIRONMENT}:latest ${ECR_URI}:${IMAGE_TAG}
    
    # Push to ECR
    print_status "Pushing image to ECR..."
    docker push ${ECR_URI}:${IMAGE_TAG}
    
    print_success "Docker image pushed successfully: ${ECR_URI}:${IMAGE_TAG}"
    
    cd ..
}

# Step 3: Deploy Infrastructure
deploy_infrastructure() {
    print_status "Step 3: Deploying infrastructure..."
    
    cd terraform/environments/${ENVIRONMENT}
    
    # Initialize Terraform
    terraform init
    
    # Plan and Apply
    terraform plan -var="aws_region=${AWS_REGION}" -var="image_tag=${IMAGE_TAG}"
    terraform apply -auto-approve -var="aws_region=${AWS_REGION}" -var="image_tag=${IMAGE_TAG}"
    
    # Get outputs
    API_URL=$(terraform output -raw api_gateway_url)
    FUNCTION_URL=$(terraform output -raw lambda_function_url)
    
    print_success "Infrastructure deployed successfully!"
    print_success "API Gateway URL: ${API_URL}"
    print_success "Lambda Function URL: ${FUNCTION_URL}"
    
    cd ../../..
}

# Test deployment
test_deployment() {
    print_status "Testing deployment..."
    
    cd terraform/environments/${ENVIRONMENT}
    API_URL=$(terraform output -raw api_gateway_url)
    FUNCTION_URL=$(terraform output -raw lambda_function_url)
    cd ../../..
    
    # Test API Gateway
    print_status "Testing API Gateway..."
    if curl -f -s "${API_URL}" >/dev/null; then
        print_success "API Gateway is responding"
    else
        print_warning "API Gateway test failed"
    fi
    
    # Test Lambda Function URL
    print_status "Testing Lambda Function URL..."
    if curl -f -s "${FUNCTION_URL}" >/dev/null; then
        print_success "Lambda Function URL is responding"
    else
        print_warning "Lambda Function URL test failed"
    fi
}

# Main execution
main() {
    print_status "Starting AWS Lambda Container DevOps Deployment"
    print_status "Environment: ${ENVIRONMENT}"
    print_status "Region: ${AWS_REGION}"
    print_status "Image Tag: ${IMAGE_TAG}"
    
    check_prerequisites
    
    case "${1:-all}" in
        "ecr")
            deploy_ecr
            ;;
        "build")
            build_and_push_image
            ;;
        "infra")
            deploy_infrastructure
            ;;
        "test")
            test_deployment
            ;;
        "all")
            deploy_ecr
            build_and_push_image
            deploy_infrastructure
            test_deployment
            ;;
        *)
            print_error "Usage: $0 [ecr|build|infra|test|all]"
            exit 1
            ;;
    esac
    
    print_success "Deployment completed successfully!"
}

# Run main function with all arguments
main "$@"