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