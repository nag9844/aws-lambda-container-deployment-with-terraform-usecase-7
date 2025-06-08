# Lambda Module - Create Lambda function with smart deployment mode detection

# Lambda function - automatically detects deployment mode
resource "aws_lambda_function" "main" {
  function_name = "${var.project_name}-${var.environment}"
  role          = aws_iam_role.lambda_execution.arn
  timeout       = var.timeout
  memory_size   = var.memory_size

  # Smart deployment mode detection
  package_type = var.force_container_mode && var.image_uri != "" ? "Image" : "Zip"
  
  # Container image URI (when using container mode)
  image_uri = var.force_container_mode && var.image_uri != "" ? var.image_uri : null
  
  # ZIP deployment (when not using container mode or no image available)
  filename         = var.force_container_mode && var.image_uri != "" ? null : data.archive_file.placeholder[0].output_path
  source_code_hash = var.force_container_mode && var.image_uri != "" ? null : data.archive_file.placeholder[0].output_base64sha256
  handler          = var.force_container_mode && var.image_uri != "" ? null : "index.lambda_handler"
  runtime          = var.force_container_mode && var.image_uri != "" ? null : "python3.11"

  dynamic "vpc_config" {
    for_each = var.vpc_config != null ? [var.vpc_config] : []
    content {
      subnet_ids         = vpc_config.value.subnet_ids
      security_group_ids = vpc_config.value.security_group_ids
    }
  }

  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [var.environment_variables] : []
    content {
      variables = environment.value
    }
  }

  dynamic "dead_letter_config" {
    for_each = var.dead_letter_target_arn != null ? [1] : []
    content {
      target_arn = var.dead_letter_target_arn
    }
  }

  tags = {
    Name           = "${var.project_name}-lambda-${var.environment}"
    Environment    = var.environment
    Project        = var.project_name
    DeploymentType = var.force_container_mode && var.image_uri != "" ? "container" : "zip"
    PackageType    = var.force_container_mode && var.image_uri != "" ? "Image" : "Zip"
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy_attachment.lambda_vpc_access,
    aws_cloudwatch_log_group.lambda
  ]

  lifecycle {
    # Allow updates to switch from ZIP to container
    ignore_changes = []
  }
}

# Create placeholder zip file for initial deployment
resource "local_file" "placeholder_zip" {
  count = var.force_container_mode && var.image_uri != "" ? 0 : 1
  
  content = <<EOF
import sys

def lambda_handler(event, context):
    """
    Simple AWS Lambda handler that returns plain text Hello World
    """
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'text/plain',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type'
        },
        'body': 'Hello World!'
    }
EOF
  
  filename = "${path.module}/placeholder.py"
}

# Create zip archive for placeholder
data "archive_file" "placeholder" {
  count = var.force_container_mode && var.image_uri != "" ? 0 : 1
  
  type        = "zip"
  output_path = "${path.module}/placeholder.zip"
  
  source {
    content  = local_file.placeholder_zip[0].content
    filename = "index.py"
  }
  
  depends_on = [local_file.placeholder_zip]
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "${var.project_name}-lambda-logs-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# IAM role for Lambda execution
resource "aws_iam_role" "lambda_execution" {
  name = "${var.project_name}-lambda-execution-role-${var.environment}"

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
    Name        = "${var.project_name}-lambda-role-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# IAM policy attachment for basic Lambda execution
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_execution.name
}

# IAM policy attachment for VPC access (if VPC config is provided)
resource "aws_iam_role_policy_attachment" "lambda_vpc_access" {
  count      = var.vpc_config != null ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  role       = aws_iam_role.lambda_execution.name
}

# Custom IAM policy for additional permissions
resource "aws_iam_role_policy" "lambda_custom" {
  count = var.custom_policy != null ? 1 : 0
  name  = "${var.project_name}-lambda-custom-policy-${var.environment}"
  role  = aws_iam_role.lambda_execution.id

  policy = var.custom_policy
}

# Lambda function URL (if enabled)
resource "aws_lambda_function_url" "main" {
  count              = var.enable_function_url ? 1 : 0
  function_name      = aws_lambda_function.main.function_name
  authorization_type = var.function_url_auth_type

  dynamic "cors" {
    for_each = var.function_url_cors != null ? [var.function_url_cors] : []
    content {
      allow_credentials = cors.value.allow_credentials
      allow_headers     = cors.value.allow_headers
      allow_methods     = cors.value.allow_methods
      allow_origins     = cors.value.allow_origins
      expose_headers    = cors.value.expose_headers
      max_age          = cors.value.max_age
    }
  }
}

# Lambda alias for versioning
resource "aws_lambda_alias" "main" {
  count            = var.create_alias ? 1 : 0
  name             = var.alias_name
  description      = "Alias for ${var.project_name} Lambda function"
  function_name    = aws_lambda_function.main.function_name
  function_version = var.function_version
}