#!/bin/bash

# Script to destroy existing AWS resources
# Usage: ./scripts/destroy-resources.sh [environment] [--force]

set -e

# Configuration
ENVIRONMENT=${1:-prod}
FORCE_FLAG=${2}
PROJECT_NAME="hello-world-lambda"
AWS_REGION=${AWS_REGION:-ap-south-1}

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    echo " Invalid environment. Use: dev, staging, or prod"
    exit 1
fi

echo "  Destroying resources for environment: $ENVIRONMENT"
echo "Project: $PROJECT_NAME"
echo "Region: $AWS_REGION"

# Warning message
if [[ "$FORCE_FLAG" != "--force" ]]; then
    echo ""
    echo "  WARNING: This will destroy ALL resources for the $ENVIRONMENT environment!"
    echo "This includes:"
    echo "  - Lambda functions"
    echo "  - API Gateway"
    echo "  - VPC and networking"
    echo "  - ECR repository (and all images)"
    echo "  - CloudWatch logs"
    echo "  - IAM roles and policies"
    echo ""
    read -p "Are you sure you want to continue? (type 'yes' to confirm): " -r
    if [[ ! $REPLY =~ ^yes$ ]]; then
        echo " Destruction cancelled."
        exit 1
    fi
fi

# Check if AWS CLI is configured
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo " AWS CLI not configured. Please run 'aws configure' first."
    exit 1
fi

echo " Checking for existing resources..."

# Function to check if resource exists
resource_exists() {
    local resource_type=$1
    local resource_name=$2
    
    case $resource_type in
        "lambda")
            aws lambda get-function --function-name "$resource_name" --region "$AWS_REGION" >/dev/null 2>&1
            ;;
        "api-gateway")
            aws apigateway get-rest-apis --query "items[?name=='$resource_name'].id" --output text --region "$AWS_REGION" | grep -q .
            ;;
        "ecr")
            aws ecr describe-repositories --repository-names "$resource_name" --region "$AWS_REGION" >/dev/null 2>&1
            ;;
        "iam-role")
            aws iam get-role --role-name "$resource_name" >/dev/null 2>&1
            ;;
        "iam-policy")
            aws iam get-policy --policy-arn "arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/$resource_name" >/dev/null 2>&1
            ;;
        "log-group")
            aws logs describe-log-groups --log-group-name-prefix "$resource_name" --region "$AWS_REGION" --query 'logGroups[0]' --output text | grep -q .
            ;;
        "vpc")
            aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$resource_name" --query 'Vpcs[0].VpcId' --output text --region "$AWS_REGION" | grep -q vpc-
            ;;
    esac
}

# Delete Lambda function
LAMBDA_NAME="${PROJECT_NAME}-${ENVIRONMENT}-hello-world"
if resource_exists "lambda" "$LAMBDA_NAME"; then
    echo "  Deleting Lambda function: $LAMBDA_NAME"
    aws lambda delete-function --function-name "$LAMBDA_NAME" --region "$AWS_REGION"
else
    echo "  Lambda function not found: $LAMBDA_NAME"
fi

# Delete API Gateway
API_NAME="${PROJECT_NAME}-${ENVIRONMENT}-api"
API_ID=$(aws apigateway get-rest-apis --query "items[?name=='$API_NAME'].id" --output text --region "$AWS_REGION" 2>/dev/null || echo "")
if [[ ! -z "$API_ID" && "$API_ID" != "None" ]]; then
    echo " Deleting API Gateway: $API_NAME (ID: $API_ID)"
    aws apigateway delete-rest-api --rest-api-id "$API_ID" --region "$AWS_REGION"
else
    echo " API Gateway not found: $API_NAME"
fi

# Delete ECR repository
ECR_REPO_NAME="${PROJECT_NAME}-hello-world"
if resource_exists "ecr" "$ECR_REPO_NAME"; then
    echo "  Deleting ECR repository: $ECR_REPO_NAME"
    aws ecr delete-repository --repository-name "$ECR_REPO_NAME" --force --region "$AWS_REGION"
else
    echo "  ECR repository not found: $ECR_REPO_NAME"
fi

# Delete CloudWatch Log Groups
echo "  Deleting CloudWatch log groups..."
LOG_GROUPS=(
    "/aws/lambda/${LAMBDA_NAME}"
    "/aws/apigateway/${PROJECT_NAME}-${ENVIRONMENT}"
)

for log_group in "${LOG_GROUPS[@]}"; do
    if aws logs describe-log-groups --log-group-name-prefix "$log_group" --region "$AWS_REGION" --query 'logGroups[0]' --output text 2>/dev/null | grep -q .; then
        echo "  Deleting log group: $log_group"
        aws logs delete-log-group --log-group-name "$log_group" --region "$AWS_REGION" || echo "     Could not delete log group: $log_group"
    else
        echo "   Log group not found: $log_group"
    fi
done

# Delete IAM roles and policies
echo "🗑️  Deleting IAM roles and policies..."
IAM_ROLES=(
    "${PROJECT_NAME}-${ENVIRONMENT}-lambda-role"
    "${PROJECT_NAME}-${ENVIRONMENT}-api-gateway-cloudwatch"
)

IAM_POLICIES=(
    "${PROJECT_NAME}-${ENVIRONMENT}-lambda-policy"
    "${PROJECT_NAME}-${ENVIRONMENT}-ecr-access"
)

# Detach and delete policies first
for policy_name in "${IAM_POLICIES[@]}"; do
    POLICY_ARN="arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/$policy_name"
    if resource_exists "iam-policy" "$policy_name"; then
        echo "  Detaching and deleting policy: $policy_name"
        
        # List entities attached to the policy
        ATTACHED_ROLES=$(aws iam list-entities-for-policy --policy-arn "$POLICY_ARN" --query 'PolicyRoles[].RoleName' --output text 2>/dev/null || echo "")
        
        # Detach from roles
        if [[ ! -z "$ATTACHED_ROLES" ]]; then
            for role in $ATTACHED_ROLES; do
                echo "    Detaching policy from role: $role"
                aws iam detach-role-policy --role-name "$role" --policy-arn "$POLICY_ARN" || echo "    Could not detach policy from role: $role"
            done
        fi
        
        # Delete the policy
        aws iam delete-policy --policy-arn "$POLICY_ARN" || echo "    Could not delete policy: $policy_name"
    else
        echo "  Policy not found: $policy_name"
    fi
done

# Delete roles
for role_name in "${IAM_ROLES[@]}"; do
    if resource_exists "iam-role" "$role_name"; then
        echo "  Deleting role: $role_name"
        
        # Detach AWS managed policies
        ATTACHED_POLICIES=$(aws iam list-attached-role-policies --role-name "$role_name" --query 'AttachedPolicies[].PolicyArn' --output text 2>/dev/null || echo "")
        if [[ ! -z "$ATTACHED_POLICIES" ]]; then
            for policy_arn in $ATTACHED_POLICIES; do
                echo "    Detaching AWS managed policy: $policy_arn"
                aws iam detach-role-policy --role-name "$role_name" --policy-arn "$policy_arn" || echo "    Could not detach policy: $policy_arn"
            done
        fi
        
        # Delete the role
        aws iam delete-role --role-name "$role_name" || echo "    Could not delete role: $role_name"
    else
        echo "  Role not found: $role_name"
    fi
done

# Delete VPC and related resources
VPC_NAME="${PROJECT_NAME}-${ENVIRONMENT}-vpc"
VPC_ID=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$VPC_NAME" --query 'Vpcs[0].VpcId' --output text --region "$AWS_REGION" 2>/dev/null || echo "None")

if [[ "$VPC_ID" != "None" && ! -z "$VPC_ID" ]]; then
    echo "Deleting VPC and related resources: $VPC_ID"
    
    # Delete NAT Gateways
    echo "  Deleting NAT Gateways..."
    NAT_GATEWAYS=$(aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=$VPC_ID" --query 'NatGateways[?State==`available`].NatGatewayId' --output text --region "$AWS_REGION" 2>/dev/null || echo "")
    for nat_id in $NAT_GATEWAYS; do
        if [[ ! -z "$nat_id" ]]; then
            echo "    Deleting NAT Gateway: $nat_id"
            aws ec2 delete-nat-gateway --nat-gateway-id "$nat_id" --region "$AWS_REGION"
        fi
    done
    
    # Wait for NAT Gateways to be deleted
    if [[ ! -z "$NAT_GATEWAYS" ]]; then
        echo "  Waiting for NAT Gateways to be deleted..."
        sleep 30
    fi
    
    # Delete Internet Gateway
    echo "  Deleting Internet Gateway..."
    IGW_ID=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query 'InternetGateways[0].InternetGatewayId' --output text --region "$AWS_REGION" 2>/dev/null || echo "None")
    if [[ "$IGW_ID" != "None" && ! -z "$IGW_ID" ]]; then
        aws ec2 detach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID" --region "$AWS_REGION"
        aws ec2 delete-internet-gateway --internet-gateway-id "$IGW_ID" --region "$AWS_REGION"
    fi
    
    # Delete subnets
    echo "  Deleting subnets..."
    SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[].SubnetId' --output text --region "$AWS_REGION" 2>/dev/null || echo "")
    for subnet_id in $SUBNET_IDS; do
        if [[ ! -z "$subnet_id" ]]; then
            echo "    Deleting subnet: $subnet_id"
            aws ec2 delete-subnet --subnet-id "$subnet_id" --region "$AWS_REGION" || echo "    Could not delete subnet: $subnet_id"
        fi
    done
    
    # Delete route tables (except main)
    echo "  Deleting route tables..."
    ROUTE_TABLE_IDS=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" --query 'RouteTables[?Associations[0].Main!=`true`].RouteTableId' --output text --region "$AWS_REGION" 2>/dev/null || echo "")
    for rt_id in $ROUTE_TABLE_IDS; do
        if [[ ! -z "$rt_id" ]]; then
            echo "    Deleting route table: $rt_id"
            aws ec2 delete-route-table --route-table-id "$rt_id" --region "$AWS_REGION" || echo "    Could not delete route table: $rt_id"
        fi
    done
    
    # Delete security groups (except default)
    echo "  Deleting security groups..."
    SECURITY_GROUP_IDS=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text --region "$AWS_REGION" 2>/dev/null || echo "")
    for sg_id in $SECURITY_GROUP_IDS; do
        if [[ ! -z "$sg_id" ]]; then
            echo "    Deleting security group: $sg_id"
            aws ec2 delete-security-group --group-id "$sg_id" --region "$AWS_REGION" || echo "    Could not delete security group: $sg_id"
        fi
    done
    
    # Release Elastic IPs
    echo "  Releasing Elastic IPs..."
    EIP_ALLOC_IDS=$(aws ec2 describe-addresses --filters "Name=domain,Values=vpc" --query 'Addresses[].AllocationId' --output text --region "$AWS_REGION" 2>/dev/null || echo "")
    for alloc_id in $EIP_ALLOC_IDS; do
        if [[ ! -z "$alloc_id" ]]; then
            echo "    Releasing EIP: $alloc_id"
            aws ec2 release-address --allocation-id "$alloc_id" --region "$AWS_REGION" || echo "    Could not release EIP: $alloc_id"
        fi
    done
    
    # Finally, delete the VPC
    echo "  Deleting VPC: $VPC_ID"
    aws ec2 delete-vpc --vpc-id "$VPC_ID" --region "$AWS_REGION" || echo "  Could not delete VPC: $VPC_ID"
else
    echo "VPC not found: $VPC_NAME"
fi

# Delete CloudWatch Dashboard
DASHBOARD_NAME="${PROJECT_NAME}-${ENVIRONMENT}-dashboard"
if aws cloudwatch get-dashboard --dashboard-name "$DASHBOARD_NAME" --region "$AWS_REGION" >/dev/null 2>&1; then
    echo "Deleting CloudWatch dashboard: $DASHBOARD_NAME"
    aws cloudwatch delete-dashboard --dashboard-name "$DASHBOARD_NAME" --region "$AWS_REGION"
else
    echo "ℹCloudWatch dashboard not found: $DASHBOARD_NAME"
fi

# Delete CloudWatch Alarms
echo "Deleting CloudWatch alarms..."
ALARM_NAMES=(
    "${PROJECT_NAME}-${ENVIRONMENT}-lambda-errors"
    "${PROJECT_NAME}-${ENVIRONMENT}-lambda-duration"
    "${PROJECT_NAME}-${ENVIRONMENT}-api-5xx-errors"
)

for alarm_name in "${ALARM_NAMES[@]}"; do
    if aws cloudwatch describe-alarms --alarm-names "$alarm_name" --region "$AWS_REGION" --query 'MetricAlarms[0]' --output text 2>/dev/null | grep -q .; then
        echo "  Deleting alarm: $alarm_name"
        aws cloudwatch delete-alarms --alarm-names "$alarm_name" --region "$AWS_REGION"
    else
        echo "Alarm not found: $alarm_name"
    fi
done

# Delete SNS Topic
SNS_TOPIC_NAME="${PROJECT_NAME}-${ENVIRONMENT}-alerts"
SNS_TOPIC_ARN=$(aws sns list-topics --region "$AWS_REGION" --query "Topics[?contains(TopicArn, '$SNS_TOPIC_NAME')].TopicArn" --output text 2>/dev/null || echo "")
if [[ ! -z "$SNS_TOPIC_ARN" ]]; then
    echo "Deleting SNS topic: $SNS_TOPIC_NAME"
    aws sns delete-topic --topic-arn "$SNS_TOPIC_ARN" --region "$AWS_REGION"
else
    echo "ℹSNS topic not found: $SNS_TOPIC_NAME"
fi

echo ""
echo "Resource destruction completed for environment: $ENVIRONMENT"
echo ""
echo "Summary:"
echo "  - Lambda functions: Deleted"
echo "  - API Gateway: Deleted"
echo "  - ECR repository: Deleted"
echo "  - VPC and networking: Deleted"
echo "  - IAM roles and policies: Deleted"
echo "  - CloudWatch resources: Deleted"
echo ""
echo "You can now run 'terraform apply' to create fresh resources."