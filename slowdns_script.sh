#!/bin/bash

# SLOW DNS - Professional DNSTT Management System
# Version: 5.0.0 - Enhanced Edition with FirewallFalcon Features
# Made by The King 👑👑

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
DNSTT_DIR="/etc/dnstt"
FIREWALL_DIR="/etc/firewallfalcon/dnstt"
SSH_DIR="/etc/slowdns"
BANNER_FILE="$SSH_DIR/banner"
USER_DB="$SSH_DIR/users.txt"
DNSTT_SERVER="/usr/local/bin/dnstt-server"
DNSTT_CLIENT="/usr/local/bin/dnstt-client"

# Create directories
mkdir -p "$DNSTT_DIR" "$FIREWALL_DIR" "$SSH_DIR"

# Banner
show_banner() {
    clear
    echo -e "${CYAN}"
    cat <<'LOGO'
  ███████╗██╗      ██████╗ ██╗    ██╗    ██████╗ ███╗   ███╗███████╗
  ██╔════╝██║     ██╔═══██╗██║    ██║    ██╔══██╗████╗ ████║██╔════╝
  ███████╗██║     ██║   ██║██║ █╗ ██║    ██║  ██║██╔████╔██║███████╗
  ╚════██║██║     ██║   ██║██║███╗██║    ██║  ██║██║╚██╔╝██║╚════██║
  ███████║███████╗╚██████╔╝╚███╔███╔╝    ██████╔╝██║ ╚═╝ ██║███████║
  ╚══════╝╚══════╝ ╚═════╝  ╚══╝╚══╝     ╚═════╝ ╚═╝     ╚═╝╚══════╝
LOGO
    echo -e "${NC}"
    echo -e "${PURPLE}════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}      DNS Tunnel & SSH Management System v5.0.0 Enhanced${NC}"
    echo -e "${PURPLE}════════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Check root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}❌ Run as root: sudo $0${NC}"
        exit 1
    fi
}

# Show system info
show_system_info() {
    echo -e "${CYAN}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}"
    
    # OS Detection
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME="$NAME $VERSION"
    else
        OS_NAME="Unknown Linux"
    fi
    
    # Architecture
    ARCH=$(uname -m)
    
    # Uptime
    UPTIME=$(uptime -p | sed 's/up //')
    
    # Users
    TOTAL_USERS=$(wc -l < "$USER_DB" 2>/dev/null || echo "0")
    ONLINE_SESSIONS=$(who | wc -l)
    
    # Resources
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    RAM_INFO=$(free | grep Mem | awk '{printf "%.2f%%", $3/$2 * 100.0}')
    
    # Domain
    if [ -f "$DNSTT_DIR/domain.txt" ]; then
        DOMAIN=$(cat "$DNSTT_DIR/domain.txt")
    else
        DOMAIN="Not Generated"
    fi
    
    echo -e "${WHITE}OS:${NC}           ${CYAN}$OS_NAME${NC}              ${WHITE}Online:${NC} ${GREEN}$ONLINE_SESSIONS Sessions${NC}"
    echo -e "${WHITE}Uptime:${NC}       ${CYAN}$UPTIME${NC}    ${WHITE}Total Users:${NC} ${GREEN}$TOTAL_USERS${NC}"
    echo -e "${WHITE}Resources:${NC}    ${CYAN}CPU($ARCH): $CPU_USAGE% | RAM: $RAM_INFO${NC} ${WHITE}Domain:${NC} ${YELLOW}$DOMAIN${NC}"
    echo -e "${CYAN}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NC}"
}

# Check port availability
check_port_available() {
    local port=$1
    echo -e "${BLUE}🔍 Checking if port $port (UDP) is available...${NC}"
    
    if ss -ulnp 2>/dev/null | grep -q ":$port "; then
        echo -e "${RED}❌ Port $port (UDP) is already in use.${NC}"
        ss -ulnp | grep ":$port "
        return 1
    else
        echo -e "${GREEN}✅ Port $port (UDP) is free to use.${NC}"
        return 0
    fi
}

# Check if port is open in UFW
check_ufw_port() {
    local port=$1
    if command -v ufw &> /dev/null; then
        if ufw status 2>/dev/null | grep -q "Status: active"; then
            if ufw status | grep -q "$port/udp"; then
                echo -e "${GREEN}✅ Port $port/udp is already open in UFW.${NC}"
            else
                echo -e "${YELLOW}⚠️  Port $port/udp not open in UFW. Opening...${NC}"
                ufw allow $port/udp > /dev/null 2>&1
                echo -e "${GREEN}✅ Port $port/udp opened in UFW.${NC}"
            fi
        fi
    fi
}

# Force release port 53
force_release_port53() {
    echo -e "${BLUE}⚙️  Forcing release of Port 53 (stopping systemd-resolved)...${NC}"
    
    # Stop and disable systemd-resolved
    if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
        systemctl stop systemd-resolved
        systemctl disable systemd-resolved
        echo -e "${GREEN}✅ systemd-resolved stopped${NC}"
    fi
    
    # Unlock and recreate resolv.conf
    chattr -i /etc/resolv.conf 2>/dev/null || true
    rm -f /etc/resolv.conf
    
    cat > /etc/resolv.conf <<EOF
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 1.1.1.1
EOF
    
    chattr +i /etc/resolv.conf
    echo -e "${GREEN}✅ DNS resolver configured${NC}"
    
    # Check port 53
    if check_port_available 53; then
        echo -e "${GREEN}✅ Port 53 (UDP) is free to use.${NC}"
    else
        echo -e "${YELLOW}⚠️  Port 53 still in use, but continuing...${NC}"
    fi
    
    # Open port 53 in UFW
    check_ufw_port 53
}

# Download pre-compiled DNSTT binary
download_precompiled_dnstt() {
    echo -e "${YELLOW}📦 Downloading pre-compiled DNSTT server binary...${NC}"
    
    # Detect architecture
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            DNSTT_ARCH="amd64"
            ;;
        aarch64|arm64)
            DNSTT_ARCH="arm64"
            ;;
        armv7l)
            DNSTT_ARCH="arm"
            ;;
        *)
            echo -e "${RED}❌ Unsupported architecture: $ARCH${NC}"
            return 1
            ;;
    esac
    
    echo -e "${BLUE}🖥️  Detected $ARCH ($DNSTT_ARCH) architecture.${NC}"
    
    # Download URLs (you can host these or use GitHub releases)
    DNSTT_SERVER_URL="https://github.com/folbricht/dnstt/releases/latest/download/dnstt-server-linux-${DNSTT_ARCH}"
    DNSTT_CLIENT_URL="https://github.com/folbricht/dnstt/releases/latest/download/dnstt-client-linux-${DNSTT_ARCH}"
    
    # Try to download
    cd /tmp
    
    # Server binary
    if wget -q --show-progress "$DNSTT_SERVER_URL" -O dnstt-server 2>/dev/null; then
        mv dnstt-server "$DNSTT_SERVER"
        chmod +x "$DNSTT_SERVER"
        echo -e "${GREEN}✅ DNSTT server downloaded${NC}"
    else
        echo -e "${YELLOW}⚠️  Pre-compiled binary not available, will build from source...${NC}"
        return 1
    fi
    
    # Client binary (optional)
    if wget -q --show-progress "$DNSTT_CLIENT_URL" -O dnstt-client 2>/dev/null; then
        mv dnstt-client "$DNSTT_CLIENT"
        chmod +x "$DNSTT_CLIENT"
        echo -e "${GREEN}✅ DNSTT client downloaded${NC}"
    fi
    
    return 0
}

# Install Go
install_go() {
    if command -v go &> /dev/null; then
        echo -e "${GREEN}✅ Go already installed${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}📦 Installing Go...${NC}"
    cd /tmp
    
    ARCH=$(uname -m)
    case $ARCH in
        x86_64) GO_ARCH="amd64" ;;
        aarch64|arm64) GO_ARCH="arm64" ;;
        armv7l) GO_ARCH="armv6l" ;;
        *)
            echo -e "${RED}❌ Unsupported architecture${NC}"
            return 1
            ;;
    esac
    
    GO_VERSION="1.21.5"
    wget -q https://go.dev/dl/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz || return 1
    rm -rf /usr/local/go
    tar -C /usr/local -xzf go${GO_VERSION}.linux-${GO_ARCH}.tar.gz
    rm -f go${GO_VERSION}.linux-${GO_ARCH}.tar.gz
    
    export PATH=$PATH:/usr/local/go/bin
    if ! grep -q "/usr/local/go/bin" /root/.bashrc; then
        echo 'export PATH=$PATH:/usr/local/go/bin' >> /root/.bashrc
    fi
    
    echo -e "${GREEN}✅ Go installed${NC}"
    return 0
}

# Install dependencies
install_deps() {
    echo -e "${YELLOW}📦 Installing dependencies...${NC}"
    export DEBIAN_FRONTEND=noninteractive
    
    apt-get update -y > /dev/null 2>&1 || return 1
    
    PACKAGES="wget curl git build-essential iptables iptables-persistent netfilter-persistent ufw"
    for pkg in $PACKAGES; do
        if ! dpkg -l | grep -q "^ii  $pkg"; then
            apt-get install -y $pkg > /dev/null 2>&1 || echo -e "${YELLOW}⚠️  $pkg installation skipped${NC}"
        fi
    done
    
    echo -e "${GREEN}✅ Dependencies installed${NC}"
    return 0
}

# Build DNSTT from source
build_dnstt() {
    echo -e "${YELLOW}🔨 Building DNSTT from source...${NC}"
    
    cd /tmp
    rm -rf dnstt
    
    if ! git clone https://github.com/folbricht/dnstt.git > /dev/null 2>&1; then
        echo -e "${RED}❌ Git clone failed${NC}"
        return 1
    fi
    
    cd dnstt/dnstt-server
    
    export PATH=$PATH:/usr/local/go/bin
    export GOPATH=$HOME/go
    export GO111MODULE=on
    
    if [ ! -f "go.mod" ]; then
        /usr/local/go/bin/go mod init dnstt-server 2>/dev/null || true
        /usr/local/go/bin/go mod tidy 2>/dev/null || true
    fi
    
    if ! /usr/local/go/bin/go build -v -o "$DNSTT_SERVER" 2>&1; then
        echo -e "${RED}❌ Build failed${NC}"
        return 1
    fi
    
    chmod +x "$DNSTT_SERVER"
    
    # Build client too
    cd ../dnstt-client
    if /usr/local/go/bin/go build -v -o "$DNSTT_CLIENT" 2>&1; then
        chmod +x "$DNSTT_CLIENT"
    fi
    
    echo -e "${GREEN}✅ DNSTT built successfully${NC}"
    cd ~
    return 0
}

# Setup firewall (UFW + iptables)
setup_firewall() {
    echo -e "${YELLOW}🔥 Configuring firewall...${NC}"
    
    # Get network interface
    IFACE=$(ip route | grep default | awk '{print $5}' | head -1)
    if [ -z "$IFACE" ]; then
        IFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo | head -1)
    fi
    IFACE=${IFACE:-eth0}
    
    echo -e "${YELLOW}Using interface: $IFACE${NC}"
    
    # UFW Configuration
    if command -v ufw &> /dev/null; then
        echo -e "${BLUE}Configuring UFW...${NC}"
        ufw allow 22/tcp > /dev/null 2>&1
        ufw allow 53/udp > /dev/null 2>&1
        ufw allow 5300/udp > /dev/null 2>&1
        echo -e "${GREEN}✅ UFW configured${NC}"
    fi
    
    # iptables Configuration
    echo -e "${BLUE}Configuring iptables...${NC}"
    
    # Clear old rules
    iptables -D INPUT -p udp --dport 5300 -j ACCEPT 2>/dev/null || true
    iptables -D INPUT -p tcp --dport 22 -j ACCEPT 2>/dev/null || true
    iptables -t nat -D PREROUTING -i "$IFACE" -p udp --dport 53 -j REDIRECT --to-ports 5300 2>/dev/null || true
    
    # Add new rules
    iptables -I INPUT -p udp --dport 5300 -j ACCEPT
    iptables -I INPUT -p tcp --dport 22 -j ACCEPT
    iptables -t nat -I PREROUTING -i "$IFACE" -p udp --dport 53 -j REDIRECT --to-ports 5300
    
    # IPv6
    if ip -6 addr show 2>/dev/null | grep -q inet6; then
        ip6tables -I INPUT -p udp --dport 5300 -j ACCEPT 2>/dev/null || true
        ip6tables -t nat -I PREROUTING -i "$IFACE" -p udp --dport 53 -j REDIRECT --to-ports 5300 2>/dev/null || true
    fi
    
    # Save rules
    if command -v netfilter-persistent &> /dev/null; then
        netfilter-persistent save > /dev/null 2>&1
    fi
    
    mkdir -p /etc/iptables
    iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
    
    echo -e "${GREEN}✅ Firewall configured${NC}"
    return 0
}

# Generate cryptographic keys
gen_keys() {
    echo -e "${YELLOW}🔑 Generating cryptographic keys...${NC}"
    
    cd "$DNSTT_DIR"
    rm -f server.key server.pub
    
    if ! "$DNSTT_SERVER" -gen-key -privkey-file server.key -pubkey-file server.pub 2>&1; then
        echo -e "${RED}❌ Key generation failed${NC}"
        return 1
    fi
    
    if [ ! -f "server.key" ] || [ ! -f "server.pub" ]; then
        echo -e "${RED}❌ Key files not created${NC}"
        return 1
    fi
    
    chmod 600 server.key
    chmod 644 server.pub
    
    PUBKEY=$(cat server.pub)
    echo -e "${WHITE}privkey written to /etc/dnstt/server.key${NC}"
    echo -e "${WHITE}pubkey  written to /etc/dnstt/server.pub${NC}"
    echo ""
    
    return 0
}

# Auto-generate or custom DNS records
setup_dns_records() {
    echo ""
    echo -e "${YELLOW}👉 Auto-generate DNS records or use custom ones? (auto/custom) [auto]:${NC}"
    read -p "Choice: " dns_choice
    dns_choice=${dns_choice:-auto}
    
    if [ "$dns_choice" = "auto" ]; then
        # Auto-generate
        echo -e "${BLUE}🔄 Auto-generating DNS records...${NC}"
        
        # Generate random subdomain
        RANDOM_SUB="tun-$(head /dev/urandom | tr -dc a-z0-9 | head -c 6)"
        
        # You can replace this with your actual domain
        read -p "Enter your base domain (e.g., example.com): " BASE_DOMAIN
        
        ns_domain="ns.${BASE_DOMAIN}"
        tunnel="${RANDOM_SUB}.${BASE_DOMAIN}"
        
    else
        # Custom
        echo ""
        echo -e "${YELLOW}👉 Nameserver domain:${NC}"
        echo -e "${CYAN}   (e.g., ns.yourdomain.com)${NC}"
        read -p "Domain: " ns_domain
        
        echo ""
        echo -e "${YELLOW}👉 Tunnel subdomain:${NC}"
        echo -e "${CYAN}   (e.g., t for t.yourdomain.com)${NC}"
        read -p "Subdomain: " sub
        
        main=$(echo "$ns_domain" | awk -F. '{if (NF>=2) print $(NF-1)"."$NF; else print $0}')
        tunnel="${sub}.${main}"
    fi
    
    echo "$ns_domain" > "$DNSTT_DIR/domain.txt"
    echo "$tunnel" > "$DNSTT_DIR/tunnel.txt"
    
    echo -e "${GREEN}✅ NS: $ns_domain${NC}"
    echo -e "${GREEN}✅ Tunnel: $tunnel${NC}"
}

# Configure MTU
configure_mtu() {
    echo ""
    echo -e "${YELLOW}👉 Enter MTU value (e.g., 512, 1200) or press [Enter] for default: 512${NC}"
    read -p "MTU: " mtu_input
    
    if [ -z "$mtu_input" ]; then
        MTU=512
    elif [ "$mtu_input" -ge 256 ] && [ "$mtu_input" -le 1500 ] 2>/dev/null; then
        MTU=$mtu_input
    else
        echo -e "${YELLOW}Invalid MTU, using 512${NC}"
        MTU=512
    fi
    
    echo "$MTU" > "$DNSTT_DIR/mtu.txt"
    echo -e "${BLUE}📊 Using MTU: $MTU${NC}"
}

# Create systemd service
create_service() {
    echo -e "${YELLOW}📝 Creating systemd service...${NC}"
    
    SSH_PORT=$(ss -tlnp 2>/dev/null | grep -E 'sshd|ssh' | awk '{print $4}' | grep -oE '[0-9]+$' | head -1)
    if [ -z "$SSH_PORT" ]; then
        SSH_PORT=$(grep -E "^Port " /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}')
    fi
    SSH_PORT=${SSH_PORT:-22}
    
    tunnel=$(cat "$DNSTT_DIR/tunnel.txt")
    MTU=$(cat "$DNSTT_DIR/mtu.txt")
    
    echo -e "${BLUE}👉 DNSTT will forward to SSH (port $SSH_PORT) on 127.0.0.1:$SSH_PORT.${NC}"
    
    cat > /etc/systemd/system/dnstt.service <<SERVICE
[Unit]
Description=DNSTT Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$DNSTT_DIR
ExecStart=$DNSTT_SERVER -udp :5300 -privkey-file $DNSTT_DIR/server.key -mtu $MTU $tunnel 127.0.0.1:$SSH_PORT
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SERVICE

    # Save configuration
    cat > "$FIREWALL_DIR/config.conf" <<CONFIG
NS_DOMAIN=$(cat "$DNSTT_DIR/domain.txt")
TUNNEL_DOMAIN=$(cat "$DNSTT_DIR/tunnel.txt")
PUBLIC_KEY=$(cat "$DNSTT_DIR/server.pub")
SSH_PORT=$SSH_PORT
MTU=$MTU
CREATED=$(date)
CONFIG

    echo -e "${GREEN}✅ Configuration saved${NC}"
}

# Start service
start_dnstt_service() {
    echo ""
    echo -e "${BLUE}🔄 Saving configuration and starting service...${NC}"
    
    systemctl daemon-reload
    systemctl enable dnstt > /dev/null 2>&1
    systemctl restart dnstt
    
    sleep 3
    
    if ! systemctl is-active --quiet dnstt; then
        echo -e "${RED}❌ Service failed to start!${NC}"
        systemctl status dnstt --no-pager
        journalctl -u dnstt -n 20 --no-pager
        return 1
    fi
    
    echo -e "${GREEN}✅ SUCCESS: DNSTT has been installed and started!${NC}"
    return 0
}

# Display connection details
show_connection_details() {
    echo ""
    echo -e "${GREEN}=======================================================${NC}"
    echo -e "${GREEN}         🎯 DNSTT Connection Details${NC}"
    echo -e "${GREEN}=======================================================${NC}"
    echo ""
    
    PUBLIC_IP=$(curl -s -m 5 ifconfig.me 2>/dev/null || curl -s -m 5 icanhazip.com 2>/dev/null || echo "YOUR_SERVER_IP")
    ns_domain=$(cat "$DNSTT_DIR/domain.txt")
    tunnel=$(cat "$DNSTT_DIR/tunnel.txt")
    PUBKEY=$(cat "$DNSTT_DIR/server.pub")
    SSH_PORT=$(cat "$DNSTT_DIR/ssh_port.txt" 2>/dev/null || echo "22")
    MTU=$(cat "$DNSTT_DIR/mtu.txt")
    
    echo -e "${WHITE}Your connection details:${NC}"
    echo -e "  ${CYAN}- Tunnel Domain: ${YELLOW}$tunnel${NC}"
    echo -e "  ${CYAN}- Public Key:    ${YELLOW}$PUBKEY${NC}"
    echo ""
    echo -e "  ${CYAN}- Forwarding To: ${YELLOW}SSH (port $SSH_PORT)${NC}"
    echo -e "  ${CYAN}- MTU Value:     ${YELLOW}$MTU${NC}"
    echo ""
    echo -e "${YELLOW}- Action Required: ${WHITE}Ensure your SSH client is configured to use the DNS tunnel.${NC}"
    echo ""
    echo -e "${WHITE}Use these details in your client configuration.${NC}"
    echo ""
    
    # Save to file
    cat > "$DNSTT_DIR/connection_info.txt" <<INFO
DNSTT Connection Details
Generated: $(date)

Server IP: $PUBLIC_IP
NS Domain: $ns_domain
Tunnel Domain: $tunnel
Public Key: $PUBKEY
SSH Port: $SSH_PORT
MTU: $MTU

DNS Records (Add these to your domain registrar):
A    $ns_domain    $PUBLIC_IP
NS   $tunnel    $ns_domain

Client Command:
dnstt-client -doh https://cloudflare-dns.com/dns-query -pubkey $PUBKEY $tunnel 127.0.0.1:8080

Then connect SSH through:
ssh user@127.0.0.1 -p 8080
INFO

    echo -e "${GREEN}📄 Details saved to: $DNSTT_DIR/connection_info.txt${NC}"
}

# Main DNSTT setup
setup_dnstt() {
    show_banner
    show_system_info
    
    echo ""
    echo -e "${CYAN}--- 🚀 DNSTT (DNS Tunnel) Management ---${NC}"
    echo ""
    
    # Check if already installed
    if systemctl is-active --quiet dnstt 2>/dev/null; then
        echo -e "${YELLOW}⚠️  DNSTT is already running${NC}"
        read -p "Reinstall? (y/n): " ans
        [ "$ans" != "y" ] && return
        systemctl stop dnstt
    fi
    
    # Installation type
    echo ""
    echo -e "${YELLOW}Please choose where DNSTT should forward traffic:${NC}"
    echo "  1) 📦 Forward to local SSH service (port 22)"
    echo "  2) 📦 Forward to local V2Ray backend (port 8787)"
    read -p "👉 Enter your choice [2]: " forward_choice
    forward_choice=${forward_choice:-1}
    
    # Install dependencies
    install_deps || { echo -e "${RED}Failed to install dependencies${NC}"; return 1; }
    
    # Force release port 53
    force_release_port53
    
    # Check port 53 availability
    check_port_available 53
    check_ufw_port 53
    check_ufw_port 5300
    
    # Try pre-compiled binary first, fall back to building
    if ! download_precompiled_dnstt; then
        echo -e "${YELLOW}📦 Pre-compiled binary not available, building from source...${NC}"
        install_go || { echo -e "${RED}Failed to install Go${NC}"; return 1; }
        build_dnstt || { echo -e "${RED}Failed to build DNSTT${NC}"; return 1; }
    fi
    
    # Setup firewall
    setup_firewall || echo -e "${YELLOW}⚠️  Firewall setup had issues${NC}"
    
    # Setup DNS records
    setup_dns_records
    
    # Generate keys
    gen_keys || { echo -e "${RED}Failed to generate keys${NC}"; return 1; }
    
    # Configure MTU
    configure_mtu
    
    # Determine forwarding port
    if [ "$forward_choice" = "2" ]; then
        echo "8787" > "$DNSTT_DIR/ssh_port.txt"
    else
        SSH_PORT=$(ss -tlnp 2>/dev/null | grep -E 'sshd|ssh' | awk '{print $4}' | grep -oE '[0-9]+$' | head -1)
        SSH_PORT=${SSH_PORT:-22}
        echo "$SSH_PORT" > "$DNSTT_DIR/ssh_port.txt"
    fi
    
    # Create service
    create_service
    
    # Start service
    if start_dnstt_service; then
        show_connection_details
    else
        echo -e "${RED}❌ Installation failed${NC}"
        return 1
    fi
    
    echo ""
    read -p "Press [Enter] to return to the menu..."
}

# Add SSH user
add_user() {
    show_banner
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         Add SSH User                   ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    read -p "Username: " user
    [ -z "$user" ] && { echo -e "${RED}Invalid username${NC}"; sleep 2; return; }
    
    if id "$user" &>/dev/null; then
        echo -e "${RED}❌ User already exists${NC}"
        sleep 2
        return
    fi
    
    read -sp "Password: " pass
    echo ""
    [ -z "$pass" ] && { echo -e "${RED}Invalid password${NC}"; sleep 2; return; }
    
    echo "Expiration:"
    echo "  1) 1 Day"
    echo "  2) 7 Days"
    echo "  3) 30 Days"
    echo "  4) 90 Days"
    echo "  5) 1 Year"
    read -p "Choice: " exp_c
    
    case $exp_c in
        1) days=1 ;;
        2) days=7 ;;
        3) days=30 ;;
        4) days=90 ;;
        5) days=365 ;;
        *) days=30 ;;
    esac
    
    useradd -m -s /bin/bash "$user"
    echo "$user:$pass" | chpassw
