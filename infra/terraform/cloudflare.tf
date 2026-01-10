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
  value   = aws_eip.k3s_server.public_ip
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
resource "cloudflare_zone_settings_override" "ssl_settings" {
  zone_id = var.cloudflare_zone_id

  settings {
    # SSL Mode: Flexible - Encrypts User<->Cloudflare, but Cloudflare<->Origin is HTTP
    # Easier to set up as you don't need certs on K3s/EC2
    ssl                      = "flexible"
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
