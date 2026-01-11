# =============================================================================
# AWS SSM PARAMETER STORE - SECRETS MANAGEMENT
# =============================================================================
# Stores secrets securely in AWS SSM, retrieved by EC2 user-data script
# =============================================================================

# Database password
resource "aws_ssm_parameter" "db_password" {
  name        = "/${var.project_name}/secrets/db-password"
  description = "PostgreSQL database password"
  type        = "SecureString"
  value       = var.db_password

  tags = {
    Environment = var.environment
  }
}

# JWT Secret Key
resource "aws_ssm_parameter" "secret_key" {
  name        = "/${var.project_name}/secrets/secret-key"
  description = "JWT secret key for authentication"
  type        = "SecureString"
  value       = var.secret_key

  tags = {
    Environment = var.environment
  }
}

# GitHub Container Registry PAT
resource "aws_ssm_parameter" "ghcr_token" {
  name        = "/${var.project_name}/secrets/ghcr-token"
  description = "GitHub PAT for pulling container images"
  type        = "SecureString"
  value       = var.ghcr_token

  tags = {
    Environment = var.environment
  }
}

# GitHub username for GHCR
resource "aws_ssm_parameter" "ghcr_username" {
  name        = "/${var.project_name}/secrets/ghcr-username"
  description = "GitHub username for GHCR"
  type        = "String"
  value       = var.ghcr_username

  tags = {
    Environment = var.environment
  }
}

# Resend API Key (optional - for email)
resource "aws_ssm_parameter" "resend_api_key" {
  name        = "/${var.project_name}/secrets/resend-api-key"
  description = "Resend API key for sending emails"
  type        = "SecureString"
  value       = var.resend_api_key != "" ? var.resend_api_key : "not-configured"

  tags = {
    Environment = var.environment
  }
}
