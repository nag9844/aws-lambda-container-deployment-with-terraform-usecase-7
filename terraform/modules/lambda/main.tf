resource "aws_lambda_function" "main" {
  function_name = "${var.name_prefix}-app"
  role         = var.execution_role
  
  package_type = "Image"
  image_uri    = "${var.ecr_repository}:latest"
  
  memory_size = var.memory_size
  timeout     = var.timeout
  
  vpc_config {
    subnet_ids         = var.vpc_config.subnet_ids
    security_group_ids = var.vpc_config.security_group_ids
  }
  
  environment {
    variables = var.environment_variables
  }
  
  tracing_config {
    mode = "Active"
  }
  
  tags = var.tags
  
  depends_on = [
    aws_cloudwatch_log_group.lambda_logs
  ]
  
  # Ignore changes to image_uri to prevent unnecessary updates
  lifecycle {
    ignore_changes = [image_uri]
  }
}

resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.name_prefix}-app"
  retention_in_days = 14
  
  tags = var.tags
}