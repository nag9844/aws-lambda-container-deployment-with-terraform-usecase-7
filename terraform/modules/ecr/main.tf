# ECR Module - Create ECR repository for container images

resource "aws_ecr_repository" "main" {
  name                 = "${var.project_name}-${var.environment}"
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = var.encryption_type
    kms_key         = var.kms_key_id
  }

  tags = {
    Name        = "${var.project_name}-ecr-${var.environment}"
    Environment = var.environment
    Project     = var.project_name
  }

  lifecycle {
    # Prevent destruction of repository if it contains images
    prevent_destroy = true
  }
}

# ECR Lifecycle Policy
resource "aws_ecr_lifecycle_policy" "main" {
  count = var.enable_lifecycle_policy ? 1 : 0

  repository = aws_ecr_repository.main.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.max_image_count} images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = var.max_image_count
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Delete untagged images older than ${var.untagged_image_days} days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.untagged_image_days
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ECR Repository Policy (for cross-account access if needed)
resource "aws_ecr_repository_policy" "main" {
  count = var.repository_policy != "" ? 1 : 0

  repository = aws_ecr_repository.main.name
  policy     = var.repository_policy
}

# Output ECR login token for CI/CD
data "aws_ecr_authorization_token" "token" {}