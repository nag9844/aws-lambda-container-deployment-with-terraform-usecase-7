# Staging Environment Configuration

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket       = "usecases-terraform-state-bucket"
    key          = "usecase7/staging/statefile.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "staging"
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  }
}

# Local variables
locals {
  environment = "staging"
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Data source to get existing ECR repository (created by ECR workflow)
data "aws_ecr_repository" "main" {
  name = "${var.project_name}-${local.environment}"
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  project_name       = var.project_name
  environment        = local.environment
  vpc_cidr          = var.vpc_cidr
  az_count          = var.az_count
  enable_nat_gateway = var.enable_nat_gateway
  enable_flow_logs   = true
}

# Lambda Module
module "lambda" {
  source = "../../modules/lambda"

  project_name = var.project_name
  environment  = local.environment
  image_uri    = var.lambda_image_uri != "" ? var.lambda_image_uri : "${data.aws_ecr_repository.main.repository_ur}:latest"
  timeout      = 60
  memory_size  = 512

  environment_variables = {
    ENVIRONMENT = local.environment
    LOG_LEVEL   = "INFO"
  }

  # VPC configuration for staging
  vpc_config = var.enable_vpc_config ? {
    subnet_ids         = module.vpc.private_subnet_ids
    security_group_ids = [aws_security_group.lambda[0].id]
  } : null

  log_retention_days = 14
  api_gateway_arn    = module.api_gateway.execution_arn
}

# Security Group for Lambda (if VPC config is enabled)
resource "aws_security_group" "lambda" {
  count = var.enable_vpc_config ? 1 : 0

  name_prefix = "${var.project_name}-lambda-sg-${local.environment}"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-lambda-sg-${local.environment}"
    Environment = local.environment
    Project     = var.project_name
  }
}

# API Gateway Module
module "api_gateway" {
  source = "../../modules/api-gateway"

  project_name      = var.project_name
  environment       = local.environment
  lambda_invoke_arn = module.lambda.function_invoke_arn
  stage_name        = "staging"
  
  enable_access_logs = true
  log_retention_days = 14
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
  
  # Production-like thresholds for staging
  lambda_error_threshold    = 5
  lambda_duration_threshold = 10000
  api_4xx_threshold        = 15
  api_5xx_threshold        = 5
  
  create_sns_topic = var.enable_alerts
  alert_email      = var.alert_email
  alarm_actions    = var.enable_alerts ? [module.monitoring.sns_topic_arn] : []
}