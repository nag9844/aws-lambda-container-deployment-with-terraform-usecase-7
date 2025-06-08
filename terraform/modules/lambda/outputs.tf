output "function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.main.arn
}

output "function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.main.function_name
}

output "function_invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  value       = aws_lambda_function.main.invoke_arn
}

output "function_url" {
  description = "Function URL if enabled"
  value       = var.enable_function_url ? aws_lambda_function_url.main[0].function_url : null
}

output "function_url_id" {
  description = "Function URL ID if enabled"
  value       = var.enable_function_url ? aws_lambda_function_url.main[0].url_id : null
}

output "execution_role_arn" {
  description = "ARN of the Lambda execution role"
  value       = aws_iam_role.lambda_execution.arn
}

output "execution_role_name" {
  description = "Name of the Lambda execution role"
  value       = aws_iam_role.lambda_execution.name
}

output "log_group_name" {
  description = "Name of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.lambda.name
}

output "log_group_arn" {
  description = "ARN of the CloudWatch log group"
  value       = aws_cloudwatch_log_group.lambda.arn
}

output "deployment_type" {
  description = "Type of deployment (always zip for this module)"
  value       = "zip"
}

output "package_type" {
  description = "Package type of the Lambda function"
  value       = aws_lambda_function.main.package_type
}