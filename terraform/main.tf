terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# VPC Module
module "vpc" {
  source = "./modules/vpc"
  
  environment          = var.environment
  project_name         = var.project_name
  vpc_cidr            = var.vpc_cidr
  availability_zones  = var.availability_zones
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

# ECR Module
module "ecr" {
  source = "./modules/ecr"
  
  environment  = var.environment
  project_name = var.project_name
  repository_name = "${var.project_name}-hello-world"
}

# Lambda Module
module "lambda" {
  source = "./modules/lambda"
  
  environment     = var.environment
  project_name    = var.project_name
  ecr_repository_uri = module.ecr.repository_uri
  vpc_id          = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  lambda_security_group_id = module.vpc.lambda_security_group_id
  
  depends_on = [module.ecr]
}

# API Gateway Module
module "api_gateway" {
  source = "./modules/api_gateway"
  
  environment         = var.environment
  project_name        = var.project_name
  lambda_function_arn = module.lambda.function_arn
  lambda_function_name = module.lambda.function_name
  lambda_invoke_arn   = module.lambda.invoke_arn
}

# Monitoring Module
module "monitoring" {
  source = "./modules/monitoring"
  
  environment         = var.environment
  project_name        = var.project_name
  lambda_function_name = module.lambda.function_name
  api_gateway_id      = module.api_gateway.api_id
}