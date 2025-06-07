output "api_id" {
  description = "ID of the API Gateway REST API"
  value       = aws_api_gateway_rest_api.main.id
}

output "api_arn" {
  description = "ARN of the API Gateway REST API"
  value       = aws_api_gateway_rest_api.main.arn
}

output "execution_arn" {
  description = "Execution ARN of the API Gateway REST API"
  value       = aws_api_gateway_rest_api.main.execution_arn
}

output "api_url" {
  description = "URL of the API Gateway"
  value       = "https://${aws_api_gateway_rest_api.main.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${aws_api_gateway_stage.main.stage_name}"
}

output "stage_name" {
  description = "Name of the API Gateway stage"
  value       = aws_api_gateway_stage.main.stage_name
}

output "custom_domain_name" {
  description = "Custom domain name if configured"
  value       = var.custom_domain_name != null ? aws_api_gateway_domain_name.main[0].domain_name : null
}

output "custom_domain_url" {
  description = "URL using custom domain if configured"
  value       = var.custom_domain_name != null ? "https://${aws_api_gateway_domain_name.main[0].domain_name}${var.base_path != null ? "/${var.base_path}" : ""}" : null
}

data "aws_region" "current" {}