#!/bin/bash
# =============================================================================
# SETUP TERRAFORM REMOTE STATE BACKEND
# =============================================================================
#
# This script creates the S3 bucket and DynamoDB table required for 
# Terraform remote state storage.
#
# Run this ONCE before using remote state:
#   ./scripts/setup-terraform-backend.sh
#
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration - CHANGE THESE IF NEEDED
BUCKET_NAME="kgr33n-terraform-state"
TABLE_NAME="kgr33n-terraform-locks"
REGION="eu-central-1"

print_header() {
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║         TERRAFORM REMOTE STATE BACKEND SETUP                    ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Check AWS CLI
check_aws() {
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed!"
        echo "Install with: curl 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o 'awscliv2.zip'"
        exit 1
    fi
    
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials not configured!"
        echo "Run: aws configure"
        exit 1
    fi
    
    print_status "AWS CLI configured"
}

# Create S3 bucket
create_bucket() {
    echo ""
    echo -e "${BLUE}Creating S3 bucket: ${BUCKET_NAME}${NC}"
    
    # Check if bucket exists
    if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
        print_warn "Bucket already exists, skipping creation"
    else
        # Create bucket (with LocationConstraint for non-us-east-1)
        aws s3api create-bucket \
            --bucket "$BUCKET_NAME" \
            --region "$REGION" \
            --create-bucket-configuration LocationConstraint="$REGION"
        print_status "Bucket created"
    fi
    
    # Enable versioning
    aws s3api put-bucket-versioning \
        --bucket "$BUCKET_NAME" \
        --versioning-configuration Status=Enabled
    print_status "Versioning enabled"
    
    # Enable encryption
    aws s3api put-bucket-encryption \
        --bucket "$BUCKET_NAME" \
        --server-side-encryption-configuration \
        '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"},"BucketKeyEnabled":true}]}'
    print_status "Encryption enabled (AES-256)"
    
    # Block public access
    aws s3api put-public-access-block \
        --bucket "$BUCKET_NAME" \
        --public-access-block-configuration \
        "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
    print_status "Public access blocked"
}

# Create DynamoDB table
create_dynamodb_table() {
    echo ""
    echo -e "${BLUE}Creating DynamoDB table: ${TABLE_NAME}${NC}"
    
    # Check if table exists
    if aws dynamodb describe-table --table-name "$TABLE_NAME" --region "$REGION" &>/dev/null; then
        print_warn "Table already exists, skipping creation"
    else
        aws dynamodb create-table \
            --table-name "$TABLE_NAME" \
            --attribute-definitions AttributeName=LockID,AttributeType=S \
            --key-schema AttributeName=LockID,KeyType=HASH \
            --billing-mode PAY_PER_REQUEST \
            --region "$REGION"
        print_status "DynamoDB table created"
        
        # Wait for table to be active
        echo -n "  Waiting for table to be active"
        aws dynamodb wait table-exists --table-name "$TABLE_NAME" --region "$REGION"
        echo -e " ${GREEN}Ready${NC}"
    fi
}

# Show next steps
show_next_steps() {
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "  ${GREEN}✓ Terraform backend infrastructure created!${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "  Resources created:"
    echo "    📦 S3 Bucket:      s3://${BUCKET_NAME}"
    echo "    🔒 DynamoDB Table: ${TABLE_NAME}"
    echo ""
    echo "  Next steps:"
    echo ""
    echo "  1. Rename the backend config file:"
    echo "     cd infra/terraform"
    echo "     mv backend.tf.example backend.tf"
    echo ""
    echo "  2. Migrate existing state (if any):"
    echo "     terraform init -migrate-state"
    echo ""
    echo "  3. Verify:"
    echo "     terraform plan"
    echo ""
    echo "  Your state will now be stored securely in S3!"
    echo ""
}

# Main
main() {
    print_header
    check_aws
    create_bucket
    create_dynamodb_table
    show_next_steps
}

main
