# =============================================================================
# TERRAFORM CONFIGURATION FOR KGR33N
# =============================================================================
# Providers:
# - AWS: EC2 instance, VPC, Security Groups
# - Cloudflare: DNS records, SSL settings
# =============================================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }

  # Remote backend for state (RECOMMENDED for production!)
  # Uncomment and configure for your setup
  # backend "s3" {
  #   bucket         = "kgr33n-terraform-state"
  #   key            = "kgr33n/terraform.tfstate"
  #   region         = "eu-central-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-locks"
  # }
}

# -----------------------------------------------------------------------------
# PROVIDERS
# -----------------------------------------------------------------------------

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

