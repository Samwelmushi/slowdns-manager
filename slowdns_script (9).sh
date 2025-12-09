#!/bin/bash

##############################################
# SLOW DNS - DNSTT Management System
# Version: 5.0.0 - Final Working Edition
# Made by The King 👑👑
# Tested and Verified Working
##############################################

# Exit on error
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

# Create directories
mkdir -p "$INSTALL_DIR" "$SSH_DIR"

# Initialize user database
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
    echo -e "${YELLOW}           DNS Tunnel & SSH Management System v5.0.0${NC}"
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
        echo -e "${RED}❌ This script must be run as root${NC}"
        echo -e "${YELLOW}Please run: sudo bash $0${NC}"
        exit 1
    fi
}

check_os() {
    if [[ ! -f /etc/debian_version ]]; then
        echo -e "${RED}❌ This script only supports Debian/Ubuntu${NC}"
        exit 1
    fi
}

#============================================
# INSTALLATION FUNCTIONS
#============================================

install_dependencies() {
    echo -e "${YELLOW}📦 Installing dependencies...${NC}"
    
    export DEBIAN_FRONTEND=noninteractive
    
    apt-get update -qq
    apt-get install -y -qq \
        wget \
        curl \
        git \
        build-essential \
        iptables \
        iptables-persistent \
        netfilter-persistent \
        ca-certificates
    
    echo -e "${GREEN}✅ Dependencies installed${NC}"
}

install_golang() {
    if command -v go &> /dev/null; then
        GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
        echo -e "${GREEN}✅ Go $GO_VERSION already installed${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}📦 Installing Go...${NC}"
    
    cd /tmp
    wget -q https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
    
    rm -rf /usr/local/go
    tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
    rm -f go1.21.5.linux-amd64.tar.gz
    
    # Add to PATH
    export PATH=$PATH:/usr/local/go/bin
    
    cat > /etc/profile.d/golang.sh << 'GOPATH'
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
GOPATH
    
    source /etc/profile.d/golang.sh
    
    echo -e "${GREEN}✅ Go $(go version | awk '{print $3}') installed${NC}"
}

build_dnstt() {
    echo -e "${YELLOW}🔨 Building DNSTT from source...${NC}"
    
    cd /tmp
    rm -rf dnstt
    
    # Clone repository
    if ! git clone -q https://github.com/tladesignz/dnstt.git; then
        echo -e "${RED}❌ Failed to clone repository${NC}"
        return 1
    fi
    
    cd dnstt/dnstt-server
    
    # Set Go paths
    export PATH=$PATH:/usr/local/go/bin
    export GOPATH=/root/go
    
    # Build
    if ! /usr/local/go/bin/go build -o "$DNSTT_BIN"; then
        echo -e "${RED}❌ Build failed${NC}"
        return 1
    fi
    
    chmod +x "$DNSTT_BIN"
    
    # Verify
    if [[ ! -f "$DNSTT_BIN" ]]; then
        echo -e "${RED}❌ Binary not found${NC}"
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
    
    # Stop systemd-resolved if running (conflicts with port 53)
    if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
        echo -e "${YELLOW}⚠️  Stopping systemd-resolved...${NC}"
        
        systemctl stop systemd-resolved
        systemctl disable systemd-resolved
        
        # Configure DNS
        rm -f /etc/resolv.conf
        cat > /etc/resolv.conf << 'RESOLVCONF'
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 1.1.1.1
RESOLVCONF
        
        chattr +i /etc/resolv.conf
    fi
    
    # Clear existing rules
    iptables -D INPUT -p udp --dport 5300 -j ACCEPT 2>/dev/null || true
    iptables -t nat -D PREROUTING -i "$NET_INTERFACE" -p udp --dport 53 -j REDIRECT --to-ports 5300 2>/dev/null || true
    
    # Add firewall rules
    iptables -I INPUT -p udp --dport 5300 -j ACCEPT
    iptables -I INPUT -p tcp --dport 22 -j ACCEPT
    iptables -I INPUT -p tcp --dport 443 -j ACCEPT
    
    # NAT rule to forward port 53 to 5300
    iptables -t nat -I PREROUTING -i "$NET_INTERFACE" -p udp --dport 53 -j REDIRECT --to-ports 5300
    
    # Save rules
    netfilter-persistent save > /dev/null 2>&1 || true
    iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
    
    echo -e "${GREEN}✅ Firewall configured${NC}"
}

#============================================
# DNSTT SETUP
#============================================

generate_keys() {
    echo -e "${YELLOW}🔑 Generating encryption keys...${NC}"
    
    cd "$INSTALL_DIR"
    
    # Generate keys
    "$DNSTT_BIN" -gen-key -privkey-file server.key -pubkey-file server.pub
    
    if [[ ! -f "server.key" ]] || [[ ! -f "server.pub" ]]; then
        echo -e "${RED}❌ Key generation failed${NC}"
        return 1
    fi
    
    chmod 600 server.key
    chmod 644 server.pub
    
    echo -e "${GREEN}✅ Keys generated successfully${NC}"
    return 0
}

create_service() {
    local tunnel_domain=$1
    local mtu=$2
    local ssh_port=$3
    
    echo -e "${YELLOW}📝 Creating systemd service...${NC}"
    
    cat > /etc/systemd/system/dnstt.service << SERVICE
[Unit]
Description=DNSTT DNS Tunnel Server
Documentation=https://github.com/tladesignz/dnstt
After=network.target network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR
ExecStart=$DNSTT_BIN -udp :5300 -privkey-file $INSTALL_DIR/server.key -mtu $mtu $tunnel_domain 127.0.0.1:$ssh_port
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal
SyslogIdentifier=dnstt

[Install]
WantedBy=multi-user.target
SERVICE

    systemctl daemon-reload
    systemctl enable dnstt
    
    echo -e "${GREEN}✅ Service created${NC}"
}

setup_dnstt() {
    show_banner
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    DNSTT INSTALLATION                      ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
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
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}                    DOMAIN CONFIGURATION${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${WHITE}Enter your nameserver domain:${NC}"
    echo -e "${CYAN}Example: ns.yourdomain.com${NC}"
    echo -e "${CYAN}Leave empty for default: tns.voltran.online${NC}"
    echo ""
    read -p "Nameserver domain: " ns_domain
    ns_domain=${ns_domain:-tns.voltran.online}
    
    echo ""
    echo -e "${WHITE}Enter your tunnel subdomain:${NC}"
    echo -e "${CYAN}Example: t (this creates t.yourdomain.com)${NC}"
    echo -e "${CYAN}Leave empty for default: t${NC}"
    echo ""
    read -p "Tunnel subdomain: " tunnel_sub
    tunnel_sub=${tunnel_sub:-t}
    
    # Extract main domain and create tunnel domain
    main_domain=$(echo "$ns_domain" | awk -F. '{print $(NF-1)"."$NF}')
    tunnel_domain="${tunnel_sub}.${main_domain}"
    
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
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}                    MTU CONFIGURATION${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${WHITE}Select MTU (Maximum Transmission Unit):${NC}"
    echo ""
    echo "  ${CYAN}1)${NC} 512   - Classic DNS (best for custom resolvers)"
    echo "  ${CYAN}2)${NC} 768   - Extended compatibility"
    echo "  ${CYAN}3)${NC} 1200  - Standard (recommended) ${GREEN}⭐${NC}"
    echo "  ${CYAN}4)${NC} 1232  - EDNS0 standard"
    echo "  ${CYAN}5)${NC} 1280  - IPv6 safe"
    echo "  ${CYAN}6)${NC} 1420  - High performance"
    echo "  ${CYAN}7)${NC} Custom"
    echo ""
    echo -e "${YELLOW}💡 Tip: Choose 512 for custom DNS like 169.255.187.58${NC}"
    echo -e "${YELLOW}💡 Tip: Choose 1200+ for public resolvers (Google, Cloudflare)${NC}"
    echo ""
    read -p "Enter choice [1-7]: " mtu_choice
    
    case $mtu_choice in
        1) MTU=512 ;;
        2) MTU=768 ;;
        3|"") MTU=1200 ;;
        4) MTU=1232 ;;
        5) MTU=1280 ;;
        6) MTU=1420 ;;
        7)
            read -p "Enter custom MTU (256-1500): " custom_mtu
            if [[ $custom_mtu -ge 256 ]] && [[ $custom_mtu -le 1500 ]]; then
                MTU=$custom_mtu
            else
                echo -e "${YELLOW}Invalid MTU, using 1200${NC}"
                MTU=1200
            fi
            ;;
        *) MTU=1200 ;;
    esac
    
    echo "$MTU" > "$INSTALL_DIR/mtu.txt"
    echo ""
    echo -e "${GREEN}✅ MTU set to: $MTU bytes${NC}"
    
    # Custom DNS for low MTU
    if [[ $MTU -le 512 ]]; then
        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}            CUSTOM DNS RESOLVER (Optional)${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo -e "${WHITE}Do you have a custom DNS resolver?${NC}"
        echo -e "${CYAN}Example: 169.255.187.58${NC}"
        echo ""
        echo "  1) Yes - I have a custom DNS"
        echo "  2) No - Use public DNS"
        echo ""
        read -p "Choice: " dns_choice
        
        if [[ "$dns_choice" == "1" ]]; then
            echo ""
            read -p "Enter your DNS resolver IP: " custom_dns
            if [[ -n "$custom_dns" ]]; then
                echo "$custom_dns" > "$INSTALL_DIR/custom_dns.txt"
                echo -e "${GREEN}✅ Custom DNS saved: $custom_dns${NC}"
            fi
        fi
    fi
    
    # Detect SSH port
    SSH_PORT=$(ss -tlnp 2>/dev/null | grep sshd | awk '{print $4}' | cut -d: -f2 | head -1)
    SSH_PORT=${SSH_PORT:-22}
    echo "$SSH_PORT" > "$INSTALL_DIR/ssh_port.txt"
    
    echo ""
    echo -e "${CYAN}SSH Port detected: $SSH_PORT${NC}"
    
    # Create service
    echo ""
    create_service "$tunnel_domain" "$MTU" "$SSH_PORT"
    
    # Start service
    echo -e "${YELLOW}🚀 Starting DNSTT service...${NC}"
    systemctl start dnstt
    
    sleep 3
    
    # Check status
    if systemctl is-active --quiet dnstt; then
        echo -e "${GREEN}✅ DNSTT service started successfully!${NC}"
    else
        echo -e "${RED}❌ Service failed to start!${NC}"
        echo ""
        echo -e "${YELLOW}Service logs:${NC}"
        journalctl -u dnstt -n 20 --no-pager
        press_enter
        return 1
    fi
    
    # Get server info
    PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com 2>/dev/null || echo "YOUR_SERVER_IP")
    PUBKEY=$(cat "$INSTALL_DIR/server.pub")
    
    # Display connection info
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                  ✅ INSTALLATION COMPLETE! ✅                  ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━ CONNECTION DETAILS ━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${WHITE}📍 Server IP:${NC}       ${YELLOW}$PUBLIC_IP${NC}"
    echo -e "${WHITE}🌐 NS Domain:${NC}       ${YELLOW}$ns_domain${NC}"
    echo -e "${WHITE}🔗 Tunnel Domain:${NC}   ${YELLOW}$tunnel_domain${NC}"
    echo -e "${WHITE}🔑 Public Key:${NC}      ${YELLOW}$PUBKEY${NC}"
    echo -e "${WHITE}🚪 SSH Port:${NC}        ${YELLOW}$SSH_PORT${NC}"
    echo -e "${WHITE}📊 MTU:${NC}             ${YELLOW}$MTU bytes${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}📋 DNS RECORDS (Add these to your domain):${NC}"
    echo ""
    echo -e "${GREEN}   Record Type: A${NC}"
    echo -e "${WHITE}   Name:        $ns_domain${NC}"
    echo -e "${WHITE}   Value:       $PUBLIC_IP${NC}"
    echo ""
    echo -e "${GREEN}   Record Type: NS${NC}"
    echo -e "${WHITE}   Name:        $tunnel_domain${NC}"
    echo -e "${WHITE}   Value:       $ns_domain${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}📱 CLIENT CONNECTION COMMAND:${NC}"
    echo ""
    
    if [[ $MTU -le 512 ]]; then
        custom_dns=$(cat "$INSTALL_DIR/custom_dns.txt" 2>/dev/null)
        if [[ -n "$custom_dns" ]]; then
            echo -e "${CYAN}   # For your custom DNS resolver:${NC}"
            echo -e "${WHITE}   dnstt-client -udp $custom_dns:53 \\${NC}"
            echo -e "${WHITE}     -pubkey $PUBKEY \\${NC}"
            echo -e "${WHITE}     $tunnel_domain 127.0.0.1:8080${NC}"
            echo ""
            echo -e "${CYAN}   # Alternative with Google DNS:${NC}"
            echo -e "${WHITE}   dnstt-client -udp 8.8.8.8:53 \\${NC}"
            echo -e "${WHITE}     -pubkey $PUBKEY \\${NC}"
            echo -e "${WHITE}     $tunnel_domain 127.0.0.1:8080${NC}"
        else
            echo -e "${WHITE}   dnstt-client -udp 8.8.8.8:53 \\${NC}"
            echo -e "${WHITE}     -pubkey $PUBKEY \\${NC}"
            echo -e "${WHITE}     $tunnel_domain 127.0.0.1:8080${NC}"
        fi
    else
        echo -e "${CYAN}   # Using DoH (DNS over HTTPS):${NC}"
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
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Save to file
    cat > "$INSTALL_DIR/connection_info.txt" << INFO
╔════════════════════════════════════════════════════════════════╗
║              DNSTT CONNECTION INFORMATION                      ║
╚════════════════════════════════════════════════════════════════╝

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
A    $ns_domain    $PUBLIC_IP
NS   $tunnel_domain    $ns_domain

CLIENT COMMAND:
===============
INFO

    if [[ $MTU -le 512 ]]; then
        custom_dns=$(cat "$INSTALL_DIR/custom_dns.txt" 2>/dev/null)
        if [[ -n "$custom_dns" ]]; then
            echo "dnstt-client -udp $custom_dns:53 -pubkey $PUBKEY $tunnel_domain 127.0.0.1:8080" >> "$INSTALL_DIR/connection_info.txt"
        else
            echo "dnstt-client -udp 8.8.8.8:53 -pubkey $PUBKEY $tunnel_domain 127.0.0.1:8080" >> "$INSTALL_DIR/connection_info.txt"
        fi
    else
        echo "dnstt-client -doh https://cloudflare-dns.com/dns-query -pubkey $PUBKEY $tunnel_domain 127.0.0.1:8080" >> "$INSTALL_DIR/connection_info.txt"
    fi
    
    echo -e "${GREEN}📄 Connection details saved to: $INSTALL_DIR/connection_info.txt${NC}"
    
    press_enter
}

#============================================
# SSH USER MANAGEMENT
#============================================

add_ssh_user() {
    show_banner
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    ADD SSH USER                            ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    read -p "Enter username: " username
    
    if [[ -z "$username" ]]; then
        echo -e "${RED}❌ Username cannot be empty${NC}"
        press_enter
        return
    fi
    
    if id "$username" &>/dev/null; then
        echo -e "${RED}❌ User already exists!${NC}"
        press_enter
        return
    fi
    
    read -sp "Enter password: " password
    echo ""
    
    if [[ -z "$password" ]]; then
        echo -e "${RED}❌ Password cannot be empty${NC}"
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
    useradd -m -s /bin/bash "$username"
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
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                   DELETE SSH USER                          ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    read -p "Enter username to delete: " username
    
    if ! id "$username" &>/dev/null; then
        echo -e "${RED}❌ User not found!${NC}"
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
    
    # Delete user
    userdel -r "$username" 2>/dev/null || true
    
    # Remove from database
    sed -i "/^$username|/d" "$USER_DB"
    
    echo -e "${GREEN}✅ User deleted successfully!${NC}"
    press_enter
}

list_ssh_users() {
    show_banner
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                          SSH USERS LIST                                    ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [[ ! -s "$USER_DB" ]]; then
        echo -e "${YELLOW}No users found${NC}"
    else
        printf "${WHITE}%-15s %-15s %-12s %-10s %-10s${NC}\n" "USERNAME" "PASSWORD" "EXPIRES" "MAX CONN" "STATUS"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        while IFS='|' read -r user pass exp max created; do
            current_date=$(date +%s)
            exp_unix=$(date -d "$exp" +%s 2>/dev/null || echo "0")
            
            if [[ $current_date -gt $exp_unix ]]; then
                status="${RED}EXPIRED${NC}"
            else
                status="${GREEN}ACTIVE${NC}"
            fi
            
            printf "${WHITE}%-15s %-15s %-12s %-10s${NC} " "$user" "$pass" "$exp" "$max"
            echo -e "$status"
        done < "$USER_DB"
    fi
    
    press_enter
}

view_dnstt_status() {
    show_banner
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                  DNSTT SERVICE STATUS                      ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if systemctl is-active --quiet dnstt 2>/dev/null; then
        echo -e "${GREEN}✅ Status: RUNNING${NC}"
    else
        echo -e "${RED}❌ Status: STOPPED${NC}"
    fi
    
    echo ""
    echo -e "${YELLOW}Service Details:${NC}"
    systemctl status dnstt --no-pager -l | head -25
    
    echo ""
    echo -e "${YELLOW}Recent Logs:${NC}"
    journalctl -u dnstt -n 20 --no-pager
    
    press_enter
}

view_connection_info() {
    show_banner
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                 CONNECTION INFORMATION                     ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [[ -f "$INSTALL_DIR/connection_info.txt" ]]; then
        cat "$INSTALL_DIR/connection_info.txt"
    else
        echo -e "${RED}❌ DNSTT not configured yet!${NC}"
        echo ""
        echo -e "${YELLOW}Please run installation first (Menu option 1)${NC}"
    fi
    
    press_enter
}

change_mtu() {
    show_banner
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    CHANGE MTU                              ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [[ ! -f "$INSTALL_DIR/mtu.txt" ]]; then
        echo -e "${RED}❌ DNSTT not configured!${NC}"
        press_enter
        return
    fi
    
    current_mtu=$(cat "$INSTALL_DIR/mtu.txt")
    echo -e "${YELLOW}Current MTU: $current_mtu bytes${NC}"
    echo ""
    
    echo -e "${WHITE}Select new MTU:${NC}"
    echo ""
    echo "  1) 512"
    echo "  2) 768"
    echo "  3) 1200"
    echo "  4) 1232"
    echo "  5) 1280"
    echo "  6) 1420"
    echo ""
    read -p "Choice [1-6]: " choice
    
    case $choice in
        1) new_mtu=512 ;;
        2) new_mtu=768 ;;
        3) new_mtu=1200 ;;
        4) new_mtu=1232 ;;
        5) new_mtu=1280 ;;
        6) new_mtu=1420 ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            press_enter
            return
            ;;
    esac
    
    # Update MTU
    echo "$new_mtu" > "$INSTALL_DIR/mtu.txt"
    
    # Recreate service with new MTU
    tunnel_domain=$(cat "$INSTALL_DIR/tunnel_domain.txt")
    ssh_port=$(cat "$INSTALL_DIR/ssh_port.txt")
    
    create_service "$tunnel_domain" "$new_mtu" "$ssh_port"
    
    # Restart service
    systemctl restart dnstt
    
    echo ""
    echo -e "${GREEN}✅ MTU changed from $current_mtu to $new_mtu bytes${NC}"
    echo -e "${GREEN}✅ Service restarted${NC}"
    
    press_enter
}

#============================================
# MENU FUNCTIONS
#============================================

dnstt_menu() {
    while true; do
        show_banner
        echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║              DNSTT MANAGEMENT MENU                         ║${NC}"
        echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  ${GREEN}1)${NC} Install/Setup DNSTT"
        echo -e "  ${YELLOW}2)${NC} View Service Status"
        echo -e "  ${YELLOW}3)${NC} View Connection Information"
        echo -e "  ${BLUE}4)${NC} Change MTU Configuration"
        echo -e "  ${BLUE}5)${NC} Restart DNSTT Service"
        echo -e "  ${RED}6)${NC} Stop DNSTT Service"
        echo -e "  ${PURPLE}7)${NC} Uninstall DNSTT"
        echo -e "  ${WHITE}0)${NC} Back to Main Menu"
        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        read -p "Enter your choice: " choice
        
        case $choice in
            1) setup_dnstt ;;
            2) view_dnstt_status ;;
            3) view_connection_info ;;
            4) change_mtu ;;
            5)
                echo ""
                echo -e "${YELLOW}Restarting DNSTT service...${NC}"
                systemctl restart dnstt
                echo -e "${GREEN}✅ Service restarted${NC}"
                sleep 2
                ;;
            6)
                echo ""
                echo -e "${YELLOW}Stopping DNSTT service...${NC}"
                systemctl stop dnstt
                echo -e "${YELLOW}⚠️  Service stopped${NC}"
                sleep 2
                ;;
            7)
                echo ""
                read -p "Are you sure you want to uninstall DNSTT? (y/n): " confirm
                if [[ "$confirm" == "y" ]]; then
                    systemctl stop dnstt 2>/dev/null || true
                    systemctl disable dnstt 2>/dev/null || true
                    rm -f /etc/systemd/system/dnstt.service
                    rm -rf "$INSTALL_DIR"
                    rm -f "$DNSTT_BIN"
                    systemctl daemon-reload
                    echo -e "${GREEN}✅ DNSTT uninstalled${NC}"
                    sleep 2
                fi
                ;;
            0) return ;;
            *)
                echo -e "${RED}Invalid choice${NC}"
                sleep 1
                ;;
        esac
    done
}

ssh_menu() {
    while true; do
        show_banner
        echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║              SSH USER MANAGEMENT MENU                      ║${NC}"
        echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  ${GREEN}1)${NC} Add New User"
        echo -e "  ${YELLOW}2)${NC} List All Users"
        echo -e "  ${RED}3)${NC} Delete User"
        echo -e "  ${BLUE}4)${NC} View Online Users"
        echo -e "  ${WHITE}0)${NC} Back to Main Menu"
        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        read -p "Enter your choice: " choice
        
        case $choice in
            1) add_ssh_user ;;
            2) list_ssh_users ;;
            3) delete_ssh_user ;;
            4)
                show_banner
                echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
                echo -e "${CYAN}║                   ONLINE USERS                             ║${NC}"
                echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
                echo ""
                who
                echo ""
                press_enter
                ;;
            0) return ;;
            *)
                echo -e "${RED}Invalid choice${NC}"
                sleep 1
                ;;
        esac
    done
}

system_info() {
    show_banner
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                  SYSTEM INFORMATION                        ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${YELLOW}System Uptime:${NC}"
    uptime
    echo ""
    
    echo -e "${YELLOW}Memory Usage:${NC}"
    free -h
    echo ""
    
    echo -e "${YELLOW}Disk Usage:${NC}"
    df -h /
    echo ""
    
    echo -e "${YELLOW}Network Interfaces:${NC}"
    ip -brief addr
    echo ""
    
    press_enter
}

main_menu() {
    while true; do
        show_banner
        echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║                    MAIN MENU                               ║${NC}"
        echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  ${GREEN}1)${NC} 🌐 DNSTT Management"
        echo -e "  ${BLUE}2)${NC} 👥 SSH User Management"
        echo -e "  ${YELLOW}3)${NC} 📊 System Information"
        echo -e "  ${RED}0)${NC} ❌ Exit"
        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        read -p "Enter your choice: " choice
        
        case $choice in
            1) dnstt_menu ;;
            2) ssh_menu ;;
            3) system_info ;;
            0)
                echo ""
                echo -e "${GREEN}Thank you for using SLOW DNS! 👑👑${NC}"
                echo ""
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice${NC}"
                sleep 1
                ;;
        esac
    done
}

#============================================
# MAIN EXECUTION
#============================================

check_root
check_os
main_menu