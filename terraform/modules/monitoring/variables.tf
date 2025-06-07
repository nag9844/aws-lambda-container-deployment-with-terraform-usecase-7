variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "lambda_function_name" {
  description = "Name of the Lambda function to monitor"
  type        = string
}

variable "api_gateway_name" {
  description = "Name of the API Gateway to monitor"
  type        = string
}

variable "lambda_error_threshold" {
  description = "Threshold for Lambda error alarms"
  type        = number
  default     = 5
}

variable "lambda_duration_threshold" {
  description = "Threshold for Lambda duration alarms (in milliseconds)"
  type        = number
  default     = 10000
}

variable "api_4xx_threshold" {
  description = "Threshold for API Gateway 4XX error alarms"
  type        = number
  default     = 10
}

variable "api_5xx_threshold" {
  description = "Threshold for API Gateway 5XX error alarms"
  type        = number
  default     = 5
}

variable "alarm_actions" {
  description = "List of ARNs to notify when alarm triggers"
  type        = list(string)
  default     = []
}

variable "create_sns_topic" {
  description = "Create SNS topic for alerts"
  type        = bool
  default     = false
}

variable "alert_email" {
  description = "Email address for alert notifications"
  type        = string
  default     = null
}