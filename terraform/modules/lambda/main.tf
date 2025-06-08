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

# Create placeholder zip file for initial deployment with beautiful webpage
resource "local_file" "placeholder_zip" {
  count = var.force_container_mode && var.image_uri != "" ? 0 : 1
  
  content = <<EOF
import json
import sys
import os

def lambda_handler(event, context):
    """
    AWS Lambda handler function for Hello World application
    
    Args:
        event: API Gateway event
        context: Lambda context
        
    Returns:
        dict: HTTP response with beautiful HTML webpage
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
            "message": f"Hello World!{sys.version}!",
            "status": "Ready for container deployment",
            "method": http_method,
            "path": path,
            "environment": os.environ.get('ENVIRONMENT', 'dev'),
            "function_name": context.function_name if context else 'unknown',
            "python_version": sys.version,
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
    
    # Default to beautiful HTML response for browser viewing
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
                padding: 1rem;
            }}
            
            .container {{ 
                max-width: 1000px;
                width: 100%;
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
                font-size: 4rem;
                font-weight: 700;
                margin-bottom: 1rem;
                background: linear-gradient(45deg, #ffd700, #ffed4e);
                -webkit-background-clip: text;
                -webkit-text-fill-color: transparent;
                background-clip: text;
                text-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
                animation: glow 2s ease-in-out infinite alternate;
            }}
            
            @keyframes glow {{
                from {{
                    filter: drop-shadow(0 0 20px rgba(255, 215, 0, 0.3));
                }}
                to {{
                    filter: drop-shadow(0 0 30px rgba(255, 215, 0, 0.6));
                }}
            }}
            
            .subtitle {{
                font-size: 1.8rem;
                margin-bottom: 2rem;
                opacity: 0.9;
                font-weight: 300;
            }}
            
            .python-version {{
                background: rgba(0, 0, 0, 0.3);
                padding: 1rem 2rem;
                border-radius: 15px;
                margin: 2rem 0;
                border: 2px solid #ffd700;
                font-family: 'Courier New', monospace;
                font-size: 1.1rem;
                color: #ffd700;
                font-weight: 600;
            }}
            
            .info-grid {{
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
                gap: 1.5rem;
                margin: 2rem 0;
            }}
            
            .info-card {{ 
                background: rgba(255, 255, 255, 0.1);
                padding: 2rem;
                border-radius: 15px;
                border: 1px solid rgba(255, 255, 255, 0.2);
                transition: all 0.3s ease;
                position: relative;
                overflow: hidden;
            }}
            
            .info-card::before {{
                content: '';
                position: absolute;
                top: 0;
                left: -100%;
                width: 100%;
                height: 100%;
                background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.1), transparent);
                transition: left 0.5s;
            }}
            
            .info-card:hover {{
                transform: translateY(-8px);
                background: rgba(255, 255, 255, 0.15);
                box-shadow: 0 15px 30px rgba(0, 0, 0, 0.2);
            }}
            
            .info-card:hover::before {{
                left: 100%;
            }}
            
            .info-label {{
                font-size: 1rem;
                opacity: 0.8;
                margin-bottom: 0.8rem;
                text-transform: uppercase;
                letter-spacing: 1px;
                font-weight: 500;
            }}
            
            .info-value {{
                font-size: 1.4rem;
                font-weight: 700;
                color: #ffd700;
                word-break: break-word;
            }}
            
            .status-badge {{
                display: inline-block;
                background: rgba(255, 165, 0, 0.2);
                color: #ffa500;
                padding: 1rem 2rem;
                border-radius: 30px;
                border: 2px solid #ffa500;
                font-weight: 700;
                font-size: 1.1rem;
                margin: 2rem 0;
                animation: pulse 2s infinite;
                text-transform: uppercase;
                letter-spacing: 1px;
            }}
            
            @keyframes pulse {{
                0%, 100% {{ 
                    opacity: 1; 
                    transform: scale(1);
                }}
                50% {{ 
                    opacity: 0.8; 
                    transform: scale(1.05);
                }}
            }}
            
            .features {{
                margin: 3rem 0;
                text-align: left;
            }}
            
            .features h3 {{
                text-align: center;
                margin-bottom: 2rem;
                font-size: 2rem;
                color: #ffd700;
                font-weight: 600;
            }}
            
            .features-grid {{
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
                gap: 1.5rem;
            }}
            
            .feature-item {{
                background: rgba(255, 255, 255, 0.1);
                padding: 1.5rem;
                border-radius: 12px;
                border-left: 5px solid #ffa500;
                transition: all 0.3s ease;
                display: flex;
                align-items: center;
                gap: 1rem;
            }}
            
            .feature-item:hover {{
                transform: translateX(10px);
                background: rgba(255, 255, 255, 0.15);
            }}
            
            .feature-icon {{
                font-size: 1.5rem;
                min-width: 2rem;
            }}
            
            .feature-text {{
                font-weight: 500;
            }}
            
            .api-info {{
                margin-top: 3rem;
                padding: 2rem;
                background: rgba(0, 0, 0, 0.3);
                border-radius: 15px;
                border: 1px solid rgba(255, 255, 255, 0.1);
            }}
            
            .api-info h4 {{
                color: #ffd700;
                margin-bottom: 1.5rem;
                font-size: 1.5rem;
            }}
            
            .api-endpoint {{
                background: rgba(255, 255, 255, 0.1);
                padding: 1rem;
                border-radius: 8px;
                font-family: 'Courier New', monospace;
                font-size: 1rem;
                margin: 1rem 0;
                word-break: break-all;
                border: 1px solid rgba(255, 215, 0, 0.3);
            }}
            
            .zip-badge {{
                background: linear-gradient(45deg, #ff9500, #ff6b35);
                color: white;
                padding: 0.5rem 1rem;
                border-radius: 20px;
                font-size: 0.9rem;
                font-weight: 600;
                margin: 0 0.5rem;
                text-transform: uppercase;
                letter-spacing: 0.5px;
                box-shadow: 0 4px 15px rgba(255, 149, 0, 0.3);
            }}
            
            .upgrade-notice {{
                background: rgba(255, 165, 0, 0.1);
                border: 2px solid #ffa500;
                border-radius: 15px;
                padding: 2rem;
                margin: 2rem 0;
                text-align: center;
            }}
            
            .upgrade-notice h4 {{
                color: #ffa500;
                margin-bottom: 1rem;
                font-size: 1.3rem;
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
                
                .features-grid {{
                    grid-template-columns: 1fr;
                }}
            }}
        </style>
    </head>
    <body>
        <div class="container">
            <h1 class="header">Hello World! 🌍</h1>
            <p class="subtitle">
                AWS Lambda Function 
                <span class="zip-badge">📦 ZIP Mode</span>
            </p>
            
            <div class="python-version">
                Python Version: {sys.version.split()[0]} 🐍
            </div>
            
            <div class="status-badge">
                ⚠️ Ready for Container Upgrade
            </div>
            
            <div class="upgrade-notice">
                <h4>🚀 Container Deployment Available</h4>
                <p>This function is currently running in ZIP mode. Trigger the build & push workflow to upgrade to container deployment for enhanced features and performance!</p>
            </div>
            
            <div class="info-grid">
                <div class="info-card">
                    <div class="info-label">Function Name</div>
                    <div class="info-value">{context.function_name if context else 'unknown'}</div>
                </div>
                <div class="info-card">
                    <div class="info-label">Environment</div>
                    <div class="info-value">{os.environ.get('ENVIRONMENT', 'dev')}</div>
                </div>
                <div class="info-card">
                    <div class="info-label">HTTP Method</div>
                    <div class="info-value">{http_method}</div>
                </div>
                <div class="info-card">
                    <div class="info-label">Request Path</div>
                    <div class="info-value">{path}</div>
                </div>
                <div class="info-card">
                    <div class="info-label">Memory Limit</div>
                    <div class="info-value">{context.memory_limit_in_mb if context else 'unknown'} MB</div>
                </div>
                <div class="info-card">
                    <div class="info-label">Remaining Time</div>
                    <div class="info-value">{context.get_remaining_time_in_millis() if context else 'unknown'} ms</div>
                </div>
            </div>
            
            <div class="features">
                <h3>🏗️ Current Deployment Features</h3>
                <div class="features-grid">
                    <div class="feature-item">
                        <div class="feature-icon">📦</div>
                        <div class="feature-text">ZIP Package Deployment</div>
                    </div>
                    <div class="feature-item">
                        <div class="feature-icon">🏗️</div>
                        <div class="feature-text">Terraform Infrastructure</div>
                    </div>
                    <div class="feature-item">
                        <div class="feature-icon">🔄</div>
                        <div class="feature-text">CI/CD Pipeline Ready</div>
                    </div>
                    <div class="feature-item">
                        <div class="feature-icon">📊</div>
                        <div class="feature-text">CloudWatch Monitoring</div>
                    </div>
                    <div class="feature-item">
                        <div class="feature-icon">🌐</div>
                        <div class="feature-text">API Gateway Integration</div>
                    </div>
                    <div class="feature-item">
                        <div class="feature-icon">⚡</div>
                        <div class="feature-text">Serverless Architecture</div>
                    </div>
                    <div class="feature-item">
                        <div class="feature-icon">🔒</div>
                        <div class="feature-text">AWS Security Best Practices</div>
                    </div>
                    <div class="feature-item">
                        <div class="feature-icon">🚀</div>
                        <div class="feature-text">Container Upgrade Available</div>
                    </div>
                </div>
            </div>
            
            <div class="api-info">
                <h4>🔗 API Access</h4>
                <p>For JSON API responses, add <code>?format=json</code> to the URL:</p>
                <div class="api-endpoint">
                    {headers.get('Host', 'your-api-domain.com')}{path}?format=json
                </div>
                <p style="margin-top: 1rem; opacity: 0.8;">
                    This will return: <code>Hello World!{sys.version.split()[0]}!</code> with additional metadata
                </p>
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