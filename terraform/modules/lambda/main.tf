# Lambda Module - Create Lambda function with container image or placeholder

# Check if ECR repository has images using external data source
data "external" "ecr_images" {
  program = ["bash", "-c", <<-EOT
    set -e
    REPO_NAME=$(echo "${var.image_uri}" | cut -d'/' -f2 | cut -d':' -f1)
    REGION=$(echo "${var.image_uri}" | cut -d'.' -f4)
    
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

# Create placeholder zip file for initial deployment
data "archive_file" "placeholder" {
  count = data.external.ecr_images.result.has_images == "false" ? 1 : 0
  
  type        = "zip"
  output_path = "${path.module}/placeholder.zip"
  
  source {
    content = <<EOF
import json
import os

def lambda_handler(event, context):
    """
    Placeholder Lambda handler function
    """
    
    # Extract request information
    http_method = event.get('httpMethod', 'GET')
    path = event.get('path', '/')
    query_params = event.get('queryStringParameters') or {}
    
    # Create response body
    response_body = {
        "message": "Hello World from Placeholder Lambda!",
        "status": "Container image will be deployed when available",
        "method": http_method,
        "path": path,
        "environment": os.environ.get('ENVIRONMENT', 'unknown'),
        "function_name": context.function_name if context else 'unknown',
        "deployment_type": "placeholder"
    }
    
    # Add query parameters if present
    if query_params:
        response_body["query_parameters"] = query_params
    
    # Create HTML response for browser viewing
    if event.get('headers', {}).get('Accept', '').find('text/html') >= 0:
        html_content = f"""
        <!DOCTYPE html>
        <html>
        <head>
            <title>Placeholder Lambda</title>
            <style>
                body {{ 
                    font-family: Arial, sans-serif; 
                    margin: 40px; 
                    background: linear-gradient(135deg, #ff9a56 0%, #ff6b6b 100%);
                    color: white;
                }}
                .container {{ 
                    max-width: 800px; 
                    margin: 0 auto; 
                    background: rgba(255,255,255,0.1);
                    padding: 30px;
                    border-radius: 10px;
                    backdrop-filter: blur(10px);
                }}
                .header {{ font-size: 2.5em; margin-bottom: 20px; }}
                .info {{ 
                    background: rgba(255,255,255,0.1); 
                    padding: 15px; 
                    border-radius: 5px; 
                    margin: 10px 0;
                }}
                .highlight {{ color: #ffd700; font-weight: bold; }}
                .status {{ 
                    background: rgba(255,165,0,0.3); 
                    padding: 10px; 
                    border-radius: 5px; 
                    margin: 15px 0;
                    border-left: 4px solid #ffa500;
                }}
            </style>
        </head>
        <body>
            <div class="container">
                <h1 class="header">🚧 Placeholder Lambda Function</h1>
                <div class="status">
                    <p><strong>Status:</strong> Container image deployment pending</p>
                </div>
                <div class="info">
                    <p><span class="highlight">Function:</span> {context.function_name if context else 'unknown'}</p>
                    <p><span class="highlight">Environment:</span> {os.environ.get('ENVIRONMENT', 'unknown')}</p>
                    <p><span class="highlight">Method:</span> {http_method}</p>
                    <p><span class="highlight">Path:</span> {path}</p>
                </div>
                <p>This is a temporary placeholder function. The containerized application will be deployed automatically when the Docker image is available in ECR.</p>
                <ul>
                    <li>⏳ Waiting for container image</li>
                    <li>✅ API Gateway configured</li>
                    <li>✅ Monitoring enabled</li>
                    <li>✅ Infrastructure ready</li>
                </ul>
            </div>
        </body>
        </html>
        """
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'text/html',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type'
            },
            'body': html_content
        }
    
    # JSON response
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type'
        },
        'body': json.dumps(response_body, indent=2)
    }
EOF
    filename = "index.py"
  }
}

# Lambda function - handles both placeholder and container deployments
resource "aws_lambda_function" "main" {
  function_name = "${var.project_name}-${var.environment}"
  role          = aws_iam_role.lambda_execution.arn
  timeout       = var.timeout
  memory_size   = var.memory_size

  # Use container image if available, otherwise use placeholder
  package_type = data.external.ecr_images.result.has_images == "true" ? "Image" : "Zip"
  
  # Container configuration
  image_uri = data.external.ecr_images.result.has_images == "true" ? var.image_uri : null
  
  # Zip configuration for placeholder
  filename         = data.external.ecr_images.result.has_images == "false" ? data.archive_file.placeholder[0].output_path : null
  source_code_hash = data.external.ecr_images.result.has_images == "false" ? data.archive_file.placeholder[0].output_base64sha256 : null
  handler          = data.external.ecr_images.result.has_images == "false" ? "index.lambda_handler" : null
  runtime          = data.external.ecr_images.result.has_images == "false" ? "python3.11" : null

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
    Name        = "${var.project_name}-lambda-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
    DeploymentType = data.external.ecr_images.result.has_images == "true" ? "container" : "placeholder"
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_iam_role_policy_attachment.lambda_vpc_access,
    aws_cloudwatch_log_group.lambda
  ]

  lifecycle {
    ignore_changes = [
      # Allow updates to switch from placeholder to container
      package_type,
      image_uri,
      filename,
      source_code_hash,
      handler,
      runtime
    ]
  }
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

# Lambda permission for API Gateway (if api_gateway_arn is provided)
resource "aws_lambda_permission" "api_gateway" {
  count         = var.api_gateway_arn != null ? 1 : 0
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_gateway_arn}/*/*"
}

# Lambda alias for versioning
resource "aws_lambda_alias" "main" {
  count            = var.create_alias ? 1 : 0
  name             = var.alias_name
  description      = "Alias for ${var.project_name} Lambda function"
  function_name    = aws_lambda_function.main.function_name
  function_version = var.function_version
}