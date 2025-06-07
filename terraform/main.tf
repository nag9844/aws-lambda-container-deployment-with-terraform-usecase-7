terraform {
  required_version = ">= 1.12.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }

  backend "s3" {
    bucket        = "usecases-terraform-state-bucket"
    key           = "usecase7/statefile.tfstate"
    region        = "ap-south-1"
    encrypt       = true
    use_lockfile  = true
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
  
  environment  = var.environment
  project_name = var.project_name
  vpc_cidr     = var.vpc_cidr
  
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

# ECR Module
module "ecr" {
  source = "./modules/ecr"
  
  environment     = var.environment
  project_name    = var.project_name
  repository_name = "${var.project_name}-${var.environment}"
}

# Lambda Module
module "lambda" {
  source = "./modules/lambda"
  
  environment        = var.environment
  project_name       = var.project_name
  ecr_repository_url = module.ecr.repository_url
  vpc_id             = module.vpc.vpc_id
  vpc_cidr           = var.vpc_cidr
  private_subnet_ids = module.vpc.private_subnet_ids
  
  depends_on = [module.ecr]
}

# API Gateway Module
module "api_gateway" {
  source = "./modules/api-gateway"
  
  environment          = var.environment
  project_name         = var.project_name
  lambda_function_name = module.lambda.function_name
  lambda_invoke_arn    = module.lambda.invoke_arn
}

# CloudWatch Module
module "cloudwatch" {
  source = "./modules/cloudwatch"
  environment          = var.environment
  project_name         = var.project_name
  lambda_function_name = module.lambda.function_name
}