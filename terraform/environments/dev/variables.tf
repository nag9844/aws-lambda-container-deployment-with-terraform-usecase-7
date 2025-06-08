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
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones"
  type        = number
  default     = 2
}

variable "lambda_image_uri" {
  description = "URI of the Lambda container image"
  type        = string
  default     = ""
}

variable "force_container_deployment" {
  description = "Force container deployment mode"
  type        = bool
  default     = false
}