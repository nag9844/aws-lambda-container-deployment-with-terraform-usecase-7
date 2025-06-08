# API Gateway Module - Create REST API with Lambda integration

# API Gateway REST API
resource "aws_api_gateway_rest_api" "main" {
  name        = "${var.project_name}-api-${var.environment}"
  description = "API Gateway for ${var.project_name} ${var.environment}"

  endpoint_configuration {
    types            = [var.endpoint_type]
    vpc_endpoint_ids = var.endpoint_type == "PRIVATE" ? var.vpc_endpoint_ids : null
  }

  # API Gateway policy for private endpoints
  policy = var.endpoint_type == "PRIVATE" && var.resource_policy != null ? var.resource_policy : null

  # Disable execute API endpoint for private APIs
  disable_execute_api_endpoint = var.endpoint_type == "PRIVATE" ? var.disable_execute_api_endpoint : false

  # Binary media types
  binary_media_types = var.binary_media_types

  # Minimum compression size
  minimum_compression_size = var.minimum_compression_size

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

  # API Key required
  api_key_required = var.api_key_required

  # Request parameters
  request_parameters = var.request_parameters

  # Request validator
  request_validator_id = var.request_validator_id != null ? var.request_validator_id : null
}

# API Gateway Method for root resource
resource "aws_api_gateway_method" "root" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_rest_api.main.root_resource_id
  http_method   = "ANY"
  authorization = var.authorization_type
  authorizer_id = var.authorizer_id

  # API Key required
  api_key_required = var.api_key_required

  # Request parameters
  request_parameters = var.request_parameters

  # Request validator
  request_validator_id = var.request_validator_id != null ? var.request_validator_id : null
}

# API Gateway Integration for proxy resource
resource "aws_api_gateway_integration" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_method.proxy.resource_id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arn

  # Connection type for VPC Link
  connection_type = var.connection_type
  connection_id   = var.connection_id

  # Timeout
  timeout_milliseconds = var.integration_timeout_milliseconds

  # Request templates
  request_templates = var.request_templates

  # Passthrough behavior
  passthrough_behavior = var.passthrough_behavior
}

# API Gateway Integration for root resource
resource "aws_api_gateway_integration" "root" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_method.root.resource_id
  http_method = aws_api_gateway_method.root.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arn

  # Connection type for VPC Link
  connection_type = var.connection_type
  connection_id   = var.connection_id

  # Timeout
  timeout_milliseconds = var.integration_timeout_milliseconds

  # Request templates
  request_templates = var.request_templates

  # Passthrough behavior
  passthrough_behavior = var.passthrough_behavior
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

  # Stage variables
  variables = var.stage_variables

  # Cache cluster
  cache_cluster_enabled = var.cache_cluster_enabled
  cache_cluster_size    = var.cache_cluster_size

  # Client certificate
  client_certificate_id = var.client_certificate_id

  # Documentation version
  documentation_version = var.documentation_version

  # X-Ray tracing
  xray_tracing_enabled = var.xray_tracing_enabled

  dynamic "access_log_settings" {
    for_each = var.enable_access_logs ? [1] : []
    content {
      destination_arn = aws_cloudwatch_log_group.api_gateway[0].arn
      format = jsonencode({
        requestId         = "$context.requestId"
        extendedRequestId = "$context.extendedRequestId"
        ip                = "$context.sourceIp"
        caller            = "$context.identity.caller"
        user              = "$context.identity.user"
        requestTime       = "$context.requestTime"
        httpMethod        = "$context.httpMethod"
        resourcePath      = "$context.resourcePath"
        status            = "$context.status"
        protocol          = "$context.protocol"
        responseLength    = "$context.responseLength"
        responseLatency   = "$context.responseLatency"
        integrationLatency = "$context.integrationLatency"
        integrationStatus = "$context.integrationStatus"
        error             = "$context.error.message"
        errorType         = "$context.error.messageString"
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
  kms_key_id        = var.log_kms_key_id

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
    metrics_enabled        = var.enable_metrics
    logging_level         = var.logging_level
    data_trace_enabled    = var.data_trace_enabled
    throttling_rate_limit = var.throttling_rate_limit
    throttling_burst_limit = var.throttling_burst_limit
    caching_enabled       = var.caching_enabled
    cache_ttl_in_seconds  = var.cache_ttl_in_seconds
    cache_data_encrypted  = var.cache_data_encrypted
    require_authorization_for_cache_control = var.require_authorization_for_cache_control
    unauthorized_cache_control_header_strategy = var.unauthorized_cache_control_header_strategy
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

  # Security policy
  security_policy = var.security_policy

  # Mutual TLS authentication
  dynamic "mutual_tls_authentication" {
    for_each = var.mutual_tls_authentication != null ? [var.mutual_tls_authentication] : []
    content {
      truststore_uri     = mutual_tls_authentication.value.truststore_uri
      truststore_version = mutual_tls_authentication.value.truststore_version
    }
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

# API Gateway Request Validator
resource "aws_api_gateway_request_validator" "main" {
  count                       = var.create_request_validator ? 1 : 0
  name                        = "${var.project_name}-validator-${var.environment}"
  rest_api_id                 = aws_api_gateway_rest_api.main.id
  validate_request_body       = var.validate_request_body
  validate_request_parameters = var.validate_request_parameters
}

# API Gateway Usage Plan
resource "aws_api_gateway_usage_plan" "main" {
  count       = var.create_usage_plan ? 1 : 0
  name        = "${var.project_name}-usage-plan-${var.environment}"
  description = "Usage plan for ${var.project_name} ${var.environment}"

  api_stages {
    api_id = aws_api_gateway_rest_api.main.id
    stage  = aws_api_gateway_stage.main.stage_name
  }

  dynamic "quota_settings" {
    for_each = var.quota_settings != null ? [var.quota_settings] : []
    content {
      limit  = quota_settings.value.limit
      offset = quota_settings.value.offset
      period = quota_settings.value.period
    }
  }

  dynamic "throttle_settings" {
    for_each = var.throttle_settings != null ? [var.throttle_settings] : []
    content {
      rate_limit  = throttle_settings.value.rate_limit
      burst_limit = throttle_settings.value.burst_limit
    }
  }

  tags = {
    Name        = "${var.project_name}-usage-plan-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# API Gateway API Key
resource "aws_api_gateway_api_key" "main" {
  count       = var.create_api_key ? 1 : 0
  name        = "${var.project_name}-api-key-${var.environment}"
  description = "API key for ${var.project_name} ${var.environment}"
  enabled     = true

  tags = {
    Name        = "${var.project_name}-api-key-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# API Gateway Usage Plan Key
resource "aws_api_gateway_usage_plan_key" "main" {
  count         = var.create_usage_plan && var.create_api_key ? 1 : 0
  key_id        = aws_api_gateway_api_key.main[0].id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.main[0].id
}