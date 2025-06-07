output "log_group_name" {
  description = "CloudWatch log group name"
  value       = aws_cloudwatch_log_group.lambda.name
}

output "log_group_arn" {
  description = "CloudWatch log group ARN"
  value       = aws_cloudwatch_log_group.lambda.arn
}

output "dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = "https://ap-south-1.console.aws.amazon.com/cloudwatch/home?region=ap-south-1#dashboards:name=${aws_cloudwatch_dashboard.lambda_dashboard.dashboard_name}"
}

output "error_alarm_arn" {
  description = "Lambda errors alarm ARN"
  value       = aws_cloudwatch_metric_alarm.lambda_errors.arn
}

output "duration_alarm_arn" {
  description = "Lambda duration alarm ARN"
  value       = aws_cloudwatch_metric_alarm.lambda_duration.arn
}

output "throttles_alarm_arn" {
  description = "Lambda throttles alarm ARN"
  value       = aws_cloudwatch_metric_alarm.lambda_throttles.arn
}

output "concurrent_executions_alarm_arn" {
  description = "Lambda concurrent executions alarm ARN"
  value       = aws_cloudwatch_metric_alarm.lambda_concurrent_executions.arn
}