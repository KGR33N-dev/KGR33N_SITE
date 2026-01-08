#!/bin/bash
# =============================================================================
# EC2 USER DATA SCRIPT - K3s Setup for ${project_name}
# =============================================================================
# This script runs on first boot and:
# - Updates the system
# - Installs security tools
# - Installs K3s (without Traefik - we use Nginx Ingress)
# - Installs Helm
# - Sets up Nginx Ingress Controller
# =============================================================================

set -euo pipefail

# Logging
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo "=== Starting user-data script at $(date) ==="

# -----------------------------------------------------------------------------
# SYSTEM UPDATE & SECURITY
# -----------------------------------------------------------------------------
echo ">>> Updating system packages..."
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

echo ">>> Installing basic tools..."
apt-get install -y \
    curl \
    wget \
    git \
    htop \
    vim \
    unzip \
    jq \
    fail2ban \
    ufw

# -----------------------------------------------------------------------------
# FIREWALL SETUP
# -----------------------------------------------------------------------------
echo ">>> Configuring firewall..."
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment 'SSH'
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'
ufw allow 6443/tcp comment 'K3s API'
ufw --force enable

# -----------------------------------------------------------------------------
# K3s INSTALLATION
# -----------------------------------------------------------------------------
echo ">>> Installing K3s..."
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik --disable servicelb" sh -

# Wait for K3s to be ready
echo ">>> Waiting for K3s to be ready..."
sleep 30
until kubectl get nodes 2>/dev/null | grep -q "Ready"; do
    echo "Waiting for K3s..."
    sleep 10
done
echo ">>> K3s is ready!"

# Make kubectl accessible without sudo
mkdir -p /home/ubuntu/.kube
cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
chown -R ubuntu:ubuntu /home/ubuntu/.kube
chmod 600 /home/ubuntu/.kube/config

# Also set up for root
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# -----------------------------------------------------------------------------
# HELM INSTALLATION
# -----------------------------------------------------------------------------
echo ">>> Installing Helm..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# -----------------------------------------------------------------------------
# NGINX INGRESS CONTROLLER
# -----------------------------------------------------------------------------
echo ">>> Installing Nginx Ingress Controller..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Install with NodePort (direct access on 80/443)
helm install ingress-nginx ingress-nginx/ingress-nginx \
    --namespace ingress-nginx \
    --create-namespace \
    --set controller.service.type=NodePort \
    --set controller.service.nodePorts.http=80 \
    --set controller.service.nodePorts.https=443 \
    --set controller.config.use-gzip="true" \
    --set controller.config.gzip-level="6" \
    --set controller.config.proxy-body-size="50m" \
    --wait

echo ">>> Nginx Ingress Controller installed!"

# -----------------------------------------------------------------------------
# GHCR AUTHENTICATION (for pulling private images)
# -----------------------------------------------------------------------------
echo ">>> Creating namespace and placeholder for app..."
kubectl create namespace ${project_name} --dry-run=client -o yaml | kubectl apply -f -

# -----------------------------------------------------------------------------
# VERIFICATION
# -----------------------------------------------------------------------------
echo ">>> Verifying installation..."
kubectl get nodes
kubectl get pods -A
kubectl get svc -n ingress-nginx

# -----------------------------------------------------------------------------
# COMPLETION
# -----------------------------------------------------------------------------
echo "=== User-data script completed at $(date) ==="
echo "=== K3s cluster is ready for deployment! ==="

# Write completion marker
touch /var/log/user-data-complete
