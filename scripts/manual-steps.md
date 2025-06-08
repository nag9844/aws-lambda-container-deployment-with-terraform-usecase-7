# Manual Deployment Steps

Follow these steps to deploy your AWS Lambda Container DevOps solution manually.

## Prerequisites

1. **AWS CLI configured** with appropriate permissions
2. **Terraform installed** (>= 1.0)
3. **Docker installed** and running
4. **S3 bucket exists:** `usecases-terraform-state-bucket`

## Step 1: Deploy ECR Repository

```bash
# Navigate to ECR standalone directory
cd terraform/standalone/ecr

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan -var="environment=dev" -var="aws_region=ap-south-1"

# Apply the changes
terraform apply -var="environment=dev" -var="aws_region=ap-south-1"

# Note the ECR repository URI from output
terraform output ecr_repository_uri
```

## Step 2: Build and Push Docker Image

```bash
# Get ECR repository URI (from Step 1 output)
ECR_URI=$(cd terraform/standalone/ecr && terraform output -raw ecr_repository_uri)

# Login to ECR
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin ${ECR_URI}

# Build Docker image
cd src
docker build -t hello-world-lambda-dev .

# Tag for ECR
docker tag hello-world-lambda-dev:latest ${ECR_URI}:latest

# Push to ECR
docker push ${ECR_URI}:latest

# Verify image was pushed
aws ecr list-images --repository-name hello-world-lambda-dev --region ap-south-1
```

## Step 3: Deploy Infrastructure

```bash
# Navigate to dev environment
cd terraform/environments/dev

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan -var="aws_region=ap-south-1" -var="image_tag=latest"

# Apply the changes
terraform apply -var="aws_region=ap-south-1" -var="image_tag=latest"

# Get the API Gateway URL
terraform output api_gateway_url
terraform output lambda_function_url
```

## Step 4: Test Deployment

```bash
# Test API Gateway
API_URL=$(cd terraform/environments/dev && terraform output -raw api_gateway_url)
curl ${API_URL}

# Test Lambda Function URL
FUNCTION_URL=$(cd terraform/environments/dev && terraform output -raw lambda_function_url)
curl ${FUNCTION_URL}
```

## Updating Your Application

After initial deployment, to update your application:

1. **Modify your code** in `src/app.py`
2. **Rebuild and push image:**
   ```bash
   cd src
   docker build -t hello-world-lambda-dev .
   docker tag hello-world-lambda-dev:latest ${ECR_URI}:latest
   docker push ${ECR_URI}:latest
   ```
3. **Update Lambda function:**
   ```bash
   aws lambda update-function-code \
     --function-name hello-world-lambda-dev \
     --image-uri ${ECR_URI}:latest \
     --region ap-south-1
   ```

## Cleanup

To destroy all resources:

```bash
# Destroy infrastructure
cd terraform/environments/dev
terraform destroy -var="aws_region=ap-south-1"

# Destroy ECR (optional - will delete all images)
cd ../../standalone/ecr
terraform destroy -var="environment=dev" -var="aws_region=ap-south-1"
```

## Troubleshooting

### Common Issues:

1. **ECR login fails:** Check AWS credentials and region
2. **Docker build fails:** Check Dockerfile syntax and dependencies
3. **Lambda creation fails:** Ensure ECR image exists and is valid
4. **API Gateway 502 errors:** Check Lambda function logs

### Useful Commands:

```bash
# Check Lambda logs
aws logs tail /aws/lambda/hello-world-lambda-dev --follow

# List ECR images
aws ecr list-images --repository-name hello-world-lambda-dev

# Test Lambda function directly
aws lambda invoke --function-name hello-world-lambda-dev response.json
```