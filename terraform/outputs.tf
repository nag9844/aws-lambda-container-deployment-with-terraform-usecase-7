output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "api_gateway_url" {
  description = "URL of the API Gateway"
  value       = module.api_gateway.api_url
}

output "ecr_repository_uri" {
  description = "URI of the ECR repository"
  value       = module.ecr.repository_uri
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = module.lambda.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = module.lambda.function_arn
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group for Lambda"
  value       = module.monitoring.log_group_name
}