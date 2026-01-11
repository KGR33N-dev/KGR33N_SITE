#!/bin/bash
set -e

echo ">>> Checking for existing swap..."
if grep -q "swap" /etc/fstab; then
    echo "Swap already configured."
    exit 0
fi

echo ">>> Adding 2GB Swap file for stability on t3.micro..."
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

echo ">>> Tuning swap settings..."
# Swappiness 10 - prefer RAM, use swap only when necessary
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
# vfs_cache_pressure 50 - keep filesystem cache in RAM longer
echo 'vm.vfs_cache_pressure=50' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

echo ">>> Swap configuration complete!"
free -h
