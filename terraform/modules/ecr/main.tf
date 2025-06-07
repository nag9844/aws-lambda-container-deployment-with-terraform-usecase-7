resource "aws_ecr_repository" "main" {
  name                 = var.repository_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-ecr"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.main.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
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
      },
      {
        rulePriority = 2
        description  = "Keep last 10 images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Create a placeholder image to bootstrap the Lambda function
resource "null_resource" "create_placeholder_image" {
  triggers = {
    repository_url = aws_ecr_repository.main.repository_url
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Check if any images exist in the repository
      IMAGE_COUNT=$(aws ecr describe-images --repository-name ${aws_ecr_repository.main.name} --region ap-south-1 --query 'length(imageDetails)' --output text 2>/dev/null || echo "0")
      
      if [ "$IMAGE_COUNT" = "0" ]; then
        echo "No images found in repository. Creating placeholder image..."
        
        # Create a temporary directory for the placeholder
        TEMP_DIR=$(mktemp -d)
        cd $TEMP_DIR
        
        # Create a minimal Dockerfile for the placeholder
        cat > Dockerfile << 'EOF'
FROM public.ecr.aws/lambda/python:3.11
COPY lambda_function.py $${LAMBDA_TASK_ROOT}/
CMD ["lambda_function.handler"]
EOF
        
        # Create a minimal Lambda handler
        cat > lambda_function.py << 'EOF'
def handler(event, context):
    return {
        'statusCode': 200,
        'body': 'Placeholder Lambda function - please deploy your application'
    }
EOF
        
        # Build and push the placeholder image
        docker build -t ${aws_ecr_repository.main.repository_url}:latest .
        
        # Login to ECR
        aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin ${split("/", aws_ecr_repository.main.repository_url)[0]}
        
        # Push the image
        docker push ${aws_ecr_repository.main.repository_url}:latest
        
        # Cleanup
        cd /
        rm -rf $TEMP_DIR
        
        echo "Placeholder image created and pushed successfully"
      else
        echo "Images already exist in repository. Skipping placeholder creation."
      fi
    EOT
  }

  depends_on = [aws_ecr_repository.main]
}