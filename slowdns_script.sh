#!/bin/bash

##############################################
# SLOW DNS - DNSTT Management System
# Version: 6.0.0 - Fixed & Working Edition
# Fixed based on official DNSTT documentation
# Official repo: https://www.bamsoftware.com/git/dnstt.git
##############################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Paths
INSTALL_DIR="/etc/dnstt"
SSH_DIR="/etc/slowdns"
USER_DB="$SSH_DIR/users.txt"
DNSTT_BIN="/usr/local/bin/dnstt-server"
DNSTT_SRC="/usr/local/src/dnstt"

# Create directories
mkdir -p "$INSTALL_DIR" "$SSH_DIR"
touch "$USER_DB"

#============================================
# DISPLAY FUNCTIONS
#============================================

show_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
  ███████╗██╗      ██████╗ ██╗    ██╗    ██████╗ ███╗   ███╗███████╗
  ██╔════╝██║     ██╔═══██╗██║    ██║    ██╔══██╗████╗ ████║██╔════╝
  ███████╗██║     ██║   ██║██║ █╗ ██║    ██║  ██║██╔████╔██║███████╗
  ╚════██║██║     ██║   ██║██║███╗██║    ██║  ██║██║╚██╔╝██║╚════██║
  ███████║███████╗╚██████╔╝╚███╔███╔╝    ██████╔╝██║ ╚═╝ ██║███████║
  ╚══════╝╚══════╝ ╚═════╝  ╚══╝╚══╝     ╚═════╝ ╚═╝     ╚═╝╚══════╝
EOF
    echo -e "${NC}"
    echo -e "${PURPLE}════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}        DNS Tunnel & SSH Management System v6.0.0 (Fixed)${NC}"
    echo -e "${PURPLE}════════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

press_enter() {
    echo ""
    read -p "Press Enter to continue..."
}

#============================================
# SYSTEM CHECKS
#============================================

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}✗ This script must be run as root${NC}"
        echo -e "${YELLOW}Please run: sudo bash $0${NC}"
        exit 1
    fi
}

check_os() {
    if [[ ! -f /etc/debian_version ]]; then
        echo -e "${RED}✗ This script only supports Debian/Ubuntu${NC}"
        exit 1
    fi
}

#============================================
# INSTALLATION FUNCTIONS
#============================================

install_dependencies() {
    echo -e "${YELLOW}📦 Installing dependencies...${NC}"
    
    export DEBIAN_FRONTEND=noninteractive
    
    apt-get update -qq > /dev/null 2>&1
    apt-get install -y -qq \
        wget \
        curl \
        git \
        build-essential \
        iptables \
        iptables-persistent \
        netfilter-persistent \
        ca-certificates \
        golang-go > /dev/null 2>&1
    
    echo -e "${GREEN}✅ Dependencies installed${NC}"
}

install_golang() {
    # Check if Go is installed
    if command -v go &> /dev/null; then
        GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
        echo -e "${GREEN}✅ Go $GO_VERSION already installed${NC}"
        
        # Check if version is sufficient (need 1.19+)
        MAJOR=$(echo "$GO_VERSION" | cut -d. -f1)
        MINOR=$(echo "$GO_VERSION" | cut -d. -f2)
        
        if [[ $MAJOR -ge 1 ]] && [[ $MINOR -ge 19 ]]; then
            return 0
        else
            echo -e "${YELLOW}⚠️  Go version too old, updating...${NC}"
        fi
    fi
    
    echo -e "${YELLOW}📦 Installing Go 1.21.5...${NC}"
    
    cd /tmp
    wget -q https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
    
    rm -rf /usr/local/go
    tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
    rm -f go1.21.5.linux-amd64.tar.gz
    
    # Add to PATH
    if ! grep -q "/usr/local/go/bin" /etc/profile; then
        cat >> /etc/profile << 'GOPATH'
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
GOPATH
    fi
    
    export PATH=$PATH:/usr/local/go/bin
    export GOPATH=$HOME/go
    
    echo -e "${GREEN}✅ Go $(go version | awk '{print $3}') installed${NC}"
}

build_dnstt() {
    echo -e "${YELLOW}🔨 Building DNSTT from official source...${NC}"
    
    # Remove old source
    rm -rf "$DNSTT_SRC"
    mkdir -p /usr/local/src
    
    cd /usr/local/src
    
    # Clone official repository
    echo -e "${CYAN}Cloning from official repository...${NC}"
    if ! git clone -q https://www.bamsoftware.com/git/dnstt.git; then
        echo -e "${YELLOW}Trying GitHub mirror...${NC}"
        git clone -q https://github.com/Mygod/dnstt.git || {
            echo -e "${RED}✗ Failed to clone repository${NC}"
            return 1
        }
    fi
    
    cd dnstt/dnstt-server
    
    # Set Go environment
    export PATH=$PATH:/usr/local/go/bin
    export GOPATH=$HOME/go
    export GO111MODULE=on
    
    # Build server
    echo -e "${CYAN}Building dnstt-server...${NC}"
    if ! go build -o "$DNSTT_BIN"; then
        echo -e "${RED}✗ Build failed${NC}"
        echo -e "${YELLOW}Trying with go mod download...${NC}"
        go mod download
        go build -o "$DNSTT_BIN" || {
            echo -e "${RED}✗ Build still failed${NC}"
            return 1
        }
    fi
    
    chmod +x "$DNSTT_BIN"
    
    # Verify binary
    if [[ ! -f "$DNSTT_BIN" ]]; then
        echo -e "${RED}✗ Binary not found after build${NC}"
        return 1
    fi
    
    # Test binary
    if ! "$DNSTT_BIN" -h > /dev/null 2>&1; then
        echo -e "${RED}✗ Binary test failed${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ DNSTT built successfully${NC}"
    cd ~
    return 0
}

#============================================
# FIREWALL CONFIGURATION
#============================================

configure_firewall() {
    echo -e "${YELLOW}🔥 Configuring firewall...${NC}"
    
    # Get network interface
    NET_INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)
    NET_INTERFACE=${NET_INTERFACE:-eth0}
    
    echo -e "${CYAN}Network interface: $NET_INTERFACE${NC}"
    
    # Save interface for later use
    echo "$NET_INTERFACE" > "$INSTALL_DIR/network_interface.txt"
    
    # Stop systemd-resolved if running (conflicts with port 53)
    if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
        echo -e "${YELLOW}⚠️  Stopping systemd-resolved (port 53 conflict)...${NC}"
        
        systemctl stop systemd-resolved
        systemctl disable systemd-resolved
        
        # Configure DNS manually
        rm -f /etc/resolv.conf
        cat > /etc/resolv.conf << 'RESOLVCONF'
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 1.1.1.1
RESOLVCONF
        
        chattr +i /etc/resolv.conf
    fi
    
    # Clear existing rules for port 5300
    iptables -D INPUT -p udp --dport 5300 -j ACCEPT 2>/dev/null || true
    iptables -t nat -D PREROUTING -i "$NET_INTERFACE" -p udp --dport 53 -j REDIRECT --to-ports 5300 2>/dev/null || true
    
    # Add new firewall rules
    echo -e "${CYAN}Adding iptables rules...${NC}"
    iptables -I INPUT -p udp --dport 5300 -j ACCEPT
    iptables -I INPUT -p tcp --dport 22 -j ACCEPT
    iptables -I INPUT -p tcp --dport 443 -j ACCEPT
    
    # NAT rule: forward port 53 -> 5300
    iptables -t nat -I PREROUTING -i "$NET_INTERFACE" -p udp --dport 53 -j REDIRECT --to-ports 5300
    
    # Save rules persistently
    if command -v netfilter-persistent &> /dev/null; then
        netfilter-persistent save > /dev/null 2>&1 || true
    fi
    
    if command -v iptables-save &> /dev/null; then
        iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
    fi
    
    echo -e "${GREEN}✅ Firewall configured${NC}"
}

#============================================
# DNSTT SETUP
#============================================

generate_keys() {
    echo -e "${YELLOW}🔑 Generating encryption keys...${NC}"
    
    cd "$INSTALL_DIR"
    
    # Remove old keys
    rm -f server.key server.pub
    
    # Generate new keys using correct command
    if ! "$DNSTT_BIN" -gen-key -privkey-file server.key -pubkey-file server.pub; then
        echo -e "${RED}✗ Key generation failed${NC}"
        return 1
    fi
    
    # Verify keys were created
    if [[ ! -f "server.key" ]] || [[ ! -f "server.pub" ]]; then
        echo -e "${RED}✗ Key files not created${NC}"
        return 1
    fi
    
    # Set proper permissions
    chmod 600 server.key
    chmod 644 server.pub
    
    echo -e "${GREEN}✅ Keys generated successfully${NC}"
    return 0
}

create_service() {
    local tunnel_domain=$1
    local mtu=$2
    local ssh_port=$3
    
    echo -e "${YELLOW}📋 Creating systemd service...${NC}"
    
    # Build the ExecStart command based on MTU
    EXEC_CMD="$DNSTT_BIN -udp :5300 -privkey-file $INSTALL_DIR/server.key"
    
    # Add MTU parameter if not default
    if [[ "$mtu" != "1232" ]]; then
        EXEC_CMD="$EXEC_CMD -mtu $mtu"
    fi
    
    EXEC_CMD="$EXEC_CMD $tunnel_domain 127.0.0.1:$ssh_port"
    
    cat > /etc/systemd/system/dnstt.service << SERVICE
[Unit]
Description=DNSTT DNS Tunnel Server
Documentation=https://www.bamsoftware.com/software/dnstt/
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR
ExecStart=$EXEC_CMD
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=dnstt

# Security hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$INSTALL_DIR

[Install]
WantedBy=multi-user.target
SERVICE

    systemctl daemon-reload
    systemctl enable dnstt > /dev/null 2>&1
    
    echo -e "${GREEN}✅ Service created${NC}"
}

setup_dnstt() {
    show_banner
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    DNSTT INSTALLATION                      ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Check if already installed
    if systemctl is-active --quiet dnstt 2>/dev/null; then
        echo -e "${YELLOW}⚠️  DNSTT is already running${NC}"
        echo ""
        read -p "Do you want to reinstall? (y/n): " reinstall
        if [[ "$reinstall" != "y" ]]; then
            return
        fi
        systemctl stop dnstt
    fi
    
    echo -e "${CYAN}Starting installation...${NC}"
    echo ""
    
    # Install components
    install_dependencies || { echo -e "${RED}Failed to install dependencies${NC}"; press_enter; return 1; }
    install_golang || { echo -e "${RED}Failed to install Go${NC}"; press_enter; return 1; }
    build_dnstt || { echo -e "${RED}Failed to build DNSTT${NC}"; press_enter; return 1; }
    configure_firewall
    
    echo ""
    echo -e "${CYAN}────────────────────────────────────────────────────────────${NC}"
    echo -e "${YELLOW}                    DOMAIN CONFIGURATION${NC}"
    echo -e "${CYAN}────────────────────────────────────────────────────────────${NC}"
    echo ""
    echo -e "${WHITE}Important: You need TWO DNS records:${NC}"
    echo -e "${CYAN}  1. A record:  ns.yourdomain.com -> SERVER_IP${NC}"
    echo -e "${CYAN}  2. NS record: t.yourdomain.com -> ns.yourdomain.com${NC}"
    echo ""
    echo -e "${WHITE}Enter your nameserver domain (ns):${NC}"
    echo -e "${CYAN}Example: ns.voltran.online${NC}"
    echo ""
    read -p "Nameserver domain: " ns_domain
    
    if [[ -z "$ns_domain" ]]; then
        echo -e "${RED}✗ Domain cannot be empty${NC}"
        press_enter
        return 1
    fi
    
    # Extract main domain
    main_domain=$(echo "$ns_domain" | awk -F. '{print $(NF-1)"."$NF}')
    
    echo ""
    echo -e "${WHITE}Enter tunnel subdomain (keep it short):${NC}"
    echo -e "${CYAN}Example: t (creates t.${main_domain})${NC}"
    echo -e "${YELLOW}💡 Shorter is better due to DNS message size limits${NC}"
    echo ""
    read -p "Tunnel subdomain [t]: " tunnel_sub
    tunnel_sub=${tunnel_sub:-t}
    
    # Create tunnel domain
    tunnel_domain="${tunnel_sub}.${main_domain}"
    
    # Validate domains
    if [[ ! "$ns_domain" =~ ^[a-zA-Z0-9.-]+$ ]] || [[ ! "$tunnel_domain" =~ ^[a-zA-Z0-9.-]+$ ]]; then
        echo -e "${RED}✗ Invalid domain format${NC}"
        press_enter
        return 1
    fi
    
    # Save configuration
    echo "$ns_domain" > "$INSTALL_DIR/ns_domain.txt"
    echo "$tunnel_domain" > "$INSTALL_DIR/tunnel_domain.txt"
    
    echo ""
    echo -e "${GREEN}✅ NS Domain: $ns_domain${NC}"
    echo -e "${GREEN}✅ Tunnel Domain: $tunnel_domain${NC}"
    
    # Generate keys
    echo ""
    generate_keys || { echo -e "${RED}Failed to generate keys${NC}"; press_enter; return 1; }
    
    echo ""
    echo -e "${CYAN}────────────────────────────────────────────────────────────${NC}"
    echo -e "${YELLOW}                    MTU CONFIGURATION${NC}"
    echo -e "${CYAN}────────────────────────────────────────────────────────────${NC}"
    echo ""
    echo -e "${WHITE}MTU controls DNS response size. Choose based on your resolver:${NC}"
    echo ""
    echo "  ${CYAN}1)${NC} 512   - Classic DNS (strict resolvers)"
    echo "  ${CYAN}2)${NC} 768   - Extended compatibility"
    echo "  ${CYAN}3)${NC} 1200  - Standard (good balance)"
    echo "  ${CYAN}4)${NC} 1232  - Default (recommended) ${GREEN}⭐${NC}"
    echo "  ${CYAN}5)${NC} 1280  - IPv6 safe"
    echo "  ${CYAN}6)${NC} Custom"
    echo ""
    echo -e "${YELLOW}💡 Use 512 for restrictive networks, 1232+ for public resolvers${NC}"
    echo ""
    read -p "Enter choice [1-6] (default 4): " mtu_choice
    
    case $mtu_choice in
        1) MTU=512 ;;
        2) MTU=768 ;;
        3) MTU=1200 ;;
        4|"") MTU=1232 ;;
        5) MTU=1280 ;;
        6)
            read -p "Enter custom MTU (256-1500): " custom_mtu
            if [[ $custom_mtu -ge 256 ]] && [[ $custom_mtu -le 1500 ]]; then
                MTU=$custom_mtu
            else
                echo -e "${YELLOW}Invalid MTU, using default 1232${NC}"
                MTU=1232
            fi
            ;;
        *) MTU=1232 ;;
    esac
    
    echo "$MTU" > "$INSTALL_DIR/mtu.txt"
    echo ""
    echo -e "${GREEN}✅ MTU set to: $MTU bytes${NC}"
    
    # Detect SSH port
    SSH_PORT=$(ss -tlnp 2>/dev/null | grep sshd | awk '{print $4}' | grep -oP ':\K\d+$' | head -1)
    SSH_PORT=${SSH_PORT:-22}
    echo "$SSH_PORT" > "$INSTALL_DIR/ssh_port.txt"
    
    echo ""
    echo -e "${CYAN}SSH Port detected: $SSH_PORT${NC}"
    
    # Create and start service
    echo ""
    create_service "$tunnel_domain" "$MTU" "$SSH_PORT"
    
    echo -e "${YELLOW}🚀 Starting DNSTT service...${NC}"
    systemctl start dnstt
    
    sleep 3
    
    # Check status
    if systemctl is-active --quiet dnstt; then
        echo -e "${GREEN}✅ DNSTT service started successfully!${NC}"
    else
        echo -e "${RED}✗ Service failed to start!${NC}"
        echo ""
        echo -e "${YELLOW}Service logs:${NC}"
        journalctl -u dnstt -n 30 --no-pager
        press_enter
        return 1
    fi
    
    # Get server info
    PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com 2>/dev/null || echo "YOUR_SERVER_IP")
    PUBKEY=$(cat "$INSTALL_DIR/server.pub")
    
    # Display connection info
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                  ✅ INSTALLATION COMPLETE! ✅                  ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}──────────────────── CONNECTION DETAILS ────────────────────${NC}"
    echo ""
    echo -e "${WHITE}🌐 Server IP:${NC}       ${YELLOW}$PUBLIC_IP${NC}"
    echo -e "${WHITE}🔗 NS Domain:${NC}       ${YELLOW}$ns_domain${NC}"
    echo -e "${WHITE}📡 Tunnel Domain:${NC}   ${YELLOW}$tunnel_domain${NC}"
    echo -e "${WHITE}🔑 Public Key:${NC}      ${YELLOW}$PUBKEY${NC}"
    echo -e "${WHITE}🚪 SSH Port:${NC}        ${YELLOW}$SSH_PORT${NC}"
    echo -e "${WHITE}📊 MTU:${NC}             ${YELLOW}$MTU bytes${NC}"
    echo ""
    echo -e "${CYAN}────────────────────────────────────────────────────────────${NC}"
    echo ""
    echo -e "${YELLOW}📋 DNS RECORDS (Add to your domain registrar):${NC}"
    echo ""
    echo -e "${GREEN}   A Record:${NC}"
    echo -e "${WHITE}   Name:  $ns_domain${NC}"
    echo -e "${WHITE}   Value: $PUBLIC_IP${NC}"
    echo ""
    echo -e "${GREEN}   NS Record:${NC}"
    echo -e "${WHITE}   Name:  $tunnel_domain${NC}"
    echo -e "${WHITE}   Value: $ns_domain${NC}"
    echo ""
    echo -e "${CYAN}────────────────────────────────────────────────────────────${NC}"
    echo ""
    echo -e "${YELLOW}📱 CLIENT CONNECTION COMMANDS:${NC}"
    echo ""
    
    if [[ $MTU -le 768 ]]; then
        echo -e "${CYAN}   # For low MTU - use UDP:${NC}"
        echo -e "${WHITE}   dnstt-client -udp 8.8.8.8:53 \\${NC}"
        echo -e "${WHITE}     -pubkey $PUBKEY \\${NC}"
        echo -e "${WHITE}     $tunnel_domain 127.0.0.1:8080${NC}"
        echo ""
        echo -e "${CYAN}   # Alternative with Cloudflare:${NC}"
        echo -e "${WHITE}   dnstt-client -udp 1.1.1.1:53 \\${NC}"
        echo -e "${WHITE}     -pubkey $PUBKEY \\${NC}"
        echo -e "${WHITE}     $tunnel_domain 127.0.0.1:8080${NC}"
    else
        echo -e "${CYAN}   # Recommended - DNS over HTTPS (DoH):${NC}"
        echo -e "${WHITE}   dnstt-client -doh https://cloudflare-dns.com/dns-query \\${NC}"
        echo -e "${WHITE}     -pubkey $PUBKEY \\${NC}"
        echo -e "${WHITE}     $tunnel_domain 127.0.0.1:8080${NC}"
        echo ""
        echo -e "${CYAN}   # Alternative resolvers:${NC}"
        echo -e "${WHITE}   -doh https://dns.google/dns-query${NC}"
        echo -e "${WHITE}   -dot dns.google:853${NC}"
        echo -e "${WHITE}   -udp 8.8.8.8:53${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}   # Then connect via SSH:${NC}"
    echo -e "${WHITE}   ssh user@127.0.0.1 -p 8080${NC}"
    echo ""
    echo -e "${CYAN}────────────────────────────────────────────────────────────${NC}"
    echo ""
    
    # Save to file
    cat > "$INSTALL_DIR/connection_info.txt" << INFO
╔═══════════════════════════════════════════════════════════╗
║              DNSTT CONNECTION INFORMATION                      ║
╚═══════════════════════════════════════════════════════════╝

Generated: $(date)

SERVER DETAILS:
===============
Server IP:       $PUBLIC_IP
NS Domain:       $ns_domain
Tunnel Domain:   $tunnel_domain
Public Key:      $PUBKEY
SSH Port:        $SSH_PORT
MTU:             $MTU bytes

DNS RECORDS:
============
A    $ns_domain       $PUBLIC_IP
NS   $tunnel_domain   $ns_domain

CLIENT COMMANDS:
================
INFO

    if [[ $MTU -le 768 ]]; then
        echo "dnstt-client -udp 8.8.8.8:53 -pubkey $PUBKEY $tunnel_domain 127.0.0.1:8080" >> "$INSTALL_DIR/connection_info.txt"
    else
        echo "dnstt-client -doh https://cloudflare-dns.com/dns-query -pubkey $PUBKEY $tunnel_domain 127.0.0.1:8080" >> "$INSTALL_DIR/connection_info.txt"
    fi
    
    echo "" >> "$INSTALL_DIR/connection_info.txt"
    echo "SSH Connection:" >> "$INSTALL_DIR/connection_info.txt"
    echo "ssh user@127.0.0.1 -p 8080" >> "$INSTALL_DIR/connection_info.txt"
    
    echo -e "${GREEN}📄 Connection details saved to: $INSTALL_DIR/connection_info.txt${NC}"
    
    press_enter
}

#============================================
# SSH USER MANAGEMENT
#============================================

add_ssh_user() {
    show_banner
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    ADD SSH USER                            ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    read -p "Enter username: " username
    
    if [[ -z "$username" ]]; then
        echo -e "${RED}✗ Username cannot be empty${NC}"
        press_enter
        return
    fi
    
    # Check if user exists
    if id "$username" &>/dev/null; then
        echo -e "${RED}✗ User already exists!${NC}"
        press_enter
        return
    fi
    
    read -sp "Enter password: " password
    echo ""
    
    if [[ -z "$password" ]]; then
        echo -e "${RED}✗ Password cannot be empty${NC}"
        press_enter
        return
    fi
    
    echo ""
    echo -e "${YELLOW}Select expiration period:${NC}"
    echo ""
    echo "  1) 1 Day"
    echo "  2) 7 Days"
    echo "  3) 30 Days"
    echo "  4) 90 Days"
    echo "  5) 1 Year"
    echo "  6) Custom"
    echo ""
    read -p "Choice [1-6]: " exp_choice
    
    case $exp_choice in
        1) days=1 ;;
        2) days=7 ;;
        3) days=30 ;;
        4) days=90 ;;
        5) days=365 ;;
        6)
            read -p "Enter days: " days
            days=${days:-30}
            ;;
        *) days=30 ;;
    esac
    
    read -p "Max connections (default 2): " max_conn
    max_conn=${max_conn:-2}
    
    # Create user
    useradd -m -s /bin/bash "$username" 2>/dev/null
    echo "$username:$password" | chpasswd
    
    # Set expiration
    exp_date=$(date -d "+$days days" +"%Y-%m-%d")
    chage -E "$exp_date" "$username"
    
    # Save to database
    echo "$username|$password|$exp_date|$max_conn|$(date +"%Y-%m-%d")" >> "$USER_DB"
    
    echo ""
    echo -e "${GREEN}✅ User created successfully!${NC}"
    echo ""
    echo -e "${WHITE}Username:       ${YELLOW}$username${NC}"
    echo -e "${WHITE}Password:       ${YELLOW}$password${NC}"
    echo -e "${WHITE}Expires:        ${YELLOW}$exp_date${NC}"
    echo -e "${WHITE}Max Connections:${YELLOW}$max_conn${NC}"
    
    press_enter
}

delete_ssh_user() {
    show_banner
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                   DELETE SSH USER                          ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    read -p "Enter username to delete: " username
    
    if ! id "$username" &>/dev/null; then
        echo -e "${RED}✗ User not found!${NC}"
        press_enter
        return
    fi
    
    echo ""
    read -p "Are you sure you want to delete user '$username'? (y/n): " confirm
    
    if [[ "$confirm" != "y" ]]; then
        echo -e "${YELLOW}Cancelled${NC}"
        press_enter
        return
    fi
    
    # Kill user processes
    pkill -u "$username" 2>/dev/null || true
    sleep 1
    
    # Delete user
    userdel -r "$username" 2>/dev/null || true
    
    # Remove from database
    sed -i "/^$username|/
