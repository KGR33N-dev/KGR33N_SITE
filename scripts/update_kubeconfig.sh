#!/bin/bash
set -e

# Configuration
SERVER_IP="3.73.234.72"
SSH_KEY="~/.ssh/kgr33n-deployer"
REPO="KGR33N-dev/KGR33N_SITE"

echo ">>> Fetching K3s config from server..."
RAW_CONFIG=$(ssh -i $SSH_KEY ubuntu@$SERVER_IP "sudo cat /etc/rancher/k3s/k3s.yaml")

if [ -z "$RAW_CONFIG" ]; then
    echo "❌ Failed to fetch config. Is the server running and SSH key correct?"
    exit 1
fi

echo ">>> Processing config..."
# Replace localhost/127.0.0.1 with public IP
PROCESSED_CONFIG=$(echo "$RAW_CONFIG" | sed "s/127.0.0.1/$SERVER_IP/g")

# Encode to Base64 (as required by our CI/CD)
BASE64_CONFIG=$(echo "$PROCESSED_CONFIG" | base64 -w 0)

echo ">>> Updating GitHub Secret 'KUBECONFIG'..."
if command -v gh &> /dev/null; then
    echo "$BASE64_CONFIG" | gh secret set KUBECONFIG --repo $REPO
    echo "✅ GitHub Secret updated successfully!"
else
    echo "⚠️ GitHub CLI (gh) not found or not logged in."
    echo "   Please install it: https://cli.github.com/"
    echo "   Or update manually with this value:"
    echo ""
    echo "$BASE64_CONFIG"
fi
