variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "hello-world-lambda"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.1.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones"
  type        = number
  default     = 2
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "enable_vpc_config" {
  description = "Enable VPC configuration for Lambda"
  type        = bool
  default     = false
}

variable "lambda_image_uri" {
  description = "URI of the Lambda container image"
  type        = string
  default     = ""
}

variable "enable_alerts" {
  description = "Enable SNS alerts"
  type        = bool
  default     = true
}

variable "alert_email" {
  description = "Email address for alerts"
  type        = string
  default     = null
}