environment = "staging"
project_name = "hello-world-lambda"
aws_region = "ap-south-1"

# VPC Configuration
vpc_cidr = "10.1.0.0/16"
availability_zones = ["ap-south-1a", "ap-south-1b"]
public_subnet_cidrs = ["10.1.1.0/24", "10.1.2.0/24"]
private_subnet_cidrs = ["10.1.3.0/24", "10.1.4.0/24"]