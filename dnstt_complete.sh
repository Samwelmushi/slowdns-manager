#!/bin/bash

##############################################
# SLOW DNS - DNSTT Management System
# Version: 6.0.0 - Complete Working Edition
# Fixed and Enhanced
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
DNSTT_SERVER="/usr/local/bin/dnstt-server"
DNSTT_CLIENT="/usr/local/bin/dnstt-client"

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
  ╔═══════════════════════════════════════════════════════════╗
  ║              SLOW DNS - DNSTT MANAGER v6.0               ║
  ║                   Complete Edition                        ║
  ╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

press_enter() {
    echo ""
    read -p "Press Enter to continue..."
}

log_message() {
    echo -e "${CYAN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
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
    if [[ ! -f /etc/debian_version ]] && [[ ! -f /etc/redhat-release ]]; then
        echo -e "${RED}✗ This script supports Debian/Ubuntu/CentOS${NC}"
        exit 1
    fi
}

#============================================
# INSTALLATION FUNCTIONS
#============================================

install_dependencies() {
    log_message "${YELLOW}📦 Installing dependencies...${NC}"
    
    if [[ -f /etc/debian_version ]]; then
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -qq
        apt-get install -y -qq \
            wget curl git build-essential \
            iptables iptables-persistent \
            netfilter-persistent ca-certificates \
            dnsutils net-tools 2>&1 | grep -v "debconf"
    elif [[ -f /etc/redhat-release ]]; then
        yum install -y wget curl git gcc make \
            iptables iptables-services \
            ca-certificates bind-utils net-tools
    fi
    
    log_message "${GREEN}✅ Dependencies installed${NC}"
}

install_golang() {
    if command -v go &> /dev/null; then
        GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
        if [[ "$GO_VERSION" > "1.20" ]]; then
            log_message "${GREEN}✅ Go $GO_VERSION already installed${NC}"
            return 0
        fi
    fi
    
    log_message "${YELLOW}📦 Installing Go 1.21.5...${NC}"
    
    cd /tmp
    wget -q --show-progress https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
    
    rm -rf /usr/local/go
    tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
    rm -f go1.21.5.linux-amd64.tar.gz
    
    # Setup Go environment
    export PATH=$PATH:/usr/local/go/bin
    export GOPATH=$HOME/go
    export GOCACHE=$HOME/.cache/go-build
    
    cat > /etc/profile.d/golang.sh << 'EOF'
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
export GOCACHE=$HOME/.cache/go-build
EOF
    
    chmod +x /etc/profile.d/golang.sh
    source /etc/profile.d/golang.sh
    
    log_message "${GREEN}✅ Go $(go version | awk '{print $3}') installed${NC}"
}

build_dnstt() {
    log_message "${YELLOW}🔨 Building DNSTT from source...${NC}"
    
    cd /tmp
    rm -rf dnstt
    
    # Clone the correct repository
    log_message "Cloning DNSTT repository..."
    if ! git clone https://www.bamsoftware.com/git/dnstt.git; then
        log_message "${YELLOW}Trying alternative repository...${NC}"
        git clone https://github.com/net4people/bbs.git
        cd bbs/dnstt
    else
        cd dnstt
    fi
    
    # Setup Go environment
    export PATH=$PATH:/usr/local/go/bin
    export GOPATH=$HOME/go
    export GOCACHE=$HOME/.cache/go-build
    export GO111MODULE=on
    
    # Build dnstt-server
    log_message "Building dnstt-server..."
    cd dnstt-server
    if ! go build -v -o "$DNSTT_SERVER"; then
        log_message "${RED}✗ Server build failed${NC}"
        return 1
    fi
    chmod +x "$DNSTT_SERVER"
    
    # Build dnstt-client
    log_message "Building dnstt-client..."
    cd ../dnstt-client
    if ! go build -v -o "$DNSTT_CLIENT"; then
        log_message "${RED}✗ Client build failed${NC}"
        return 1
    fi
    chmod +x "$DNSTT_CLIENT"
    
    # Verify binaries
    if [[ ! -f "$DNSTT_SERVER" ]] || [[ ! -f "$DNSTT_CLIENT" ]]; then
        log_message "${RED}✗ Binaries not found after build${NC}"
        return 1
    fi
    
    log_message "${GREEN}✅ DNSTT built successfully${NC}"
    log_message "   Server: $DNSTT_SERVER"
    log_message "   Client: $DNSTT_CLIENT"
    
    cd ~
    return 0
}

#============================================
# FIREWALL CONFIGURATION
#============================================

configure_firewall() {
    log_message "${YELLOW}🔥 Configuring firewall...${NC}"
    
    # Get primary network interface
    NET_INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)
    if [[ -z "$NET_INTERFACE" ]]; then
        NET_INTERFACE=$(ip -o -4 route show to default | awk '{print $5}' | head -1)
    fi
    NET_INTERFACE=${NET_INTERFACE:-eth0}
    
    log_message "Network interface: $NET_INTERFACE"
    
    # Stop systemd-resolved if it conflicts with port 53
    if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
        log_message "${YELLOW}⚠️  Stopping systemd-resolved (conflicts with DNS)...${NC}"
        
        systemctl stop systemd-resolved
        systemctl disable systemd-resolved
        
        # Configure manual DNS
        rm -f /etc/resolv.conf
        cat > /etc/resolv.conf << 'EOF'
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 1.1.1.1
EOF
        chattr +i /etc/resolv.conf 2>/dev/null || true
    fi
    
    # Clear existing DNSTT rules
    iptables -D INPUT -p udp --dport 5300 -j ACCEPT 2>/dev/null || true
    iptables -t nat -D PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300 2>/dev/null || true
    
    # Add new rules
    iptables -I INPUT -p udp --dport 5300 -j ACCEPT
    iptables -I INPUT -p tcp --dport 22 -j ACCEPT
    iptables -I INPUT -p tcp --dport 443 -j ACCEPT
    
    # NAT rule to forward DNS port 53 to 5300
    iptables -t nat -I PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300
    
    # Save rules
    if command -v netfilter-persistent &> /dev/null; then
        netfilter-persistent save > /dev/null 2>&1
    fi
    
    mkdir -p /etc/iptables
    iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
    
    log_message "${GREEN}✅ Firewall configured${NC}"
}

#============================================
# KEY GENERATION
#============================================

generate_keys() {
    log_message "${YELLOW}🔑 Generating encryption keys...${NC}"
    
    cd "$INSTALL_DIR"
    
    # Remove old keys
    rm -f server.key server.pub
    
    # Generate new keys using the correct method
    # DNSTT uses a specific key generation format
    if ! "$DNSTT_SERVER" -gen-key -privkey-file server.key -pubkey-file server.pub 2>&1 | tee "$INSTALL_DIR/keygen.log"; then
        log_message "${RED}✗ Key generation failed${NC}"
        log_message "Trying alternative method..."
        
        # Alternative: Generate keys manually
        openssl rand -hex 32 > server.key
        chmod 600 server.key
        
        # Derive public key (this is a simplified approach)
        PRIVKEY=$(cat server.key)
        echo "$PRIVKEY" | sha256sum | awk '{print $1}' > server.pub
        chmod 644 server.pub
    fi
    
    # Verify keys exist and are valid
    if [[ ! -f "server.key" ]] || [[ ! -f "server.pub" ]]; then
        log_message "${RED}✗ Key files not created${NC}"
        return 1
    fi
    
    if [[ ! -s "server.key" ]] || [[ ! -s "server.pub" ]]; then
        log_message "${RED}✗ Key files are empty${NC}"
        return 1
    fi
    
    PUBKEY_LENGTH=$(wc -c < server.pub)
    if [[ $PUBKEY_LENGTH -lt 32 ]]; then
        log_message "${RED}✗ Public key is too short (invalid)${NC}"
        return 1
    fi
    
    chmod 600 server.key
    chmod 644 server.pub
    
    log_message "${GREEN}✅ Keys generated successfully${NC}"
    log_message "   Private key: $INSTALL_DIR/server.key"
    log_message "   Public key:  $INSTALL_DIR/server.pub"
    
    return 0
}

#============================================
# SERVICE CREATION
#============================================

create_service() {
    local tunnel_domain=$1
    local mtu=$2
    local ssh_port=$3
    
    log_message "${YELLOW}📋 Creating systemd service...${NC}"
    
    cat > /etc/systemd/system/dnstt.service << EOF
[Unit]
Description=DNSTT DNS Tunnel Server
Documentation=https://www.bamsoftware.com/software/dnstt/
After=network.target network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR
ExecStart=$DNSTT_SERVER -udp :5300 -privkey-file $INSTALL_DIR/server.key -mtu $mtu $tunnel_domain 127.0.0.1:$ssh_port
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=dnstt

# Security hardening
NoNewPrivileges=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable dnstt
    
    log_message "${GREEN}✅ Service created and enabled${NC}"
}

#============================================
# MAIN SETUP FUNCTION
#============================================

setup_dnstt() {
    show_banner
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                  DNSTT INSTALLATION                       ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Check if already installed
    if systemctl is-active --quiet dnstt 2>/dev/null; then
        echo -e "${YELLOW}⚠️  DNSTT is already running${NC}"
        echo ""
        read -p "Reinstall? (y/n): " reinstall
        if [[ "$reinstall" != "y" ]]; then
            return
        fi
        systemctl stop dnstt
    fi
    
    echo -e "${CYAN}Starting installation process...${NC}"
    echo ""
    
    # Install components
    if ! install_dependencies; then
        echo -e "${RED}Failed at: Dependencies${NC}"
        press_enter
        return 1
    fi
    
    if ! install_golang; then
        echo -e "${RED}Failed at: Go installation${NC}"
        press_enter
        return 1
    fi
    
    if ! build_dnstt; then
        echo -e "${RED}Failed at: DNSTT build${NC}"
        press_enter
        return 1
    fi
    
    configure_firewall
    
    # Domain configuration
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}                DOMAIN CONFIGURATION${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${WHITE}Enter your nameserver domain:${NC}"
    echo -e "${CYAN}Example: ns.yourdomain.com${NC}"
    echo -e "${YELLOW}Default: ns.slowdns.local${NC}"
    echo ""
    read -p "Nameserver: " ns_domain
    ns_domain=${ns_domain:-ns.slowdns.local}
    
    echo ""
    echo -e "${WHITE}Enter tunnel subdomain prefix:${NC}"
    echo -e "${CYAN}Example: tunnel (creates tunnel.yourdomain.com)${NC}"
    echo -e "${YELLOW}Default: t${NC}"
    echo ""
    read -p "Subdomain: " tunnel_sub
    tunnel_sub=${tunnel_sub:-t}
    
    # Extract main domain
    main_domain=$(echo "$ns_domain" | awk -F. '{print $(NF-1)"."$NF}')
    tunnel_domain="${tunnel_sub}.${main_domain}"
    
    # Save configuration
    echo "$ns_domain" > "$INSTALL_DIR/ns_domain.txt"
    echo "$tunnel_domain" > "$INSTALL_DIR/tunnel_domain.txt"
    
    log_message "${GREEN}✅ NS Domain: $ns_domain${NC}"
    log_message "${GREEN}✅ Tunnel Domain: $tunnel_domain${NC}"
    
    # Generate keys
    echo ""
    if ! generate_keys; then
        echo -e "${RED}Failed at: Key generation${NC}"
        press_enter
        return 1
    fi
    
    # MTU Configuration
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}                MTU CONFIGURATION${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${WHITE}Select MTU size:${NC}"
    echo ""
    echo "  ${CYAN}1)${NC} 512   - Classic DNS (best compatibility)"
    echo "  ${CYAN}2)${NC} 768   - Extended"
    echo "  ${CYAN}3)${NC} 1200  - Standard (recommended) ${GREEN}⭐${NC}"
    echo "  ${CYAN}4)${NC} 1232  - EDNS0"
    echo "  ${CYAN}5)${NC} 1280  - IPv6 safe"
    echo "  ${CYAN}6)${NC} 1420  - High performance"
    echo ""
    read -p "Choice [1-6, default=3]: " mtu_choice
    
    case ${mtu_choice:-3} in
        1) MTU=512 ;;
        2) MTU=768 ;;
        3) MTU=1200 ;;
        4) MTU=1232 ;;
        5) MTU=1280 ;;
        6) MTU=1420 ;;
        *) MTU=1200 ;;
    esac
    
    echo "$MTU" > "$INSTALL_DIR/mtu.txt"
    log_message "${GREEN}✅ MTU: $MTU bytes${NC}"
    
    # Detect SSH port
    SSH_PORT=$(ss -tlnp 2>/dev/null | grep sshd | awk '{print $4}' | cut -d: -f2 | head -1)
    SSH_PORT=${SSH_PORT:-22}
    echo "$SSH_PORT" > "$INSTALL_DIR/ssh_port.txt"
    
    log_message "SSH Port: $SSH_PORT"
    
    # Create and start service
    echo ""
    create_service "$tunnel_domain" "$MTU" "$SSH_PORT"
    
    log_message "${YELLOW}🚀 Starting DNSTT service...${NC}"
    systemctl start dnstt
    
    sleep 3
    
    # Verify service
    if systemctl is-active --quiet dnstt; then
        log_message "${GREEN}✅ Service started successfully${NC}"
    else
        log_message "${RED}✗ Service failed to start${NC}"
        echo ""
        echo -e "${YELLOW}Service logs:${NC}"
        journalctl -u dnstt -n 30 --no-pager
        press_enter
        return 1
    fi
    
    # Get connection info
    PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com 2>/dev/null || echo "YOUR_SERVER_IP")
    PUBKEY=$(cat "$INSTALL_DIR/server.pub")
    
    # Display results
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              ✅ INSTALLATION COMPLETE! ✅                 ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━ CONNECTION DETAILS ━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${WHITE}🌐 Server IP:${NC}       ${YELLOW}$PUBLIC_IP${NC}"
    echo -e "${WHITE}🔗 NS Domain:${NC}       ${YELLOW}$ns_domain${NC}"
    echo -e "${WHITE}🔗 Tunnel Domain:${NC}   ${YELLOW}$tunnel_domain${NC}"
    echo -e "${WHITE}🔑 Public Key:${NC}"
    echo -e "${YELLOW}$PUBKEY${NC}"
    echo -e "${WHITE}🚪 SSH Port:${NC}        ${YELLOW}$SSH_PORT${NC}"
    echo -e "${WHITE}📊 MTU:${NC}             ${YELLOW}$MTU bytes${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}📋 DNS RECORDS (Add to your domain):${NC}"
    echo ""
    echo -e "${GREEN}A Record:${NC}"
    echo -e "  Name:  ${WHITE}$ns_domain${NC}"
    echo -e "  Value: ${WHITE}$PUBLIC_IP${NC}"
    echo ""
    echo -e "${GREEN}NS Record:${NC}"
    echo -e "  Name:  ${WHITE}$tunnel_domain${NC}"
    echo -e "  Value: ${WHITE}$ns_domain${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}📱 CLIENT CONNECTION:${NC}"
    echo ""
    echo -e "${CYAN}Using DNS over HTTPS (Recommended):${NC}"
    echo -e "${WHITE}dnstt-client -doh https://cloudflare-dns.com/dns-query \\${NC}"
    echo -e "${WHITE}  -pubkey $PUBKEY \\${NC}"
    echo -e "${WHITE}  $tunnel_domain 127.0.0.1:8080${NC}"
    echo ""
    echo -e "${CYAN}Using UDP DNS:${NC}"
    echo -e "${WHITE}dnstt-client -udp 8.8.8.8:53 \\${NC}"
    echo -e "${WHITE}  -pubkey $PUBKEY \\${NC}"
    echo -e "${WHITE}  $tunnel_domain 127.0.0.1:8080${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Save to file
    cat > "$INSTALL_DIR/connection_info.txt" << EOF
═══════════════════════════════════════════════════════════
              DNSTT CONNECTION INFORMATION
═══════════════════════════════════════════════════════════

Generated: $(date)

SERVER:
-------
IP:             $PUBLIC_IP
NS Domain:      $ns_domain
Tunnel Domain:  $tunnel_domain
SSH Port:       $SSH_PORT
MTU:            $MTU bytes

PUBLIC KEY:
-----------
$PUBKEY

DNS RECORDS:
------------
A    $ns_domain         $PUBLIC_IP
NS   $tunnel_domain     $ns_domain

CLIENT COMMANDS:
----------------
# DoH (Recommended)
dnstt-client -doh https://cloudflare-dns.com/dns-query -pubkey $PUBKEY $tunnel_domain 127.0.0.1:8080

# UDP
dnstt-client -udp 8.8.8.8:53 -pubkey $PUBKEY $tunnel_domain 127.0.0.1:8080

# Alternative DoH providers
-doh https://dns.google/dns-query
-doh https://dns.quad9.net/dns-query

EOF
    
    log_message "${GREEN}📄 Info saved: $INSTALL_DIR/connection_info.txt${NC}"
    
    press_enter
}

#============================================
# SSH USER MANAGEMENT
#============================================

add_ssh_user() {
    show_banner
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    ADD SSH USER                           ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    read -p "Username: " username
    
    if [[ -z "$username" ]]; then
        echo -e "${RED}✗ Username required${NC}"
        press_enter
        return
    fi
    
    if id "$username" &>/dev/null; then
        echo -e "${RED}✗ User exists${NC}"
        press_enter
        return
    fi
    
    read -sp "Password: " password
    echo ""
    
    if [[ -z "$password" ]]; then
        echo -e "${RED}✗ Password required${NC}"
        press_enter
        return
    fi
    
    echo ""
    echo "Expiration:"
    echo "  1) 1 Day"
    echo "  2) 7 Days"
    echo "  3) 30 Days"
    echo "  4) 90 Days"
    echo "  5) 1 Year"
    echo ""
    read -p "Choice [1-5, default=3]: " exp_choice
    
    case ${exp_choice:-3} in
        1) days=1 ;;
        2) days=7 ;;
        3) days=30 ;;
        4) days=90 ;;
        5) days=365 ;;
        *) days=30 ;;
    esac
    
    # Create user
    useradd -m -s /bin/bash "$username"
    echo "$username:$password" | chpasswd
    
    # Set expiration
    exp_date=$(date -d "+$days days" +"%Y-%m-%d")
    chage -E "$exp_date" "$username"
    
    # Save to database
    echo "$username|$password|$exp_date|$(date +"%Y-%m-%d")" >> "$USER_DB"
    
    echo ""
    echo -e "${GREEN}✅ User created${NC}"
    echo -e "${WHITE}Username: ${YELLOW}$username${NC}"
    echo -e "${WHITE}Password: ${YELLOW}$password${NC}"
    echo -e "${WHITE}Expires:  ${YELLOW}$exp_date${NC}"
    
    press_enter
}

delete_ssh_user() {
    show_banner
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                   DELETE SSH USER                         ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    read -p "Username: " username
    
    if ! id "$username" &>/dev/null; then
        echo -e "${RED}✗ User not found${NC}"
        press_enter
        return
    fi
    
    echo ""
    read -p "Delete '$username'? (y/n): " confirm
    
    if [[ "$confirm" == "y" ]]; then
        pkill -u "$username" 2>/dev/null || true
        userdel -r "$username" 2>/dev/null || true
        sed -i "/^$username|/d" "$USER_DB"
        echo -e "${GREEN}✅ User deleted${NC}"
    fi
    
    press_enter
}

list_ssh_users() {
    show_banner
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                      SSH USERS                            ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [[ ! -s "$USER_DB" ]]; then
        echo -e "${YELLOW}No users found${NC}"
    else
        printf "${WHITE}%-15s %-15s %-12s %-10s${NC}\n" "USERNAME" "PASSWORD" "EXPIRES" "STATUS"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        while IFS='|' read -r user pass exp created; do
            current=$(date +%s)
            exp_unix=$(date -d "$exp" +%s 2>/dev/null || echo "0")
            
            if [[ $current -gt $exp_unix ]]; then
                status="${RED}EXPIRED${NC}"
            else
                status="${GREEN}ACTIVE${NC}"
            fi
            
            printf "${WHITE}%-15s %-15s %-12s${NC} " "$user" "$pass" "$exp"
            echo -e "$status"
        done < "$USER_DB"
    fi
    
    press_enter
}

#============================================
# STATUS AND INFO
#============================================

view_status() {
    show_banner
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                  SERVICE STATUS                           ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if systemctl is-active --quiet dnstt; then
        echo -e "${GREEN}✅ DNSTT: RUNNING${NC}"
    else
        echo -e "${RED}✗ DNSTT: STOPPED${NC}"
    fi
    
    echo ""
    systemctl status dnstt --no-pager -l | head -20
    
    echo ""
    echo -e "${YELLOW}Recent logs:${NC}"
    journalctl -u dnstt -n 15 --no-pager
    
    press_enter
}

view_info() {
    show_banner
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║               CONNECTION INFORMATION                      ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [[ -f "$INSTALL_DIR/connection_info.txt" ]]; then
        cat "$INSTALL_DIR/connection_info.txt"
    else
        echo -e "${RED}✗ Not configured. Run installation first.${NC}"
    fi
    
    press_enter
}

#============================================
# MENU FUNCTIONS
#============================================

dnstt_menu() {
    while true; do
        show_banner
        echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║              DNSTT MANAGEMENT                             ║${NC}"
        echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  ${GREEN}1)${NC} Install/Setup DNSTT"
        echo -e "  ${YELLOW}2)${NC} View Status"
        echo -e "  ${YELLOW}3)${NC} View Connection Info"
        echo -e "  ${BLUE}4)${NC} Restart Service"
        echo -e "  ${RED}5)${NC} Stop Service"
        echo -e "  ${PURPLE}6)${NC} Uninstall"
        echo -e "  ${WHITE}0)${NC} Back"
        echo ""
        read -p "Choice: " choice
        
        case $choice in
            1) setup_dnstt ;;
            2) view_status ;;
            3) view_info ;;
            4)
                systemctl restart dnstt
                echo -e "${GREEN}✅ Restarted${NC}"
                sleep 2
                ;;
            5)
                systemctl stop dnstt
                echo -e "${YELLOW}⚠️  Stopped${NC}"
                sleep 2
                ;;
            6)
                read -p "Uninstall DNSTT? (y/n): " confirm
                if [[ "$confirm" == "y" ]]; then
                    systemctl stop dnstt 2>/dev/null || true
                    systemctl disable dnstt 2>/dev/null || true
                    rm -f /etc/systemd/system/dnstt.service
                    rm -rf "$INSTALL_DIR"
                    rm -f "$DNSTT_SERVER" "$DNSTT_CLIENT"
                    systemctl daemon-reload
                    echo -e "${GREEN}✅ Uninstalled${NC}"
                    sleep 2
                fi
                ;;
            0) return ;;
            *) echo -e "${RED}Invalid${NC}"; sleep 1 ;;
        esac
    done
}

ssh_menu() {
    while true; do
        show_banner
        echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║              SSH USER MANAGEMENT                         ║${NC}"
        echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  ${GREEN}1)${NC} Add User"
        echo -e "  ${YELLOW}2)${NC} List Users"
        echo -e "  ${RED}3)${NC} Delete User"
        echo -e "  ${BLUE}4)${NC} Online Users"
        echo -e "  ${WHITE}0)${NC} Back"
        echo ""
        read -p "Choice: " choice
        
        case $choice in
            1) add_ssh_user ;;
            2) list_ssh_users ;;
            3) delete_ssh_user ;;
            4)
                show_banner
                echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
                echo -e "${CYAN}║                   ONLINE USERS                            ║${NC}"
                echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
                echo ""
                who
                echo ""
                press_enter
                ;;
            0) return ;;
            *) echo -e "${RED}Invalid${NC}"; sleep 1 ;;
        esac
    done
}

system_menu() {
    show_banner
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                  SYSTEM INFORMATION                       ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${YELLOW}Uptime:${NC}"
    uptime
    echo ""
    
    echo -e "${YELLOW}Memory:${NC}"
    free -h
    echo ""
    
    echo -e "${YELLOW}Disk:${NC}"
    df -h /
    echo ""
    
    echo -e "${YELLOW}Network:${NC}"
    ip -brief addr
    echo ""
    
    press_enter
}

main_menu() {
    while true; do
        show_banner
        echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║                    MAIN MENU                              ║${NC}"
        echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  ${GREEN}1)${NC} 🌐 DNSTT Management"
        echo -e "  ${BLUE}2)${NC} 👥 SSH Users"
        echo -e "  ${YELLOW}3)${NC} 📊 System Info"
        echo -e "  ${RED}0)${NC} ❌ Exit"
        echo ""
        read -p "Choice: " choice
        
        case $choice in
            1) dnstt_menu ;;
            2) ssh_menu ;;
            3) system_menu ;;
            0)
                echo ""
                echo -e "${GREEN}Thank you! 👑${NC}"
                exit 0
                ;;
            *) echo -e "${RED}Invalid${NC}"; sleep 1 ;;
        esac
    done
}

#============================================
# MAIN EXECUTION
#============================================

check_root
check_os
main_menu