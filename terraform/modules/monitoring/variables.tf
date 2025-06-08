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

variable "alarm_period" {
  description = "Period for CloudWatch alarms in seconds"
  type        = number
  default     = 300
  validation {
    condition     = var.alarm_period >= 60
    error_message = "Alarm period must be at least 60 seconds."
  }
}

variable "lambda_error_threshold" {
  description = "Threshold for Lambda error alarms"
  type        = number
  default     = 5
}

variable "lambda_error_evaluation_periods" {
  description = "Number of evaluation periods for Lambda error alarms"
  type        = number
  default     = 2
}

variable "lambda_duration_threshold" {
  description = "Threshold for Lambda duration alarms (in milliseconds)"
  type        = number
  default     = 10000
}

variable "lambda_duration_evaluation_periods" {
  description = "Number of evaluation periods for Lambda duration alarms"
  type        = number
  default     = 2
}

variable "enable_lambda_throttle_alarm" {
  description = "Enable Lambda throttle alarm"
  type        = bool
  default     = true
}

variable "api_4xx_threshold" {
  description = "Threshold for API Gateway 4XX error alarms"
  type        = number
  default     = 10
}

variable "api_4xx_evaluation_periods" {
  description = "Number of evaluation periods for API Gateway 4XX error alarms"
  type        = number
  default     = 2
}

variable "api_5xx_threshold" {
  description = "Threshold for API Gateway 5XX error alarms"
  type        = number
  default     = 5
}

variable "api_5xx_evaluation_periods" {
  description = "Number of evaluation periods for API Gateway 5XX error alarms"
  type        = number
  default     = 2
}

variable "enable_api_latency_alarm" {
  description = "Enable API Gateway latency alarm"
  type        = bool
  default     = false
}

variable "api_latency_threshold" {
  description = "Threshold for API Gateway latency alarm (in milliseconds)"
  type        = number
  default     = 5000
}

variable "alarm_actions" {
  description = "List of ARNs to notify when alarm triggers"
  type        = list(string)
  default     = []
}

variable "ok_actions" {
  description = "List of ARNs to notify when alarm returns to OK state"
  type        = list(string)
  default     = []
}

variable "create_sns_topic" {
  description = "Create SNS topic for alerts"
  type        = bool
  default     = false
}

variable "sns_kms_key_id" {
  description = "KMS key ID for SNS topic encryption"
  type        = string
  default     = null
}

variable "sns_delivery_policy" {
  description = "SNS topic delivery policy"
  type        = string
  default     = null
}

variable "alert_email" {
  description = "Email address for alert notifications"
  type        = string
  default     = null
}

variable "alert_phone" {
  description = "Phone number for SMS alert notifications"
  type        = string
  default     = null
}

variable "slack_webhook_url" {
  description = "Slack webhook URL for alert notifications"
  type        = string
  default     = null
}

variable "create_composite_alarm" {
  description = "Create a composite alarm for overall health"
  type        = bool
  default     = false
}

variable "custom_log_metric_filters" {
  description = "Custom log metric filters"
  type = map(object({
    pattern     = string
    metric_name = string
    namespace   = string
    value       = string
  }))
  default = {}
}

variable "custom_metric_alarms" {
  description = "Custom metric alarms"
  type = map(object({
    comparison_operator = string
    evaluation_periods  = number
    metric_name         = string
    namespace           = string
    period              = number
    statistic           = string
    threshold           = number
    description         = string
    treat_missing_data  = string
    dimensions          = map(string)
  }))
  default = {}
}