# Production Environment Configuration

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
    key          = "usecase7/prod/statefile.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = "prod"
      Project     = var.project_name
      ManagedBy   = "Terraform"
    }
  }
}

# Local variables
locals {
  environment = "prod"
  
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
  vpc_cidr           = var.vpc_cidr
  az_count           = var.az_count
  enable_nat_gateway = true
  enable_flow_logs   = true
}

# ECR Module
module "ecr" {
  source = "../../modules/ecr"

  project_name   = var.project_name
  environment    = local.environment
  repository_name = "${var.project_name}-${local.environment}"
}

# Lambda Module
module "lambda" {
  source = "../../modules/lambda"

  project_name = var.project_name
  environment  = local.environment

  # Required attributes for your lambda module
  ecr_repository_url = module.ecr.repository_url
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids

  # Pass additional variables only if they are defined in the module's variables.tf
  # For example, if your module supports environment_variables, timeout, memory_size, etc., add them here.
  # environment_variables = {
  #   ENVIRONMENT = local.environment
  #   LOG_LEVEL   = "WARN"
  # }
  # timeout      = 300
  # memory_size  = 1024
  # dead_letter_target_arn = aws_sqs_queue.dlq.arn

  depends_on = [module.ecr]
}

# Security Group for Lambda
resource "aws_security_group" "lambda" {
  name_prefix = "${var.project_name}-lambda-sg-${local.environment}"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS outbound"
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP outbound"
  }

  tags = {
    Name        = "${var.project_name}-lambda-sg-${local.environment}"
    Environment = local.environment
    Project     = var.project_name
  }
}

# Dead Letter Queue
resource "aws_sqs_queue" "dlq" {
  name                      = "${var.project_name}-dlq-${local.environment}"
  message_retention_seconds = 1209600  # 14 days

  tags = {
    Name        = "${var.project_name}-dlq-${local.environment}"
    Environment = local.environment
    Project     = var.project_name
  }
}

# IAM policy for Lambda to access DLQ
resource "aws_iam_role_policy" "lambda_dlq" {
  name = "${var.project_name}-lambda-dlq-policy-${local.environment}"
  role = module.lambda.execution_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage"
        ]
        Resource = aws_sqs_queue.dlq.arn
      }
    ]
  })
}

# API Gateway Module
module "api_gateway" {
  source = "../../modules/api-gateway"

  project_name         = var.project_name
  environment          = local.environment
  lambda_invoke_arn    = module.lambda.function_invoke_arn
  lambda_function_name = module.lambda.function_name
}

# Monitoring Module
module "monitoring" {
  source = "../../modules/monitoring"

  project_name         = var.project_name
  environment          = local.environment
  lambda_function_name = module.lambda.function_name
  api_gateway_id       = module.api_gateway.api_gateway_id
}

# X-Ray tracing for production observability
resource "aws_lambda_function_event_invoke_config" "xray_tracing" {
  function_name = module.lambda.function_name

  destination_config {
    on_failure {
      destination = aws_sqs_queue.dlq.arn
    }
  }
}

# Additional CloudWatch Alarms for production
resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  alarm_name          = "${var.project_name}-${local.environment}-lambda-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  alarm_description   = "This metric monitors lambda throttles"
  alarm_actions       = [module.monitoring.sns_topic_arn]

  dimensions = {
    FunctionName = module.lambda.function_name
  }

  tags = {
    Name        = "${var.project_name}-lambda-throttles-alarm-${local.environment}"
    Environment = local.environment
    Project     = var.project_name
  }
}