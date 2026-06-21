#!/bin/bash
set -e

echo "=== Preparing Ubuntu VM for template generation ==="

# Update packages
sudo apt-get update
sudo apt-get upgrade -y

# Install QEMU Guest Agent (should be pre-installed, but verify)
sudo apt-get install -y qemu-guest-agent
sudo systemctl enable qemu-guest-agent

# Clean up cloud-init
sudo systemctl stop cloud-init || true
sudo rm -rf /var/lib/cloud/instances/*
sudo cloud-init clean --logs

# Clean apt cache
sudo apt-get autoremove -y
sudo apt-get clean

# Truncate machine-id (so cloned VMs generate unique IDs/IPs)
sudo truncate -s 0 /etc/machine-id
if [ -f /var/lib/dbus/machine-id ]; then
    sudo ln -fs /etc/machine-id /var/lib/dbus/machine-id
fi

# Clean up log files
sudo find /var/log -type f -exec truncate --size=0 {} \;

# Clear bash history
cat /dev/null > ~/.bash_history
history -c

echo "=== VM template preparation completed ==="
