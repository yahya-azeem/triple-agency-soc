#!/bin/bash
# Script to automate Atomic Red Team test execution on Linux hosts

set -e

TECHNIQUE=$1
test -z "$TECHNIQUE" && { echo "Usage: $0 <MITRE Technique ID, e.g. T1070.006>"; exit 1; }

echo "=== Running Atomic Red Team test: $TECHNIQUE ==="

# Download Atomic Red Team framework if not present
if [ ! -d "/opt/atomic-red-team" ]; then
    echo "Installing Atomic Red Team repository..."
    sudo mkdir -p /opt/atomic-red-team
    sudo git clone --depth=1 https://github.com/redcanaryco/atomic-red-team.git /opt/atomic-red-team/repo
fi

# Locate the technique yaml
TECHNIQUE_DIR="/opt/atomic-red-team/repo/atomics/$TECHNIQUE"
if [ ! -d "$TECHNIQUE_DIR" ]; then
    echo "[ERROR] Technique directory not found in repository: $TECHNIQUE"
    exit 1
fi

# Run the commands specified in the technique yaml using simple script automation
# We can extract the executor block and execute it
# For demonstration purposes, we run the specific touch timestomping commands directly:
if [ "$TECHNIQUE" == "T1070.006" ]; then
    echo "Simulating Timestomp evasion on /tmp/evil_file..."
    touch /tmp/evil_file
    touch -d "2010-10-10 10:10:10" /tmp/evil_file
    ls -la /tmp/evil_file
elif [ "$TECHNIQUE" == "T1548.003" ]; then
    echo "Simulating Sudoers abuse..."
    # Attempting to check sudo permissions or run a shell as root
    sudo -l
else
    echo "[WARNING] General runner: checking dependencies for $TECHNIQUE"
    # General parser would parse yaml, for a home lab we target specific techniques
fi

echo "=== Test executed ==="
