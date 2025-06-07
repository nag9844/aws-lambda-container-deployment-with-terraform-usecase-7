# Development Environment Configuration

terraform {
  required_version = ">= 1.12.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket       = "usecases-terraform-state-bucket"
    key          = "usecase7/dev/statefile.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "dev"
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  }
}

# Local variables
locals {
  environment = "dev"
  
  # Default ECR image URI for initial deployment
  default_image_uri = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.project_name}-${local.environment}:latest"
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"
  project_name       = var.project_name
  environment        = local.environment
  vpc_cidr          = var.vpc_cidr
  az_count          = var.az_count
  enable_nat_gateway = false  # Disabled for dev to save costs
  enable_flow_logs   = false  # Disabled for dev to save costs
}

# ECR Module
module "ecr" {
  source = "../../modules/ecr"
  project_name          = var.project_name
  environment           = local.environment
  image_tag_mutability  = "MUTABLE"
  scan_on_push         = true
  max_image_count      = 5   # Lower limit for dev
  untagged_image_days  = 3   # Shorter retention for dev
}

# Lambda Module
module "lambda" {
  source = "../../modules/lambda"

  project_name = var.project_name
  environment  = local.environment
  image_uri    = var.lambda_image_uri != "" ? var.lambda_image_uri : local.default_image_uri
  timeout      = 30
  memory_size  = 256

  environment_variables = {
    ENVIRONMENT = local.environment
    LOG_LEVEL   = "DEBUG"
  }

  enable_function_url    = true
  function_url_auth_type = "NONE"
  function_url_cors = {
    allow_credentials = false
    allow_headers     = ["content-type", "x-amz-date", "authorization", "x-api-key"]
    allow_methods     = ["*"]
    allow_origins     = ["*"]
    expose_headers    = ["date", "keep-alive"]
    max_age          = 86400
  }

  log_retention_days = 7  # Shorter retention for dev

  depends_on = [module.ecr]
}

# API Gateway Module
module "api_gateway" {
  source = "../../modules/api-gateway"

  project_name      = var.project_name
  environment       = local.environment
  lambda_invoke_arn = module.lambda.function_invoke_arn
  stage_name        = "dev"
  
  enable_access_logs = true
  log_retention_days = 7  # Shorter retention for dev
  enable_metrics     = true
  logging_level      = "INFO"
}

# Monitoring Module
module "monitoring" {
  source = "../../modules/monitoring"

  project_name         = var.project_name
  environment          = local.environment
  aws_region          = var.aws_region
  lambda_function_name = module.lambda.function_name
  api_gateway_name     = "${var.project_name}-api-${local.environment}"
  
  # More lenient thresholds for dev
  lambda_error_threshold    = 10
  lambda_duration_threshold = 15000
  api_4xx_threshold        = 20
  api_5xx_threshold        = 10
  
  create_sns_topic = false  # Disabled for dev
}