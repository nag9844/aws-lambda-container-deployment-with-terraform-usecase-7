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
    key          = "usecase7/statefile.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# Local values for resource naming
locals {
  name_prefix = "${var.project_name}-${var.environment}"
  
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"
  
  name_prefix         = local.name_prefix
  environment         = var.environment
  project_name        = var.project_name
  cidr_block         = var.vpc_cidr
  availability_zones = var.availability_zones
  
  tags = local.common_tags
}

# ECR Module
module "ecr" {
  source = "./modules/ecr"
  
  name_prefix      = local.name_prefix
  repository_name  = "${local.name_prefix}-app"
  environment      = var.environment
  project_name     = var.project_name
  
  tags = local.common_tags
}

# IAM Module
module "iam" {
  source = "./modules/iam"
  
  name_prefix   = local.name_prefix
  environment   = var.environment
  project_name  = var.project_name
  
  tags = local.common_tags
}

# Lambda Module
module "lambda" {
  source = "./modules/lambda"
  
  name_prefix     = local.name_prefix
  environment     = var.environment
  project_name    = var.project_name
  ecr_repository  = module.ecr.repository_url
  execution_role  = module.iam.lambda_execution_role_arn
  memory_size     = var.lambda_memory_size
  timeout         = var.lambda_timeout
  
  vpc_config = {
    subnet_ids         = module.vpc.private_subnet_ids
    security_group_ids = [module.vpc.lambda_security_group_id]
  }
  
  environment_variables = {
    ENVIRONMENT = var.environment
    NODE_ENV    = "production"
  }
  
  tags = local.common_tags
}

# API Gateway Module
module "api_gateway" {
  source = "./modules/api_gateway"
  
  name_prefix          = local.name_prefix
  environment          = var.environment
  project_name         = var.project_name
  lambda_function_arn  = module.lambda.function_arn
  lambda_function_name = module.lambda.function_name
  
  tags = local.common_tags
}

# CloudWatch Module
module "cloudwatch" {
  source = "./modules/cloudwatch"
  
  name_prefix          = local.name_prefix
  environment          = var.environment
  project_name         = var.project_name
  lambda_function_name = module.lambda.function_name
  api_gateway_name     = module.api_gateway.api_name
  
  tags = local.common_tags
}