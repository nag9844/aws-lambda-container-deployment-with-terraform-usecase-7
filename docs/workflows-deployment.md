# Complete Workflow Deployment Guide

## Prerequisites

Before starting, ensure you have:

1. **AWS Account** with OIDC role configured
2. **GitHub Repository Variables** set:
   - `AWS_ROLE_ARN`: Your OIDC role ARN
3. **S3 Bucket** exists: `usecases-terraform-state-bucket` in `ap-south-1`

##  Deployment Sequence

### **Step 1: Create ECR Repository** 
**Workflow:** `deploy-ecr.yml`

```bash
gh workflow run deploy-ecr.yml \
  -f environment=dev \
  -f action=apply
```

**What it does:**
- Creates ECR repository for your container images
- Sets up lifecycle policies for image cleanup
- **Must be done first** - other workflows depend on this

---

### **Step 2: Build & Deploy Everything** 
**Workflow:** `build-deploy.yml` *(Recommended - All-in-One)*

```bash
gh workflow run build-deploy.yml \
  -f environment=dev \
  -f image_tag=v1.0.0
```

**What it does:**
- Builds Docker image from `src/` directory
- Pushes image to ECR repository
- Deploys complete infrastructure (VPC, Lambda, API Gateway)
- Runs deployment tests
- **This is your main deployment workflow**

---

### **Alternative: Separate Build & Infrastructure** 

If you prefer separate steps:

#### **Step 2a: Build & Push Image**
**Workflow:** `build-push.yml`

```bash
gh workflow run build-push.yml \
  -f environment=dev \
  -f image_tag=v1.0.0
```

#### **Step 2b: Deploy Infrastructure**
**Workflow:** `infrastructure.yml`

```bash
gh workflow run infrastructure.yml \
  -f environment=dev \
  -f action=apply
```

---

##  Workflow Summary

| Workflow | Purpose | When to Use |
|----------|---------|-------------|
| `deploy-ecr.yml` | Create ECR repository | **First time only** |
| `build-deploy.yml` | Complete deployment | **Main workflow** - builds + deploys |
| `build-push.yml` | Build image only | When you only want to update image |
| `infrastructure.yml` | Infrastructure only | When you only want to update infrastructure |
| `destroy-infrastructure.yml` | Cleanup resources | When you want to tear down |

---

##  Typical Development Workflow

### **Initial Setup (One Time)**
```bash
# 1. Create ECR repository
gh workflow run deploy-ecr.yml -f environment=dev -f action=apply

# 2. Deploy everything
gh workflow run build-deploy.yml -f environment=dev -f image_tag=v1.0.0
```

### **Regular Updates**
```bash
# Update code and deploy new version
gh workflow run build-deploy.yml -f environment=dev -f image_tag=v1.1.0
```

### **Code-Only Updates**
```bash
# Just update the container image
gh workflow run build-push.yml -f environment=dev -f image_tag=v1.1.1
```

### **Infrastructure-Only Updates**
```bash
# Just update infrastructure (after modifying Terraform)
gh workflow run infrastructure.yml -f environment=dev -f action=apply
```

---

##  Multi-Environment Deployment

### **Development**
```bash
gh workflow run build-deploy.yml -f environment=dev -f image_tag=latest
```

### **Staging**
```bash
# First create ECR for staging
gh workflow run deploy-ecr.yml -f environment=staging -f action=apply

# Then deploy
gh workflow run build-deploy.yml -f environment=staging -f image_tag=v1.0.0
```

### **Production**
```bash
# First create ECR for production
gh workflow run deploy-ecr.yml -f environment=prod -f action=apply

# Then deploy with specific version
gh workflow run build-deploy.yml -f environment=prod -f image_tag=v1.0.0
```

---

##  Cleanup

### **Destroy Infrastructure Only**
```bash
gh workflow run destroy-infrastructure.yml \
  -f environment=dev \
  -f confirm_destroy=DESTROY
```

### **Destroy Everything (Including ECR)**
```bash
gh workflow run destroy-infrastructure.yml \
  -f environment=dev \
  -f confirm_destroy=DESTROY \
  -f destroy_ecr=true
```

---

##  Monitoring Deployments

### **Check Workflow Status**
```bash
gh run list --workflow=build-deploy.yml
```

### **View Workflow Logs**
```bash
gh run view --log
```

### **Test Deployed Application**
After successful deployment, you'll get:
- **API Gateway URL**: `https://xxx.execute-api.ap-south-1.amazonaws.com/dev`
- **Lambda Function URL**: `https://xxx.lambda-url.ap-south-1.on.aws/`

---

##  Important Notes

1. **Always run ECR workflow first** for new environments
2. **Use `build-deploy.yml`** for most deployments (it's the complete workflow)
3. **Image tags** should be unique for proper versioning
4. **Environment names** must be: `dev`, `staging`, or `prod`
5. **S3 bucket** `usecases-terraform-state-bucket` must exist before running workflows

---

##  Troubleshooting

### **ECR Repository Not Found**
```bash
# Re-run ECR creation
gh workflow run deploy-ecr.yml -f environment=dev -f action=apply
```

### **Image Not Found**
```bash
# Check if image was pushed successfully
aws ecr list-images --repository-name hello-world-lambda-dev --region ap-south-1
```

### **Terraform State Issues**
```bash
# Verify S3 bucket exists and is accessible
aws s3 ls s3://usecases-terraform-state-bucket/
```

---

##  Quick Start Commands

For a complete fresh deployment:

```bash
# 1. Create ECR (one time)
gh workflow run deploy-ecr.yml -f environment=dev -f action=apply

# 2. Wait for ECR to complete, then deploy everything
gh workflow run build-deploy.yml -f environment=dev -f image_tag=v1.0.0

# 3. Test your deployment
curl https://YOUR_API_GATEWAY_URL/dev
```
