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

## 🚀 Quick Start

### 1. Clone and Setup

```bash
git clone <repository-url>
cd hello-world-lambda
npm install
```

### 2. Configure Terraform Backend

The project uses an existing S3 bucket for Terraform state:
- **Bucket**: `usecases-terraform-state-bucket`
- **Key**: `usecase2/statefile.tfstate`
- **Region**: `ap-south-1`

### 3. Deploy Infrastructure

#### Using GitHub Actions (Recommended)

1. Go to **Actions** tab in your GitHub repository
2. Select **AWS infra** workflow
3. Click **Run workflow**
4. Choose:
   - **Action**: `apply` or `destroy`
   - **Environment**: `dev`, `staging`, or `prod`

#### Using Local Scripts

```bash
# Deploy to dev environment
./scripts/deploy-environment.sh dev apply

# Plan changes for staging
./scripts/deploy-environment.sh staging plan

# Destroy prod environment
./scripts/deploy-environment.sh prod destroy
```

### 4. Build and Deploy Application

The CI/CD pipeline automatically:
- Tests and builds the application
- Creates Docker images
- Pushes to ECR
- Updates Lambda functions

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

## 🔄 CI/CD Pipeline

### Infrastructure Workflow (`terraform.yml`)
- **Manual Trigger**: Workflow dispatch with environment and action selection
- **Lint & Security**: TFLint validation and formatting checks
- **OIDC Authentication**: Secure AWS access without long-lived credentials
- **Multi-Environment**: Support for dev, staging, and prod

### Application Workflow (`build-and-deploy.yml`)
- **Automated Triggers**: Push to main/develop branches
- **Testing**: Lint and build validation
- **Container Build**: Docker image creation and ECR push
- **Lambda Update**: Automatic function code updates

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

## 🔧 Troubleshooting

### Common Issues

1. **OIDC Authentication Issues**
   - Verify OIDC provider configuration in AWS
   - Check IAM role trust policy
   - Ensure correct role ARN in workflows

2. **Terraform State Issues**
   - Verify S3 bucket access permissions
   - Check state file path and region

3. **Lambda Container Issues**
   - Verify Dockerfile Lambda compatibility
   - Check ECR repository permissions

### Useful Commands

```bash
# Check Lambda logs
aws logs tail /aws/lambda/hello-world-lambda-dev-app --follow --region ap-south-1

# List ECR images
aws ecr list-images --repository-name hello-world-lambda-dev-app --region ap-south-1

# Test API Gateway
curl -X GET https://your-api-gateway-url.amazonaws.com/
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