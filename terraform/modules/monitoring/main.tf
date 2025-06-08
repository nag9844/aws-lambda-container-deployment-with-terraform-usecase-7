# Monitoring Module - CloudWatch dashboards and alarms

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
            ["AWS/Lambda", "Invocations", "FunctionName", var.lambda_function_name],
            ["AWS/Lambda", "Errors", "FunctionName", var.lambda_function_name],
            ["AWS/Lambda", "Duration", "FunctionName", var.lambda_function_name],
            ["AWS/Lambda", "Throttles", "FunctionName", var.lambda_function_name],
            ["AWS/Lambda", "ConcurrentExecutions", "FunctionName", var.lambda_function_name],
            ["AWS/Lambda", "DeadLetterErrors", "FunctionName", var.lambda_function_name]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Lambda Metrics"
          period  = 300
          stat    = "Sum"
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
            ["AWS/ApiGateway", "Count", "ApiName", var.api_gateway_name],
            ["AWS/ApiGateway", "4XXError", "ApiName", var.api_gateway_name],
            ["AWS/ApiGateway", "5XXError", "ApiName", var.api_gateway_name],
            ["AWS/ApiGateway", "Latency", "ApiName", var.api_gateway_name],
            ["AWS/ApiGateway", "IntegrationLatency", "ApiName", var.api_gateway_name]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "API Gateway Metrics"
          period  = 300
          stat    = "Average"
        }
      },
      {
        type   = "log"
        x      = 0
        y      = 12
        width  = 24
        height = 6

        properties = {
          query   = "SOURCE '/aws/lambda/${var.lambda_function_name}' | fields @timestamp, @message | sort @timestamp desc | limit 100"
          region  = var.aws_region
          title   = "Recent Lambda Logs"
          view    = "table"
        }
      }
    ]
  })
}

# CloudWatch Alarm for Lambda Errors
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${var.project_name}-${var.environment}-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.lambda_error_evaluation_periods
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = var.alarm_period
  statistic           = "Sum"
  threshold           = var.lambda_error_threshold
  alarm_description   = "This metric monitors lambda errors"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = var.lambda_function_name
  }

  tags = {
    Name        = "${var.project_name}-lambda-errors-alarm-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudWatch Alarm for Lambda Duration
resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  alarm_name          = "${var.project_name}-${var.environment}-lambda-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.lambda_duration_evaluation_periods
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = var.alarm_period
  statistic           = "Average"
  threshold           = var.lambda_duration_threshold
  alarm_description   = "This metric monitors lambda duration"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = var.lambda_function_name
  }

  tags = {
    Name        = "${var.project_name}-lambda-duration-alarm-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudWatch Alarm for Lambda Throttles
resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  count               = var.enable_lambda_throttle_alarm ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-lambda-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = var.alarm_period
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "This metric monitors lambda throttles"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = var.lambda_function_name
  }

  tags = {
    Name        = "${var.project_name}-lambda-throttles-alarm-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudWatch Alarm for API Gateway 4XX Errors
resource "aws_cloudwatch_metric_alarm" "api_gateway_4xx" {
  alarm_name          = "${var.project_name}-${var.environment}-api-4xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.api_4xx_evaluation_periods
  metric_name         = "4XXError"
  namespace           = "AWS/ApiGateway"
  period              = var.alarm_period
  statistic           = "Sum"
  threshold           = var.api_4xx_threshold
  alarm_description   = "This metric monitors API Gateway 4XX errors"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiName = var.api_gateway_name
  }

  tags = {
    Name        = "${var.project_name}-api-4xx-alarm-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudWatch Alarm for API Gateway 5XX Errors
resource "aws_cloudwatch_metric_alarm" "api_gateway_5xx" {
  alarm_name          = "${var.project_name}-${var.environment}-api-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.api_5xx_evaluation_periods
  metric_name         = "5XXError"
  namespace           = "AWS/ApiGateway"
  period              = var.alarm_period
  statistic           = "Sum"
  threshold           = var.api_5xx_threshold
  alarm_description   = "This metric monitors API Gateway 5XX errors"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiName = var.api_gateway_name
  }

  tags = {
    Name        = "${var.project_name}-api-5xx-alarm-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudWatch Alarm for API Gateway Latency
resource "aws_cloudwatch_metric_alarm" "api_gateway_latency" {
  count               = var.enable_api_latency_alarm ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-api-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "Latency"
  namespace           = "AWS/ApiGateway"
  period              = var.alarm_period
  statistic           = "Average"
  threshold           = var.api_latency_threshold
  alarm_description   = "This metric monitors API Gateway latency"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiName = var.api_gateway_name
  }

  tags = {
    Name        = "${var.project_name}-api-latency-alarm-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# SNS Topic for alerts (optional)
resource "aws_sns_topic" "alerts" {
  count = var.create_sns_topic ? 1 : 0
  name  = "${var.project_name}-alerts-${var.environment}"

  # KMS encryption
  kms_master_key_id = var.sns_kms_key_id

  # Delivery policy
  delivery_policy = var.sns_delivery_policy

  tags = {
    Name        = "${var.project_name}-alerts-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}

# SNS Topic Subscription for email alerts
resource "aws_sns_topic_subscription" "email_alerts" {
  count     = var.create_sns_topic && var.alert_email != null ? 1 : 0
  topic_arn = aws_sns_topic.alerts[0].arn
  protocol  = "email"
  endpoint  = var.alert_email

  # Confirmation timeout
  confirmation_timeout_in_minutes = 5
}

# SNS Topic Subscription for SMS alerts
resource "aws_sns_topic_subscription" "sms_alerts" {
  count     = var.create_sns_topic && var.alert_phone != null ? 1 : 0
  topic_arn = aws_sns_topic.alerts[0].arn
  protocol  = "sms"
  endpoint  = var.alert_phone
}

# SNS Topic Subscription for Slack webhook
resource "aws_sns_topic_subscription" "slack_alerts" {
  count     = var.create_sns_topic && var.slack_webhook_url != null ? 1 : 0
  topic_arn = aws_sns_topic.alerts[0].arn
  protocol  = "https"
  endpoint  = var.slack_webhook_url
}

# CloudWatch Log Metric Filter for custom metrics
resource "aws_cloudwatch_log_metric_filter" "custom_metrics" {
  for_each = var.custom_log_metric_filters

  name           = each.key
  log_group_name = "/aws/lambda/${var.lambda_function_name}"
  pattern        = each.value.pattern

  metric_transformation {
    name      = each.value.metric_name
    namespace = each.value.namespace
    value     = each.value.value
  }
}

# CloudWatch Alarms for custom metrics
resource "aws_cloudwatch_metric_alarm" "custom_metric_alarms" {
  for_each = var.custom_metric_alarms

  alarm_name          = "${var.project_name}-${var.environment}-${each.key}"
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = each.value.metric_name
  namespace           = each.value.namespace
  period              = each.value.period
  statistic           = each.value.statistic
  threshold           = each.value.threshold
  alarm_description   = each.value.description
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions
  treat_missing_data  = each.value.treat_missing_data

  dimensions = each.value.dimensions

  tags = {
    Name        = "${var.project_name}-${each.key}-alarm-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }
}