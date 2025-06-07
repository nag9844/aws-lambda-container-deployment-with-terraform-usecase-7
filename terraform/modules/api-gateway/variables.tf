variable "environment" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "project_name" {
  description = "Project name"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "lambda_function_name" {
  description = "Lambda function name"
  type        = string
  validation {
    condition     = length(var.lambda_function_name) > 0
    error_message = "Lambda function name cannot be empty."
  }
}

variable "lambda_invoke_arn" {
  description = "Lambda function invoke ARN"
  type        = string
  validation {
    condition     = can(regex("^arn:aws:apigateway:[a-z0-9-]+:lambda:path/2015-03-31/functions/arn:aws:lambda:[a-z0-9-]+:[0-9]+:function:[a-zA-Z0-9-_]+/invocations$", var.lambda_invoke_arn))
    error_message = "Lambda invoke ARN must be a valid API Gateway Lambda invoke ARN."
  }
}