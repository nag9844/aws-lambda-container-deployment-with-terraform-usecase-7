# Hello World Lambda - AWS DevOps Challenge

A comprehensive DevOps implementation showcasing containerized AWS Lambda deployment with Infrastructure as Code, CI/CD pipelines, and monitoring using OIDC authentication.

## 🏗️ Architecture Overview

This project demonstrates:
- **Containerized Lambda Functions**: React app deployed as container images
- **Multi-Environment Infrastructure**: Separate dev, staging, and production environments
- **Infrastructure as Code**: Complete AWS infrastructure managed with Terraform
- **CI/CD Automation**: GitHub Actions with OIDC authentication for secure deployments
- **Monitoring & Logging**: CloudWatch dashboards, alarms, and X-Ray tracing

## 📋 Prerequisites

- AWS Account with OIDC provider configured
- GitHub repository with Actions enabled
- Local development environment:
  - Node.js 18+
  - Docker
  - Terraform 1.6+
  - AWS CLI configured

## 🔐 OIDC Setup

This project uses OpenID Connect (OIDC) for secure authentication with AWS. The GitHub Actions workflows assume you have:

1. **OIDC Identity Provider** configured in AWS IAM
2. **IAM Role** with trust policy for GitHub Actions: `arn:aws:iam::199570228070:role/oidc-demo-role`

### Required IAM Permissions

The OIDC role should have permissions for:
- EC2 (VPC, Subnets, Security Groups)
- Lambda (Functions, Permissions)
- ECR (Repositories, Images)
- API Gateway (APIs, Routes, Stages)
- CloudWatch (Log Groups, Dashboards, Alarms)
- IAM (Roles, Policies)

## 🚀 Deployment Process

### Step 1: Setup ECR Repository

Before deploying infrastructure, you need to create the ECR repository and push an initial image:

1. Go to **Actions** → **Setup ECR Repository**
2. Click **Run workflow**
3. Select your environment (dev/staging/prod)
4. Wait for completion

This workflow will:
- ✅ Create ECR repository if it doesn't exist
- ✅ Setup lifecycle policies for image management
- ✅ Build and push initial Docker image
- ✅ Make the repository ready for Lambda deployment

### Step 2: Deploy Infrastructure

After ECR setup is complete:

1. Go to **Actions** → **Deploy Infrastructure**
2. Click **Run workflow**
3. Select:
   - **Action**: `apply`
   - **Environment**: Same as Step 1
4. Wait for completion

This workflow will:
- ✅ Validate Terraform configuration
- ✅ Check ECR repository exists
- ✅ Deploy all AWS infrastructure
- ✅ Create Lambda function using ECR image

### Step 3: Deploy Application Updates

For subsequent application updates:

1. **Automatic**: Push to `main` (prod) or `develop` (dev) branches
2. **Manual**: Go to **Actions** → **Build and Deploy Application**

This workflow will:
- ✅ Test and build application
- ✅ Build new Docker image
- ✅ Push to ECR
- ✅ Update Lambda function
- ✅ Test deployment

## 🧹 Cleanup and Destruction

### Regular Cleanup

For normal environment cleanup:

1. Go to **Actions** → **Cleanup Environment**
2. Click **Run workflow**
3. Select:
   - **Environment**: Environment to cleanup
   - **Cleanup Level**: 
     - `infrastructure-only`: Keeps ECR repository and images
     - `complete-cleanup`: Deletes everything including ECR

**Cleanup Levels:**

| Level | Infrastructure | ECR Repository | Use Case |
|-------|---------------|----------------|----------|
| Infrastructure Only | ✅ Destroyed | ❌ Preserved | Temporary infrastructure removal |
| Complete Cleanup | ✅ Destroyed | ✅ Deleted | Full environment removal |

### Emergency Cleanup

For stuck resources or emergency situations:

1. Go to **Actions** → **Emergency Cleanup**
2. Click **Run workflow**
3. Type `EMERGENCY-CLEANUP` in the confirmation field
4. Select environment

**⚠️ Warning**: Emergency cleanup forcefully deletes resources and may leave some resources requiring manual cleanup.

### Manual Cleanup Commands

If workflows fail, you can manually clean up:

```bash
# Delete Lambda function
aws lambda delete-function --function-name hello-world-lambda-dev-app --region ap-south-1

# Delete API Gateway (get API ID first)
aws apigatewayv2 get-apis --query "Items[?Name=='hello-world-lambda-dev-api'].ApiId" --output text
aws apigatewayv2 delete-api --api-id <API_ID>

# Delete ECR repository
aws ecr delete-repository --repository-name hello-world-lambda-dev-app --force --region ap-south-1

# Delete CloudWatch log groups
aws logs delete-log-group --log-group-name /aws/lambda/hello-world-lambda-dev-app
```

## 🔄 GitHub Actions Workflows

### Deployment Workflows

1. **Setup ECR Repository** (`ecr-setup.yml`)
   - **Trigger**: Manual workflow dispatch
   - **Purpose**: Create ECR repository and push initial image
   - **Run First**: Before any infrastructure deployment

2. **Deploy Infrastructure** (`infrastructure.yml`)
   - **Trigger**: Manual workflow dispatch
   - **Purpose**: Deploy/destroy AWS infrastructure with Terraform
   - **Prerequisites**: ECR repository must exist

3. **Build and Deploy Application** (`build-and-deploy.yml`)
   - **Trigger**: Push to main/develop, manual dispatch
   - **Purpose**: Build and deploy application updates
   - **Prerequisites**: Infrastructure must be deployed

### Cleanup Workflows

4. **Cleanup Environment** (`cleanup-environment.yml`)
   - **Trigger**: Manual workflow dispatch
   - **Purpose**: Controlled cleanup with options
   - **Options**: Infrastructure-only or complete cleanup

5. **Emergency Cleanup** (`emergency-cleanup.yml`)
   - **Trigger**: Manual workflow dispatch with confirmation
   - **Purpose**: Force delete stuck resources
   - **Use**: When normal cleanup fails

## 🏗️ Infrastructure Components

### Core AWS Resources

- **VPC**: Multi-AZ setup with public/private subnets
- **Lambda**: Container-based functions with VPC integration
- **API Gateway**: HTTP API for Lambda invocation
- **ECR**: Container registry for Docker images
- **CloudWatch**: Logging, monitoring, and alerting
- **X-Ray**: Distributed tracing

### Terraform Structure

```
terraform/
├── main.tf                 # Root configuration with S3 backend
├── variables.tf           # Variable definitions
├── outputs.tf            # Output values
├── modules/              # Reusable modules
│   ├── vpc/             # VPC and networking
│   ├── ecr/             # Container registry
│   ├── iam/             # IAM roles and policies
│   ├── lambda/          # Lambda functions
│   ├── api_gateway/     # API Gateway
│   └── cloudwatch/      # Monitoring
└── environments/        # Environment-specific configs
    ├── dev/
    ├── staging/
    └── prod/
```

## 📊 Monitoring

### CloudWatch Dashboards
- Lambda execution metrics (duration, errors, invocations)
- API Gateway performance metrics
- Custom alarms for error rates and performance

### X-Ray Tracing
- End-to-end request tracing
- Performance bottleneck identification
- Service dependency mapping

## 🔒 Security Features

- **OIDC Authentication**: No long-lived AWS credentials in GitHub
- **IAM Least Privilege**: Minimal required permissions
- **VPC Isolation**: Lambda functions in private subnets
- **Encryption**: S3 state encryption, CloudWatch logs encryption
- **Container Scanning**: ECR vulnerability scanning enabled

## 🌍 Multi-Environment Support

Each environment has:
- Separate Terraform state in S3
- Environment-specific variables
- Isolated AWS resources
- Independent CI/CD workflows

### Environment Configuration

| Environment | VPC CIDR | Lambda Memory | Timeout | Region |
|------------|----------|---------------|---------|---------|
| Dev | 10.0.0.0/16 | 256 MB | 15s | ap-south-1 |
| Staging | 10.1.0.0/16 | 512 MB | 30s | ap-south-1 |
| Production | 10.2.0.0/16 | 1024 MB | 60s | ap-south-1 |

## 🛠️ Local Development

### Run Application Locally
```bash
npm run dev
```

### Test Docker Container
```bash
docker build -t hello-world-lambda .
docker run -p 9000:8080 hello-world-lambda
```

### Terraform Commands
```bash
cd terraform

# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Plan changes
terraform plan -var-file=environments/dev/terraform.tfvars

# Apply changes
terraform apply -var-file=environments/dev/terraform.tfvars
```

## 🔧 Troubleshooting

### Common Issues

1. **ECR Repository Not Found**
   ```
   Error: Source image does not exist
   ```
   **Solution**: Run "Setup ECR Repository" workflow first

2. **Lambda Function Not Found**
   ```
   Error: Lambda function does not exist
   ```
   **Solution**: Run "Deploy Infrastructure" workflow first

3. **OIDC Authentication Issues**
   - Verify OIDC provider configuration in AWS
   - Check IAM role trust policy
   - Ensure correct role ARN in workflows

4. **Terraform State Issues**
   - Verify S3 bucket access permissions
   - Check state file path and region

5. **Stuck Resources**
   - Use "Emergency Cleanup" workflow
   - Check AWS console for manual cleanup needs

### Deployment Order

Always follow this order:
1. **Setup ECR Repository** (once per environment)
2. **Deploy Infrastructure** (when infrastructure changes)
3. **Build and Deploy Application** (for code updates)

### Cleanup Order

For complete environment removal:
1. **Cleanup Environment** (complete-cleanup option)
2. **Emergency Cleanup** (if regular cleanup fails)
3. **Manual verification** in AWS console

### Useful Commands

```bash
# Check Lambda logs
aws logs tail /aws/lambda/hello-world-lambda-dev-app --follow --region ap-south-1

# List ECR images
aws ecr list-images --repository-name hello-world-lambda-dev-app --region ap-south-1

# Test API Gateway
curl -X GET https://your-api-gateway-url.amazonaws.com/

# Check Lambda function
aws lambda get-function --function-name hello-world-lambda-dev-app --region ap-south-1

# List all resources for cleanup verification
aws lambda list-functions --query "Functions[?contains(FunctionName, 'hello-world-lambda-dev')]"
aws apigatewayv2 get-apis --query "Items[?contains(Name, 'hello-world-lambda-dev')]"
aws ecr describe-repositories --query "repositories[?contains(repositoryName, 'hello-world-lambda-dev')]"
```

## 📈 Monitoring & Alerts

### Key Metrics Monitored
- Lambda function errors and duration
- API Gateway latency and error rates
- ECR image vulnerabilities
- Cost optimization opportunities

### Automated Alerts
- High error rates (>5 errors in 5 minutes)
- High latency (>10 seconds average)
- Failed deployments

## 🔄 Complete Workflow Lifecycle

### 🚀 Setup (First Time)
```
1. Setup ECR Repository → 2. Deploy Infrastructure → 3. Build and Deploy
```

### 🔄 Development Cycle
```
Code Changes → Push to Branch → Auto Build and Deploy
```

### 🧹 Cleanup
```
Cleanup Environment (infrastructure-only) → Redeploy Infrastructure → Continue Development
```

### 🗑️ Complete Removal
```
Cleanup Environment (complete-cleanup) → Verify in AWS Console → Done
```

### 🚨 Emergency
```
Emergency Cleanup → Manual Verification → Regular Cleanup (if needed)
```

## 📚 Additional Resources

- [AWS Lambda Container Images](https://docs.aws.amazon.com/lambda/latest/dg/images-create.html)
- [GitHub OIDC with AWS](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.