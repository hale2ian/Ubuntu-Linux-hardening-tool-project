#!/bin/bash

# Filename: audit_generate.sh
# Title: Audit Report Generator 
# Description: Generates Lynis audit report and stores log.
# Author: Jean Ian Panganiban
# Date: 20250708

set -e

REPORT_DIR="$HOME/linux-hardening-tool/reports"
LOG_DIR="$HOME/linux-hardening-tool/logs"
mkdir -p "$REPORT_DIR"
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "=== Audit Report Generation Started at $(date) ==="

# Check if Lynis is installed
if ! command -v lynis >/dev/null 2>&1; then
    echo "[!] Lynis not found. Installing..."
    if [ -f /etc/debian_version ]; then
        sudo apt update
        sudo apt install -y lynis
    elif [ -f /etc/redhat-release ] || [ -f /etc/centos-release ]; then
        sudo dnf install -y lynis || sudo yum install -y lynis
    else
        echo "[!] Unsupported distribution. Install Lynis manually."
        exit 1
    fi
fi

# Prompt for scan type
read -p "Is this a pre-hardening or post-hardening scan? (pre/post): " SCAN_TYPE
SCAN_TYPE=$(echo "$SCAN_TYPE" | tr '[:upper:]' '[:lower:]')

if [ "$SCAN_TYPE" != "pre" ] && [ "$SCAN_TYPE" != "post" ]; then
    echo "[!] Invalid scan type. Use 'pre' or 'post'."
    exit 1
fi

REPORT_FILE="$REPORT_DIR/lynis_${SCAN_TYPE}_hardening_${TIMESTAMP}.txt"
LOG_FILE="$LOG_DIR/lynis_${SCAN_TYPE}_hardening_${TIMESTAMP}.log"

echo "[*] Running Lynis system audit..."
sudo lynis audit system --quiet --no-colors --logfile "$LOG_FILE" | tee "$REPORT_FILE"

# Extract and record hardening index
HARDENING_INDEX=$(grep -i "hardening_index" "$REPORT_FILE" | awk -F'=' '{print $2}')
echo "[*] Hardening Index recorded: $HARDENING_INDEX"

echo "=== Audit Report Generation Completed at $(date) ==="
echo "[*] Report saved to: $REPORT_FILE"
echo "[*] Lynis log saved to: $LOG_FILE"
