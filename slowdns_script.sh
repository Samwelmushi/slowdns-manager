#!/bin/bash

##############################################
# SLOW DNS - DNSTT Management System
# Version: 6.1.0 - Performance Optimized
# Fixed MTU menu & Enhanced for 5-10 Mbps
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
LOG_DIR="/var/log/dnstt"
DNSTT_SERVER="/usr/local/bin/dnstt-server"
DNSTT_CLIENT="/usr/local/bin/dnstt-client"

# Create directories
mkdir -p "$INSTALL_DIR" "$SSH_DIR" "$LOG_DIR"
touch "$USER_DB"

#============================================
# LOGGING SYSTEM
#============================================

log_to_file() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_DIR/dnstt.log"
}

log_message() {
    local message="$1"
    echo -e "${CYAN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $message"
    log_to_file "INFO" "$message"
}

log_error() {
    local message="$1"
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $message"
    log_to_file "ERROR" "$message"
}

log_success() {
    local message="$1"
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] SUCCESS:${NC} $message"
    log_to_file "SUCCESS" "$message"
}

log_warning() {
    local message="$1"
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING:${NC} $message"
    log_to_file "WARNING" "$message"
}

#============================================
# DISPLAY FUNCTIONS
#============================================

show_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
  ╔═══════════════════════════════════════════════════════════╗
  ║         SLOW DNS - DNSTT MANAGER v6.1 OPTIMIZED          ║
  ║              High-Performance Edition (5-10 Mbps)         ║
  ╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
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
        log_error "This script must be run as root"
        echo -e "${YELLOW}Please run: sudo bash $0${NC}"
        exit 1
    fi
}

check_os() {
    if [[ ! -f /etc/debian_version ]] && [[ ! -f /etc/redhat-release ]]; then
        log_error "This script supports Debian/Ubuntu/CentOS only"
        exit 1
    fi
}

#============================================
# SYSTEM OPTIMIZATION FOR HIGH SPEED
#============================================

optimize_system() {
    log_message "${YELLOW}⚡ Optimizing system for high-speed DNS tunneling...${NC}"
    
    # Increase network buffers
    sysctl -w net.core.rmem_max=134217728 > /dev/null 2>&1
    sysctl -w net.core.wmem_max=134217728 > /dev/null 2>&1
    sysctl -w net.core.rmem_default=16777216 > /dev/null 2>&1
    sysctl -w net.core.wmem_default=16777216 > /dev/null 2>&1
    sysctl -w net.ipv4.tcp_rmem="4096 87380 67108864" > /dev/null 2>&1
    sysctl -w net.ipv4.tcp_wmem="4096 65536 67108864" > /dev/null 2>&1
    
    # UDP buffer tuning
    sysctl -w net.ipv4.udp_rmem_min=16384 > /dev/null 2>&1
    sysctl -w net.ipv4.udp_wmem_min=16384 > /dev/null 2>&1
    
    # Connection tracking
    sysctl -w net.netfilter.nf_conntrack_max=1000000 > /dev/null 2>&1
    sysctl -w net.netfilter.nf_conntrack_tcp_timeout_established=7200 > /dev/null 2>&1
    
    # TCP optimizations
    sysctl -w net.ipv4.tcp_congestion_control=bbr > /dev/null 2>&1
    sysctl -w net.core.default_qdisc=fq > /dev/null 2>&1
    sysctl -w net.ipv4.tcp_fastopen=3 > /dev/null 2>&1
    sysctl -w net.ipv4.tcp_slow_start_after_idle=0 > /dev/null 2>&1
    
    # Make permanent
    cat > /etc/sysctl.d/99-dnstt-optimize.conf << 'EOF'
# DNSTT Performance Optimization
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.core.rmem_default = 16777216
net.core.wmem_default = 16777216
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.udp_rmem_min = 16384
net.ipv4.udp_wmem_min = 16384
net.netfilter.nf_conntrack_max = 1000000
net.netfilter.nf_conntrack_tcp_timeout_established = 7200
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_slow_start_after_idle = 0
EOF
    
    log_success "System optimized for high-speed traffic"
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
            dnsutils net-tools sysstat htop \
            2>&1 | grep -v "debconf"
    elif [[ -f /etc/redhat-release ]]; then
        yum install -y wget curl git gcc make \
            iptables iptables-services \
            ca-certificates bind-utils net-tools sysstat htop
    fi
    
    log_success "Dependencies installed"
}

install_golang() {
    if command -v go &> /dev/null; then
        GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
        if [[ "$GO_VERSION" > "1.20" ]]; then
            log_success "Go $GO_VERSION already installed"
            return 0
        fi
    fi
    
    log_message "${YELLOW}📦 Installing Go 1.21.5...${NC}"
    
    cd /tmp
    wget -q --show-progress https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
    
    rm -rf /usr/local/go
    tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
    rm -f go1.21.5.linux-amd64.tar.gz
    
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
    
    log_success "Go $(go version | awk '{print $3}') installed"
}

build_dnstt() {
    log_message "${YELLOW}🔨 Building DNSTT from source...${NC}"
    
    cd /tmp
    rm -rf dnstt
    
    log_message "Cloning DNSTT repository..."
    if ! git clone https://www.bamsoftware.com/git/dnstt.git; then
        log_warning "Trying alternative repository..."
        git clone https://github.com/net4people/bbs.git
        cd bbs/dnstt
    else
        cd dnstt
    fi
    
    export PATH=$PATH:/usr/local/go/bin
    export GOPATH=$HOME/go
    export GOCACHE=$HOME/.cache/go-build
    export GO111MODULE=on
    
    log_message "Building dnstt-server..."
    cd dnstt-server
    if ! go build -v -o "$DNSTT_SERVER"; then
        log_error "Server build failed"
        return 1
    fi
    chmod +x "$DNSTT_SERVER"
    
    log_message "Building dnstt-client..."
    cd ../dnstt-client
    if ! go build -v -o "$DNSTT_CLIENT"; then
        log_error "Client build failed"
        return 1
    fi
    chmod +x "$DNSTT_CLIENT"
    
    if [[ ! -f "$DNSTT_SERVER" ]] || [[ ! -f "$DNSTT_CLIENT" ]]; then
        log_error "Binaries not found after build"
        return 1
    fi
    
    log_success "DNSTT built successfully"
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
    
    NET_INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)
    if [[ -z "$NET_INTERFACE" ]]; then
        NET_INTERFACE=$(ip -o -4 route show to default | awk '{print $5}' | head -1)
    fi
    NET_INTERFACE=${NET_INTERFACE:-eth0}
    
    log_message "Network interface: $NET_INTERFACE"
    
    if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
        log_warning "Stopping systemd-resolved (conflicts with DNS)..."
        systemctl stop systemd-resolved
        systemctl disable systemd-resolved
        
        rm -f /etc/resolv.conf
        cat > /etc/resolv.conf << 'EOF'
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 1.1.1.1
EOF
        chattr +i /etc/resolv.conf 2>/dev/null || true
    fi
    
    iptables -D INPUT -p udp --dport 5300 -j ACCEPT 2>/dev/null || true
    iptables -t nat -D PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300 2>/dev/null || true
    
    iptables -I INPUT -p udp --dport 5300 -j ACCEPT
    iptables -I INPUT -p tcp --dport 22 -j ACCEPT
    iptables -I INPUT -p tcp --dport 443 -j ACCEPT
    iptables -t nat -I PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300
    
    if command -v netfilter-persistent &> /dev/null; then
        netfilter-persistent save > /dev/null 2>&1
    fi
    
    mkdir -p /etc/iptables
    iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
    
    log_success "Firewall configured"
}

#============================================
# KEY GENERATION
#============================================

generate_keys() {
    log_message "${YELLOW}🔑 Generating encryption keys...${NC}"
    
    cd "$INSTALL_DIR"
    rm -f server.key server.pub
    
    if ! "$DNSTT_SERVER" -gen-key -privkey-file server.key -pubkey-file server.pub 2>&1 | tee "$INSTALL_DIR/keygen.log"; then
        log_error "Key generation failed"
        log_message "Trying alternative method..."
        
        openssl rand -hex 32 > server.key
        chmod 600 server.key
        PRIVKEY=$(cat server.key)
        echo "$PRIVKEY" | sha256sum | awk '{print $1}' > server.pub
        chmod 644 server.pub
    fi
    
    if [[ ! -f "server.key" ]] || [[ ! -f "server.pub" ]] || [[ ! -s "server.key" ]] || [[ ! -s "server.pub" ]]; then
        log_error "Key files creation failed"
        return 1
    fi
    
    PUBKEY_LENGTH=$(wc -c < server.pub)
    if [[ $PUBKEY_LENGTH -lt 32 ]]; then
        log_error "Public key is too short (invalid)"
        return 1
    fi
    
    chmod 600 server.key
    chmod 644 server.pub
    
    log_success "Keys generated successfully"
    return 0
}

#============================================
# SERVICE CREATION WITH LOGGING
#============================================

create_service() {
    local tunnel_domain=$1
    local mtu=$2
    local ssh_port=$3
    
    log_message "${YELLOW}📋 Creating systemd service with logging...${NC}"
    
    cat > /etc/systemd/system/dnstt.service << EOF
[Unit]
Description=DNSTT DNS Tunnel Server (High Performance)
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
StandardOutput=append:$LOG_DIR/dnstt-server.log
StandardError=append:$LOG_DIR/dnstt-error.log
SyslogIdentifier=dnstt

# Performance tuning
LimitNOFILE=1048576
LimitNPROC=512

# Security
NoNewPrivileges=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

    # Create log rotation
    cat > /etc/logrotate.d/dnstt << EOF
$LOG_DIR/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root root
}
EOF

    systemctl daemon-reload
    systemctl enable dnstt
    
    log_success "Service created with logging enabled"
}

#============================================
# MAIN SETUP FUNCTION
#============================================

setup_dnstt() {
    show_banner
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              DNSTT INSTALLATION & OPTIMIZATION            ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if systemctl is-active --quiet dnstt 2>/dev/null; then
        log_warning "DNSTT is already running"
        echo ""
        read -p "Reinstall? (y/n): " reinstall
        if [[ "$reinstall" != "y" ]]; then
            return
        fi
        systemctl stop dnstt
        rm -f "$INSTALL_DIR/ns_domain.txt" "$INSTALL_DIR/tunnel_domain.txt"
    fi
    
    echo -e "${CYAN}Starting installation process...${NC}"
    echo ""
    
    if ! install_dependencies; then
        log_error "Failed at: Dependencies"
        press_enter
        return 1
    fi
    
    if ! install_golang; then
        log_error "Failed at: Go installation"
        press_enter
        return 1
    fi
    
    if ! build_dnstt; then
        log_error "Failed at: DNSTT build"
        press_enter
        return 1
    fi
    
    optimize_system
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
    echo -e "${WHITE}Enter your full tunnel domain:${NC}"
    echo -e "${CYAN}Example: tunnel.yourdomain.com${NC}"
    echo ""
    read -p "Tunnel domain: " tunnel_domain
    
    if [[ -z "$tunnel_domain" ]]; then
        base_domain=$(echo "$ns_domain" | awk -F. '{print $(NF-1)"."$NF}')
        tunnel_domain="t.${base_domain}"
    fi
    
    tunnel_domain=$(echo "$tunnel_domain" | sed 's/\.\.*/./g' | sed 's/\.$//')
    
    echo "$ns_domain" > "$INSTALL_DIR/ns_domain.txt"
    echo "$tunnel_domain" > "$INSTALL_DIR/tunnel_domain.txt"
    
    log_success "NS Domain: $ns_domain"
    log_success "Tunnel Domain: $tunnel_domain"
    
    if [[ "$tunnel_domain" =~ \.\. ]]; then
        log_error "Invalid domain format (contains double dots)"
        press_enter
        return 1
    fi
    
    echo ""
    if ! generate_keys; then
        log_error "Failed at: Key generation"
        press_enter
        return 1
    fi
    
    # MTU Configuration - FIXED MENU WITH NUMBERS
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}          MTU CONFIGURATION (Optimized for Speed)${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${WHITE}Select MTU size:${NC}"
    echo ""
    echo -e "  ${CYAN}1)${NC} 768   - Basic (slower, high compatibility)"
    echo -e "  ${CYAN}2)${NC} 1200  - Balanced ${GREEN}⭐ Good${NC}"
    echo -e "  ${CYAN}3)${NC} 1232  - EDNS0 Standard ${GREEN}⭐ Recommended${NC}"
    echo -e "  ${CYAN}4)${NC} 1280  - High Performance ${GREEN}⭐⭐ Best for Speed${NC}"
    echo -e "  ${CYAN}5)${NC} 1420  - Maximum (requires good network)"
    echo -e "  ${CYAN}6)${NC} 1500  - Gigabit (experimental, best networks only)"
    echo ""
    echo -e "${YELLOW}💡 For 5-10 Mbps: Choose option 3 or 4${NC}"
    echo ""
    read -p "Choice [1-6, default=3]: " mtu_choice
    
    case ${mtu_choice:-3} in
        1) MTU=768 ;;
        2) MTU=1200 ;;
        3) MTU=1232 ;;
        4) MTU=1280 ;;
        5) MTU=1420 ;;
        6) MTU=1500 ;;
        *) MTU=1232 ;;
    esac
    
    echo "$MTU" > "$INSTALL_DIR/mtu.txt"
    log_success "MTU: $MTU bytes"
    
    SSH_PORT=$(ss -tlnp 2>/dev/null | grep sshd | awk '{print $4}' | cut -d: -f2 | head -1)
    SSH_PORT=${SSH_PORT:-22}
    echo "$SSH_PORT" > "$INSTALL_DIR/ssh_port.txt"
    log_message "SSH Port: $SSH_PORT"
    
    echo ""
    create_service "$tunnel_domain" "$MTU" "$SSH_PORT"
    
    log_message "${YELLOW}🚀 Starting DNSTT service...${NC}"
    systemctl start dnstt
    sleep 3
    
    if systemctl is-active --quiet dnstt; then
        log_success "Service started successfully"
    else
        log_error "Service failed to start"
        echo ""
        echo -e "${YELLOW}Service logs:${NC}"
        journalctl -u dnstt -n 30 --no-pager
        press_enter
        return 1
    fi
    
    PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com 2>/dev/null || echo "YOUR_SERVER_IP")
    PUBKEY=$(cat "$INSTALL_DIR/server.pub")
    
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
    echo -e "${WHITE}⚡ Expected Speed:${NC}  ${GREEN}5-10 Mbps${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}📋 DNS RECORDS:${NC}"
    echo ""
    echo -e "${GREEN}A Record:${NC}  $ns_domain → $PUBLIC_IP"
    echo -e "${GREEN}NS Record:${NC} $tunnel_domain → $ns_domain"
    echo ""
    echo -e "${YELLOW}📱 CLIENT CONNECTION (High Speed):${NC}"
    echo ""
    echo -e "${CYAN}Recommended (DoH - Cloudflare):${NC}"
    echo -e "${WHITE}dnstt-client -doh https://cloudflare-dns.com/dns-query \\${NC}"
    echo -e "${WHITE}  -pubkey $PUBKEY \\${NC}"
    echo -e "${WHITE}  $tunnel_domain 127.0.0.1:8080${NC}"
    echo ""
    echo -e "${CYAN}Alternative (DoH - Google):${NC}"
    echo -e "${WHITE}dnstt-client -doh https://dns.google/dns-query \\${NC}"
    echo -e "${WHITE}  -pubkey $PUBKEY \\${NC}"
    echo -e "${WHITE}  $tunnel_domain 127.0.0.1:8080${NC}"
    echo ""
    
    # Save connection info
    cat > "$INSTALL_DIR/connection_info.txt" << EOF
╔═══════════════════════════════════════════════════════════╗
║        DNSTT CONNECTION INFO - OPTIMIZED FOR SPEED        ║
╚═══════════════════════════════════════════════════════════╝

Generated: $(date)

SERVER DETAILS:
═══════════════
IP:             $PUBLIC_IP
NS Domain:      $ns_domain
Tunnel Domain:  $tunnel_domain
SSH Port:       $SSH_PORT
MTU:            $MTU bytes
Expected Speed: 5-10 Mbps

PUBLIC KEY:
═══════════
$PUBKEY

DNS RECORDS:
════════════
A    $ns_domain         $PUBLIC_IP
NS   $tunnel_domain     $ns_domain

HIGH-SPEED CLIENT COMMANDS:
════════════════════════════
# Cloudflare DoH (Recommended)
dnstt-client -doh https://cloudflare-dns.com/dns-query -pubkey $PUBKEY $tunnel_domain 127.0.0.1:8080

# Google DoH
dnstt-client -doh https://dns.google/dns-query -pubkey $PUBKEY $tunnel_domain 127.0.0.1:8080

# Quad9 DoH
dnstt-client -doh https://dns.quad9.net/dns-query -pubkey $PUBKEY $tunnel_domain 127.0.0.1:8080

LOGS LOCATION:
══════════════
Server Log: $LOG_DIR/dnstt-server.log
Error Log:  $LOG_DIR/dnstt-error.log
Main Log:   $LOG_DIR/dnstt.log

SPEED OPTIMIZATION TIPS:
════════════════════════
✓ System optimized with BBR congestion control
✓ Network buffers increased for high throughput
✓ Use MTU 1232-1280 for best balance
✓ DoH provides better performance than UDP
✓ Monitor logs: tail -f $LOG_DIR/dnstt-server.log

EOF
    
    log_success "📄 Info saved: $INSTALL_DIR/connection_info.txt"
    press_enter
}

#============================================
# VIEW LOGS
#============================================

view_logs() {
    show_banner
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    DNSTT LOGS                             ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${YELLOW}Select log to view:${NC}"
    echo ""
    echo -e "  ${CYAN}1)${NC} Main Log (dnstt.log)"
    echo -e "  ${CYAN}2)${NC} Server Log (dnstt-server.log)"
    echo -e "  ${CYAN}3)${NC} Error Log (dnstt-error.log)"
    echo -e "  ${CYAN}4)${NC} System Journal (journalctl)"
    echo -e "  ${CYAN}5)${NC} Live Tail (real-time)"
    echo -e "  ${WHITE}0)${NC} Back"
    echo ""
    read -p "Choice: " log_choice
    
    case $log_choice in
        1)
            if [[ -f "$LOG_DIR/dnstt.log" ]]; then
                less +G "$LOG_DIR/dnstt.log"
            else
                echo -e "${RED}Log file not found${NC}"
            fi
            ;;
        2)
            if [[ -f "$LOG_DIR/dnstt-server.log" ]]; then
                less +G "$LOG_DIR/dnstt-server.log"
            else
                echo -e "${RED}Log file not found${NC}"
            fi
            ;;
        3)
            if [[ -f "$LOG_DIR/dnstt-error.log" ]]; then
                less +G "$LOG_DIR/dnstt-error.log"
            else
                echo -e "${RED}No errors logged${NC}"
            fi
            ;;
        4)
            journalctl -u dnstt --no-pager -n 100
            ;;
        5)
            echo -e "${YELLOW}Following logs in real-time (Ctrl+C to stop)...${NC}"
            echo ""
            tail -f "$LOG_DIR/dnstt-server.log" "$LOG_DIR/dnstt-error.log"
            ;;
        0)
            return
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            sleep 1
            ;;
    esac
    
    press_enter
}

#============================================
# PERFORMANCE MONITORING
#============================================

view_performance() {
    show_banner
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              PERFORMANCE MONITORING                       ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Service status
    echo -e "${YELLOW}━━━ SERVICE STATUS ━━━${NC}"
    if systemctl is-active --quiet dnstt; then
        echo -e "${GREEN}✅ DNSTT: RUNNING${NC}"
        
        # Get service uptime
        uptime_sec=$(systemctl show dnstt --property=ActiveEnterTimestampMonotonic --value)
        if [[ -n "$uptime_sec" && "$uptime_sec" != "0" ]]; then
            current_sec=$(date +%s)
            uptime_readable=$(systemctl show dnstt --property=ActiveEnterTimestamp --value)
            echo -e "${WHITE}Uptime: Started at $uptime_readable${NC}"
        fi
    else
        echo -e "${RED}✗ DNSTT: STOPPED${NC}"
    fi
    echo ""
    
    # Network statistics
    echo -e "${YELLOW}━━━ NETWORK STATISTICS ━━━${NC}"
    if command -v ss &> /dev/null; then
        UDP_CONNS=$(ss -u | grep -c ':5300' 2>/dev/null || echo "0")
        echo -e "${WHITE}UDP Connections on port 5300: ${CYAN}$UDP_CONNS${NC}"
    fi
    echo ""
    
    # System resources
    echo -e "${YELLOW}━━━ SYSTEM RESOURCES ━━━${NC}"
    
    # CPU usage
    if command -v mpstat &> /dev/null; then
        CPU_IDLE=$(mpstat 1 1 | awk '/Average/ {print $NF}')
        CPU_USED=$(echo "100 - $CPU_IDLE" | bc 2>/dev/null || echo "N/A")
        echo -e "${WHITE}CPU Usage: ${CYAN}${CPU_USED}%${NC}"
    fi
    
    # Memory
    MEM_TOTAL=$(free -h | awk '/^Mem:/ {print $2}')
    MEM_USED=$(free -h | awk '/^Mem:/ {print $3}')
    MEM_PERCENT=$(free | awk '/^Mem:/ {printf "%.1f", $3/$2*100}')
    echo -e "${WHITE}Memory: ${CYAN}${MEM_USED}/${MEM_TOTAL} (${MEM_PERCENT}%)${NC}"
    
    # Network traffic
    echo ""
    echo -e "${YELLOW}━━━ NETWORK TRAFFIC (last 5 seconds) ━━━${NC}"
    NET_INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)
    if [[ -n "$NET_INTERFACE" ]]; then
        RX1=$(cat /sys/class/net/$NET_INTERFACE/statistics/rx_bytes 2>/dev/null || echo "0")
        TX1=$(cat /sys/class/net/$NET_INTERFACE/statistics/tx_bytes 2>/dev/null || echo "0")
        sleep 5
        RX2=$(cat /sys/class/net/$NET_INTERFACE/statistics/rx_bytes 2>/dev/null || echo "0")
        TX2=$(cat /sys/class/net/$NET_INTERFACE/statistics/tx_bytes 2>/dev/null || echo "0")
        
        RX_RATE=$(( (RX2 - RX1) / 5 ))
        TX_RATE=$(( (TX2 - TX1) / 5 ))
        
        RX_MBPS=$(echo "scale=2; $RX_RATE * 8 / 1000000" | bc 2>/dev/null || echo "0")
        TX_MBPS=$(echo "scale=2; $TX_RATE * 8 / 1000000" | bc 2>/dev/null || echo "0")
        
        echo -e "${WHITE}Download: ${GREEN}${RX_MBPS} Mbps${NC}"
        echo -e "${WHITE}Upload:   ${GREEN}${TX_MBPS} Mbps${NC}"
    fi
    
    echo ""
    echo -e "${YELLOW}━━━ CONFIGURATION ━━━${NC}"
    if [[ -f "$INSTALL_DIR/mtu.txt" ]]; then
        MTU=$(cat "$INSTALL_DIR/mtu.txt")
        echo -e "${WHITE}MTU: ${CYAN}${MTU} bytes${NC}"
    fi
    if [[ -f "$INSTALL_DIR/tunnel_domain.txt" ]]; then
        DOMAIN=$(cat "$INSTALL_DIR/tunnel_domain.txt")
        echo -e "${WHITE}Domain: ${CYAN}${DOMAIN}${NC}"
    fi
    
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
        log_error "Username required"
        press_enter
        return
    fi
    
    if id "$username" &>/dev/null; then
        log_error "User exists"
        press_enter
        return
    fi
    
    read -sp "Password: " password
    echo ""
    
    if [[ -z "$password" ]]; then
        log_error "Password required"
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
    
    useradd -m -s /bin/bash "$username"
    echo "$username:$password" | chpasswd
    
    exp_date=$(date -d "+$days days" +"%Y-%m-%d")
    chage -E "$exp_date" "$username"
    
    echo "$username|$password|$exp_date|$(date +"%Y-%m-%d")" >> "$USER_DB"
    
    log_success "User created"
    echo -e "${WHITE}Username: ${YELLOW}$username${NC}"
    echo -e "${WHITE}Password: ${YELLOW}$password${NC}"
    echo -e "${WHITE}Expires:  ${YELLOW}$exp_date${NC}"
    
    log_to_file "INFO" "SSH user created: $username (expires: $exp_date)"
    
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
        log_error "User not found"
        press_enter
        return
    fi
    
    echo ""
    read -p "Delete '$username'? (y/n): " confirm
    
    if [[ "$confirm" == "y" ]]; then
        pkill -u "$username" 2>/dev/null || true
        userdel -r "$username" 2>/dev/null || true
        sed -i "/^$username|/d" "$USER_DB"
        log_success "User deleted"
        log_to_file "INFO" "SSH user deleted: $username"
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
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
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
        log_error "Not configured. Run installation first."
    fi
    
    press_enter
}

#============================================
# QUICK FIX FOR BROKEN DOMAIN
#============================================

fix_domain() {
    show_banner
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                  FIX DOMAIN ISSUE                         ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [[ ! -f "$INSTALL_DIR/tunnel_domain.txt" ]]; then
        log_error "No configuration found"
        press_enter
        return
    fi
    
    echo -e "${YELLOW}Current domain:${NC}"
    cat "$INSTALL_DIR/tunnel_domain.txt"
    echo ""
    
    echo -e "${WHITE}Enter the CORRECT tunnel domain:${NC}"
    echo -e "${CYAN}Example: t.yourdomain.com${NC}"
    echo ""
    read -p "Correct tunnel domain: " correct_domain
    
    if [[ -z "$correct_domain" ]]; then
        log_error "Domain required"
        press_enter
        return
    fi
    
    correct_domain=$(echo "$correct_domain" | sed 's/\.\.*/./g' | sed 's/\.$//')
    
    if [[ "$correct_domain" =~ \.\. ]]; then
        log_error "Invalid domain (contains double dots)"
        press_enter
        return
    fi
    
    MTU=$(cat "$INSTALL_DIR/mtu.txt" 2>/dev/null || echo "1232")
    SSH_PORT=$(cat "$INSTALL_DIR/ssh_port.txt" 2>/dev/null || echo "22")
    
    echo "$correct_domain" > "$INSTALL_DIR/tunnel_domain.txt"
    
    log_message "Recreating service with correct domain..."
    create_service "$correct_domain" "$MTU" "$SSH_PORT"
    
    systemctl daemon-reload
    systemctl restart dnstt
    
    sleep 2
    
    if systemctl is-active --quiet dnstt; then
        log_success "Fixed! Service is now running"
        echo ""
        echo -e "${WHITE}Tunnel Domain: ${YELLOW}$correct_domain${NC}"
        echo -e "${WHITE}MTU: ${YELLOW}$MTU${NC}"
        echo -e "${WHITE}SSH Port: ${YELLOW}$SSH_PORT${NC}"
    else
        log_error "Still failing. Check logs:"
        journalctl -u dnstt -n 10 --no-pager
    fi
    
    press_enter
}

#============================================
# BANDWIDTH TEST
#============================================

bandwidth_test() {
    show_banner
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                  BANDWIDTH TEST                           ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if ! systemctl is-active --quiet dnstt; then
        log_error "DNSTT service is not running"
        press_enter
        return
    fi
    
    echo -e "${YELLOW}Testing bandwidth for 30 seconds...${NC}"
    echo -e "${CYAN}Monitoring UDP traffic on port 5300${NC}"
    echo ""
    
    NET_INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)
    if [[ -z "$NET_INTERFACE" ]]; then
        log_error "Could not detect network interface"
        press_enter
        return
    fi
    
    echo -e "${WHITE}Interface: ${CYAN}$NET_INTERFACE${NC}"
    echo ""
    
    # Initial reading
    RX1=$(cat /sys/class/net/$NET_INTERFACE/statistics/rx_bytes)
    TX1=$(cat /sys/class/net/$NET_INTERFACE/statistics/tx_bytes)
    
    echo -e "${YELLOW}Measuring... (30 seconds)${NC}"
    
    for i in {1..30}; do
        echo -ne "\rProgress: [$i/30] "
        sleep 1
    done
    echo ""
    
    # Final reading
    RX2=$(cat /sys/class/net/$NET_INTERFACE/statistics/rx_bytes)
    TX2=$(cat /sys/class/net/$NET_INTERFACE/statistics/tx_bytes)
    
    # Calculate rates
    RX_BYTES=$(( RX2 - RX1 ))
    TX_BYTES=$(( TX2 - TX1 ))
    
    RX_MBPS=$(echo "scale=2; $RX_BYTES * 8 / 30 / 1000000" | bc)
    TX_MBPS=$(echo "scale=2; $TX_BYTES * 8 / 30 / 1000000" | bc)
    
    RX_MB=$(echo "scale=2; $RX_BYTES / 1048576" | bc)
    TX_MB=$(echo "scale=2; $TX_BYTES / 1048576" | bc)
    
    echo ""
    echo -e "${GREEN}━━━ TEST RESULTS ━━━${NC}"
    echo ""
    echo -e "${WHITE}Download:${NC}"
    echo -e "  Rate: ${GREEN}${RX_MBPS} Mbps${NC}"
    echo -e "  Data: ${CYAN}${RX_MB} MB${NC}"
    echo ""
    echo -e "${WHITE}Upload:${NC}"
    echo -e "  Rate: ${GREEN}${TX_MBPS} Mbps${NC}"
    echo -e "  Data: ${CYAN}${TX_MB} MB${NC}"
    echo ""
    
    # Performance assessment
    TOTAL_MBPS=$(echo "$RX_MBPS + $TX_MBPS" | bc)
    TOTAL_MBPS_INT=$(printf "%.0f" "$TOTAL_MBPS")
    
    if (( $(echo "$TOTAL_MBPS >= 5" | bc -l) )); then
        echo -e "${GREEN}✅ Performance: EXCELLENT (Target 5-10 Mbps achieved)${NC}"
    elif (( $(echo "$TOTAL_MBPS >= 2" | bc -l) )); then
        echo -e "${YELLOW}⚠️  Performance: GOOD (Consider optimizing MTU)${NC}"
    else
        echo -e "${RED}❌ Performance: NEEDS IMPROVEMENT${NC}"
        echo -e "${YELLOW}   Try increasing MTU to 1232 or 1280${NC}"
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
        echo -e "  ${CYAN}4)${NC} View Logs"
        echo -e "  ${CYAN}5)${NC} Performance Monitor"
        echo -e "  ${CYAN}6)${NC} Bandwidth Test"
        echo -e "  ${PURPLE}7)${NC} Fix Domain Issue"
        echo -e "  ${BLUE}8)${NC} Restart Service"
        echo -e "  ${RED}9)${NC} Stop Service"
        echo -e "  ${RED}10)${NC} Uninstall"
        echo -e "  ${WHITE}0)${NC} Back"
        echo ""
        read -p "Choice: " choice
        
        case $choice in
            1) setup_dnstt ;;
            2) view_status ;;
            3) view_info ;;
            4) view_logs ;;
            5) view_performance ;;
            6) bandwidth_test ;;
            7) fix_domain ;;
            8)
                systemctl restart dnstt
                log_success "Service restarted"
                sleep 2
                ;;
            9)
                systemctl stop dnstt
                log_warning "Service stopped"
                sleep 2
                ;;
            10)
                read -p "Uninstall DNSTT? (y/n): " confirm
                if [[ "$confirm" == "y" ]]; then
                    systemctl stop dnstt 2>/dev/null || true
                    systemctl disable dnstt 2>/dev/null || true
                    rm -f /etc/systemd/system/dnstt.service
                    rm -rf "$INSTALL_DIR" "$LOG_DIR"
                    rm -f "$DNSTT_SERVER" "$DNSTT_CLIENT"
                    rm -f /etc/sysctl.d/99-dnstt-optimize.conf
                    systemctl daemon-reload
                    log_success "Uninstalled"
                    sleep 2
                fi
                ;;
            0) return ;;
            *) log_error "Invalid choice"; sleep 1 ;;
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
                echo -e "${YELLOW}Active SSH sessions:${NC}"
                ss -tn state established '( dport = :22 or sport = :22 )' | grep -v "Recv-Q" | wc -l
                echo ""
                press_enter
                ;;
            0) return ;;
            *) log_error "Invalid choice"; sleep 1 ;;
        esac
    done
}

system_menu() {
    show_banner
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                  SYSTEM INFORMATION                       ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${YELLOW}━━━ UPTIME ━━━${NC}"
    uptime
    echo ""
    
    echo -e "${YELLOW}━━━ MEMORY ━━━${NC}"
    free -h
    echo ""
    
    echo -e "${YELLOW}━━━ DISK ━━━${NC}"
    df -h /
    echo ""
    
    echo -e "${YELLOW}━━━ NETWORK ━━━${NC}"
    ip -brief addr
    echo ""
    
    echo -e "${YELLOW}━━━ SYSTEM OPTIMIZATIONS ━━━${NC}"
    if [[ -f /etc/sysctl.d/99-dnstt-optimize.conf ]]; then
        echo -e "${GREEN}✅ BBR Congestion Control enabled${NC}"
        echo -e "${GREEN}✅ Network buffers optimized${NC}"
        echo -e "${GREEN}✅ TCP FastOpen enabled${NC}"
    else
        echo -e "${YELLOW}⚠️  No optimizations applied${NC}"
    fi
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
        echo -e "  ${RED}0)${NC} ⛔ Exit"
        echo ""
        read -p "Choice: " choice
        
        case $choice in
            1) dnstt_menu ;;
            2) ssh_menu ;;
            3) system_menu ;;
            0)
                echo ""
                log_success "Thank you! 👋"
                exit 0
                ;;
            *) log_error "Invalid choice"; sleep 1 ;;
        esac
    done
}

#============================================
# MAIN EXECUTION
#============================================

check_root
check_os
main_menu
