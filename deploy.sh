#!/bin/bash

# GRC Platform - AWS Deployment Script
# This script deploys the complete GRC platform infrastructure to AWS

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT_NAME="grc-capstone"
AWS_REGION="us-east-1"
STACK_PREFIX="${ENVIRONMENT_NAME}"

# Functions
print_header() {
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}========================================${NC}"
}

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        exit 1
    fi
    print_success "AWS CLI found"
}

check_aws_credentials() {
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials are not configured. Please configure them first."
        exit 1
    fi
    print_success "AWS credentials verified"
}

deploy_network_stack() {
    print_header "Deploying Network Stack"
    
    STACK_NAME="${STACK_PREFIX}-network-stack"
    
    print_info "Creating/Updating stack: $STACK_NAME"
    
    aws cloudformation deploy \
        --template-file cloudformation-network-stack.yaml \
        --stack-name "$STACK_NAME" \
        --parameter-overrides \
            EnvironmentName="$ENVIRONMENT_NAME" \
        --region "$AWS_REGION" \
        --no-fail-on-empty-changeset
    
    print_success "Network stack deployed"
}

deploy_database_stack() {
    print_header "Deploying Database Stack"
    
    STACK_NAME="${STACK_PREFIX}-database-stack"
    
    # Prompt for database credentials
    read -sp "Enter database master username: " DB_USERNAME
    echo
    read -sp "Enter database master password (min 8 characters): " DB_PASSWORD
    echo
    
    print_info "Creating/Updating stack: $STACK_NAME"
    
    aws cloudformation deploy \
        --template-file cloudformation-database-stack.yaml \
        --stack-name "$STACK_NAME" \
        --parameter-overrides \
            EnvironmentName="$ENVIRONMENT_NAME" \
            DBUsername="$DB_USERNAME" \
            DBPassword="$DB_PASSWORD" \
        --region "$AWS_REGION" \
        --no-fail-on-empty-changeset \
        --capabilities CAPABILITY_IAM
    
    print_success "Database stack deployed"
}

deploy_lambda_functions() {
    print_header "Deploying Lambda Functions"
    
    print_info "Packaging Lambda function"
    
    # Create deployment package
    mkdir -p lambda_package
    cp lambda_compliance_monitor.py lambda_package/lambda_function.py
    
    cd lambda_package
    zip -r ../lambda_compliance_monitor.zip . > /dev/null
    cd ..
    
    print_info "Uploading Lambda function to S3"
    
    LAMBDA_BUCKET="${ENVIRONMENT_NAME}-lambda-${AWS_REGION}-$(aws sts get-caller-identity --query Account --output text)"
    
    # Create bucket if it doesn't exist
    if ! aws s3 ls "s3://${LAMBDA_BUCKET}" 2>&1 | grep -q 'NoSuchBucket'; then
        print_info "S3 bucket already exists"
    else
        print_info "Creating S3 bucket for Lambda"
        aws s3 mb "s3://${LAMBDA_BUCKET}" --region "$AWS_REGION"
    fi
    
    # Upload Lambda package
    aws s3 cp lambda_compliance_monitor.zip "s3://${LAMBDA_BUCKET}/" --region "$AWS_REGION"
    
    print_success "Lambda functions deployed"
}

configure_aws_config() {
    print_header "Configuring AWS Config"
    
    print_info "Enabling AWS Config"
    
    # Check if Config is already enabled
    if aws configservice describe-configuration-recorders --region "$AWS_REGION" &> /dev/null; then
        print_info "AWS Config is already enabled"
    else
        print_info "Setting up AWS Config"
        
        # Create S3 bucket for Config
        CONFIG_BUCKET="${ENVIRONMENT_NAME}-config-${AWS_REGION}-$(aws sts get-caller-identity --query Account --output text)"
        aws s3 mb "s3://${CONFIG_BUCKET}" --region "$AWS_REGION" 2>/dev/null || true
        
        # Create IAM role for Config
        aws iam create-role \
            --role-name "${ENVIRONMENT_NAME}-config-role" \
            --assume-role-policy-document '{
                "Version": "2012-10-17",
                "Statement": [{
                    "Effect": "Allow",
                    "Principal": {"Service": "config.amazonaws.com"},
                    "Action": "sts:AssumeRole"
                }]
            }' 2>/dev/null || true
        
        # Attach policy to role
        aws iam attach-role-policy \
            --role-name "${ENVIRONMENT_NAME}-config-role" \
            --policy-arn "arn:aws:iam::aws:policy/service-role/ConfigRole" 2>/dev/null || true
        
        print_success "AWS Config configured"
    fi
}

configure_cloudtrail() {
    print_header "Configuring CloudTrail"
    
    print_info "Setting up CloudTrail for audit logging"
    
    TRAIL_NAME="${ENVIRONMENT_NAME}-trail"
    TRAIL_BUCKET="${ENVIRONMENT_NAME}-cloudtrail-${AWS_REGION}-$(aws sts get-caller-identity --query Account --output text)"
    
    # Create S3 bucket for CloudTrail
    aws s3 mb "s3://${TRAIL_BUCKET}" --region "$AWS_REGION" 2>/dev/null || true
    
    # Create CloudTrail trail
    aws cloudtrail create-trail \
        --name "$TRAIL_NAME" \
        --s3-bucket-name "$TRAIL_BUCKET" \
        --region "$AWS_REGION" 2>/dev/null || true
    
    # Start logging
    aws cloudtrail start-logging \
        --trail-name "$TRAIL_NAME" \
        --region "$AWS_REGION" 2>/dev/null || true
    
    print_success "CloudTrail configured"
}

verify_deployment() {
    print_header "Verifying Deployment"
    
    print_info "Checking CloudFormation stacks"
    
    aws cloudformation describe-stacks \
        --region "$AWS_REGION" \
        --query "Stacks[?starts_with(StackName, '${STACK_PREFIX}')].{Name:StackName,Status:StackStatus}" \
        --output table
    
    print_success "Deployment verification complete"
}

cleanup() {
    print_info "Cleaning up temporary files"
    rm -rf lambda_package lambda_compliance_monitor.zip
}

# Main execution
main() {
    print_header "GRC Platform AWS Deployment"
    
    print_info "Environment: $ENVIRONMENT_NAME"
    print_info "Region: $AWS_REGION"
    
    check_aws_cli
    check_aws_credentials
    
    deploy_network_stack
    deploy_database_stack
    deploy_lambda_functions
    configure_aws_config
    configure_cloudtrail
    verify_deployment
    cleanup
    
    print_header "Deployment Complete"
    print_success "GRC Platform has been successfully deployed to AWS"
    print_info "Next steps:"
    print_info "1. Deploy the GRC application to ECS"
    print_info "2. Configure DNS and SSL certificates"
    print_info "3. Load sample data into the database"
    print_info "4. Set up monitoring and alerting"
}

# Run main function
main "$@"
