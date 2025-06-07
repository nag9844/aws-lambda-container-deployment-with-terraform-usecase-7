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
  default     = "10.2.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones"
  type        = number
  default     = 3  # More AZs for production high availability
}

variable "lambda_image_uri" {
  description = "URI of the Lambda container image"
  type        = string
  default     = ""
}

variable "alert_email" {
  description = "Email address for production alerts"
  type        = string
}