environment = "staging"
aws_region  = "ap-south-1"
project_name = "hello-world-lambda"

vpc_cidr                = "10.1.0.0/16"
public_subnet_cidrs     = ["10.1.1.0/24", "10.1.2.0/24"]
private_subnet_cidrs    = ["10.1.10.0/24", "10.1.20.0/24"]
availability_zones      = ["ap-south-1a", "ap-south-1b"]