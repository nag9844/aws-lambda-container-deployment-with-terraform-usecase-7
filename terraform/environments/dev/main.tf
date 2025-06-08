# Development Environment Configuration

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
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
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Data source to get existing ECR repository (created by ECR workflow)
data "aws_ecr_repository" "main" {
  name = "${var.project_name}-${local.environment}"
}

# Check if ECR repository has images using external data source
data "external" "ecr_images" {
  program = ["bash", "-c", <<-EOT
    set -e
    REPO_NAME="${var.project_name}-${local.environment}"
    REGION="${var.aws_region}"
    
    # Try to list images and check if any exist
    IMAGE_COUNT=$(aws ecr list-images --repository-name "$REPO_NAME" --region "$REGION" --query 'length(imageIds)' --output text 2>/dev/null || echo "0")
    
    if [ "$IMAGE_COUNT" -gt 0 ]; then
      echo '{"has_images": "true"}'
    else
      echo '{"has_images": "false"}'
    fi
  EOT
  ]
}

# Create a placeholder Lambda function with a simple Python runtime first
# This will be used when no container image is available
resource "aws_lambda_function" "placeholder" {
  count = data.external.ecr_images.result.has_images == "false" ? 1 : 0
  
  function_name = "${var.project_name}-${local.environment}"
  role          = aws_iam_role.lambda_execution.arn
  handler       = "index.handler"
  runtime       = "python3.11"
  timeout       = 30
  memory_size   = 256

  filename         = "placeholder.zip"
  source_code_hash = data.archive_file.placeholder[0].output_base64sha256

  environment {
    variables = {
      ENVIRONMENT = local.environment
      LOG_LEVEL   = "DEBUG"
    }
  }

  tags = {
    Name        = "${var.project_name}-lambda-${local.environment}"
    Environment = local.environment
    Project     = var.project_name
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_cloudwatch_log_group.lambda
  ]

  lifecycle {
    ignore_changes = [
      filename,
      source_code_hash,
      handler,
      runtime,
      package_type,
      image_uri
    ]
  }
}

# Create placeholder zip file for initial deployment
data "archive_file" "placeholder" {
  count = data.external.ecr_images.result.has_images == "false" ? 1 : 0
  
  type        = "zip"
  output_path = "placeholder.zip"
  
  source {
    content = <<EOF
import json

def handler(event, context):
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type'
        },
        'body': json.dumps({
            'message': 'Hello from placeholder Lambda function!',
            'status': 'Container image will be deployed when available',
            'environment': '${local.environment}',
            'function_name': context.function_name if context else 'unknown'
        })
    }
EOF
    filename = "index.py"
  }
}

# IAM role for Lambda execution (shared between placeholder and container function)
resource "aws_iam_role" "lambda_execution" {
  name = "${var.project_name}-lambda-execution-role-${local.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-lambda-role-${local.environment}"
    Environment = local.environment
    Project     = var.project_name
  }
}

# IAM policy attachment for basic Lambda execution
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_execution.name
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.project_name}-${local.environment}"
  retention_in_days = 7

  tags = {
    Name        = "${var.project_name}-lambda-logs-${local.environment}"
    Environment = local.environment
    Project     = var.project_name
  }
}

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

# Lambda Module (only if container image exists)
module "lambda" {
  count = data.external.ecr_images.result.has_images == "true" ? 1 : 0
  
  source = "../../modules/lambda"

  project_name = var.project_name
  environment  = local.environment
  image_uri    = var.lambda_image_uri != "" ? var.lambda_image_uri : "${data.aws_ecr_repository.main.repository_url}:latest"
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
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = data.external.ecr_images.result.has_images == "true" ? module.lambda[0].function_name : aws_lambda_function.placeholder[0].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.execution_arn}/*/*"
}

# API Gateway Module
module "api_gateway" {
  source = "../../modules/api-gateway"

  project_name      = var.project_name
  environment       = local.environment
  lambda_invoke_arn = data.external.ecr_images.result.has_images == "true" ? module.lambda[0].function_invoke_arn : aws_lambda_function.placeholder[0].invoke_arn
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
  lambda_function_name = data.external.ecr_images.result.has_images == "true" ? module.lambda[0].function_name : aws_lambda_function.placeholder[0].function_name
  api_gateway_name     = "${var.project_name}-api-${local.environment}"
  
  # More lenient thresholds for dev
  lambda_error_threshold    = 10
  lambda_duration_threshold = 15000
  api_4xx_threshold        = 20
  api_5xx_threshold        = 10
  
  create_sns_topic = false  # Disabled for dev
}