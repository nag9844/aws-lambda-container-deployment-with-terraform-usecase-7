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

variable "repository_name" {
  description = "ECR repository name"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.repository_name))
    error_message = "Repository name must contain only lowercase letters, numbers, and hyphens."
  }
}