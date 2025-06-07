output "lambda_execution_role_arn" {
  description = "Lambda execution role ARN"
  value       = aws_iam_role.lambda_execution.arn
}

output "api_gateway_role_arn" {
  description = "API Gateway role ARN"
  value       = aws_iam_role.api_gateway.arn
}