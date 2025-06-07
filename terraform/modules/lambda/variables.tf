variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "ecr_repository_uri" {
  description = "URI of the ECR repository"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "lambda_security_group_id" {
  description = "Security group ID for Lambda"
  type        = string
  default     = ""
}

variable "api_gateway_execution_arn" {
  description = "API Gateway execution ARN"
  type        = string
  default     = "*"
}