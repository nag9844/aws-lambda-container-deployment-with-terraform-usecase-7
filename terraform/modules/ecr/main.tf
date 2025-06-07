resource "aws_ecr_repository" "main" {
  name                 = var.repository_name
  image_tag_mutability = "MUTABLE"
  
  image_scanning_configuration {
    scan_on_push = true
  }
  
  tags = var.tags
  
  # Prevent accidental deletion of repository with images
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.main.name
  
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Delete untagged images older than 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Force delete ECR repository on destroy (for testing environments)
resource "null_resource" "ecr_cleanup" {
  count = var.environment != "prod" ? 1 : 0
  
  triggers = {
    repository_name = aws_ecr_repository.main.name
  }
  
  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      aws ecr delete-repository \
        --repository-name ${self.triggers.repository_name} \
        --force \
        --region ${data.aws_region.current.name} || true
    EOT
  }
  
  depends_on = [aws_ecr_repository.main]
}

data "aws_region" "current" {}