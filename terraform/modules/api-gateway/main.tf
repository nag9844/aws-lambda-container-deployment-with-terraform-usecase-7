# API Gateway Module - Create REST API with Lambda integration

# API Gateway REST API
resource "aws_api_gateway_rest_api" "main" {
  name        = "${var.project_name}-api-${var.environment}"
  description = "API Gateway for ${var.project_name} ${var.environment}"

  endpoint_configuration {
    types = [var.endpoint_type]
  }

  tags = {
    Name        = "${var.project_name}-api-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# API Gateway Resource (proxy resource to catch all paths)
resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "{proxy+}"
}

# API Gateway Method for proxy resource
resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = var.authorization_type
  authorizer_id = var.authorizer_id
}

# API Gateway Method for root resource
resource "aws_api_gateway_method" "root" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_rest_api.main.root_resource_id
  http_method   = "ANY"
  authorization = var.authorization_type
  authorizer_id = var.authorizer_id
}

# API Gateway Integration for proxy resource
resource "aws_api_gateway_integration" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_method.proxy.resource_id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arn
}

# API Gateway Integration for root resource
resource "aws_api_gateway_integration" "root" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_method.root.resource_id
  http_method = aws_api_gateway_method.root.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arn
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "main" {
  depends_on = [
    aws_api_gateway_integration.proxy,
    aws_api_gateway_integration.root,
  ]

  rest_api_id = aws_api_gateway_rest_api.main.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.proxy.id,
      aws_api_gateway_method.proxy.id,
      aws_api_gateway_integration.proxy.id,
      aws_api_gateway_method.root.id,
      aws_api_gateway_integration.root.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway Stage
resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = var.stage_name

  dynamic "access_log_settings" {
    for_each = var.enable_access_logs ? [1] : []
    content {
      destination_arn = aws_cloudwatch_log_group.api_gateway[0].arn
      format = jsonencode({
        requestId      = "$context.requestId"
        extendedRequestId = "$context.extendedRequestId"
        ip             = "$context.sourceIp"
        caller         = "$context.identity.caller"
        user           = "$context.identity.user"
        requestTime    = "$context.requestTime"
        httpMethod     = "$context.httpMethod"
        resourcePath   = "$context.resourcePath"
        status         = "$context.status"
        protocol       = "$context.protocol"
        responseLength = "$context.responseLength"
        responseLatency = "$context.responseLatency"
        integrationLatency = "$context.integrationLatency"
        integrationStatus = "$context.integrationStatus"
        error          = "$context.error.message"
        errorType      = "$context.error.messageString"
      })
    }
  }

  dynamic "canary_settings" {
    for_each = var.canary_settings != null ? [var.canary_settings] : []
    content {
      percent_traffic          = canary_settings.value.percent_traffic
      deployment_id           = canary_settings.value.deployment_id
      stage_variable_overrides = canary_settings.value.stage_variable_overrides
      use_stage_cache         = canary_settings.value.use_stage_cache
    }
  }

  tags = {
    Name        = "${var.project_name}-api-stage-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudWatch Log Group for API Gateway access logs
resource "aws_cloudwatch_log_group" "api_gateway" {
  count             = var.enable_access_logs ? 1 : 0
  name              = "/aws/apigateway/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "${var.project_name}-api-logs-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# API Gateway Method Settings
resource "aws_api_gateway_method_settings" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_stage.main.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled = var.enable_metrics
    logging_level   = var.logging_level
  }
}

# Custom Domain Name (optional)
resource "aws_api_gateway_domain_name" "main" {
  count           = var.custom_domain_name != null ? 1 : 0
  domain_name     = var.custom_domain_name
  certificate_arn = var.certificate_arn

  endpoint_configuration {
    types = [var.endpoint_type]
  }

  tags = {
    Name        = "${var.project_name}-api-domain-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Base Path Mapping for custom domain
resource "aws_api_gateway_base_path_mapping" "main" {
  count       = var.custom_domain_name != null ? 1 : 0
  api_id      = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_stage.main.stage_name
  domain_name = aws_api_gateway_domain_name.main[0].domain_name
  base_path   = var.base_path
}