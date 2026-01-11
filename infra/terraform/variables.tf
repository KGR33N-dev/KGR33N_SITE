# =============================================================================
# INPUT VARIABLES
# =============================================================================

# -----------------------------------------------------------------------------
# PROJECT
# -----------------------------------------------------------------------------

variable "project_name" {
  description = "Name of the project (used for resource naming)"
  type        = string
  default     = "kgr33n"
}

variable "environment" {
  description = "Environment name (production, staging, dev)"
  type        = string
  default     = "production"
}

# -----------------------------------------------------------------------------
# AWS
# -----------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "eu-central-1" # Frankfurt - good for EU
}

variable "ec2_instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro" # 2 vCPU, 1GB RAM - Free tier eligible!
  # Options:
  # t3.micro  - 2 vCPU, 1GB RAM  (Free tier, good for small projects)
  # t3.small  - 2 vCPU, 2GB RAM  (If you need more RAM)
  # t3.medium - 2 vCPU, 4GB RAM  (Production with high traffic)
}

variable "ec2_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 30
}

variable "ssh_public_key" {
  description = "SSH public key for EC2 access"
  type        = string
  # Generate with: ssh-keygen -t ed25519 -C "kgr33n-deployer"
  # Then paste the contents of ~/.ssh/id_ed25519.pub here
}

variable "ssh_allowed_cidr" {
  description = "CIDR blocks allowed to SSH (restrict to your IP!)"
  type        = list(string)
  default     = ["0.0.0.0/0"] # WARNING: Open to all - restrict in production!
  # Example: ["123.45.67.89/32"] - your IP only
}

# -----------------------------------------------------------------------------
# CLOUDFLARE
# -----------------------------------------------------------------------------

variable "cloudflare_api_token" {
  description = "Cloudflare API token with Zone:Edit permissions"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID for your domain"
  type        = string
}

variable "domain" {
  description = "Domain name"
  type        = string
  default     = "kgr33n.com"
}

variable "cloudflare_proxy_enabled" {
  description = "Enable Cloudflare proxy (orange cloud) for DDoS protection and CDN"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# APPLICATION SECRETS (stored in AWS SSM Parameter Store)
# -----------------------------------------------------------------------------

variable "db_password" {
  description = "PostgreSQL database password"
  type        = string
  sensitive   = true
}

variable "secret_key" {
  description = "JWT secret key for authentication (64+ chars recommended)"
  type        = string
  sensitive   = true
}

variable "ghcr_username" {
  description = "GitHub username for container registry"
  type        = string
  default     = "KGR33N-dev"
}

variable "ghcr_token" {
  description = "GitHub Personal Access Token with read:packages scope"
  type        = string
  sensitive   = true
}

variable "resend_api_key" {
  description = "Resend API key for sending emails (optional)"
  type        = string
  sensitive   = true
  default     = ""
}
