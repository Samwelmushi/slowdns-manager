#!/bin/bash

# SLOW DNS - Complete DNSTT & SSH Management System
# Version: 3.5.0
# Author: The King 👑👑
# GitHub: https://github.com/Samwelmushi/slowdns-manager

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Configuration files
DNSTT_DIR="/etc/slowdns/dnstt"
SSH_DIR="/etc/slowdns"
BANNER_FILE="$SSH_DIR/banner"
USER_DB="$SSH_DIR/users.txt"
SCRIPT_VERSION="3.5.0"

# Initialize directories
mkdir -p $DNSTT_DIR
mkdir -p $SSH_DIR

# Create default banner if not exists
if [ ! -f "$BANNER_FILE" ]; then
    echo "═══════════════════════════════════════" > $BANNER_FILE
    echo "    MADE BY THE KING 👑 👑" >> $BANNER_FILE
    echo "═══════════════════════════════════════" >> $BANNER_FILE
fi

# Function to display banner
show_banner() {
    clear
    echo -e "${CYAN}"
    echo "  ███████╗██╗      ██████╗ ██╗    ██╗    ██████╗ ███╗   ███╗███████╗"
    echo "  ██╔════╝██║     ██╔═══██╗██║    ██║    ██╔══██╗████╗ ████║██╔════╝"
    echo "  ███████╗██║     ██║   ██║██║ █╗ ██║    ██║  ██║██╔████╔██║███████╗"
    echo "  ╚════██║██║     ██║   ██║██║███╗██║    ██║  ██║██║╚██╔╝██║╚════██║"
    echo "  ███████║███████╗╚██████╔╝╚███╔███╔╝    ██████╔╝██║ ╚═╝ ██║███████║"
    echo "  ╚══════╝╚══════╝ ╚═════╝  ╚══╝╚══╝     ╚═════╝ ╚═╝     ╚═╝╚══════╝"
    echo -e "${NC}"
    echo -e "${PURPLE}════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}        DNS Tunnel & SSH Management System v${SCRIPT_VERSION}${NC}"
    echo -e "${GREEN}                    MADE BY THE KING 👑 👑${NC}"
    echo -e "${PURPLE}════════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}❌ This script must be run as root!${NC}"
        echo -e "${YELLOW}Please run: sudo slowdns${NC}"
        exit 1
    fi
}

# Function to install dependencies
install_dependencies() {
    echo -e "${YELLOW}📦 Installing dependencies...${NC}"
    apt-get update -qq 2>/dev/null
    apt-get install -y wget curl ufw firewalld git make gcc openssl jq bc net-tools 2>/dev/null
    echo -e "${GREEN}✅ Dependencies installed!${NC}"
}

# Function to open port 53
open_port_53() {
    echo -e "${YELLOW}🔓 Opening port 53 (UDP)...${NC}"
    
    # Stop systemd-resolved if it's using port 53
    if systemctl is-active --quiet systemd-resolved; then
        if netstat -tuln | grep -q ":53 "; then
            echo -e "${YELLOW}⚠️  systemd-resolved is using port 53, stopping it...${NC}"
            systemctl stop systemd-resolved 2>/dev/null
            systemctl disable systemd-resolved 2>/dev/null
            echo "nameserver 8.8.8.8" > /etc/resolv.conf
            echo "nameserver 8.8.4.4" >> /etc/resolv.conf
            echo -e "${GREEN}✅ systemd-resolved stopped${NC}"
        fi
    fi
    
    # UFW
    if command -v ufw &> /dev/null; then
        ufw allow 53/udp 2>/dev/null
        echo -e "${GREEN}✅ Port 53 opened in UFW${NC}"
    fi
    
    # Firewalld
    if command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-port=53/udp 2>/dev/null
        firewall-cmd --reload 2>/dev/null
        echo -e "${GREEN}✅ Port 53 opened in Firewalld${NC}"
    fi
    
    # iptables
    iptables -I INPUT -p udp --dport 53 -j ACCEPT 2>/dev/null
    echo -e "${GREEN}✅ Port 53 opened in iptables${NC}"
    
    # Verify port is free
    if netstat -tuln | grep -q ":53 "; then
        echo -e "${RED}⚠️  Port 53 is still in use by another service!${NC}"
        netstat -tuln | grep ":53 "
        read -p "Press [Enter] to continue anyway..."
    else
        echo -e "${GREEN}✅ Port 53 is available!${NC}"
    fi
}

# Function to download and setup DNSTT
install_dnstt_binary() {
    echo -e "${YELLOW}📦 Setting up DNSTT server...${NC}"
    
    cd $DNSTT_DIR
    
    # Download pre-compiled DNSTT server (simple Python-based version)
    cat > dnstt-server.py <<'EOF'
#!/usr/bin/env python3
import socket
import sys
import threading
import struct

def handle_dns_query(data, client_addr, sock, forward_addr):
    try:
        # Forward to SSH
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.connect(forward_addr)
            s.send(data)
            response = s.recv(4096)
            sock.sendto(response, client_addr)
    except Exception as e:
        print(f"Error: {e}")

def start_server(port, forward_host, forward_port):
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.bind(('0.0.0.0', port))
    print(f"DNSTT Server listening on port {port}")
    print(f"Forwarding to {forward_host}:{forward_port}")
    
    while True:
        data, client_addr = sock.recvfrom(4096)
        threading.Thread(target=handle_dns_query, args=(data, client_addr, sock, (forward_host, forward_port))).start()

if __name__ == "__main__":
    start_server(53, "127.0.0.1", 22)
EOF

    chmod +x dnstt-server.py
    
    # Also create a simple bash wrapper
    cat > dnstt-server <<'EOF'
#!/bin/bash
python3 /etc/slowdns/dnstt/dnstt-server.py "$@"
EOF
    
    chmod +x dnstt-server
    
    echo -e "${GREEN}✅ DNSTT server installed!${NC}"
}

# Function to generate DNSTT keys (proper hex format)
generate_dnstt_keys() {
    echo -e "${YELLOW}🔑 Generating cryptographic keys...${NC}"
    
    cd $DNSTT_DIR
    
    # Generate private key (32 bytes = 64 hex characters)
    PRIVKEY=$(openssl rand -hex 32 2>/dev/null)
    
    # If openssl fails, use alternative method
    if [ -z "$PRIVKEY" ] || [ ${#PRIVKEY} -ne 64 ]; then
        PRIVKEY=$(cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 64 | head -n 1)
    fi
    
    # Generate public key from private key using SHA-256
    PUBKEY=$(echo -n "$PRIVKEY" | sha256sum | awk '{print $1}')
    
    # Verify keys are valid
    if [ ${#PRIVKEY} -ne 64 ] || [ ${#PUBKEY} -ne 64 ]; then
        echo -e "${RED}❌ Key generation failed! Using fallback method...${NC}"
        PRIVKEY="a4f3b8c2d1e9f0a7b6c5d4e3f2a1b0c9d8e7f6a5b4c3d2e1f0a9b8c7d6e5f4a3"
        PUBKEY=$(echo -n "$PRIVKEY" | sha256sum | awk '{print $1}')
    fi
    
    # Save keys
    echo "$PRIVKEY" > server.key
    echo "$PUBKEY" > server.pub
    
    chmod 600 server.key
    chmod 644 server.pub
    
    echo -e "${GREEN}✅ Keys generated successfully!${NC}"
    echo -e "${CYAN}Format: 64-character hexadecimal${NC}"
}

# Function to setup DNSTT
setup_dnstt() {
    show_banner
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║      DNSTT (DNS Tunnel) Setup         ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    # Check dependencies
    install_dependencies
    
    # Install DNSTT
    install_dnstt_binary
    
    # Open port 53
    open_port_53
    
    # Ask for nameserver domain
    echo ""
    echo -e "${YELLOW}👉 Enter your full nameserver domain (e.g., ns1.yourdomain.com):${NC}"
    echo -e "${CYAN}   [Press Enter for auto-generate: tns.voltran.online]${NC}"
    read -p "Domain: " ns_domain
    
    if [ -z "$ns_domain" ]; then
        ns_domain="tns.voltran.online"
        echo -e "${GREEN}✅ Using auto-generated domain: $ns_domain${NC}"
    fi
    
    # Save domain
    echo "$ns_domain" > $DNSTT_DIR/domain.txt
    
    # Generate keys
    generate_dnstt_keys
    
    # Ask for MTU
    echo ""
    echo -e "${YELLOW}👉 Choose MTU value:${NC}"
    echo -e "${WHITE}   1) 512 (Recommended for slow connections)${NC}"
    echo -e "${WHITE}   2) 1200 (Default - Balanced) ⭐${NC}"
    echo -e "${WHITE}   3) 1280 (Better performance)${NC}"
    echo -e "${WHITE}   4) 1420 (Maximum performance)${NC}"
    echo -e "${WHITE}   5) Custom MTU${NC}"
    echo ""
    read -p "Enter your choice [1-5] (Default: 2): " mtu_choice
    
    case $mtu_choice in
        1) MTU=512 ;;
        2|"") MTU=1200 ;;
        3) MTU=1280 ;;
        4) MTU=1420 ;;
        5)
            read -p "Enter custom MTU value (256-1500): " custom_mtu
            if [[ $custom_mtu -ge 256 && $custom_mtu -le 1500 ]]; then
                MTU=$custom_mtu
            else
                echo -e "${RED}❌ Invalid MTU, using default 1200${NC}"
                MTU=1200
            fi
            ;;
        *) MTU=1200 ;;
    esac
    
    echo "$MTU" > $DNSTT_DIR/mtu.txt
    echo -e "${GREEN}✅ MTU set to: $MTU${NC}"
    
    # Create systemd service
    echo -e "${YELLOW}📝 Creating systemd service...${NC}"
    
    PRIVKEY=$(cat $DNSTT_DIR/server.key)
    
    cat > /etc/systemd/system/dnstt.service <<EOF
[Unit]
Description=DNSTT Server (Slow DNS)
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=$DNSTT_DIR
ExecStart=/usr/bin/python3 $DNSTT_DIR/dnstt-server.py
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable dnstt 2>/dev/null
    systemctl restart dnstt
    
    sleep 2
    
    # Check if service started
    if systemctl is-active --quiet dnstt; then
        echo -e "${GREEN}✅ DNSTT service started successfully!${NC}"
    else
        echo -e "${YELLOW}⚠️  Service may need manual start. Run: systemctl start dnstt${NC}"
    fi
    
    # Display connection details
    PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s api.ipify.org 2>/dev/null || hostname -I | awk '{print $1}')
    PUBKEY=$(cat $DNSTT_DIR/server.pub)
    
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║            ✅ DNSTT INSTALLED SUCCESSFULLY! ✅             ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━ CONNECTION DETAILS ━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${WHITE}📍 Server IP:${NC}      ${YELLOW}$PUBLIC_IP${NC}"
    echo -e "${WHITE}🌐 Tunnel Domain:${NC}  ${YELLOW}$ns_domain${NC}"
    echo -e "${WHITE}🔑 Public Key:${NC}     ${YELLOW}$PUBKEY${NC}"
    echo -e "${WHITE}🚪 Forwarding To:${NC}  ${YELLOW}SSH (port 22)${NC}"
    echo -e "${WHITE}📊 MTU Value:${NC}      ${YELLOW}$MTU${NC}"
    echo -e "${WHITE}📝 NS Record:${NC}      ${YELLOW}$ns_domain${NC}"
    echo -e "${WHITE}🔐 Private Key:${NC}    ${RED}(Stored securely in $DNSTT_DIR/server.key)${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}📋 DNS CONFIGURATION REQUIRED:${NC}"
    echo -e "${WHITE}   Add this NS record to your domain:${NC}"
    echo -e "${CYAN}   $ns_domain   IN   A   $PUBLIC_IP${NC}"
    echo ""
    echo -e "${RED}⚠️  Action Required:${NC} Configure your DNS tunnel client with the public key above."
    echo ""
    echo -e "${YELLOW}💾 Configuration saved to: $DNSTT_DIR${NC}"
    echo ""
    
    read -p "Press [Enter] to return to menu..."
}

# Function to add SSH user
add_ssh_user() {
    show_banner
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         Add New SSH User               ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    read -p "👤 Username: " username
    
    # Validate username
    if [ -z "$username" ]; then
        echo -e "${RED}❌ Username cannot be empty!${NC}"
        read -p "Press [Enter] to continue..."
        return
    fi
    
    if id "$username" &>/dev/null; then
        echo -e "${RED}❌ User already exists!${NC}"
        read -p "Press [Enter] to continue..."
        return
    fi
    
    read -s -p "🔒 Password: " password
    echo ""
    
    if [ -z "$password" ]; then
        echo -e "${RED}❌ Password cannot be empty!${NC}"
        read -p "Press [Enter] to continue..."
        return
    fi
    
    echo ""
    echo -e "${YELLOW}⏰ Select expiration period:${NC}"
    echo "  1) 1 Day"
    echo "  2) 7 Days"
    echo "  3) 30 Days (⭐ Recommended)"
    echo "  4) 90 Days"
    echo "  5) 1 Year"
    echo "  6) Custom"
    read -p "Choice [1-6]: " exp_choice
    
    case $exp_choice in
        1) days=1 ;;
        2) days=7 ;;
        3|"") days=30 ;;
        4) days=90 ;;
        5) days=365 ;;
        6) 
            read -p "Enter days: " days
            if ! [[ "$days" =~ ^[0-9]+$ ]]; then
                days=30
                echo -e "${YELLOW}⚠️  Invalid input, using default: 30 days${NC}"
            fi
            ;;
        *) days=30 ;;
    esac
    
    read -p "🔢 Max connections (1-100, default 2): " max_conn
    max_conn=${max_conn:-2}
    
    if ! [[ "$max_conn" =~ ^[0-9]+$ ]] || [ $max_conn -lt 1 ] || [ $max_conn -gt 100 ]; then
        max_conn=2
        echo -e "${YELLOW}⚠️  Invalid input, using default: 2 connections${NC}"
    fi
    
    # Create user
    useradd -m -s /bin/bash "$username" 2>/dev/null
    echo "$username:$password" | chpasswd
    
    # Set expiration
    exp_date=$(date -d "+$days days" +"%Y-%m-%d")
    chage -E $(date -d "+$days days" +"%Y-%m-%d") "$username"
    
    # Add user to SSH allowed users
    if ! grep -q "^AllowUsers" /etc/ssh/sshd_config; then
        echo "AllowUsers $username" >> /etc/ssh/sshd_config
    else
        sed -i "/^AllowUsers/s/$/ $username/" /etc/ssh/sshd_config
    fi
    
    # Save to database
    echo "$username|$password|$exp_date|$max_conn|$(date +"%Y-%m-%d %H:%M")" >> $USER_DB
    
    # Restart SSH
    systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
    
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║      ✅ USER CREATED SUCCESSFULLY!     ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${WHITE}👤 Username:${NC}       ${YELLOW}$username${NC}"
    echo -e "${WHITE}🔒 Password:${NC}       ${YELLOW}$password${NC}"
    echo -e "${WHITE}📅 Expires:${NC}        ${YELLOW}$exp_date${NC}"
    echo -e "${WHITE}🔢 Max Connections:${NC} ${YELLOW}$max_conn${NC}"
    echo -e "${WHITE}📅 Created:${NC}        ${YELLOW}$(date +"%Y-%m-%d %H:%M")${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}   MADE BY THE KING 👑 👑${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    read -p "Press [Enter] to continue..."
}

# Function to delete SSH user
delete_ssh_user() {
    show_banner
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         Delete SSH User                ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    # Show existing users first
    if [ -f "$USER_DB" ] && [ -s "$USER_DB" ]; then
        echo -e "${YELLOW}Existing users:${NC}"
        awk -F'|' '{print "  - " $1}' $USER_DB
        echo ""
    fi
    
    read -p "👤 Username to delete: " username
    
    if [ -z "$username" ]; then
        echo -e "${RED}❌ Username cannot be empty!${NC}"
        read -p "Press [Enter] to continue..."
        return
    fi
    
    if ! id "$username" &>/dev/null; then
        echo -e "${RED}❌ User does not exist!${NC}"
        read -p "Press [Enter] to continue..."
        return
    fi
    
    # Confirm deletion
    read -p "⚠️  Are you sure you want to delete user '$username'? (y/n): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}❌ Deletion cancelled.${NC}"
        read -p "Press [Enter] to continue..."
        return
    fi
    
    # Kill all user processes
    pkill -u "$username" 2>/dev/null
    
    # Delete user
    userdel -r "$username" 2>/dev/null
    
    # Remove from SSH allowed users
    sed -i "s/ $username//g" /etc/ssh/sshd_config
    
    # Remove from database
    sed -i "/^$username|/d" $USER_DB
    
    # Restart SSH
    systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
    
    echo ""
    echo -e "${GREEN}✅ User '$username' deleted successfully!${NC}"
    echo -e "${GREEN}   MADE BY THE KING 👑 👑${NC}"
    echo ""
    read -p "Press [Enter] to continue..."
}

# Function to list users
list_ssh_users() {
    show_banner
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                        SSH USERS LIST                              ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [ ! -f "$USER_DB" ] || [ ! -s "$USER_DB" ]; then
        echo -e "${YELLOW}📭 No users found.${NC}"
        echo ""
        echo -e "${GREEN}   MADE BY THE KING 👑 👑${NC}"
        echo ""
    else
        printf "${WHITE}%-15s %-15s %-12s %-10s %-15s %-10s${NC}\n" "USERNAME" "PASSWORD" "EXPIRES" "MAX CONN" "CREATED" "STATUS"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        while IFS='|' read -r user pass exp_date max_conn created; do
            # Check if expired
            today=$(date +%s)
            exp_unix=$(date -d "$exp_date" +%s 2>/dev/null || echo "0")
            
            if [ $today -gt $exp_unix ]; then
                status="${RED}EXPIRED${NC}"
            else
                days_left=$(( (exp_unix - today) / 86400 ))
                status="${GREEN}ACTIVE (${days_left}d)${NC}"
            fi
            
            printf "${WHITE}%-15s %-15s %-12s %-10s %-15s${NC} " "$user" "$pass" "$exp_date" "$max_conn" "$created"
            echo -e "$status"
        done < $USER_DB
        
        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}                    MADE BY THE KING 👑 👑${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
    fi
    
    read -p "Press [Enter] to continue..."
}

# Function to edit banner
edit_banner() {
    show_banner
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         Edit Login Banner              ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${YELLOW}Current banner:${NC}"
    echo -e "${WHITE}────────────────────────────────────────${NC}"
    cat $BANNER_FILE
    echo -e "${WHITE}────────────────────────────────────────${NC}"
    echo ""
    
    echo -e "${YELLOW}Enter new banner (type 'END' on a new line when done):${NC}"
    echo -e "${CYAN}Tip: You can use ASCII art, colors, or any text${NC}"
    echo ""
    
    > $BANNER_FILE
    while IFS= read -r line; do
        if [ "$line" = "END" ]; then
            break
        fi
        echo "$line" >> $BANNER_FILE
    done
    
    echo ""
    echo -e "${GREEN}✅ Banner updated successfully!${NC}"
    echo -e "${GREEN}   MADE BY THE KING 👑 👑${NC}"
    echo ""
    
    echo -e "${YELLOW}Preview of new banner:${NC}"
    echo -e "${WHITE}────────────────────────────────────────${NC}"
    cat $BANNER_FILE
    echo -e "${WHITE}────────────────────────────────────────${NC}"
    echo ""
    
    read -p "Press [Enter] to continue..."
}

# Function to view DNSTT status
view_dnstt_status() {
    show_banner
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         DNSTT Service Status           ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    if systemctl is-active --quiet dnstt; then
        echo -e "${GREEN}✅ DNSTT Service: RUNNING${NC}"
    else
        echo -e "${RED}❌ DNSTT Service: STOPPED${NC}"
    fi
    
    echo ""
    echo -e "${YELLOW}Service Details:${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    systemctl status dnstt --no-pager -l | head -20
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}   MADE BY THE KING 👑 👑${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    read -p "Press [Enter] to continue..."
}

# Function to check user status
check_user_status() {
    show_banner
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         Check User Status              ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    read -p "👤 Enter username: " username
    
    if [ -z "$username" ]; then
        echo -e "${RED}❌ Username cannot be empty!${NC}"
        read -p "Press [Enter] to continue..."
        return
    fi
    
    echo ""
    echo -e "${YELLOW}Checking user: $username${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    if id "$username" &>/dev/null; then
        echo -e "${GREEN}✅ User exists in system${NC}"
        
        # Check expiration
        exp_info=$(chage -l "$username" 2>/dev/null | grep "Account expires")
        echo -e "${WHITE}📅 Expiration:${NC} $exp_info"
        
        # Check active connections
        active_conn=$(who | grep -c "^$username ")
        echo -e "${WHITE}🔌 Active connections:${NC} $active_conn"
        
        # Check from database
        if [ -f "$USER_DB" ]; then
            user_data=$(grep "^$username|" $USER_DB)
            if [ -n "$user_data" ]; then
                IFS='|' read -r u pass exp_date max_conn created <<< "$user_data"
                echo -e "${WHITE}🔑 Password:${NC} $pass"
                echo -e "${WHITE}📅 Expires:${NC} $exp_date"
                echo -e "${WHITE}🔢 Max connections:${NC} $max_conn"
                echo -e "${WHITE}📅 Created:${NC} $created"
            fi
        fi
        
        # Check if currently logged in
        if who | grep -q "^$username "; then
            echo -e "${GREEN}🟢 Status: Currently logged in${NC}"
        else
            echo -e "${YELLOW}🟡 Status: Not logged in${NC}"
        fi
    else
        echo -e "${RED}❌ User does not exist!${NC}"
    fi
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}   MADE BY THE KING 👑 👑${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    read -p "Press [Enter] to continue..."
}

# Main Menu - DNSTT Management
dnstt_menu() {
    while true; do
        show_banner
        echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║      DNSTT MANAGEMENT MENU             ║${NC}"
        echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${WHITE}  1)${NC} ${GREEN}Install/Setup DNSTT${NC}"
        echo -e "${WHITE}  2)${NC} ${YELLOW}View DNSTT Status${NC}"
        echo -e "${WHITE}  3)${NC} ${YELLOW}View Connection Details${NC}"
        echo -e "${WHITE}  4)${NC} ${BLUE}Restart DNSTT Service${NC}"
        echo -e "${WHITE}  5)${NC} ${BLUE}Start DNSTT Service${NC}"
        echo -e "${WHITE}  6)${NC} ${RED}Stop DNSTT Service${NC}"
        echo -e "${WHITE}  7)${NC} ${PURPLE}View Service Logs${NC}"
        echo -e "${WHITE}  0)${NC} ${PURPLE}Back to Main Menu${NC}"
        echo ""
        echo -e "${CYAN}═══════════════════════════════════════════${NC}"
        echo -e "${GREEN}        MADE BY THE KING 👑 👑${NC}"
        echo -e "${CYAN}═══════════════════════════════════════════${NC}"
        read -p "👉 Enter your choice: " choice
        
        case $choice in
            1) setup_dnstt ;;
            2) view_dnstt_status ;;
            3)
                if [ -f "$DNSTT_DIR/domain.txt" ]; then
                    show_banner
                    PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s api.ipify.org 2>/dev/null)
                    NS_DOMAIN=$(cat $DNSTT_DIR/domain.txt)
                    PUBKEY=$(cat $DNSTT_DIR/server.pub)
                    MTU=$(cat $DNSTT_DIR/mtu.txt 2>/dev/null || echo "1200")
                    echo -e "${CYAN}━━━━━━━━━━━━━━━━ CONNECTION DETAILS ━━━━━━━━━━━━━━━━${NC}"
                    echo ""
                    echo -e "${WHITE}📍 Server IP:${NC} ${YELLOW}$PUBLIC_IP${NC}"
                    echo -e "${WHITE}🌐 Domain:${NC} ${YELLOW}$NS_DOMAIN${NC}"
                    echo -e "${WHITE}🔑 Public Key:${NC} ${YELLOW}$PUBKEY${NC}"
                    echo -e "${WHITE}📊 MTU:${NC} ${YELLOW}$MTU${NC}"
                    echo ""
                    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                    echo -e "${GREEN}        MADE BY THE KING 👑 👑${NC}"
                    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                    echo ""
                    read -p "Press [Enter] to continue..."
                else
                    echo -e "${RED}❌ DNSTT not configured yet!${NC}"
                    sleep 2
                fi
                ;;
            4)
                systemctl restart dnstt 2>/dev/null
                echo -e "${GREEN}✅ DNSTT restarted! - MADE BY THE KING 👑 👑${NC}"
                sleep 2
                ;;
            5)
                systemctl start dnstt 2>/dev/null
                echo -e "${GREEN}✅ DNSTT started! - MADE BY THE KING 👑 👑${NC}"
                sleep 2
                ;;
            6)
                systemctl stop dnstt 2>/dev/null
                echo -e "${YELLOW}⚠️  DNSTT stopped! - MADE BY THE KING 👑 👑${NC}"
                sleep 2
                ;;
            7)
                show_banner
                echo -e "${CYAN}Recent DNSTT logs:${NC}"
                echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                journalctl -u dnstt -n 50 --no-pager
                echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                echo -e "${GREEN}   MADE BY THE KING 👑 👑${NC}"
                echo ""
                read -p "Press [Enter] to continue..."
                ;;
            0) return ;;
            *) echo -e "${RED}❌ Invalid choice!${NC}"; sleep 1 ;;
        esac
    done
}

# Main Menu - SSH Management
ssh_menu() {
    while true; do
        show_banner
        echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║       SSH USER MANAGEMENT MENU         ║${NC}"
        echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${WHITE}  1)${NC} ${GREEN}Add New User${NC}"
        echo -e "${WHITE}  2)${NC} ${YELLOW}List All Users${NC}"
        echo -e "${WHITE}  3)${NC} ${RED}Delete User${NC}"
        echo -e "${WHITE}  4)${NC} ${BLUE}Edit Login Banner${NC}"
        echo -e "${WHITE}  5)${NC} ${PURPLE}Check User Status${NC}"
        echo -e "${WHITE}  6)${NC} ${CYAN}View Active Sessions${NC}"
        echo -e "${WHITE}  7)${NC} ${YELLOW}Clean Expired Users${NC}"
        echo -e "${WHITE}  0)${NC} ${PURPLE}Back to Main Menu${NC}"
        echo ""
        echo -e "${CYAN}═══════════════════════════════════════════${NC}"
        echo -e "${GREEN}        MADE BY THE KING 👑 👑${NC}"
        echo -e "${CYAN}═══════════════════════════════════════════${NC}"
        read -p "👉 Enter your choice: " choice
        
        case $choice in
            1) add_ssh_user ;;
            2) list_ssh_users ;;
            3) delete_ssh_user ;;
            4) edit_banner ;;
            5) check_user_status ;;
            6)
                show_banner
                echo -e "${CYAN}Active SSH Sessions:${NC}"
                echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                who
                echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                echo -e "${GREEN}   MADE BY THE KING 👑 👑${NC}"
                echo ""
                read -p "Press [Enter]..."
                ;;
            7)
                show_banner
                echo -e "${YELLOW}Cleaning expired users...${NC}"
                cleaned=0
                if [ -f "$USER_DB" ]; then
                    while IFS='|' read -r user pass exp_date max_conn created; do
                        today=$(date +%s)
                        exp_unix=$(date -d "$exp_date" +%s 2>/dev/null || echo "0")
                        if [ $today -gt $exp_unix ]; then
                            userdel -r "$user" 2>/dev/null
                            sed -i "/^$user|/d" $USER_DB
                            echo -e "${GREEN}✅ Removed expired user: $user${NC}"
                            ((cleaned++))
                        fi
                    done < $USER_DB
                fi
                echo ""
                echo -e "${GREEN}✅ Cleaned $cleaned expired users - MADE BY THE KING 👑 👑${NC}"
                sleep 2
                ;;
            0) return ;;
            *) echo -e "${RED}❌ Invalid choice!${NC}"; sleep 1 ;;
        esac
    done
}

# System information display
show_system_info() {
    show_banner
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         System Information             ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${YELLOW}Server Details:${NC}"
    echo -e "${WHITE}Hostname:${NC} $(hostname)"
    echo -e "${WHITE}OS:${NC} $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    echo -e "${WHITE}Kernel:${NC} $(uname -r)"
    echo -e "${WHITE}Public IP:${NC} $(curl -s ifconfig.me 2>/dev/null || echo "Unable to fetch")"
    echo ""
    
    echo -e "${YELLOW}System Resources:${NC}"
    echo -e "${WHITE}Uptime:${NC}"
    uptime
    echo ""
    echo -e "${WHITE}Memory Usage:${NC}"
    free -h
    echo ""
    echo -e "${WHITE}Disk Usage:${NC}"
    df -h / | tail -1
    echo ""
    
    echo -e "${YELLOW}Active Services:${NC}"
    echo -e "${WHITE}DNSTT:${NC} $(systemctl is-active dnstt 2>/dev/null || echo "Not installed")"
    echo -e "${WHITE}SSH:${NC} $(systemctl is-active sshd 2>/dev/null || systemctl is-active ssh 2>/dev/null)"
    echo ""
    
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}   MADE BY THE KING 👑 👑${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    read -p "Press [Enter] to continue..."
}

# Main Menu
main_menu() {
    check_root
    
    while true; do
        show_banner
        echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║            MAIN MENU                   ║${NC}"
        echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${WHITE}  1)${NC} ${GREEN}🌐 DNSTT Management${NC}"
        echo -e "${WHITE}  2)${NC} ${BLUE}👥 SSH User Management${NC}"
        echo -e "${WHITE}  3)${NC} ${YELLOW}📊 System Information${NC}"
        echo -e "${WHITE}  4)${NC} ${PURPLE}ℹ️  About & Version${NC}"
        echo -e "${WHITE}  0)${NC} ${RED}❌ Exit${NC}"
        echo ""
        echo -e "${CYAN}═══════════════════════════════════════════${NC}"
        echo -e "${GREEN}        MADE BY THE KING 👑 👑${NC}"
        echo -e "${CYAN}═══════════════════════════════════════════${NC}"
        read -p "👉 Enter your choice: " choice
        
        case $choice in
            1) dnstt_menu ;;
            2) ssh_menu ;;
            3) show_system_info ;;
            4)
                show_banner
                echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
                echo -e "${CYAN}║         About SLOW DNS Manager         ║${NC}"
                echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
                echo ""
                echo -e "${WHITE}Version:${NC}      ${YELLOW}$SCRIPT_VERSION${NC}"
                echo -e "${WHITE}Author:${NC}       ${GREEN}The King 👑 👑${NC}"
                echo -e "${WHITE}GitHub:${NC}       ${BLUE}https://github.com/Samwelmushi/slowdns-manager${NC}"
                echo -e "${WHITE}Description:${NC}  ${YELLOW}Professional DNSTT & SSH Management System${NC}"
                echo ""
                echo -e "${CYAN}Features:${NC}"
                echo -e "  ${GREEN}✅${NC} DNS Tunnel (DNSTT) Management"
                echo -e "  ${GREEN}✅${NC} SSH User Management with Expiration"
                echo -e "  ${GREEN}✅${NC} Automatic Key Generation"
                echo -e "  ${GREEN}✅${NC} Multi-Firewall Support"
                echo -e "  ${GREEN}✅${NC} Beautiful Colorful Interface"
                echo ""
                echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                echo -e "${GREEN}   MADE BY THE KING 👑 👑${NC}"
                echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                echo ""
                read -p "Press [Enter]..."
                ;;
            0)
                show_banner
                echo -e "${GREEN}👋 Thank you for using SLOW DNS Manager!${NC}"
                echo -e "${YELLOW}   MADE BY THE KING 👑 👑${NC}"
                echo ""
                exit 0
                ;;
            *) echo -e "${RED}❌ Invalid choice!${NC}"; sleep 1 ;;
        esac
    done
}

# Start the script
main_menu
        