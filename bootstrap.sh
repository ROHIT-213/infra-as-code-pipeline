#!/bin/bash
# -------------------------------------------------------
# Bootstrap Script - Creates S3 bucket and DynamoDB table
# for Terraform remote state management
# Run this ONCE before terraform init
# Usage: chmod +x bootstrap.sh && ./bootstrap.sh
# -------------------------------------------------------

set -e

BUCKET_NAME="infra-pipeline-terraform-state"
DYNAMODB_TABLE="infra-pipeline-terraform-locks"
REGION="ap-south-1"

echo "Creating S3 bucket for Terraform state..."
aws s3api create-bucket \                                       
  --bucket $BUCKET_NAME \
  --region $REGION \
  --create-bucket-configuration LocationConstraint=$REGION

echo "Enabling versioning on S3 bucket..."
aws s3api put-bucket-versioning \
  --bucket $BUCKET_NAME \
  --versioning-configuration Status=Enabled

echo "Enabling encryption on S3 bucket..."
aws s3api put-bucket-encryption \
  --bucket $BUCKET_NAME \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

echo "Blocking public access on S3 bucket..."
aws s3api put-public-access-block \
  --bucket $BUCKET_NAME \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

echo "Creating DynamoDB table for state locking..."
aws dynamodb create-table \
  --table-name $DYNAMODB_TABLE \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region $REGION

echo ""
echo "Bootstrap complete!"
echo "S3 Bucket  : $BUCKET_NAME"
echo "DynamoDB   : $DYNAMODB_TABLE"
echo "Region     : $REGION"
echo ""
echo "Now run terraform init in each environment:"
echo "  cd terraform/envs/dev     && terraform init"
echo "  cd terraform/envs/staging && terraform init"
echo "  cd terraform/envs/prod    && terraform init"
