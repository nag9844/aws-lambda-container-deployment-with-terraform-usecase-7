# Lambda Module - Create Lambda function with ZIP deployment first, then upgrade to container

# Create placeholder zip file for deployment
data "archive_file" "placeholder" {
  type        = "zip"
  output_path = "${path.module}/placeholder.zip"
  
  source {
    content = <<EOF
import json
import os

def lambda_handler(event, context):
    """
    Placeholder Lambda handler function - Always returns HTML for browser viewing
    """
    
    # Extract request information
    http_method = event.get('httpMethod', 'GET')
    path = event.get('path', '/')
    query_params = event.get('queryStringParameters') or {}
    headers = event.get('headers', {})
    
    # Check if this is an API call (has specific API headers or query parameter)
    is_api_call = (
        headers.get('Content-Type', '').startswith('application/json') or
        headers.get('X-Requested-With') == 'XMLHttpRequest' or
        query_params.get('format') == 'json' or
        path.startswith('/api/')
    )
    
    # Create response body for JSON API calls
    if is_api_call:
        response_body = {
            "message": "Hello World from AWS Lambda!",
            "status": "Ready for container deployment",
            "method": http_method,
            "path": path,
            "environment": os.environ.get('ENVIRONMENT', 'unknown'),
            "function_name": context.function_name if context else 'unknown',
            "deployment_type": "zip_placeholder"
        }
        
        if query_params:
            response_body["query_parameters"] = query_params
        
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
    
    # Default to HTML response for browser viewing
    html_content = f"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Hello World - AWS Lambda</title>
        <style>
            * {{
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }}
            
            body {{ 
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                min-height: 100vh;
                display: flex;
                align-items: center;
                justify-content: center;
                color: white;
                line-height: 1.6;
            }}
            
            .container {{ 
                max-width: 900px;
                width: 90%;
                background: rgba(255, 255, 255, 0.1);
                padding: 3rem;
                border-radius: 20px;
                backdrop-filter: blur(20px);
                border: 1px solid rgba(255, 255, 255, 0.2);
                box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
                text-align: center;
                animation: fadeInUp 0.8s ease-out;
            }}
            
            @keyframes fadeInUp {{
                from {{
                    opacity: 0;
                    transform: translateY(30px);
                }}
                to {{
                    opacity: 1;
                    transform: translateY(0);
                }}
            }}
            
            .header {{ 
                font-size: 3.5rem;
                font-weight: 700;
                margin-bottom: 1rem;
                background: linear-gradient(45deg, #ffd700, #ffed4e);
                -webkit-background-clip: text;
                -webkit-text-fill-color: transparent;
                background-clip: text;
                text-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
            }}
            
            .subtitle {{
                font-size: 1.5rem;
                margin-bottom: 2rem;
                opacity: 0.9;
                font-weight: 300;
            }}
            
            .info-grid {{
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
                gap: 1.5rem;
                margin: 2rem 0;
            }}
            
            .info-card {{ 
                background: rgba(255, 255, 255, 0.1);
                padding: 1.5rem;
                border-radius: 15px;
                border: 1px solid rgba(255, 255, 255, 0.2);
                transition: transform 0.3s ease, background 0.3s ease;
            }}
            
            .info-card:hover {{
                transform: translateY(-5px);
                background: rgba(255, 255, 255, 0.15);
            }}
            
            .info-label {{
                font-size: 0.9rem;
                opacity: 0.8;
                margin-bottom: 0.5rem;
                text-transform: uppercase;
                letter-spacing: 1px;
            }}
            
            .info-value {{
                font-size: 1.2rem;
                font-weight: 600;
                color: #ffd700;
            }}
            
            .status-badge {{
                display: inline-block;
                background: rgba(0, 255, 0, 0.2);
                color: #00ff88;
                padding: 0.8rem 1.5rem;
                border-radius: 25px;
                border: 2px solid #00ff88;
                font-weight: 600;
                margin: 1.5rem 0;
                animation: pulse 2s infinite;
            }}
            
            @keyframes pulse {{
                0%, 100% {{ opacity: 1; }}
                50% {{ opacity: 0.7; }}
            }}
            
            .features {{
                margin: 2rem 0;
                text-align: left;
            }}
            
            .features h3 {{
                text-align: center;
                margin-bottom: 1.5rem;
                font-size: 1.5rem;
                color: #ffd700;
            }}
            
            .features-list {{
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
                gap: 1rem;
                list-style: none;
            }}
            
            .features-list li {{
                background: rgba(255, 255, 255, 0.1);
                padding: 1rem;
                border-radius: 10px;
                border-left: 4px solid #00ff88;
                transition: transform 0.2s ease;
            }}
            
            .features-list li:hover {{
                transform: translateX(5px);
            }}
            
            .api-info {{
                margin-top: 2rem;
                padding: 1.5rem;
                background: rgba(0, 0, 0, 0.2);
                border-radius: 15px;
                border: 1px solid rgba(255, 255, 255, 0.1);
            }}
            
            .api-info h4 {{
                color: #ffd700;
                margin-bottom: 1rem;
            }}
            
            .api-endpoint {{
                background: rgba(255, 255, 255, 0.1);
                padding: 0.8rem;
                border-radius: 8px;
                font-family: 'Courier New', monospace;
                font-size: 0.9rem;
                margin: 0.5rem 0;
                word-break: break-all;
            }}
            
            @media (max-width: 768px) {{
                .container {{
                    padding: 2rem;
                    margin: 1rem;
                }}
                
                .header {{
                    font-size: 2.5rem;
                }}
                
                .info-grid {{
                    grid-template-columns: 1fr;
                }}
            }}
        </style>
    </head>
    <body>
        <div class="container">
            <h1 class="header">Hello World! 🌍</h1>
            <p class="subtitle">AWS Lambda Function Successfully Deployed</p>
            
            <div class="status-badge">
                ✅ Function Active & Ready
            </div>
            
            <div class="info-grid">
                <div class="info-card">
                    <div class="info-label">Function Name</div>
                    <div class="info-value">{context.function_name if context else 'unknown'}</div>
                </div>
                <div class="info-card">
                    <div class="info-label">Environment</div>
                    <div class="info-value">{os.environ.get('ENVIRONMENT', 'unknown')}</div>
                </div>
                <div class="info-card">
                    <div class="info-label">HTTP Method</div>
                    <div class="info-value">{http_method}</div>
                </div>
                <div class="info-card">
                    <div class="info-label">Request Path</div>
                    <div class="info-value">{path}</div>
                </div>
            </div>
            
            <div class="features">
                <h3>🚀 Deployment Features</h3>
                <ul class="features-list">
                    <li>✅ Lambda Function Deployed</li>
                    <li>✅ API Gateway Configured</li>
                    <li>✅ CloudWatch Monitoring</li>
                    <li>✅ Infrastructure as Code</li>
                    <li>✅ CI/CD Pipeline Ready</li>
                    <li>🔄 Container Upgrade Available</li>
                </ul>
            </div>
            
            <div class="api-info">
                <h4>🔗 API Access</h4>
                <p>For JSON API responses, add <code>?format=json</code> to the URL:</p>
                <div class="api-endpoint">
                    {headers.get('Host', 'your-api-domain.com')}{path}?format=json
                </div>
            </div>
        </div>
    </body>
    </html>
    """
    
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'text/html; charset=utf-8',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Cache-Control': 'no-cache'
        },
        'body': html_content
    }
EOF
    filename = "index.py"
  }
}

# Lambda function - starts with ZIP, can be upgraded to container later
resource "aws_lambda_function" "main" {
  function_name = "${var.project_name}-${var.environment}"
  role          = aws_iam_role.lambda_execution.arn
  timeout       = var.timeout
  memory_size   = var.memory_size

  # Always start with ZIP deployment for reliability
  package_type     = var.force_container_mode && var.image_uri != "" ? "Image" : "Zip"
  
  # Container configuration (only when forced and image URI provided)
  image_uri = var.force_container_mode && var.image_uri != "" ? var.image_uri : null
  
  # ZIP configuration (default)
  filename         = var.force_container_mode && var.image_uri != "" ? null : data.archive_file.placeholder.output_path
  source_code_hash = var.force_container_mode && var.image_uri != "" ? null : data.archive_file.placeholder.output_base64sha256
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
    ignore_changes = [
      # Allow updates to switch from ZIP to container
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

# Lambda alias for versioning
resource "aws_lambda_alias" "main" {
  count            = var.create_alias ? 1 : 0
  name             = var.alias_name
  description      = "Alias for ${var.project_name} Lambda function"
  function_name    = aws_lambda_function.main.function_name
  function_version = var.function_version
}