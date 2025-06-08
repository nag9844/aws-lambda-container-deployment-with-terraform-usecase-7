variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "image_uri" {
  description = "URI of the container image in ECR (optional)"
  type        = string
  default     = ""
}

variable "force_container_mode" {
  description = "Force container deployment mode (requires valid image_uri)"
  type        = bool
  default     = false
}

variable "timeout" {
  description = "The amount of time your Lambda Function has to run in seconds"
  type        = number
  default     = 30
}

variable "memory_size" {
  description = "Amount of memory in MB your Lambda Function can use at runtime"
  type        = number
  default     = 256
}

variable "environment_variables" {
  description = "Environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}

variable "vpc_config" {
  description = "VPC configuration for the Lambda function"
  type = object({
    subnet_ids         = list(string)
    security_group_ids = list(string)
  })
  default = null
}

variable "dead_letter_target_arn" {
  description = "ARN of an SNS topic or SQS queue to notify when an invocation fails"
  type        = string
  default     = null
}

variable "log_retention_days" {
  description = "Specifies the number of days you want to retain log events"
  type        = number
  default     = 14
}

variable "custom_policy" {
  description = "Custom IAM policy for the Lambda function"
  type        = string
  default     = null
}

variable "enable_function_url" {
  description = "Enable Lambda function URL"
  type        = bool
  default     = false
}

variable "function_url_auth_type" {
  description = "The type of authentication that the function URL uses"
  type        = string
  default     = "AWS_IAM"
  validation {
    condition     = contains(["AWS_IAM", "NONE"], var.function_url_auth_type)
    error_message = "Function URL auth type must be either AWS_IAM or NONE."
  }
}

variable "function_url_cors" {
  description = "CORS configuration for the function URL"
  type = object({
    allow_credentials = bool
    allow_headers     = list(string)
    allow_methods     = list(string)
    allow_origins     = list(string)
    expose_headers    = list(string)
    max_age          = number
  })
  default = null
}

variable "api_gateway_execution_arn" {
  description = "Execution ARN of the API Gateway to allow invocation from"
  type        = string
  default     = null
}

variable "create_alias" {
  description = "Create an alias for the Lambda function"
  type        = bool
  default     = false
}

variable "alias_name" {
  description = "Name of the Lambda alias"
  type        = string
  default     = "live"
}

variable "function_version" {
  description = "Lambda function version for the alias"
  type        = string
  default     = "$LATEST"
}