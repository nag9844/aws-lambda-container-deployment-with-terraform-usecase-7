environment = "prod"
aws_region  = "ap-south-1"

# VPC Configuration
vpc_cidr           = "10.2.0.0/16"
availability_zones = ["ap-south-1a", "ap-south-1b"]

# Lambda Configuration
lambda_memory_size = 1024
lambda_timeout     = 60