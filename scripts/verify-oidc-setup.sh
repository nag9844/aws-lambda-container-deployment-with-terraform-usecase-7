#!/bin/bash

# Script to verify OIDC setup and permissions
# Usage: ./scripts/verify-oidc-setup.sh

set -e

# Configuration
ROLE_NAME="oidc-demo-role"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION="ap-south-1"

echo "🔍 Verifying OIDC setup..."
echo "Account ID: $AWS_ACCOUNT_ID"
echo "Role Name: $ROLE_NAME"
echo "Region: $AWS_REGION"
echo ""

# Check if OIDC provider exists
echo "1️⃣ Checking OIDC provider..."
if aws iam get-open-id-connect-provider --open-id-connect-provider-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com" >/dev/null 2>&1; then
    echo "✅ OIDC provider exists"
else
    echo "❌ OIDC provider not found"
    echo "💡 Create it with: aws iam create-open-id-connect-provider --url https://token.actions.githubusercontent.com --client-id-list sts.amazonaws.com --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1"
fi

# Check if role exists
echo ""
echo "2️⃣ Checking IAM role..."
if aws iam get-role --role-name "$ROLE_NAME" >/dev/null 2>&1; then
    echo "✅ Role exists: $ROLE_NAME"
    
    # Get role ARN
    ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query 'Role.Arn' --output text)
    echo "🔗 Role ARN: $ROLE_ARN"
    
    # Check attached policies
    echo ""
    echo "3️⃣ Checking attached policies..."
    ATTACHED_POLICIES=$(aws iam list-attached-role-policies --role-name "$ROLE_NAME" --query 'AttachedPolicies[].PolicyArn' --output text)
    
    if [ ! -z "$ATTACHED_POLICIES" ]; then
        echo "📋 Attached policies:"
        for policy_arn in $ATTACHED_POLICIES; do
            POLICY_NAME=$(echo $policy_arn | cut -d'/' -f2)
            echo "  - $POLICY_NAME ($policy_arn)"
        done
        
        # Check if AdministratorAccess is attached
        if echo "$ATTACHED_POLICIES" | grep -q "AdministratorAccess"; then
            echo "✅ AdministratorAccess policy is attached"
        else
            echo "⚠️ AdministratorAccess policy not found"
            echo "💡 Attach it with: aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AdministratorAccess"
        fi
    else
        echo "❌ No policies attached to role"
        echo "💡 Attach AdministratorAccess: aws iam attach-role-policy --role-name $ROLE_NAME --policy-arn arn:aws:iam::aws:policy/AdministratorAccess"
    fi
else
    echo "❌ Role not found: $ROLE_NAME"
    echo "💡 Create the role first"
fi

# Check ECR repository
echo ""
echo "4️⃣ Checking ECR repository..."
REPO_NAME="hello-world-lambda-hello-world"
if aws ecr describe-repositories --repository-names "$REPO_NAME" --region "$AWS_REGION" >/dev/null 2>&1; then
    ECR_URI=$(aws ecr describe-repositories --repository-names "$REPO_NAME" --region "$AWS_REGION" --query 'repositories[0].repositoryUri' --output text)
    echo "✅ ECR repository exists: $ECR_URI"
else
    echo "⚠️ ECR repository not found: $REPO_NAME"
    echo "💡 It will be created automatically during the first workflow run"
fi

# Test ECR login (if role has permissions)
echo ""
echo "5️⃣ Testing ECR access..."
if aws ecr get-login-password --region "$AWS_REGION" >/dev/null 2>&1; then
    echo "✅ ECR login successful"
else
    echo "❌ ECR login failed"
    echo "💡 Check if the role has ECR permissions"
fi

echo ""
echo "📋 Summary:"
echo "- OIDC Provider: $(aws iam get-open-id-connect-provider --open-id-connect-provider-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com" >/dev/null 2>&1 && echo "✅ Exists" || echo "❌ Missing")"
echo "- IAM Role: $(aws iam get-role --role-name "$ROLE_NAME" >/dev/null 2>&1 && echo "✅ Exists" || echo "❌ Missing")"
echo "- ECR Repository: $(aws ecr describe-repositories --repository-names "$REPO_NAME" --region "$AWS_REGION" >/dev/null 2>&1 && echo "✅ Exists" || echo "⚠️ Will be created")"

echo ""
echo "🔧 GitHub Secrets needed:"
echo "- No secrets required (ECR URI is determined automatically)"
echo ""
echo "📝 Workflow file should use:"
echo "role-to-assume: arn:aws:iam::${AWS_ACCOUNT_ID}:role/${ROLE_NAME}"