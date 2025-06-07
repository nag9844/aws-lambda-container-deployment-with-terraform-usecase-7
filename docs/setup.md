# Setup and Deployment Guide

This guide walks you through setting up the AWS Lambda container DevOps solution from scratch.

## Prerequisites

### 1. AWS Account Setup
- AWS Account with sufficient permissions
- AWS CLI configured with appropriate credentials
- Terraform >= 1.0 installed
- Docker installed and running

### 2. GitHub Repository Setup
- GitHub repository with this code
- GitHub Secrets and Variables configured

## GitHub OIDC Configuration

### Step 1: Create AWS Identity Provider

1. **Login to AWS Console** and navigate to IAM > Identity Providers
2. **Create Identity Provider**:
   - Provider Type: `OpenID Connect`
   - Provider URL: `https://token.actions.githubusercontent.com`
   - Audience: `sts.amazonaws.com`

### Step 2: Create IAM Role for GitHub Actions

```bash
# Create trust policy file
cat > github-actions-trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_USERNAME/YOUR_REPO_NAME:*"
        }
      }
    }
  ]
}
EOF

# Create the role
aws iam create-role \
  --role-name GitHubActionsRole \
  --assume-role-policy-document file://github-actions-trust-policy.json

# Attach necessary policies
aws iam attach-role-policy \
  --role-name GitHubActionsRole \
  --policy-arn arn:aws:iam::aws:policy/PowerUserAccess

# Create custom policy for Terraform state
cat > terraform-state-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::YOUR-TERRAFORM-STATE-BUCKET",
        "arn:aws:s3:::YOUR-TERRAFORM-STATE-BUCKET/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "arn:aws:dynamodb:*:*:table/YOUR-TERRAFORM-LOCK-TABLE"
    }
  ]
}
EOF

aws iam put-role-policy \
  --role-name GitHubActionsRole \
  --policy-name TerraformStatePolicy \
  --policy-document file://terraform-state-policy.json
```

### Step 3: Create S3 Backend and DynamoDB Table

```bash
# Create S3 bucket for Terraform state
aws s3 mb s3://your-terraform-state-bucket-unique-name

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket your-terraform-state-bucket-unique-name \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

## GitHub Repository Configuration

### Step 4: Configure Repository Secrets and Variables

**Repository Variables** (Settings > Secrets and Variables > Actions > Variables):
```
AWS_ROLE_ARN: arn:aws:iam::YOUR_ACCOUNT_ID:role/GitHubActionsRole
TERRAFORM_STATE_BUCKET: your-terraform-state-bucket-unique-name
TERRAFORM_LOCK_TABLE: terraform-state-lock
```

**Environment Variables** (for each environment: dev, staging, prod):
```
AWS_ROLE_ARN: arn:aws:iam::YOUR_ACCOUNT_ID:role/GitHubActionsRole
TERRAFORM_STATE_BUCKET: your-terraform-state-bucket-unique-name
TERRAFORM_LOCK_TABLE: terraform-state-lock
```

## Deployment Process

### Step 5: Initial Infrastructure Deployment

1. **Create ECR Repository**:
   ```bash
   # Trigger ECR workflow manually
   gh workflow run ecr.yml -f environment=dev
   ```

2. **Build and Push Initial Image**:
   ```bash
   # This will fail initially but creates the repository
   gh workflow run build-push.yml -f environment=dev -f image_tag=v1.0.0
   ```

3. **Deploy Infrastructure**:
   ```bash
   # Deploy dev environment
   gh workflow run infrastructure.yml -f environment=dev -f action=apply
   ```

### Step 6: Automated Deployments

Once the initial setup is complete, deployments are automated:

- **Push to main branch**: Automatically deploys to dev environment
- **Create release**: Can be configured to deploy to staging/prod
- **Manual deployment**: Use workflow dispatch for specific environments

## Environment-Specific Configuration

### Development Environment
- **Purpose**: Development and testing
- **Resources**: Minimal (no NAT Gateway, shorter log retention)
- **Access**: Function URL enabled with no authentication
- **Monitoring**: Basic alarms with lenient thresholds

### Staging Environment
- **Purpose**: Pre-production testing
- **Resources**: Production-like (optional NAT Gateway, VPC configuration)
- **Access**: API Gateway with proper authentication
- **Monitoring**: Production-like alarms with SNS notifications

### Production Environment
- **Purpose**: Live application
- **Resources**: Full redundancy (NAT Gateway, multiple AZs, DLQ)
- **Access**: API Gateway with strict security
- **Monitoring**: Comprehensive alarms, X-Ray tracing, SNS alerts

## Monitoring and Observability

### CloudWatch Dashboards
Each environment gets a comprehensive dashboard showing:
- Lambda function metrics (invocations, errors, duration)
- API Gateway metrics (requests, latency, errors)
- Custom business metrics

### Alarms
- **Lambda Errors**: Triggers when error rate exceeds threshold
- **Lambda Duration**: Monitors function execution time
- **API Gateway 4XX/5XX**: Tracks client and server errors
- **Lambda Throttles**: Production-only throttling alerts

### Logging
- **Lambda Logs**: Structured logging with different levels per environment
- **API Gateway Logs**: Request/response logging with configurable detail
- **VPC Flow Logs**: Network traffic monitoring (staging/prod)

## Troubleshooting

### Common Issues

1. **ECR Repository Not Found**:
   - Ensure ECR workflow ran successfully
   - Check repository naming convention

2. **Lambda Function Update Fails**:
   - Verify image URI is correct
   - Check Lambda execution role permissions

3. **API Gateway 502 Errors**:
   - Check Lambda function logs
   - Verify integration configuration

4. **Terraform State Lock**:
   ```bash
   # Force unlock if necessary (use with caution)
   terraform force-unlock LOCK_ID
   ```

### Useful Commands

```bash
# Check deployment status
aws lambda get-function --function-name hello-world-lambda-dev

# View function logs
aws logs tail /aws/lambda/hello-world-lambda-dev --follow

# Test API endpoint
curl -X GET https://YOUR_API_ID.execute-api.ap-south-1.amazonaws.com/dev/

# Check ECR images
aws ecr list-images --repository-name hello-world-lambda-dev
```

## Security Best Practices

1. **IAM Roles**: Use least privilege principle
2. **Secrets Management**: Store sensitive data in AWS Secrets Manager
3. **Network Security**: Use VPC for production environments
4. **Container Security**: Regular image scanning enabled
5. **Access Logging**: Comprehensive logging for audit trails

## Cost Optimization

1. **Environment Sizing**: Right-size resources per environment
2. **Log Retention**: Shorter retention for non-production
3. **Image Lifecycle**: Automatic cleanup of old images
4. **Reserved Capacity**: Consider reserved capacity for production

## Support and Maintenance

1. **Regular Updates**: Keep Terraform and container images updated
2. **Security Patches**: Monitor and apply security updates
3. **Performance Monitoring**: Regular review of metrics and alarms
4. **Backup and Recovery**: Ensure proper backup strategies

For additional support, refer to the main README.md or create a GitHub issue.