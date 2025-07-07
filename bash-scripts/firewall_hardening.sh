#!/bin/bash

# Filename: firewall_hardening.sh
# Title: Firewall Hardening Module for Linux Hardening Tool
# Author: Jean Ian Panganiban
# Date: 20250630
# Description: Configures and enforces firewall rules for system hardening.

set -e

LOG_FILE="$HOME/linux-hardening-tool/logs/firewall_hardening_$(date +%Y%m%d_%H%M%S).log"

echo "=== Firewall Hardening Started at $(date) ===" | tee -a "$LOG_FILE"

# Define allowed services and ports
ALLOWED_TCP_PORTS=(2222 80 443)
# You may adjust ports depending on your server services
DEFAULT_POLICY="deny"

# Function to configure UFW
configure_ufw() {
    echo "[*] Configuring UFW..." | tee -a "$LOG_FILE"
    sudo ufw default "$DEFAULT_POLICY" incoming
    sudo ufw default allow outgoing

    for PORT in "${ALLOWED_TCP_PORTS[@]}";
		do
        echo "[*] Allowing TCP port $PORT..." | tee -a "$LOG_FILE"
        sudo ufw allow "$PORT"/tcp
    done

    echo "[*] Enabling UFW..." | tee -a "$LOG_FILE"
    sudo ufw --force enable
    sudo ufw reload

    echo "[*] UFW status:" | tee -a "$LOG_FILE"
    sudo ufw status verbose | tee -a "$LOG_FILE"
}

# Function to configure firewalld
configure_firewalld() {
    echo "[*] Configuring firewalld..." | tee -a "$LOG_FILE"
    sudo firewall-cmd --set-default-zone=public
    sudo firewall-cmd --set-log-denied=all

    for PORT in "${ALLOWED_TCP_PORTS[@]}"
	do
        echo "[*] Allowing TCP port $PORT..." | tee -a "$LOG_FILE"
        sudo firewall-cmd --permanent --add-port="$PORT"/tcp
    done

    echo "[*] Reloading firewalld..." | tee -a "$LOG_FILE"
    sudo firewall-cmd --reload

    echo "[*] firewalld active zones and rules:" | tee -a "$LOG_FILE"
    sudo firewall-cmd --list-all | tee -a "$LOG_FILE"
}

# Function to configure iptables (fallback)
configure_iptables() {
    echo "[*] Configuring iptables..." | tee -a "$LOG_FILE"
    sudo iptables -P INPUT DROP
    sudo iptables -P FORWARD DROP
    sudo iptables -P OUTPUT ACCEPT

    sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    sudo iptables -A INPUT -i lo -j ACCEPT

    for PORT in "${ALLOWED_TCP_PORTS[@]}"; do
        echo "[*] Allowing TCP port $PORT..." | tee -a "$LOG_FILE"
        sudo iptables -A INPUT -p tcp --dport "$PORT" -j ACCEPT
    done

    echo "[*] Saving iptables rules..." | tee -a "$LOG_FILE"
    sudo iptables-save | sudo tee /etc/iptables/rules.v4 > /dev/null
    echo "[*] iptables configuration applied." | tee -a "$LOG_FILE"
}

# Detect firewall tool and configure
if command -v ufw >/dev/null 2>&1; then
    configure_ufw
elif command -v firewall-cmd >/dev/null 2>&1; then
    configure_firewalld
elif command -v iptables >/dev/null 2>&1; then
    configure_iptables
else
    echo "[!] No supported firewall detected. Please configure manually." | tee -a "$LOG_FILE"
fi

echo "=== Firewall Hardening Completed at $(date) ===" | tee -a "$LOG_FILE"

exit 0
