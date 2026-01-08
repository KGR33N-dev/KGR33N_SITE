# =============================================================================
# MAIN TERRAFORM CONFIGURATION
# =============================================================================
#
# This is the entry point for Terraform. Resources are organized in:
# - aws.tf       → EC2, VPC, Security Groups, EIP
# - cloudflare.tf → DNS records, SSL settings
# - variables.tf  → Input variables
# - outputs.tf    → Output values
#
# Usage:
#   1. Copy terraform.tfvars.example to terraform.tfvars
#   2. Fill in your values
#   3. terraform init
#   4. terraform plan
#   5. terraform apply
#
# =============================================================================

# Data source to verify Cloudflare zone exists
data "cloudflare_zone" "main" {
  zone_id = var.cloudflare_zone_id
}

# Locals for computed values
locals {
  full_domain = var.domain
  www_domain  = "www.${var.domain}"
  
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

