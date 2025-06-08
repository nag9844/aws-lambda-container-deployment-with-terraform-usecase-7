output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "ecr_repository_url" {
  description = "URL of the ECR repository (from existing repository)"
  value       = data.aws_ecr_repository.main.repository_url
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = data.external.ecr_images.result.has_images == "true" ? module.lambda[0].function_arn : aws_lambda_function.placeholder[0].arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = data.external.ecr_images.result.has_images == "true" ? module.lambda[0].function_name : aws_lambda_function.placeholder[0].function_name
}

output "lambda_function_url" {
  description = "Function URL of the Lambda function"
  value       = data.external.ecr_images.result.has_images == "true" ? module.lambda[0].function_url : null
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

output "container_image_available" {
  description = "Whether container image is available in ECR"
  value       = data.external.ecr_images.result.has_images == "true"
}

output "deployment_type" {
  description = "Type of Lambda deployment (placeholder or container)"
  value       = data.external.ecr_images.result.has_images == "true" ? "container" : "placeholder"
}

# Output summary for easy access
output "deployment_summary" {
  description = "Summary of deployed resources"
  value = {
    environment            = "dev"
    api_gateway_url       = module.api_gateway.api_url
    lambda_function_url   = data.external.ecr_images.result.has_images == "true" ? module.lambda[0].function_url : null
    ecr_repository_url    = data.aws_ecr_repository.main.repository_url
    dashboard_url         = module.monitoring.dashboard_url
    container_image_ready = data.external.ecr_images.result.has_images == "true"
    deployment_type       = data.external.ecr_images.result.has_images == "true" ? "container" : "placeholder"
  }
}