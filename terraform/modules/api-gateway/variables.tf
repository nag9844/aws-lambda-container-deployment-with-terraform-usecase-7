variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "lambda_invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  type        = string
}

variable "stage_name" {
  description = "Name of the API Gateway stage"
  type        = string
  default     = "api"
}

variable "endpoint_type" {
  description = "Type of endpoint for API Gateway"
  type        = string
  default     = "REGIONAL"
  validation {
    condition     = contains(["EDGE", "REGIONAL", "PRIVATE"], var.endpoint_type)
    error_message = "Endpoint type must be one of: EDGE, REGIONAL, PRIVATE."
  }
}

variable "vpc_endpoint_ids" {
  description = "List of VPC endpoint IDs for private API"
  type        = list(string)
  default     = []
}

variable "resource_policy" {
  description = "Resource policy for private API Gateway"
  type        = string
  default     = null
}

variable "disable_execute_api_endpoint" {
  description = "Disable the default execute-api endpoint"
  type        = bool
  default     = false
}

variable "binary_media_types" {
  description = "List of binary media types supported by the REST API"
  type        = list(string)
  default     = []
}

variable "minimum_compression_size" {
  description = "Minimum response size to compress for the REST API"
  type        = number
  default     = -1
}

variable "authorization_type" {
  description = "Authorization type for API Gateway methods"
  type        = string
  default     = "NONE"
  validation {
    condition     = contains(["NONE", "AWS_IAM", "CUSTOM", "COGNITO_USER_POOLS"], var.authorization_type)
    error_message = "Authorization type must be one of: NONE, AWS_IAM, CUSTOM, COGNITO_USER_POOLS."
  }
}

variable "authorizer_id" {
  description = "ID of the authorizer to use"
  type        = string
  default     = null
}

variable "api_key_required" {
  description = "Whether API key is required for the methods"
  type        = bool
  default     = false
}

variable "request_parameters" {
  description = "Request parameters for the methods"
  type        = map(bool)
  default     = {}
}

variable "request_validator_id" {
  description = "ID of the request validator"
  type        = string
  default     = null
}

variable "connection_type" {
  description = "Integration connection type"
  type        = string
  default     = "INTERNET"
  validation {
    condition     = contains(["INTERNET", "VPC_LINK"], var.connection_type)
    error_message = "Connection type must be either INTERNET or VPC_LINK."
  }
}

variable "connection_id" {
  description = "ID of the VPC link for private integration"
  type        = string
  default     = null
}

variable "integration_timeout_milliseconds" {
  description = "Integration timeout in milliseconds"
  type        = number
  default     = 29000
  validation {
    condition     = var.integration_timeout_milliseconds >= 50 && var.integration_timeout_milliseconds <= 29000
    error_message = "Integration timeout must be between 50 and 29000 milliseconds."
  }
}

variable "request_templates" {
  description = "Request templates for the integration"
  type        = map(string)
  default     = {}
}

variable "passthrough_behavior" {
  description = "Integration passthrough behavior"
  type        = string
  default     = "WHEN_NO_MATCH"
  validation {
    condition     = contains(["WHEN_NO_MATCH", "WHEN_NO_TEMPLATES", "NEVER"], var.passthrough_behavior)
    error_message = "Passthrough behavior must be one of: WHEN_NO_MATCH, WHEN_NO_TEMPLATES, NEVER."
  }
}

variable "stage_variables" {
  description = "Map of stage variables"
  type        = map(string)
  default     = {}
}

variable "cache_cluster_enabled" {
  description = "Enable cache cluster for the stage"
  type        = bool
  default     = false
}

variable "cache_cluster_size" {
  description = "Size of the cache cluster"
  type        = string
  default     = "0.5"
  validation {
    condition = contains([
      "0.5", "1.6", "6.1", "13.5", "28.4", "58.2", "118", "237"
    ], var.cache_cluster_size)
    error_message = "Cache cluster size must be a valid value."
  }
}

variable "client_certificate_id" {
  description = "ID of the client certificate for the stage"
  type        = string
  default     = null
}

variable "documentation_version" {
  description = "Version of the associated API documentation"
  type        = string
  default     = null
}

variable "xray_tracing_enabled" {
  description = "Enable X-Ray tracing for the stage"
  type        = bool
  default     = false
}

variable "enable_access_logs" {
  description = "Enable access logs for API Gateway"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Number of days to retain log events"
  type        = number
  default     = 14
}

variable "log_kms_key_id" {
  description = "KMS key ID for encrypting logs"
  type        = string
  default     = null
}

variable "enable_metrics" {
  description = "Enable detailed CloudWatch metrics"
  type        = bool
  default     = true
}

variable "logging_level" {
  description = "Logging level for API Gateway"
  type        = string
  default     = "INFO"
  validation {
    condition     = contains(["OFF", "ERROR", "INFO"], var.logging_level)
    error_message = "Logging level must be one of: OFF, ERROR, INFO."
  }
}

variable "data_trace_enabled" {
  description = "Enable data trace logging"
  type        = bool
  default     = false
}

variable "throttling_rate_limit" {
  description = "Throttling rate limit"
  type        = number
  default     = 10000
}

variable "throttling_burst_limit" {
  description = "Throttling burst limit"
  type        = number
  default     = 5000
}

variable "caching_enabled" {
  description = "Enable caching for the method"
  type        = bool
  default     = false
}

variable "cache_ttl_in_seconds" {
  description = "Cache TTL in seconds"
  type        = number
  default     = 300
}

variable "cache_data_encrypted" {
  description = "Encrypt cache data"
  type        = bool
  default     = false
}

variable "require_authorization_for_cache_control" {
  description = "Require authorization for cache control"
  type        = bool
  default     = true
}

variable "unauthorized_cache_control_header_strategy" {
  description = "Strategy for unauthorized cache control header"
  type        = string
  default     = "SUCCEED_WITH_RESPONSE_HEADER"
  validation {
    condition = contains([
      "FAIL_WITH_403", "SUCCEED_WITH_RESPONSE_HEADER", "SUCCEED_WITHOUT_RESPONSE_HEADER"
    ], var.unauthorized_cache_control_header_strategy)
    error_message = "Invalid cache control header strategy."
  }
}

variable "custom_domain_name" {
  description = "Custom domain name for the API"
  type        = string
  default     = null
}

variable "certificate_arn" {
  description = "ARN of the SSL certificate for custom domain"
  type        = string
  default     = null
}

variable "security_policy" {
  description = "Security policy for the domain name"
  type        = string
  default     = "TLS_1_2"
  validation {
    condition     = contains(["TLS_1_0", "TLS_1_2"], var.security_policy)
    error_message = "Security policy must be either TLS_1_0 or TLS_1_2."
  }
}

variable "mutual_tls_authentication" {
  description = "Mutual TLS authentication configuration"
  type = object({
    truststore_uri     = string
    truststore_version = string
  })
  default = null
}

variable "base_path" {
  description = "Base path for the API when using custom domain"
  type        = string
  default     = null
}

variable "canary_settings" {
  description = "Canary settings for the API Gateway stage"
  type = object({
    percent_traffic          = number
    deployment_id           = string
    stage_variable_overrides = map(string)
    use_stage_cache         = bool
  })
  default = null
}

variable "create_request_validator" {
  description = "Create a request validator"
  type        = bool
  default     = false
}

variable "validate_request_body" {
  description = "Validate request body"
  type        = bool
  default     = false
}

variable "validate_request_parameters" {
  description = "Validate request parameters"
  type        = bool
  default     = false
}

variable "create_usage_plan" {
  description = "Create a usage plan"
  type        = bool
  default     = false
}

variable "quota_settings" {
  description = "Quota settings for usage plan"
  type = object({
    limit  = number
    offset = number
    period = string
  })
  default = null
}

variable "throttle_settings" {
  description = "Throttle settings for usage plan"
  type = object({
    rate_limit  = number
    burst_limit = number
  })
  default = null
}

variable "create_api_key" {
  description = "Create an API key"
  type        = bool
  default     = false
}