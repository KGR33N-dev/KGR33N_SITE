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

# Get public IP from AWS metadata service (works on EC2)
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 || echo "")
echo ">>> Detected public IP: $PUBLIC_IP"

# Install K3s with public IP in TLS SAN (for remote kubectl access)
if [ -n "$PUBLIC_IP" ]; then
    curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--tls-san $PUBLIC_IP --disable traefik --disable servicelb" sh -
else
    echo ">>> Warning: Could not detect public IP, installing without TLS SAN"
    curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik --disable servicelb" sh -
fi

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

# Install with hostPort (direct access on 80/443 without NodePort range issues)
helm install ingress-nginx ingress-nginx/ingress-nginx \
    --namespace ingress-nginx \
    --create-namespace \
    --set controller.hostPort.enabled=true \
    --set controller.service.type=ClusterIP \
    --set controller.config.use-gzip="true" \
    --set controller.config.gzip-level="6" \
    --set controller.config.proxy-body-size="50m" \
    --wait --timeout 180s

echo ">>> Nginx Ingress Controller installed!"

# -----------------------------------------------------------------------------
# GHCR AUTHENTICATION (for pulling private images)
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------
# AWS CLI INSTALLATION (For SSM Access)
# -----------------------------------------------------------------------------
echo ">>> Installing AWS CLI v2..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -q awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

# -----------------------------------------------------------------------------
# SECRETS MANAGEMENT (Fetch from SSM and create K8s secrets)
# -----------------------------------------------------------------------------
echo ">>> Fetching secrets from AWS SSM Parameter Store..."

# Get AWS Region
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | sed 's/.$//')

# Fetch parameters
DB_PASSWORD=$(aws ssm get-parameter --name "/${project_name}/secrets/db-password" --with-decryption --region $REGION --query "Parameter.Value" --output text)
SECRET_KEY=$(aws ssm get-parameter --name "/${project_name}/secrets/secret-key" --with-decryption --region $REGION --query "Parameter.Value" --output text)
GHCR_TOKEN=$(aws ssm get-parameter --name "/${project_name}/secrets/ghcr-token" --with-decryption --region $REGION --query "Parameter.Value" --output text)
GHCR_USERNAME=$(aws ssm get-parameter --name "/${project_name}/secrets/ghcr-username" --region $REGION --query "Parameter.Value" --output text)
RESEND_API_KEY=$(aws ssm get-parameter --name "/${project_name}/secrets/resend-api-key" --with-decryption --region $REGION --query "Parameter.Value" --output text)

echo ">>> Creating K8s namespace and secrets..."
kubectl create namespace ${project_name} --dry-run=client -o yaml | kubectl apply -f -

# Create app-secrets
kubectl create secret generic app-secrets \
    --namespace ${project_name} \
    --from-literal=database-url="postgresql://kgr33n:$DB_PASSWORD@postgres:5432/${project_name}_prod" \
    --from-literal=postgres-db="${project_name}_prod" \
    --from-literal=postgres-user="kgr33n" \
    --from-literal=postgres-password="$DB_PASSWORD" \
    --from-literal=secret-key="$SECRET_KEY" \
    --from-literal=resend-api-key="$RESEND_API_KEY" \
    --dry-run=client -o yaml | kubectl apply -f -

# Create ghcr-secret
kubectl create secret docker-registry ghcr-secret \
    --namespace ${project_name} \
    --docker-server=ghcr.io \
    --docker-username="$GHCR_USERNAME" \
    --docker-password="$GHCR_TOKEN" \
    --dry-run=client -o yaml | kubectl apply -f -

echo ">>> K8s secrets created successfully!"

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
