# Production Environment Configuration

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
    key          = "usecase6/prod/terraform.tfstate"
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
  enable_nat_gateway = true
  enable_flow_logs   = true
}

# Lambda Module
module "lambda" {
  source = "../../modules/lambda"

  project_name = var.project_name
  environment  = local.environment
  image_uri    = var.lambda_image_uri != "" ? var.lambda_image_uri : "${data.aws_ecr_repository.main.repository_url}:latest"
  timeout      = 300  # 5 minutes max for production
  memory_size  = 1024 # Higher memory for production

  environment_variables = {
    ENVIRONMENT = local.environment
    LOG_LEVEL   = "WARN"
  }

  # VPC configuration for production security
  vpc_config = {
    subnet_ids         = module.vpc.private_subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  # Dead letter queue for failed invocations
  dead_letter_target_arn = aws_sqs_queue.dlq.arn

  log_retention_days = 30  # Longer retention for production
  api_gateway_arn    = module.api_gateway.execution_arn
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

  project_name      = var.project_name
  environment       = local.environment
  lambda_invoke_arn = module.lambda.function_invoke_arn
  stage_name        = "prod"
  
  enable_access_logs = true
  log_retention_days = 30
  enable_metrics     = true
  logging_level      = "ERROR"  # Less verbose logging for production
}

# Monitoring Module
module "monitoring" {
  source = "../../modules/monitoring"

  project_name         = var.project_name
  environment          = local.environment
  aws_region          = var.aws_region
  lambda_function_name = module.lambda.function_name
  api_gateway_name     = "${var.project_name}-api-${local.environment}"
  
  # Strict thresholds for production
  lambda_error_threshold    = 3
  lambda_duration_threshold = 5000
  api_4xx_threshold        = 10
  api_5xx_threshold        = 3
  
  create_sns_topic = true
  alert_email      = var.alert_email
  alarm_actions    = [module.monitoring.sns_topic_arn]
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