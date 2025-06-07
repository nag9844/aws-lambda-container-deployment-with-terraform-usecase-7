# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 14
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.environment}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/Lambda", "Duration", "FunctionName", var.lambda_function_name],
            [".", "Errors", ".", "."],
            [".", "Invocations", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "Lambda Metrics"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApiGateway", "Count", "ApiName", "${var.project_name}-${var.environment}-api"],
            [".", "Latency", ".", "."],
            [".", "4XXError", ".", "."],
            [".", "5XXError", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "API Gateway Metrics"
          period  = 300
        }
      }
    ]
  })
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.project_name}-${var.environment}-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This metric monitors lambda errors"
  
  dimensions = {
    FunctionName = var.lambda_function_name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  alarm_name          = "${var.project_name}-${var.environment}-lambda-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Average"
  threshold           = "10000"
  alarm_description   = "This metric monitors lambda duration"
  
  dimensions = {
    FunctionName = var.lambda_function_name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "api_gateway_5xx" {
  alarm_name          = "${var.project_name}-${var.environment}-api-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This metric monitors API Gateway 5xx errors"
  
  dimensions = {
    ApiName = "${var.project_name}-${var.environment}-api"
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
}

# SNS Topic for alerts
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-${var.environment}-alerts"
}

# X-Ray Service Map (automatically created when tracing is enabled)
data "aws_region" "current" {}