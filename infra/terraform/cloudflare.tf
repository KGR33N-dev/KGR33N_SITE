# =============================================================================
# CLOUDFLARE DNS CONFIGURATION
# =============================================================================
# Automatically configures DNS to point to AWS EC2 Elastic IP
# =============================================================================

# Root domain - A record pointing to EC2 Elastic IP
resource "cloudflare_record" "root" {
  zone_id = var.cloudflare_zone_id
  name    = "@"
  content = aws_eip.k3s_server.public_ip # <-- Uses AWS Elastic IP!
  type    = "A"
  ttl     = 1 # Auto (when proxied)
  proxied = var.cloudflare_proxy_enabled
  comment = "Managed by Terraform - points to AWS EC2"
}

# WWW subdomain - A record to EC2 IP
resource "cloudflare_record" "www" {
  zone_id = var.cloudflare_zone_id
  name    = "www"
  content = aws_eip.k3s_server.public_ip
  type    = "A"
  ttl     = 1
  proxied = var.cloudflare_proxy_enabled
  comment = "Managed by Terraform - points to AWS EC2 Elastic IP"
}

# Optional: API subdomain (if you want api.kgr33n.com)
# resource "cloudflare_record" "api" {
#   zone_id = var.cloudflare_zone_id
#   name    = "api"
#   value   = var.vps_ip_address
#   type    = "A"
#   ttl     = 1
#   proxied = var.cloudflare_proxy_enabled
#   comment = "Managed by Terraform - API subdomain"
# }

# Cloudflare SSL/TLS Settings
# NOTE: Requires API token with Zone Settings:Edit permission
# Configure these manually in Cloudflare Dashboard if token doesn't have permissions
# resource "cloudflare_zone_settings_override" "ssl_settings" {
#   zone_id = var.cloudflare_zone_id
#
#   settings {
#     ssl                      = "flexible"
#     always_use_https         = "on"
#     automatic_https_rewrites = "on"
#     min_tls_version          = "1.2"
#     security_level = "medium"
#     browser_check  = "on"
#     minify {
#       css  = "on"
#       js   = "on"
#       html = "on"
#     }
#     brotli = "on"
#   }
# }
