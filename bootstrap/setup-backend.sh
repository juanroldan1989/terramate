#!/bin/bash

# Terraform Backend Infrastructure Setup Script
# This script creates the S3 bucket and DynamoDB table needed for Terraform state management
# with security best practices applied

set -e  # Exit on any error

# Configuration
AWS_REGION="us-west-1"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="enterprise-terraform-state-${AWS_ACCOUNT_ID}-${AWS_REGION}"
ACCESS_LOGS_BUCKET="enterprise-terraform-state-access-logs-${AWS_ACCOUNT_ID}-${AWS_REGION}"
DYNAMODB_TABLE="enterprise-terraform-state-locks-${AWS_ACCOUNT_ID}"
ENVIRONMENT="dev"

# Function to create S3 bucket with proper location constraint
create_s3_bucket() {
  local bucket_name=$1
  local region=$2

  echo "Creating bucket: $bucket_name in region: $region"

  if [ "$region" == "us-east-1" ]; then
    # us-east-1 is the default region and doesn't need LocationConstraint
    aws s3api create-bucket \
      --bucket "$bucket_name" \
      --region "$region"
  else
    # All other regions require explicit LocationConstraint
    aws s3api create-bucket \
      --bucket "$bucket_name" \
      --region "$region" \
      --create-bucket-configuration LocationConstraint="$region"
  fi
}

echo "🚀 Setting up Terraform backend infrastructure..."
echo "📍 Region: $AWS_REGION"
echo "🪣 Bucket: $BUCKET_NAME"
echo "📊 DynamoDB Table: $DYNAMODB_TABLE"
echo ""

# Create access logs bucket first
# This bucket stores detailed logs of every request to your state bucket
# Provides security auditing, compliance trails, and troubleshooting capabilities
echo "1️⃣ Creating access logs bucket..."
echo "   📝 This bucket will record all access to your Terraform state for security & compliance"
create_s3_bucket "$ACCESS_LOGS_BUCKET" "$AWS_REGION"

# Apply security settings to access logs bucket
echo "🔒 Securing access logs bucket..."
aws s3api put-bucket-encryption \
  --bucket "$ACCESS_LOGS_BUCKET" \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      },
      "BucketKeyEnabled": true
    }]
  }'

aws s3api put-public-access-block \
  --bucket "$ACCESS_LOGS_BUCKET" \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# Create main terraform state bucket
echo "2️⃣ Creating Terraform state bucket..."
create_s3_bucket "$BUCKET_NAME" "$AWS_REGION"

# Apply security and compliance settings
echo "🔒 Applying security settings to state bucket..."

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket "$BUCKET_NAME" \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      },
      "BucketKeyEnabled": true
    }]
  }'

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket "$BUCKET_NAME" \
  --versioning-configuration Status=Enabled

# Block all public access
aws s3api put-public-access-block \
  --bucket "$BUCKET_NAME" \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

# Enable access logging
# Records who, what, when, and where for every state bucket access
# Essential for security auditing and troubleshooting Terraform operations
echo "📊 Enabling access logging (audit trail for all state bucket operations)..."
aws s3api put-bucket-logging \
  --bucket "$BUCKET_NAME" \
  --bucket-logging-status '{
    "LoggingEnabled": {
      "TargetBucket": "'$ACCESS_LOGS_BUCKET'",
      "TargetPrefix": "terraform-state-access-logs/"
    }
  }'

# Apply lifecycle policy
aws s3api put-bucket-lifecycle-configuration \
  --bucket "$BUCKET_NAME" \
  --lifecycle-configuration '{
    "Rules": [
      {
        "ID": "StateFileRetention",
        "Status": "Enabled",
        "Filter": {"Prefix": ""},
        "NoncurrentVersionExpiration": {
          "NoncurrentDays": 90
        },
        "AbortIncompleteMultipartUpload": {
          "DaysAfterInitiation": 7
        }
      }
    ]
  }'

# Add bucket tags
aws s3api put-bucket-tagging \
  --bucket "$BUCKET_NAME" \
  --tagging '{
    "TagSet": [
      {"Key": "Name", "Value": "'$BUCKET_NAME'"},
      {"Key": "Purpose", "Value": "Terraform State Storage"},
      {"Key": "Environment", "Value": "'$ENVIRONMENT'"},
      {"Key": "ManagedBy", "Value": "Manual Setup"},
      {"Key": "Security", "Value": "High"},
      {"Key": "Project", "Value": "Terramate Integration"}
    ]
  }'

# Create DynamoDB table for state locking
echo "3️⃣ Creating DynamoDB table for state locking..."
aws dynamodb create-table \
  --table-name "$DYNAMODB_TABLE" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "$AWS_REGION" \
  --sse-specification Enabled=true \
  --tags Key=Name,Value="$DYNAMODB_TABLE" \
         Key=Purpose,Value="Terraform State Locking" \
         Key=Environment,Value="$ENVIRONMENT" \
         Key=ManagedBy,Value="Manual Setup" \
         Key=Security,Value="High" \
         Key=Project,Value="Terramate Integration"

# Wait for table to be active
echo "⏳ Waiting for DynamoDB table to be active..."
aws dynamodb wait table-exists \
  --table-name "$DYNAMODB_TABLE" \
  --region "$AWS_REGION"

# Enable Point-in-Time Recovery
echo "🔄 Enabling Point-in-Time Recovery for DynamoDB table..."
aws dynamodb update-continuous-backups \
  --table-name "$DYNAMODB_TABLE" \
  --region "$AWS_REGION" \
  --point-in-time-recovery-specification PointInTimeRecoveryEnabled=true

# Enable deletion protection
echo "🛡️ Enabling deletion protection for DynamoDB table..."
aws dynamodb update-table \
  --table-name "$DYNAMODB_TABLE" \
  --region "$AWS_REGION" \
  --deletion-protection-enabled

echo ""
echo "✅ Terraform backend infrastructure created successfully!"
echo ""
echo "📋 Summary:"
echo "   S3 Bucket: $BUCKET_NAME"
echo "   S3 Access Logs: $ACCESS_LOGS_BUCKET (records all state bucket access for security)"
echo "   DynamoDB Table: $DYNAMODB_TABLE"
echo "   Region: $AWS_REGION"
echo ""
echo "🔧 Next steps:"
echo "   1. Update your terragrunt.hcl with the correct bucket name"
echo "   2. Create IAM role for Terramate with access to these resources"
echo "   3. Configure Terramate AWS integration with the IAM role"
echo ""
echo "⚠️  Security Notes:"
echo "   - Both S3 bucket and DynamoDB table have encryption enabled"
echo "   - S3 bucket has versioning and lifecycle policies"
echo "   - All public access is blocked"
echo "   - Access logging enabled (audit trail of who accessed state files)"
echo "   - DynamoDB has point-in-time recovery enabled"