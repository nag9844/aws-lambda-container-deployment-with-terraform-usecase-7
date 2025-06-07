environment = "dev"
aws_region  = "ap-south-1"
project_name = "hello-world-lambda"

vpc_cidr                = "10.0.0.0/16"
public_subnet_cidrs     = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs    = ["10.0.10.0/24", "10.0.20.0/24"]
availability_zones      = ["ap-south-1a", "ap-south-1b"]