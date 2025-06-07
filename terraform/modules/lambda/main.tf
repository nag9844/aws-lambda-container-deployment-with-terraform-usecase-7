data "aws_caller_identity" "current" {}

# Lambda execution role
resource "aws_iam_role" "lambda_execution" {
  name = "${var.project_name}-${var.environment}-lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_execution_basic" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_execution_vpc" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_xray" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

# Security group for Lambda
resource "aws_security_group" "lambda" {
  name_prefix = "${var.project_name}-${var.environment}-lambda-"
  vpc_id      = var.vpc_id
  description = "Security group for Lambda function ${var.project_name}-${var.environment}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
    description = "Allow all traffic from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-lambda-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Create a placeholder image in ECR if it doesn't exist
resource "null_resource" "push_placeholder_image" {
  triggers = {
    ecr_repository_url = var.ecr_repository_url
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      REPO_NAME=$(echo "${var.ecr_repository_url}" | cut -d'/' -f2)
      REGISTRY_URL=$(echo "${var.ecr_repository_url}" | cut -d'/' -f1)

      echo "Checking if image exists in ECR..."
      if ! aws ecr describe-images \
          --repository-name "$REPO_NAME" \
          --image-ids imageTag=latest \
          --region ap-south-1 >/dev/null 2>&1; then

        echo 'Image not found. Building and pushing placeholder...'

        cat <<EOF > /tmp/Dockerfile.placeholder
              FROM public.ecr.aws/lambda/nodejs:18
              CMD ["index.handler"]
              EOF

        docker build -f /tmp/Dockerfile.placeholder -t "${var.ecr_repository_url}:latest" /tmp

        aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin "$REGISTRY_URL"

        docker push "${var.ecr_repository_url}:latest"
      else
        echo "Image already exists in ECR. Skipping push."
      fi
    EOT
    interpreter = ["/bin/bash", "-c"]
  }
}

# Lambda function using image from ECR
resource "aws_lambda_function" "main" {
  function_name = "${var.project_name}-${var.environment}"
  role          = aws_iam_role.lambda_execution.arn
  package_type  = "Image"
  image_uri     = "${var.ecr_repository_url}:latest"
  timeout       = 30
  memory_size   = 512

  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.lambda.id]
  }

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }

  lifecycle {
    ignore_changes = [image_uri]
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_execution_basic,
    aws_iam_role_policy_attachment.lambda_execution_vpc,
    null_resource.push_placeholder_image
  ]
}
