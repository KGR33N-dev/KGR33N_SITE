# =============================================================================
# CLOUDFLARE DNS CONFIGURATION
# =============================================================================
# Automatically configures DNS to point to AWS EC2 Elastic IP
# =============================================================================

# Root domain - A record pointing to EC2 Elastic IP
resource "cloudflare_record" "root" {
  zone_id = var.cloudflare_zone_id
  name    = "@"
  value   = aws_eip.k3s_server.public_ip # <-- Uses AWS Elastic IP!
  type    = "A"
  ttl     = 1 # Auto (when proxied)
  proxied = var.cloudflare_proxy_enabled
  comment = "Managed by Terraform - points to AWS EC2"
}

# WWW subdomain - CNAME to root
resource "cloudflare_record" "www" {
  zone_id = var.cloudflare_zone_id
  name    = "www"
  value   = var.domain
  type    = "CNAME"
  ttl     = 1
  proxied = var.cloudflare_proxy_enabled
  comment = "Managed by Terraform - www subdomain"
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
resource "cloudflare_zone_settings_override" "ssl_settings" {
  zone_id = var.cloudflare_zone_id

  settings {
    # SSL Mode: Full (strict) - validates origin certificate
    ssl                      = "full"
    always_use_https         = "on"
    automatic_https_rewrites = "on"
    min_tls_version          = "1.2"
    
    # Security
    security_level = "medium"
    browser_check  = "on"
    
    # Performance
    minify {
      css  = "on"
      js   = "on"
      html = "on"
    }
    brotli = "on"
  }
}
