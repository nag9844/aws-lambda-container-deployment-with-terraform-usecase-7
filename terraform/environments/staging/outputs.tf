output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "ecr_repository_url" {
  description = "URI of the ECR repository"
  value       = module.ecr.repository_url
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = module.lambda.function_arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = module.lambda.function_name
}

output "api_gateway_url" {
  description = "URL of the API Gateway"
  value       = module.api_gateway.api_url
}

output "api_gateway_id" {
  description = "ID of the API Gateway"
  value       = module.api_gateway.api_id
}

output "monitoring_dashboard_url" {
  description = "URL of the CloudWatch dashboard"
  value       = module.monitoring.dashboard_url
}

# Output summary for easy access
output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    environment         = "staging"
    api_gateway_url    = module.api_gateway.api_url
    ecr_repository_url = module.ecr.repository_url
    dashboard_url      = module.monitoring.dashboard_url
  }
}