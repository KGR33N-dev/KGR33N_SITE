# =============================================================================
# OUTPUT VALUES
# =============================================================================

# -----------------------------------------------------------------------------
# AWS EC2
# -----------------------------------------------------------------------------

output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.k3s_server.id
}

output "ec2_public_ip" {
  description = "EC2 Elastic IP (static)"
  value       = aws_eip.k3s_server.public_ip
}

output "ec2_ssh_command" {
  description = "SSH command to connect to EC2"
  value       = "ssh -i ~/.ssh/kgr33n-deployer ubuntu@${aws_eip.k3s_server.public_ip}"
}

output "ec2_instance_type" {
  description = "EC2 instance type"
  value       = aws_instance.k3s_server.instance_type
}

# -----------------------------------------------------------------------------
# CLOUDFLARE / DNS
# -----------------------------------------------------------------------------

output "domain" {
  description = "Main domain"
  value       = var.domain
}

output "dns_records" {
  description = "Created DNS records"
  value = {
    root = cloudflare_record.root.hostname
    www  = cloudflare_record.www.hostname
  }
}

output "cloudflare_proxy_status" {
  description = "Cloudflare proxy (orange cloud) status"
  value       = var.cloudflare_proxy_enabled ? "enabled (DDoS protection + CDN active)" : "disabled (DNS only)"
}

# -----------------------------------------------------------------------------
# KUBECONFIG (for GitHub Actions)
# -----------------------------------------------------------------------------

output "kubeconfig_instructions" {
  description = "How to get kubeconfig for GitHub Actions"
  value       = <<-EOT
    
    To get KUBECONFIG for GitHub Actions, run on EC2:
    
    ssh ubuntu@${aws_eip.k3s_server.public_ip}
    sudo cat /etc/rancher/k3s/k3s.yaml | sed 's/127.0.0.1/${aws_eip.k3s_server.public_ip}/g' | base64 -w 0
    
    Then add to GitHub Secrets as: KUBECONFIG
  EOT
}

  EOT
}

# -----------------------------------------------------------------------------
# BACKUP CREDENTIALS
# -----------------------------------------------------------------------------

output "backup_bucket_name" {
  description = "S3 Bucket for backups"
  value       = aws_s3_bucket.backups.id
}

output "backup_aws_access_key" {
  description = "Access Key for backup bot"
  value       = aws_iam_access_key.backup_user.id
}

output "backup_aws_secret_key" {
  description = "Secret Key for backup bot"
  value       = aws_iam_access_key.backup_user.secret
  sensitive   = true
}

# -----------------------------------------------------------------------------
# NEXT STEPS
# -----------------------------------------------------------------------------

output "next_steps" {
  description = "Next steps after Terraform apply"
  value       = <<-EOT
    
    ✅ AWS EC2 + Cloudflare DNS configured successfully!
    
    ┌─────────────────────────────────────────────────────────────┐
    │                      DEPLOYMENT INFO                         │
    ├─────────────────────────────────────────────────────────────┤
    │  EC2 Public IP:  ${aws_eip.k3s_server.public_ip}                              
    │  Domain:         https://${var.domain}                       
    │  SSH:            ssh ubuntu@${aws_eip.k3s_server.public_ip}                   
    └─────────────────────────────────────────────────────────────┘
    
    Next steps:
    1. Wait ~5 min for EC2 user-data script to complete
    2. SSH and verify: ssh ubuntu@${aws_eip.k3s_server.public_ip}
    3. Check K3s: kubectl get nodes
    4. Get KUBECONFIG for GitHub (see kubeconfig_instructions output)
    5. Add secrets to GitHub repo
    6. Push to main → CI/CD will deploy!
    
    Your site will be available at: https://${var.domain}
  EOT
}

