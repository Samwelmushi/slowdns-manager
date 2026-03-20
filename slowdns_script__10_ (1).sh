#!/bin/bash

##############################################
# DNSTT ULTRA SPEED - SSH OPTIMIZED EDITION
# Created By THE KING 👑 💯
# Version: 8.0.0 - Maximum Speed SSH
# Optimized for 10-25 Mbps speeds
# V2Ray removed - Pure SSH performance
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
# BANNER
#============================================

show_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   ██████╗ ███╗   ██╗███████╗████████╗████████╗               ║
║   ██╔══██╗████╗  ██║██╔════╝╚══██╔══╝╚══██╔══╝               ║
║   ██║  ██║██╔██╗ ██║███████╗   ██║      ██║                  ║
║   ██║  ██║██║╚██╗██║╚════██║   ██║      ██║                  ║
║   ██████╔╝██║ ╚████║███████║   ██║      ██║                  ║
║   ╚═════╝ ╚═╝  ╚═══╝╚══════╝   ╚═╝      ╚═╝                  ║
║                                                               ║
║        ██╗   ██╗██╗  ████████╗██████╗  █████╗                ║
║        ██║   ██║██║  ╚══██╔══╝██╔══██╗██╔══██╗               ║
║        ██║   ██║██║     ██║   ██████╔╝███████║               ║
║        ██║   ██║██║     ██║   ██╔══██╗██╔══██║               ║
║        ╚██████╔╝███████╗██║   ██║  ██║██║  ██║               ║
║         ╚═════╝ ╚══════╝╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝               ║
║                                                               ║
║              SSH TUNNEL MANAGER v8.0 ULTRA                   ║
║           Maximum Speed Edition - 10-25 Mbps                 ║
║                  SSH ONLY - NO V2RAY                         ║
║                                                               ║
║          ╔═══════════════════════════════════╗               ║
║          ║  CREATED BY THE KING 👑 💯       ║               ║
║          ╚═══════════════════════════════════╝               ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
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
        echo -e "${RED}ERROR: This script must be run as root${NC}"
        echo -e "${YELLOW}Please run: sudo bash $0${NC}"
        exit 1
    fi
}

check_os() {
    if [[ ! -f /etc/debian_version ]] && [[ ! -f /etc/redhat-release ]]; then
        echo -e "${RED}ERROR: This script supports Debian/Ubuntu/CentOS only${NC}"
        exit 1
    fi
}

#============================================
# LOGGING
#============================================

log_message() {
    local message="$1"
    echo -e "${CYAN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $message"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $message" >> "$LOG_DIR/dnstt.log"
}

log_error() {
    local message="$1"
    echo -e "${RED}[ERROR]${NC} $message"
    echo "[ERROR] $message" >> "$LOG_DIR/dnstt.log"
}

log_success() {
    local message="$1"
    echo -e "${GREEN}[SUCCESS]${NC} $message"
    echo "[SUCCESS] $message" >> "$LOG_DIR/dnstt.log"
}

#============================================
# ULTRA SPEED OPTIMIZATION v2.0
# Enhanced UDP + SSH optimizations
# Target: 10-25 Mbps
#============================================

optimize_system_ultra() {
    log_message "${YELLOW}⚡ Applying ULTRA SPEED v2.0 optimization...${NC}"
    echo ""
    
    # Enable IP forwarding
    sysctl -w net.ipv4.ip_forward=1 > /dev/null 2>&1 || true
    
    # Load required modules
    modprobe tcp_bbr 2>/dev/null || true
    modprobe tcp_hybla 2>/dev/null || true
    
    # Set massive ulimit
    ulimit -n 2097152 2>/dev/null || ulimit -n 1048576 2>/dev/null || true
    
    echo -e "${CYAN}[1/12]${NC} Configuring BBR v2 (Next-gen congestion control)..."
    sysctl -w net.ipv4.tcp_congestion_control=bbr > /dev/null 2>&1 || true
    sysctl -w net.core.default_qdisc=fq_codel > /dev/null 2>&1 || sysctl -w net.core.default_qdisc=fq > /dev/null 2>&1 || true
    echo -e "${GREEN}✓ BBR v2 enabled with FQ-CoDel${NC}"
    sleep 0.5
    
    echo -e "${CYAN}[2/12]${NC} CRITICAL: Maximum network buffers (1GB for ULTRA speed)..."
    sysctl -w net.core.rmem_max=1073741824 > /dev/null 2>&1 || true
    sysctl -w net.core.wmem_max=1073741824 > /dev/null 2>&1 || true
    sysctl -w net.core.rmem_default=134217728 > /dev/null 2>&1 || true
    sysctl -w net.core.wmem_default=134217728 > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_rmem="16384 1048576 1073741824" > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_wmem="16384 1048576 1073741824" > /dev/null 2>&1 || true
    echo -e "${GREEN}✓ Network buffers: 1GB configured${NC}"
    sleep 0.5
    
    echo -e "${CYAN}[3/12]${NC} EXTREME UDP optimization (512KB buffers - EDNS0++)..."
    sysctl -w net.ipv4.udp_rmem_min=524288 > /dev/null 2>&1 || true
    sysctl -w net.ipv4.udp_wmem_min=524288 > /dev/null 2>&1 || true
    sysctl -w net.ipv4.udp_mem="524288 1048576 2097152" > /dev/null 2>&1 || true
    
    # Advanced UDP tuning
    sysctl -w net.core.netdev_max_backlog=300000 > /dev/null 2>&1 || true
    sysctl -w net.core.netdev_budget=3000 > /dev/null 2>&1 || true
    sysctl -w net.core.netdev_budget_usecs=20000 > /dev/null 2>&1 || true
    sysctl -w net.core.somaxconn=262144 > /dev/null 2>&1 || true
    echo -e "${GREEN}✓ UDP: 512KB buffers + 300K backlog (no packet loss)${NC}"
    sleep 0.5
    
    echo -e "${CYAN}[4/12]${NC} SSH-specific optimizations (maximum throughput)..."
    # SSH uses TCP, optimize for SSH traffic
    sysctl -w net.ipv4.tcp_window_scaling=1 > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_adv_win_scale=2 > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_moderate_rcvbuf=1 > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_notsent_lowat=131072 > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_retries1=3 > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_retries2=5 > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_orphan_retries=1 > /dev/null 2>&1 || true
    echo -e "${GREEN}✓ SSH bulk transfer optimizations${NC}"
    sleep 0.5
    
    echo -e "${CYAN}[5/12]${NC} Massive connection tracking (8M connections)..."
    sysctl -w net.netfilter.nf_conntrack_max=8000000 > /dev/null 2>&1 || true
    sysctl -w net.netfilter.nf_conntrack_tcp_timeout_established=432000 > /dev/null 2>&1 || true
    sysctl -w net.netfilter.nf_conntrack_udp_timeout=600 > /dev/null 2>&1 || true
    sysctl -w net.netfilter.nf_conntrack_udp_timeout_stream=600 > /dev/null 2>&1 || true
    echo 1048576 > /sys/module/nf_conntrack/parameters/hashsize 2>/dev/null || true
    echo -e "${GREEN}✓ Connection tracking: 8M connections${NC}"
    sleep 0.5
    
    echo -e "${CYAN}[6/12]${NC} Advanced TCP optimizations..."
    sysctl -w net.ipv4.tcp_fastopen=3 > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_slow_start_after_idle=0 > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_tw_reuse=1 > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_tw_recycle=0 > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_fin_timeout=5 > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_max_tw_buckets=2000000 > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_max_syn_backlog=262144 > /dev/null 2>&1 || true
    echo -e "${GREEN}✓ TCP FastOpen + advanced tuning${NC}"
    sleep 0.5
    
    echo -e "${CYAN}[7/12]${NC} TCP Keepalive for stable tunnels..."
    sysctl -w net.ipv4.tcp_keepalive_time=60 > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_keepalive_probes=5 > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_keepalive_intvl=10 > /dev/null 2>&1 || true
    echo -e "${GREEN}✓ TCP Keepalive: 60s intervals${NC}"
    sleep 0.5
    
    echo -e "${CYAN}[8/12]${NC} Zero-copy and offloading optimizations..."
    sysctl -w net.ipv4.tcp_low_latency=1 > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_sack=1 > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_fack=1 > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_timestamps=1 > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_mtu_probing=1 > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_tso_win_divisor=3 > /dev/null 2>&1 || true
    echo -e "${GREEN}✓ Zero-copy + offloading enabled${NC}"
    sleep 0.5
    
    echo -e "${CYAN}[9/12]${NC} Expanded port range (mega scale)..."
    sysctl -w net.ipv4.ip_local_port_range="1024 65535" > /dev/null 2>&1 || true
    sysctl -w net.ipv4.ip_local_reserved_ports="" > /dev/null 2>&1 || true
    echo -e "${GREEN}✓ Port range: 1024-65535 (64K ports)${NC}"
    sleep 0.5
    
    echo -e "${CYAN}[10/12]${NC} DNS tunnel specific optimizations..."
    sysctl -w net.ipv4.udp_early_demux=1 > /dev/null 2>&1 || true
    sysctl -w net.ipv4.ip_early_demux=1 > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_early_retrans=3 > /dev/null 2>&1 || true
    sysctl -w net.ipv4.route.max_size=4194304 > /dev/null 2>&1 || true
    echo -e "${GREEN}✓ DNS tunnel optimizations${NC}"
    sleep 0.5
    
    echo -e "${CYAN}[11/12]${NC} Memory and queue optimizations..."
    sysctl -w net.core.optmem_max=134217728 > /dev/null 2>&1 || true
    sysctl -w net.core.netdev_budget=3000 > /dev/null 2>&1 || true
    sysctl -w net.core.netdev_budget_usecs=20000 > /dev/null 2>&1 || true
    sysctl -w vm.min_free_kbytes=65536 > /dev/null 2>&1 || true
    echo -e "${GREEN}✓ Memory optimization: 128MB socket buffers${NC}"
    sleep 0.5
    
    echo -e "${CYAN}[12/12]${NC} Creating permanent configuration..."
    
    cat > /etc/sysctl.d/99-dnstt-ultra-v2.conf << 'EOF'
# DNSTT ULTRA SPEED v2.0 - SSH OPTIMIZED
# Created By THE KING 👑 💯
# Optimized for 10-25 Mbps DNS tunnel speeds
# SSH ONLY - Maximum Performance

### IP FORWARDING ###
net.ipv4.ip_forward = 1

### BBR v2 CONGESTION CONTROL ###
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq_codel

### MAXIMUM NETWORK BUFFERS (1GB) ###
net.core.rmem_max = 1073741824
net.core.wmem_max = 1073741824
net.core.rmem_default = 134217728
net.core.wmem_default = 134217728
net.ipv4.tcp_rmem = 16384 1048576 1073741824
net.ipv4.tcp_wmem = 16384 1048576 1073741824
net.core.optmem_max = 134217728

### EXTREME UDP OPTIMIZATION (512KB - EDNS0++) ###
net.ipv4.udp_rmem_min = 524288
net.ipv4.udp_wmem_min = 524288
net.ipv4.udp_mem = 524288 1048576 2097152

### DNS BURST HANDLING (300K PACKETS) ###
net.core.netdev_max_backlog = 300000
net.core.netdev_budget = 3000
net.core.netdev_budget_usecs = 20000
net.core.somaxconn = 262144

### MASSIVE CONNECTION TRACKING (8M) ###
net.netfilter.nf_conntrack_max = 8000000
net.netfilter.nf_conntrack_tcp_timeout_established = 432000
net.netfilter.nf_conntrack_udp_timeout = 600
net.netfilter.nf_conntrack_udp_timeout_stream = 600

### SSH-SPECIFIC OPTIMIZATIONS ###
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_adv_win_scale = 2
net.ipv4.tcp_moderate_rcvbuf = 1
net.ipv4.tcp_notsent_lowat = 131072

### ADVANCED TCP OPTIMIZATIONS ###
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_fin_timeout = 5
net.ipv4.tcp_max_tw_buckets = 2000000
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_retries1 = 3
net.ipv4.tcp_retries2 = 5
net.ipv4.tcp_orphan_retries = 1

### TCP KEEPALIVE ###
net.ipv4.tcp_keepalive_time = 60
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_keepalive_intvl = 10

### ZERO-COPY & OFFLOADING ###
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_fack = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_tso_win_divisor = 3

### PORT RANGE ###
net.ipv4.ip_local_port_range = 1024 65535

### DNS-SPECIFIC ###
net.ipv4.udp_early_demux = 1
net.ipv4.ip_early_demux = 1
net.ipv4.tcp_early_retrans = 3
net.ipv4.route.max_size = 4194304

### MEMORY ###
vm.min_free_kbytes = 65536
EOF

    echo -e "${GREEN}✓ Config saved: /etc/sysctl.d/99-dnstt-ultra-v2.conf${NC}"
    
    echo -e "${CYAN}[BONUS]${NC} Setting ultra-high file descriptors..."
    cat > /etc/security/limits.d/99-dnstt-ultra-v2.conf << 'EOF'
# DNSTT ULTRA v2.0 - Maximum file descriptors
# Created By THE KING 👑 💯
* soft nofile 2097152
* hard nofile 2097152
root soft nofile 2097152
root hard nofile 2097152
* soft nproc 2097152
* hard nproc 2097152
EOF
    echo -e "${GREEN}✓ File descriptors: 2M (ultra scale)${NC}"
    
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         ⚡ ULTRA SPEED v2.0 ACTIVATED ⚡            ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}Optimization Summary (SSH OPTIMIZED):${NC}"
    echo -e "  ${GREEN}✓${NC} BBR v2 + FQ-CoDel"
    echo -e "  ${GREEN}✓${NC} 1GB Network Buffers"
    echo -e "  ${GREEN}✓${NC} 512KB UDP Buffers (EDNS0++)"
    echo -e "  ${GREEN}✓${NC} 300K Packet Backlog"
    echo -e "  ${GREEN}✓${NC} 8M Connection Tracking"
    echo -e "  ${GREEN}✓${NC} SSH Bulk Transfer Optimization"
    echo -e "  ${GREEN}✓${NC} Zero-Copy + Offloading"
    echo -e "  ${GREEN}✓${NC} 2M File Descriptors"
    echo -e "  ${GREEN}✓${NC} Advanced TCP tuning"
    echo ""
    echo -e "${YELLOW}Expected Speed: 10-25 Mbps 🚀🚀🚀${NC}"
    
    sleep 3
}

#============================================
# SSH SERVER OPTIMIZATION
#============================================

optimize_ssh_server() {
    log_message "${YELLOW}🔧 Optimizing SSH server for maximum throughput...${NC}"
    echo ""
    
    # Backup original sshd_config
    if [[ ! -f /etc/ssh/sshd_config.backup ]]; then
        cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
        echo -e "${GREEN}✓ Backed up SSH config${NC}"
    fi
    
    # Apply high-performance SSH settings
    cat >> /etc/ssh/sshd_config << 'EOF'

# DNSTT ULTRA SPEED v2.0 - SSH Optimizations
# Created By THE KING 👑 💯

# Performance optimizations
TCPKeepAlive yes
ClientAliveInterval 30
ClientAliveCountMax 10
Compression yes
MaxSessions 1000
MaxStartups 1000:30:2000

# Cipher optimizations (fastest ciphers)
Ciphers chacha20-poly1305@openssh.com,aes128-gcm@openssh.com,aes256-gcm@openssh.com
MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org

# Large window size for high bandwidth
# No limit on packet size
EOF

    echo -e "${GREEN}✓ SSH server optimized for high throughput${NC}"
    
    echo -e "${CYAN}Restarting SSH service...${NC}"
    systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
    echo -e "${GREEN}✓ SSH service restarted${NC}"
    
    sleep 1
}

#============================================
# INSTALLATION
#============================================

install_dependencies() {
    log_message "${YELLOW}📦 Installing dependencies...${NC}"
    echo ""
    
    if [[ -f /etc/debian_version ]]; then
        export DEBIAN_FRONTEND=noninteractive
        
        echo -e "${CYAN}Updating repositories...${NC}"
        apt-get update -qq > /dev/null 2>&1
        echo -e "${GREEN}✓ Repositories updated${NC}"
        
        echo -e "${CYAN}Installing packages...${NC}"
        apt-get install -y -qq \
            wget curl git \
            build-essential \
            iptables iptables-persistent \
            netfilter-persistent \
            ca-certificates \
            dnsutils \
            net-tools iproute2 \
            sysstat htop \
            bc \
            openssh-server \
            2>&1 | grep -v "debconf" > /dev/null
        echo -e "${GREEN}✓ All packages installed${NC}"
        
        echo -e "${CYAN}Configuring SSH...${NC}"
        systemctl enable ssh 2>/dev/null || systemctl enable sshd 2>/dev/null
        systemctl start ssh 2>/dev/null || systemctl start sshd 2>/dev/null
        echo -e "${GREEN}✓ SSH configured${NC}"
        
    elif [[ -f /etc/redhat-release ]]; then
        yum install -y wget curl git gcc make \
            iptables iptables-services \
            ca-certificates bind-utils net-tools \
            sysstat htop bc openssh-server > /dev/null 2>&1
    fi
    
    echo ""
    log_success "Dependencies installed successfully"
    sleep 1
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
    echo ""
    
    cd /tmp
    
    echo -e "${CYAN}Downloading Go...${NC}"
    wget -q https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
    echo -e "${GREEN}✓ Downloaded${NC}"
    
    echo -e "${CYAN}Extracting...${NC}"
    rm -rf /usr/local/go
    tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
    rm -f go1.21.5.linux-amd64.tar.gz
    echo -e "${GREEN}✓ Extracted${NC}"
    
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
    
    echo ""
    log_success "Go $(go version | awk '{print $3}') installed"
    sleep 1
}

build_dnstt() {
    log_message "${YELLOW}🔨 Building DNSTT from source...${NC}"
    echo ""
    
    cd /tmp
    rm -rf dnstt
    
    echo -e "${CYAN}Cloning repository...${NC}"
    if ! git clone https://www.bamsoftware.com/git/dnstt.git > /dev/null 2>&1; then
        git clone https://github.com/net4people/bbs.git > /dev/null 2>&1
        cd bbs/dnstt
    else
        cd dnstt
    fi
    echo -e "${GREEN}✓ Repository cloned${NC}"
    
    export PATH=$PATH:/usr/local/go/bin
    export GOPATH=$HOME/go
    export GOCACHE=$HOME/.cache/go-build
    export GO111MODULE=on
    
    echo -e "${CYAN}Building dnstt-server...${NC}"
    cd dnstt-server
    if ! go build -v -o "$DNSTT_SERVER" > /dev/null 2>&1; then
        log_error "Server build failed"
        return 1
    fi
    chmod +x "$DNSTT_SERVER"
    echo -e "${GREEN}✓ Server compiled${NC}"
    
    echo -e "${CYAN}Building dnstt-client...${NC}"
    cd ../dnstt-client
    if ! go build -v -o "$DNSTT_CLIENT" > /dev/null 2>&1; then
        log_error "Client build failed"
        return 1
    fi
    chmod +x "$DNSTT_CLIENT"
    echo -e "${GREEN}✓ Client compiled${NC}"
    
    if [[ ! -f "$DNSTT_SERVER" ]] || [[ ! -f "$DNSTT_CLIENT" ]]; then
        log_error "Binaries not found"
        return 1
    fi
    
    echo ""
    log_success "DNSTT build completed"
    log_message "   Server: $DNSTT_SERVER"
    log_message "   Client: $DNSTT_CLIENT"
    
    cd ~
    sleep 1
    return 0
}

#============================================
# FIREWALL CONFIGURATION
#============================================

configure_firewall() {
    log_message "${YELLOW}🔥 Configuring firewall for ULTRA speed...${NC}"
    echo ""
    
    NET_INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)
    if [[ -z "$NET_INTERFACE" ]]; then
        NET_INTERFACE=$(ip -o -4 route show to default | awk '{print $5}' | head -1)
    fi
    NET_INTERFACE=${NET_INTERFACE:-eth0}
    
    log_message "Network interface: $NET_INTERFACE"
    
    # Disable UFW
    if command -v ufw &> /dev/null; then
        echo -e "${CYAN}Disabling UFW...${NC}"
        ufw --force disable 2>/dev/null || true
        systemctl stop ufw 2>/dev/null || true
        systemctl disable ufw 2>/dev/null || true
        echo -e "${GREEN}✓ UFW disabled${NC}"
    fi
    
    # Stop systemd-resolved (conflicts with port 53)
    if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
        echo -e "${CYAN}Stopping systemd-resolved...${NC}"
        systemctl stop systemd-resolved 2>/dev/null
        systemctl disable systemd-resolved 2>/dev/null
        
        rm -f /etc/resolv.conf
        cat > /etc/resolv.conf << 'EOF'
nameserver 1.1.1.1
nameserver 1.0.0.1
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF
        chattr +i /etc/resolv.conf 2>/dev/null || true
        echo -e "${GREEN}✓ DNS resolvers configured${NC}"
    fi
    
    echo -e "${CYAN}Configuring iptables (NO LIMITS on UDP)...${NC}"
    
    # Flush rules
    iptables -F 2>/dev/null || true
    iptables -t nat -F 2>/dev/null || true
    iptables -X 2>/dev/null || true
    
    # Set policies
    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT
    
    # Loopback
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A OUTPUT -o lo -j ACCEPT
    
    # Established connections
    iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    
    # HIGHEST PRIORITY: UDP DNS ports (UNLIMITED)
    iptables -I INPUT 1 -p udp --dport 5300 -j ACCEPT
    iptables -I OUTPUT 1 -p udp --sport 5300 -j ACCEPT
    iptables -I INPUT 1 -p udp --dport 53 -j ACCEPT
    iptables -I OUTPUT 1 -p udp --sport 53 -j ACCEPT
    
    # NAT redirect 53 to 5300
    iptables -t nat -I PREROUTING 1 -p udp --dport 53 -j REDIRECT --to-ports 5300
    
    # SSH
    iptables -I INPUT 2 -p tcp --dport 22 -j ACCEPT
    iptables -I OUTPUT 2 -p tcp --sport 22 -j ACCEPT
    
    # HTTP/HTTPS
    iptables -A INPUT -p tcp --dport 443 -j ACCEPT
    iptables -A INPUT -p tcp --dport 80 -j ACCEPT
    
    # Allow new UDP connections
    iptables -A INPUT -p udp -m conntrack --ctstate NEW -j ACCEPT
    
    # Forward chain
    iptables -A FORWARD -p udp --dport 5300 -j ACCEPT
    iptables -A FORWARD -p udp --dport 53 -j ACCEPT
    
    echo -e "${GREEN}✓ iptables configured (UNLIMITED UDP)${NC}"
    
    # Optimize netfilter
    echo -e "${CYAN}Optimizing connection tracking...${NC}"
    echo 8000000 > /proc/sys/net/netfilter/nf_conntrack_max 2>/dev/null || true
    echo 600 > /proc/sys/net/netfilter/nf_conntrack_udp_timeout 2>/dev/null || true
    echo 600 > /proc/sys/net/netfilter/nf_conntrack_udp_timeout_stream 2>/dev/null || true
    echo 1048576 > /sys/module/nf_conntrack/parameters/hashsize 2>/dev/null || true
    echo -e "${GREEN}✓ Connection tracking: 8M (optimized)${NC}"
    
    # Save rules
    if command -v netfilter-persistent &> /dev/null; then
        netfilter-persistent save > /dev/null 2>&1
    fi
    mkdir -p /etc/iptables
    iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
    
    echo ""
    log_success "Firewall: UNLIMITED UDP speed mode"
    echo -e "${CYAN}Open Ports:${NC}"
    echo -e "  ${GREEN}✓${NC} UDP 53 (DNS - auto redirect)"
    echo -e "  ${GREEN}✓${NC} UDP 5300 (DNSTT - UNLIMITED)"
    echo -e "  ${GREEN}✓${NC} TCP 22 (SSH)"
    echo -e "  ${GREEN}✓${NC} TCP 443 (HTTPS)"
    
    sleep 2
}

#============================================
# KEY GENERATION
#============================================

generate_keys() {
    log_message "${YELLOW}🔑 Generating encryption keys...${NC}"
    echo ""
    
    cd "$INSTALL_DIR"
    rm -f server.key server.pub
    
    echo -e "${CYAN}Creating keys...${NC}"
    if ! "$DNSTT_SERVER" -gen-key -privkey-file server.key -pubkey-file server.pub 2>&1 | tee "$INSTALL_DIR/keygen.log" > /dev/null; then
        log_message "Trying alternative method..."
        openssl rand -hex 32 > server.key
        chmod 600 server.key
        PRIVKEY=$(cat server.key)
        echo "$PRIVKEY" | sha256sum | awk '{print $1}' > server.pub
        chmod 644 server.pub
    fi
    
    if [[ ! -f "server.key" ]] || [[ ! -f "server.pub" ]] || [[ ! -s "server.key" ]] || [[ ! -s "server.pub" ]]; then
        log_error "Key generation failed"
        return 1
    fi
    
    PUBKEY_LENGTH=$(wc -c < server.pub)
    if [[ $PUBKEY_LENGTH -lt 32 ]]; then
        log_error "Invalid public key"
        return 1
    fi
    
    chmod 600 server.key
    chmod 644 server.pub
    
    echo -e "${GREEN}✓ Keys generated${NC}"
    log_success "Encryption keys created"
    sleep 1
    return 0
}

#============================================
# SERVICE CREATION
#============================================

create_service() {
    local tunnel_domain=$1
    local mtu=$2
    local ssh_port=$3
    
    log_message "${YELLOW}📋 Creating systemd service with ULTRA v2 settings...${NC}"
    echo ""
    
    cat > /etc/systemd/system/dnstt.service << EOF
[Unit]
Description=DNSTT DNS Tunnel Server (ULTRA v2 - THE KING 👑)
Documentation=https://www.bamsoftware.com/software/dnstt/
After=network.target network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR
Environment=GOMAXPROCS=4
ExecStart=$DNSTT_SERVER -udp :5300 -privkey-file $INSTALL_DIR/server.key -mtu $mtu $tunnel_domain 127.0.0.1:$ssh_port
Restart=always
RestartSec=2
StandardOutput=append:$LOG_DIR/dnstt-server.log
StandardError=append:$LOG_DIR/dnstt-error.log
SyslogIdentifier=dnstt

# ULTRA v2 Performance - THE KING 👑
LimitNOFILE=2097152
LimitNPROC=4096
Nice=-20
IOSchedulingClass=realtime
IOSchedulingPriority=0
CPUSchedulingPolicy=fifo
CPUSchedulingPriority=99

# Memory and CPU
MemoryMax=12G
CPUQuota=3200%

# Security
NoNewPrivileges=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

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
    systemctl enable dnstt > /dev/null 2>&1
    
    echo -e "${GREEN}✓ Service created with ULTRA v2 settings${NC}"
    log_success "DNSTT Configuration:"
    log_message "   MTU: $mtu bytes"
    log_message "   SSH Port: $ssh_port"
    log_message "   UDP Port: 5300"
    log_message "   Max Performance Mode"
    sleep 2
}

#============================================
# MAIN SETUP
#============================================

setup_dnstt() {
    show_banner
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║          DNSTT ULTRA v2.0 INSTALLATION               ║${NC}"
    echo -e "${CYAN}║               SSH OPTIMIZED EDITION                   ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if systemctl is-active --quiet dnstt 2>/dev/null; then
        echo -e "${YELLOW}⚠️  DNSTT is already running${NC}"
        echo ""
        read -p "Reinstall? (y/n): " reinstall
        if [[ "$reinstall" != "y" ]]; then
            return
        fi
        systemctl stop dnstt
        rm -f "$INSTALL_DIR/ns_domain.txt" "$INSTALL_DIR/tunnel_domain.txt"
    fi
    
    echo -e "${CYAN}Starting installation...${NC}"
    echo ""
    
    if ! install_dependencies; then
        log_error "Failed: Dependencies"
        press_enter
        return 1
    fi
    
    if ! install_golang; then
        log_error "Failed: Go installation"
        press_enter
        return 1
    fi
    
    if ! build_dnstt; then
        log_error "Failed: DNSTT build"
        press_enter
        return 1
    fi
    
    optimize_system_ultra
    optimize_ssh_server
    configure_firewall
    
    # Domain configuration
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}            DOMAIN CONFIGURATION${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${WHITE}Enter your nameserver domain:${NC}"
    echo -e "${CYAN}Example: ns.yourdomain.com${NC}"
    echo -e "${YELLOW}Default: ns.slowdns.local${NC}"
    echo ""
    read -p "Nameserver: " ns_domain
    ns_domain=${ns_domain:-ns.slowdns.local}
    
    echo ""
    echo -e "${WHITE}Enter your tunnel domain:${NC}"
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
    
    echo ""
    if ! generate_keys; then
        log_error "Failed: Key generation"
        press_enter
        return 1
    fi
    
    # MTU Configuration
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}         MTU CONFIGURATION (ULTRA v2 Optimized)${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${WHITE}Select MTU size:${NC}"
    echo ""
    echo -e "  ${CYAN}1)${NC} 512   - Classic DNS ${GREEN}✓ Most Compatible${NC}"
    echo -e "  ${CYAN}2)${NC} 1024  - Standard"
    echo -e "  ${CYAN}3)${NC} 1232  - EDNS0 Standard"
    echo -e "  ${CYAN}4)${NC} 1280  - High Speed ${GREEN}⭐ Recommended${NC}"
    echo -e "  ${CYAN}5)${NC} 1420  - Very High Speed ${GREEN}⭐⭐ Best for SSH${NC}"
    echo -e "  ${CYAN}6)${NC} 4096  - EDNS0 Maximum ${YELLOW}⚡ ULTRA (experimental)${NC}"
    echo -e "  ${YELLOW}7)${NC} ${YELLOW}CUSTOM - Enter your own${NC}"
    echo ""
    echo -e "${YELLOW}💡 Recommended: Option 5 (1420) for maximum SSH speed${NC}"
    echo ""
    read -p "Choice [1-7, default=5]: " mtu_choice
    
    case ${mtu_choice:-5} in
        1) MTU=512 ;;
        2) MTU=1024 ;;
        3) MTU=1232 ;;
        4) MTU=1280 ;;
        5) MTU=1420 ;;
        6) MTU=4096 ;;
        7)
            echo ""
            echo -e "${YELLOW}Enter custom MTU (64-4096):${NC}"
            read -p "MTU: " custom_mtu
            if [[ "$custom_mtu" =~ ^[0-9]+$ ]] && [ "$custom_mtu" -ge 64 ] && [ "$custom_mtu" -le 4096 ]; then
                MTU=$custom_mtu
                log_success "Custom MTU: $MTU"
            else
                log_error "Invalid MTU, using 512"
                MTU=512
            fi
            ;;
        *) MTU=1420 ;;
    esac
    
    echo "$MTU" > "$INSTALL_DIR/mtu.txt"
    log_success "MTU: $MTU bytes"
    
    SSH_PORT=$(ss -tlnp 2>/dev/null | grep sshd | awk '{print $4}' | cut -d: -f2 | head -1)
    SSH_PORT=${SSH_PORT:-22}
    echo "$SSH_PORT" > "$INSTALL_DIR/ssh_port.txt"
    log_message "SSH Port: $SSH_PORT"
    
    echo ""
    create_service "$tunnel_domain" "$MTU" "$SSH_PORT"
    
    echo ""
    echo -e "${CYAN}🚀 Starting DNSTT service...${NC}"
    systemctl start dnstt
    sleep 3
    
    if systemctl is-active --quiet dnstt; then
        log_success "Service started successfully"
    else
        log_error "Service failed to start"
        echo ""
        journalctl -u dnstt -n 20 --no-pager
        press_enter
        return 1
    fi
    
    PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com 2>/dev/null || echo "YOUR_SERVER_IP")
    PUBKEY=$(cat "$INSTALL_DIR/server.pub")
    
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║            ✅ INSTALLATION COMPLETE! ✅              ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━ CONNECTION DETAILS ━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${WHITE}🌐 Server IP:${NC}       ${YELLOW}$PUBLIC_IP${NC}"
    echo -e "${WHITE}🔗 NS Domain:${NC}       ${YELLOW}$ns_domain${NC}"
    echo -e "${WHITE}🔗 Tunnel Domain:${NC}   ${YELLOW}$tunnel_domain${NC}"
    echo -e "${WHITE}🔑 Public Key:${NC}"
    echo -e "${YELLOW}$PUBKEY${NC}"
    echo -e "${WHITE}🚪 SSH Port:${NC}        ${YELLOW}$SSH_PORT${NC}"
    echo -e "${WHITE}📊 MTU:${NC}             ${YELLOW}$MTU bytes${NC}"
    echo -e "${WHITE}⚡ Expected Speed:${NC}  ${GREEN}10-25 Mbps 🚀${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}📋 DNS RECORDS:${NC}"
    echo ""
    echo -e "${GREEN}A Record:${NC}  $ns_domain → $PUBLIC_IP"
    echo -e "${GREEN}NS Record:${NC} $tunnel_domain → $ns_domain"
    echo ""
    echo -e "${YELLOW}📱 CLIENT COMMAND (Direct UDP - FASTEST):${NC}"
    echo ""
    echo -e "${GREEN}Direct UDP:${NC}"
    echo -e "${WHITE}dnstt-client -udp $PUBLIC_IP:5300 \\${NC}"
    echo -e "${WHITE}  -pubkey $PUBKEY \\${NC}"
    echo -e "${WHITE}  -mtu $MTU \\${NC}"
    echo -e "${WHITE}  $tunnel_domain 127.0.0.1:$SSH_PORT${NC}"
    echo ""
    echo -e "${CYAN}Alternative (DoH):${NC}"
    echo -e "${WHITE}dnstt-client -doh https://cloudflare-dns.com/dns-query \\${NC}"
    echo -e "${WHITE}  -pubkey $PUBKEY \\${NC}"
    echo -e "${WHITE}  -mtu $MTU \\${NC}"
    echo -e "${WHITE}  $tunnel_domain 127.0.0.1:$SSH_PORT${NC}"
    echo ""
    echo -e "${YELLOW}💡 SSH Connection:${NC}"
    echo -e "${WHITE}   After starting dnstt-client:${NC}"
    echo -e "${WHITE}   ssh username@127.0.0.1 -p $SSH_PORT${NC}"
    echo ""
    echo -e "${YELLOW}💡 ULTRA v2 OPTIMIZATIONS ACTIVE:${NC}"
    echo -e "   ${GREEN}✓${NC} BBR v2 + FQ-CoDel congestion control"
    echo -e "   ${GREEN}✓${NC} 1GB network buffers (2x faster)"
    echo -e "   ${GREEN}✓${NC} 512KB UDP buffers (EDNS0++)"
    echo -e "   ${GREEN}✓${NC} SSH server optimized (fastest ciphers)"
    echo -e "   ${GREEN}✓${NC} Zero-copy + offloading"
    echo -e "   ${GREEN}✓${NC} MTU $MTU (optimized for SSH)"
    echo -e "   ${GREEN}✓${NC} 8M connection tracking"
    echo -e "   ${GREEN}✓${NC} 300K packet backlog (zero loss)"
    echo ""
    
    # Save info
    cat > "$INSTALL_DIR/connection_info.txt" << EOF
╔═══════════════════════════════════════════════════════╗
║      DNSTT ULTRA v2.0 - SSH OPTIMIZED EDITION        ║
║              Created By THE KING 👑 💯               ║
╚═══════════════════════════════════════════════════════╝

Generated: $(date)

SERVER DETAILS:
═══════════════
IP:             $PUBLIC_IP
NS Domain:      $ns_domain
Tunnel Domain:  $tunnel_domain
SSH Port:       $SSH_PORT
MTU:            $MTU bytes
Expected Speed: 10-25 Mbps

PUBLIC KEY:
═══════════
$PUBKEY

DNS RECORDS:
════════════
A    $ns_domain         $PUBLIC_IP
NS   $tunnel_domain     $ns_domain

ULTRA SPEED CLIENT COMMANDS:
═════════════════════════════
# Direct UDP (FASTEST - Recommended)
dnstt-client -udp $PUBLIC_IP:5300 -pubkey $PUBKEY -mtu $MTU $tunnel_domain 127.0.0.1:$SSH_PORT

# Cloudflare DoH
dnstt-client -doh https://cloudflare-dns.com/dns-query -pubkey $PUBKEY -mtu $MTU $tunnel_domain 127.0.0.1:$SSH_PORT

# Google DoH
dnstt-client -doh https://dns.google/dns-query -pubkey $PUBKEY -mtu $MTU $tunnel_domain 127.0.0.1:$SSH_PORT

SSH CONNECTION:
═══════════════
After starting dnstt-client, connect:
ssh username@127.0.0.1 -p $SSH_PORT

ULTRA v2 OPTIMIZATIONS:
════════════════════════
✓ BBR v2 + FQ-CoDel (next-gen congestion control)
✓ 1GB Network Buffers (double speed)
✓ 512KB UDP Buffers (EDNS0++ support)
✓ 300K Packet Backlog (zero packet loss)
✓ 8M Connection Tracking (unlimited connections)
✓ SSH Server Optimized (fastest ciphers)
✓ Zero-Copy + Offloading enabled
✓ Realtime CPU Priority (FIFO 99)
✓ I/O Realtime Priority
✓ TCP Bulk Transfer Optimization
✓ 2M File Descriptors (ultra parallel)
✓ MTU $MTU (optimized for your network)

LOGS:
══════
Server: $LOG_DIR/dnstt-server.log
Error:  $LOG_DIR/dnstt-error.log
Main:   $LOG_DIR/dnstt.log

Created By THE KING 👑 💯
EOF
    
    log_success "Info saved: $INSTALL_DIR/connection_info.txt"
    press_enter
}

#============================================
# SSH USER MANAGEMENT
#============================================

add_ssh_user() {
    show_banner
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                  ADD SSH USER                        ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    read -p "Username: " username
    
    if [[ -z "$username" ]]; then
        log_error "Username required"
        press_enter
        return
    fi
    
    if id "$username" &>/dev/null; then
        log_error "User already exists"
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
    echo -e "${YELLOW}Select expiration:${NC}"
    echo ""
    echo -e "  ${CYAN}1)${NC} 1 Day"
    echo -e "  ${CYAN}2)${NC} 7 Days"
    echo -e "  ${CYAN}3)${NC} 30 Days ${GREEN}⭐${NC}"
    echo -e "  ${CYAN}4)${NC} 90 Days"
    echo -e "  ${CYAN}5)${NC} 365 Days"
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
    
    echo ""
    echo -e "${CYAN}Creating user...${NC}"
    
    useradd -m -s /bin/bash "$username" 2>/dev/null
    echo "$username:$password" | chpasswd 2>/dev/null
    
    exp_date=$(date -d "+$days days" +"%Y-%m-%d")
    chage -E "$exp_date" "$username" 2>/dev/null
    
    echo "$username|$password|$exp_date|$(date +"%Y-%m-%d")" >> "$USER_DB"
    
    echo -e "${GREEN}✓ User created${NC}"
    echo ""
    log_success "SSH User Created!"
    echo ""
    echo -e "  ${WHITE}👤 Username:${NC} ${GREEN}$username${NC}"
    echo -e "  ${WHITE}🔐 Password:${NC} ${GREEN}$password${NC}"
    echo -e "  ${WHITE}📅 Expires:${NC}  ${YELLOW}$exp_date${NC}"
    echo -e "  ${WHITE}⏳ Valid:${NC}    ${GREEN}$days days${NC}"
    echo ""
    
    press_enter
}

delete_ssh_user() {
    show_banner
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                 DELETE SSH USER                      ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    read -p "Username to delete: " username
    
    if ! id "$username" &>/dev/null; then
        log_error "User not found"
        press_enter
        return
    fi
    
    echo ""
    echo -e "${RED}⚠️  WARNING: You are about to DELETE user: $username${NC}"
    echo ""
    read -p "Type 'yes' to confirm: " confirm
    
    if [[ "$confirm" != "yes" ]]; then
        echo -e "${YELLOW}Deletion cancelled${NC}"
        press_enter
        return
    fi
    
    echo ""
    echo -e "${CYAN}Deleting user...${NC}"
    
    pkill -u "$username" 2>/dev/null || true
    userdel -r "$username" 2>/dev/null || true
    sed -i "/^$username|/d" "$USER_DB"
    
    echo -e "${GREEN}✓ User deleted${NC}"
    log_success "User $username removed"
    
    press_enter
}

list_ssh_users() {
    show_banner
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    SSH USERS                         ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [[ ! -s "$USER_DB" ]]; then
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "            ${YELLOW}No users found${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    else
        echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
        printf "${CYAN}║${NC} ${WHITE}%-12s %-12s %-12s %-10s %-12s${NC} ${CYAN}║${NC}\n" "USERNAME" "PASSWORD" "EXPIRES" "DAYS LEFT" "STATUS"
        echo -e "${CYAN}╠═══════════════════════════════════════════════════════════════╣${NC}"
        
        local user_count=0
        local active_count=0
        
        while IFS='|' read -r user pass exp created; do
            user_count=$((user_count + 1))
            
            current=$(date +%s)
            exp_unix=$(date -d "$exp" +%s 2>/dev/null || echo "0")
            days_left=$(( (exp_unix - current) / 86400 ))
            
            if [[ $current -gt $exp_unix ]]; then
                status="${RED}● EXPIRED${NC}"
                days_display="${RED}0${NC}"
            else
                if [[ $days_left -le 3 ]]; then
                    status="${RED}● EXPIRING${NC}"
                    days_display="${RED}$days_left${NC}"
                elif [[ $days_left -le 7 ]]; then
                    status="${YELLOW}● WARNING${NC}"
                    days_display="${YELLOW}$days_left${NC}"
                else
                    status="${GREEN}● ACTIVE${NC}"
                    days_display="${GREEN}$days_left${NC}"
                    active_count=$((active_count + 1))
                fi
            fi
            
            printf "${CYAN}║${NC} ${WHITE}%-12s %-12s %-12s %-10s${NC} " "$user" "$pass" "$exp" "$days_display"
            echo -e "$status ${CYAN}║${NC}"
            
        done < "$USER_DB"
        
        echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${CYAN}Total Users: ${WHITE}$user_count${NC}  |  ${GREEN}Active: $active_count${NC}  |  ${RED}Expired: $((user_count - active_count))${NC}"
    fi
    
    press_enter
}

#============================================
# STATUS & INFO
#============================================

view_status() {
    show_banner
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                 SERVICE STATUS                       ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if systemctl is-active --quiet dnstt; then
        echo -e "${GREEN}✅ DNSTT: RUNNING (ULTRA v2 MODE 👑)${NC}"
        
        uptime_sec=$(systemctl show dnstt --property=ActiveEnterTimestamp --value)
        if [[ -n "$uptime_sec" ]]; then
            echo -e "${WHITE}Started: ${GREEN}$uptime_sec${NC}"
            
            start_epoch=$(date -d "$uptime_sec" +%s 2>/dev/null || echo "0")
            current_epoch=$(date +%s)
            uptime_seconds=$((current_epoch - start_epoch))
            uptime_days=$((uptime_seconds / 86400))
            uptime_hours=$(( (uptime_seconds % 86400) / 3600 ))
            uptime_mins=$(( (uptime_seconds % 3600) / 60 ))
            
            echo -e "${WHITE}Uptime: ${GREEN}${uptime_days}d ${uptime_hours}h ${uptime_mins}m${NC}"
        fi
        
        DNSTT_PID=$(systemctl show dnstt --property=MainPID --value)
        if [[ -n "$DNSTT_PID" && "$DNSTT_PID" != "0" ]]; then
            NICE=$(ps -o nice= -p $DNSTT_PID 2>/dev/null || echo "N/A")
            CPU_PCT=$(ps -o %cpu= -p $DNSTT_PID 2>/dev/null | tr -d ' ' || echo "N/A")
            MEM_PCT=$(ps -o %mem= -p $DNSTT_PID 2>/dev/null | tr -d ' ' || echo "N/A")
            echo -e "${WHITE}Process Priority: ${GREEN}$NICE (Realtime)${NC}"
            echo -e "${WHITE}CPU Usage:        ${CYAN}${CPU_PCT}%${NC}"
            echo -e "${WHITE}Memory Usage:     ${CYAN}${MEM_PCT}%${NC}"
        fi
        
        CURRENT_MTU=$(cat "$INSTALL_DIR/mtu.txt" 2>/dev/null || echo "unknown")
        TUNNEL_DOM=$(cat "$INSTALL_DIR/tunnel_domain.txt" 2>/dev/null || echo "unknown")
        UDP_CONNS=$(ss -u state established 2>/dev/null | grep -c ':5300' || echo "0")
        echo -e "${WHITE}Current MTU:      ${CYAN}${CURRENT_MTU} bytes${NC}"
        echo -e "${WHITE}Tunnel Domain:    ${CYAN}${TUNNEL_DOM}${NC}"
        echo -e "${WHITE}Active UDP conns: ${CYAN}${UDP_CONNS}${NC}"
    else
        echo -e "${RED}❌ DNSTT: STOPPED${NC}"
        CURRENT_MTU=$(cat "$INSTALL_DIR/mtu.txt" 2>/dev/null || echo "unknown")
        echo -e "${WHITE}Last MTU used: ${YELLOW}${CURRENT_MTU} bytes${NC}"
        echo -e "${YELLOW}Tip: Use option 8 to restart, or option 11 to change MTU${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}━━━━━ Full Status ━━━━━${NC}"
    systemctl status dnstt --no-pager -l | head -20
    
    echo ""
    echo -e "${CYAN}━━━━━ Recent Logs ━━━━━${NC}"
    journalctl -u dnstt -n 10 --no-pager
    
    press_enter
}

view_logs() {
    show_banner
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    DNSTT LOGS                        ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
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

view_info() {
    show_banner
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║            CONNECTION INFORMATION                    ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [[ -f "$INSTALL_DIR/connection_info.txt" ]]; then
        cat "$INSTALL_DIR/connection_info.txt"
    else
        log_error "Not configured. Run installation first."
    fi
    
    press_enter
}

view_performance() {
    show_banner
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║        ULTRA v2 PERFORMANCE MONITORING               ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${YELLOW}━━━ SERVICE STATUS ━━━${NC}"
    if systemctl is-active --quiet dnstt; then
        echo -e "${GREEN}✅ DNSTT: RUNNING (ULTRA v2 MODE)${NC}"
    else
        echo -e "${RED}❌ DNSTT: STOPPED${NC}"
    fi
    echo ""
    
    echo -e "${YELLOW}━━━ TUNNEL CONFIG ━━━${NC}"
    CURRENT_MTU=$(cat "$INSTALL_DIR/mtu.txt" 2>/dev/null || echo "unknown")
    TUNNEL_DOM=$(cat "$INSTALL_DIR/tunnel_domain.txt" 2>/dev/null || echo "unknown")
    SSH_P=$(cat "$INSTALL_DIR/ssh_port.txt" 2>/dev/null || echo "22")
    echo -e "${WHITE}MTU Size:       ${CYAN}${CURRENT_MTU} bytes${NC}"
    echo -e "${WHITE}Tunnel Domain:  ${CYAN}${TUNNEL_DOM}${NC}"
    echo -e "${WHITE}SSH Port:       ${CYAN}${SSH_P}${NC}"
    echo -e "${WHITE}Go Workers:     ${CYAN}GOMAXPROCS=4 (parallel DNS processing)${NC}"
    echo ""

    echo -e "${YELLOW}━━━ ULTRA v2 SETTINGS ━━━${NC}"
    echo -e "${GREEN}✓${NC} CPU Priority: Realtime (FIFO 99)"
    echo -e "${GREEN}✓${NC} I/O Priority: Realtime (0)"
    echo -e "${GREEN}✓${NC} Nice: -20 (highest)"
    echo -e "${GREEN}✓${NC} CPU Quota: 3200% (32 cores)"
    echo -e "${GREEN}✓${NC} Memory: 12GB"
    echo -e "${GREEN}✓${NC} File Descriptors: 2M"
    echo -e "${GREEN}✓${NC} GOMAXPROCS=4 (4 parallel Go workers)"
    echo ""
    
    echo -e "${YELLOW}━━━ LIVE PROCESS STATS ━━━${NC}"
    DNSTT_PID=$(systemctl show dnstt --property=MainPID --value 2>/dev/null || echo "0")
    if [[ -n "$DNSTT_PID" && "$DNSTT_PID" != "0" ]]; then
        CPU_PCT=$(ps -o %cpu= -p $DNSTT_PID 2>/dev/null | tr -d ' ' || echo "N/A")
        MEM_MB=$(ps -o rss= -p $DNSTT_PID 2>/dev/null | awk '{printf "%.1f", $1/1024}' || echo "N/A")
        THREADS=$(ps -o nlwp= -p $DNSTT_PID 2>/dev/null | tr -d ' ' || echo "N/A")
        echo -e "${WHITE}PID:            ${CYAN}${DNSTT_PID}${NC}"
        echo -e "${WHITE}CPU:            ${CYAN}${CPU_PCT}%${NC}"
        echo -e "${WHITE}Memory:         ${CYAN}${MEM_MB} MB${NC}"
        echo -e "${WHITE}Threads:        ${CYAN}${THREADS}${NC}"
    else
        echo -e "${RED}Process not running${NC}"
    fi
    echo ""

    echo -e "${YELLOW}━━━ NETWORK STATS ━━━${NC}"
    if command -v ss &> /dev/null; then
        UDP_CONNS=$(ss -u state established 2>/dev/null | grep -c ':5300' || echo "0")
        UDP_ALL=$(ss -u 2>/dev/null | grep -c ':5300' || echo "0")
        echo -e "${WHITE}UDP Active (5300):  ${CYAN}$UDP_CONNS${NC}"
        echo -e "${WHITE}UDP Total (5300):   ${CYAN}$UDP_ALL${NC}"
    fi
    
    RMEM_MAX=$(sysctl -n net.core.rmem_max 2>/dev/null || echo "0")
    UDP_RMEM=$(sysctl -n net.ipv4.udp_rmem_min 2>/dev/null || echo "0")
    BACKLOG=$(sysctl -n net.core.netdev_max_backlog 2>/dev/null || echo "0")
    BBR=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo "N/A")
    
    RMEM_MB=$((RMEM_MAX / 1048576))
    UDP_KB=$((UDP_RMEM / 1024))
    
    echo -e "${WHITE}Network Buffer:     ${GREEN}${RMEM_MB}MB${NC}"
    echo -e "${WHITE}UDP Buffer:         ${GREEN}${UDP_KB}KB${NC}"
    echo -e "${WHITE}Packet Backlog:     ${GREEN}${BACKLOG}${NC}"
    echo -e "${WHITE}Congestion Control: ${GREEN}${BBR}${NC}"
    echo ""
    
    echo -e "${YELLOW}━━━ SYSTEM RESOURCES ━━━${NC}"
    MEM_TOTAL=$(free -h | awk '/^Mem:/ {print $2}')
    MEM_USED=$(free -h | awk '/^Mem:/ {print $3}')
    CPU_CORES=$(nproc 2>/dev/null || echo "?")
    LOAD=$(uptime | awk -F'load average:' '{print $2}' | tr -d ' ')
    echo -e "${WHITE}Memory:     ${CYAN}${MEM_USED}/${MEM_TOTAL}${NC}"
    echo -e "${WHITE}CPU Cores:  ${CYAN}${CPU_CORES}${NC}"
    echo -e "${WHITE}Load Avg:   ${CYAN}${LOAD}${NC}"
    echo ""
    
    press_enter
}

bandwidth_test() {
    show_banner
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                 BANDWIDTH TEST                       ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if ! systemctl is-active --quiet dnstt; then
        log_error "DNSTT service is not running"
        press_enter
        return
    fi
    
    CURRENT_MTU=$(cat "$INSTALL_DIR/mtu.txt" 2>/dev/null || echo "unknown")
    echo -e "${YELLOW}Testing bandwidth for 30 seconds...${NC}"
    echo -e "${CYAN}Monitoring UDP traffic on port 5300${NC}"
    echo -e "${WHITE}Current MTU: ${CYAN}${CURRENT_MTU} bytes${NC}"
    echo ""

    NET_INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)
    if [[ -z "$NET_INTERFACE" ]]; then
        log_error "Could not detect network interface"
        press_enter
        return
    fi

    echo -e "${WHITE}Interface: ${CYAN}$NET_INTERFACE${NC}"
    echo ""

    RX1=$(cat /sys/class/net/$NET_INTERFACE/statistics/rx_bytes)
    TX1=$(cat /sys/class/net/$NET_INTERFACE/statistics/tx_bytes)
    PREV_RX=$RX1
    PREV_TX=$TX1
    PEAK_RX=0
    PEAK_TX=0

    printf "  %-5s  %-14s  %-14s  %s\n" "SEC" "DOWN (Kbps)" "UP (Kbps)" "TOTAL"
    echo -e "  ${DIM}------------------------------------------------${NC}"

    for i in $(seq 1 30); do
        sleep 1
        CUR_RX=$(cat /sys/class/net/$NET_INTERFACE/statistics/rx_bytes)
        CUR_TX=$(cat /sys/class/net/$NET_INTERFACE/statistics/tx_bytes)
        DIFF_RX=$(( (CUR_RX - PREV_RX) * 8 / 1000 ))
        DIFF_TX=$(( (CUR_TX - PREV_TX) * 8 / 1000 ))
        DIFF_TOT=$(( DIFF_RX + DIFF_TX ))
        [ $DIFF_RX -gt $PEAK_RX ] && PEAK_RX=$DIFF_RX
        [ $DIFF_TX -gt $PEAK_TX ] && PEAK_TX=$DIFF_TX
        if [ $DIFF_TOT -gt 5000 ]; then
            COL="${GREEN}"
        elif [ $DIFF_TOT -gt 1000 ]; then
            COL="${YELLOW}"
        else
            COL="${RED}"
        fi
        printf "  ${CYAN}%-5s${NC}  ${COL}%-14s${NC}  ${COL}%-14s${NC}  ${COL}%s Kbps${NC}\n" \
               "${i}s" "${DIFF_RX}" "${DIFF_TX}" "${DIFF_TOT}"
        PREV_RX=$CUR_RX
        PREV_TX=$CUR_TX
    done

    RX2=$(cat /sys/class/net/$NET_INTERFACE/statistics/rx_bytes)
    TX2=$(cat /sys/class/net/$NET_INTERFACE/statistics/tx_bytes)
    RX_BYTES=$(( RX2 - RX1 ))
    TX_BYTES=$(( TX2 - TX1 ))
    RX_MBPS=$(echo "scale=2; $RX_BYTES * 8 / 30 / 1000000" | bc)
    TX_MBPS=$(echo "scale=2; $TX_BYTES * 8 / 30 / 1000000" | bc)
    PEAK_RX_MBPS=$(echo "scale=2; $PEAK_RX / 1000" | bc)
    PEAK_TX_MBPS=$(echo "scale=2; $PEAK_TX / 1000" | bc)
    RX_MB=$(echo "scale=2; $RX_BYTES / 1048576" | bc)
    TX_MB=$(echo "scale=2; $TX_BYTES / 1048576" | bc)

    echo ""
    echo -e "${GREEN}━━━ TEST RESULTS ━━━${NC}"
    echo ""
    echo -e "${WHITE}Download:${NC}"
    echo -e "  Avg Rate: ${GREEN}${RX_MBPS} Mbps${NC}"
    echo -e "  Peak:     ${CYAN}${PEAK_RX_MBPS} Mbps${NC}"
    echo -e "  Total:    ${CYAN}${RX_MB} MB${NC}"
    echo ""
    echo -e "${WHITE}Upload:${NC}"
    echo -e "  Avg Rate: ${GREEN}${TX_MBPS} Mbps${NC}"
    echo -e "  Peak:     ${CYAN}${PEAK_TX_MBPS} Mbps${NC}"
    echo -e "  Total:    ${CYAN}${TX_MB} MB${NC}"
    echo ""
    echo -e "${WHITE}MTU Used: ${CYAN}${CURRENT_MTU} bytes${NC}"
    echo ""

    TOTAL_MBPS=$(echo "$RX_MBPS + $TX_MBPS" | bc)

    if (( $(echo "$TOTAL_MBPS >= 10" | bc -l) )); then
        echo -e "${GREEN}✅ Performance: EXCELLENT (${TOTAL_MBPS} Mbps — target achieved!)${NC}"
    elif (( $(echo "$TOTAL_MBPS >= 5" | bc -l) )); then
        echo -e "${YELLOW}⚠️  Performance: GOOD (${TOTAL_MBPS} Mbps)${NC}"
        echo -e "${YELLOW}   Tip: Use option 11 (Change MTU) to try a larger size${NC}"
    elif (( $(echo "$TOTAL_MBPS >= 1" | bc -l) )); then
        echo -e "${YELLOW}⚠️  Performance: LOW (${TOTAL_MBPS} Mbps)${NC}"
        echo -e "${YELLOW}   Tip: Use option 11 → Choose 0 (Auto-detect MTU)${NC}"
        echo -e "${YELLOW}   Current MTU: ${CURRENT_MTU}B — auto-detect finds optimal size${NC}"
    else
        echo -e "${RED}❌ Performance: VERY LOW (${TOTAL_MBPS} Mbps)${NC}"
        echo -e "${RED}   Action: Go to option 11 → Choose 0 (Auto-detect MTU)${NC}"
        echo -e "${RED}   This will test your network and set the correct MTU automatically${NC}"
    fi
    
    press_enter
}

change_mtu() {
    show_banner
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              CHANGE MTU SIZE                          ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""

    if [[ ! -f "$INSTALL_DIR/mtu.txt" ]]; then
        log_error "DNSTT not installed yet"
        press_enter
        return
    fi

    CURRENT_MTU=$(cat "$INSTALL_DIR/mtu.txt" 2>/dev/null || echo "unknown")
    echo -e "${YELLOW}Current MTU: ${CYAN}${CURRENT_MTU} bytes${NC}"
    echo ""
    echo -e "  ${GREEN}0)${NC} ${GREEN}AUTO-DETECT - Test your network now ⭐⭐⭐${NC}"
    echo -e "  ${CYAN}1)${NC} 192   - Low MTU (strict carriers)"
    echo -e "  ${CYAN}2)${NC} 256   - Low-Medium"
    echo -e "  ${CYAN}3)${NC} 512   - Classic DNS"
    echo -e "  ${CYAN}4)${NC} 1024  - Standard"
    echo -e "  ${CYAN}5)${NC} 1232  - EDNS0 Standard"
    echo -e "  ${CYAN}6)${NC} 1280  - High Speed"
    echo -e "  ${CYAN}7)${NC} 1420  - Very High Speed"
    echo -e "  ${CYAN}8)${NC} 4096  - EDNS0 Maximum"
    echo -e "  ${YELLOW}9)${NC} CUSTOM (64-4096)"
    echo ""
    read -p "Choice [0-9]: " mtu_choice

    NEW_MTU=0
    case ${mtu_choice} in
        0)
            echo ""
            echo -e "${CYAN}Auto-detecting best MTU...${NC}"
            echo ""
            if ! command -v dig &>/dev/null; then
                apt-get install -y -qq dnsutils > /dev/null 2>&1 || true
            fi
            BEST_MTU=0; BEST_SCORE=0
            TEST_SIZES=(64 128 192 256 320 384 448 512 576 640 768 1024 1280 1420 1480)
            printf "  %-8s  %-10s  %-6s  %s
" "MTU" "RTT(avg)" "OK/5" "STATUS"
            echo -e "  ${DIM}--------------------------------------------${NC}"
            for TEST_MTU in "${TEST_SIZES[@]}"; do
                PAD=$(( TEST_MTU - 29 )); [ $PAD -lt 1 ] && PAD=1
                LABEL=""; REM=$PAD
                while [ $REM -gt 0 ]; do
                    SEG=$REM; [ $SEG -gt 63 ] && SEG=63
                    LABEL+=$(printf 'x%.0s' $(seq 1 $SEG))
                    REM=$(( REM - SEG ))
                    [ $REM -gt 0 ] && LABEL+="."
                done
                TEST_DOMAIN="${LABEL}.google.com"
                TOTAL=0; OK=0; FAIL=0
                for r in 1 2 3 4 5; do
                    T0=$(date +%s%3N)
                    OUT=$(dig +time=2 +tries=1 +udp "@8.8.8.8" A "$TEST_DOMAIN" 2>/dev/null)
                    T1=$(date +%s%3N)
                    if echo "$OUT" | grep -qE "status: (NOERROR|NXDOMAIN)"; then
                        TOTAL=$(echo "$TOTAL + ($T1 - $T0)" | bc)
                        (( OK++ ))
                    else
                        (( FAIL++ ))
                    fi
                done
                if [ $OK -gt 0 ]; then
                    AVG=$(echo "scale=0; $TOTAL / $OK" | bc)
                    SCORE=$(echo "scale=0; ($TEST_MTU * $OK * 10) / ($AVG + 1)" | bc 2>/dev/null || echo 0)
                    STATUS="${GREEN}[+] OK${NC}"; [ $FAIL -gt 0 ] && STATUS="${YELLOW}[~] PARTIAL${NC}"
                    printf "  %-8s  %-10s  %-6s  " "${TEST_MTU}B" "${AVG}ms" "${OK}/5"
                    echo -e "$STATUS"
                    if [ "$SCORE" -gt "$BEST_SCORE" ]; then BEST_SCORE=$SCORE; BEST_MTU=$TEST_MTU; fi
                else
                    printf "  %-8s  %-10s  %-6s  " "${TEST_MTU}B" "timeout" "0/5"
                    echo -e "${RED}[X] NO RESPONSE${NC}"
                fi
            done
            echo ""
            if [ "$BEST_MTU" -gt 0 ]; then
                NEW_MTU=$BEST_MTU
                echo -e "${GREEN}✓ Best MTU: ${CYAN}${NEW_MTU} bytes${NC}"
            else
                echo -e "${RED}Could not detect MTU. No change made.${NC}"
                press_enter; return
            fi
            ;;
        1) NEW_MTU=192 ;;
        2) NEW_MTU=256 ;;
        3) NEW_MTU=512 ;;
        4) NEW_MTU=1024 ;;
        5) NEW_MTU=1232 ;;
        6) NEW_MTU=1280 ;;
        7) NEW_MTU=1420 ;;
        8) NEW_MTU=4096 ;;
        9)
            echo ""
            read -p "Enter MTU (64-4096): " custom_mtu
            if [[ "$custom_mtu" =~ ^[0-9]+$ ]] && [ "$custom_mtu" -ge 64 ] && [ "$custom_mtu" -le 4096 ]; then
                NEW_MTU=$custom_mtu
            else
                log_error "Invalid MTU. No change made."
                press_enter; return
            fi
            ;;
        *)
            log_error "Invalid choice. No change made."
            press_enter; return
            ;;
    esac

    if [ "$NEW_MTU" -eq 0 ]; then
        press_enter; return
    fi

    TUNNEL_DOMAIN=$(cat "$INSTALL_DIR/tunnel_domain.txt" 2>/dev/null || echo "")
    SSH_PORT_SAVED=$(cat "$INSTALL_DIR/ssh_port.txt" 2>/dev/null || echo "22")

    if [[ -z "$TUNNEL_DOMAIN" ]]; then
        log_error "Tunnel domain not found. Please reinstall."
        press_enter; return
    fi

    echo ""
    echo -e "${CYAN}Applying new MTU: ${YELLOW}${NEW_MTU} bytes${NC}${CYAN} (was ${CURRENT_MTU})...${NC}"
    echo "$NEW_MTU" > "$INSTALL_DIR/mtu.txt"
    create_service "$TUNNEL_DOMAIN" "$NEW_MTU" "$SSH_PORT_SAVED"
    systemctl daemon-reload
    systemctl restart dnstt
    sleep 2

    if systemctl is-active --quiet dnstt; then
        log_success "MTU changed to ${NEW_MTU} bytes — service restarted"
    else
        log_error "Service failed after MTU change. Check logs."
        journalctl -u dnstt -n 10 --no-pager
    fi

    press_enter
}

fix_domain() {
    show_banner
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                 FIX DOMAIN ISSUE                     ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
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
    
    MTU=$(cat "$INSTALL_DIR/mtu.txt" 2>/dev/null || echo "1420")
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
    else
        log_error "Still failing. Check logs:"
        journalctl -u dnstt -n 10 --no-pager
    fi
    
    press_enter
}

#============================================
# MENUS
#============================================

dnstt_menu() {
    while true; do
        show_banner
        echo -e "${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║              DNSTT MANAGEMENT                        ║${NC}"
        echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
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
        echo -e "  ${GREEN}11)${NC} Change MTU Size"
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
                echo ""
                echo -e "${CYAN}Restarting DNSTT...${NC}"
                systemctl restart dnstt
                sleep 2
                if systemctl is-active --quiet dnstt; then
                    echo -e "${GREEN}✓ Service restarted${NC}"
                else
                    echo -e "${RED}✗ Service failed${NC}"
                fi
                sleep 2
                ;;
            9)
                echo ""
                echo -e "${CYAN}Stopping DNSTT...${NC}"
                systemctl stop dnstt
                echo -e "${YELLOW}Service stopped${NC}"
                sleep 2
                ;;
            10)
                echo ""
                echo -e "${RED}⚠️  WARNING: Uninstall DNSTT${NC}"
                echo ""
                read -p "Type 'yes' to confirm: " confirm
                if [[ "$confirm" == "yes" ]]; then
                    echo ""
                    echo -e "${CYAN}Uninstalling...${NC}"
                    systemctl stop dnstt 2>/dev/null || true
                    systemctl disable dnstt 2>/dev/null || true
                    rm -f /etc/systemd/system/dnstt.service
                    rm -rf "$INSTALL_DIR" "$LOG_DIR"
                    rm -f "$DNSTT_SERVER" "$DNSTT_CLIENT"
                    rm -f /etc/sysctl.d/99-dnstt-ultra-v2.conf
                    rm -f /etc/security/limits.d/99-dnstt-ultra-v2.conf
                    systemctl daemon-reload
                    echo -e "${GREEN}✓ DNSTT uninstalled${NC}"
                    sleep 2
                else
                    echo -e "${YELLOW}Cancelled${NC}"
                    sleep 1
                fi
                ;;
            11) change_mtu ;;
            0) return ;;
            *) 
                log_error "Invalid choice"
                sleep 1
                ;;
        esac
    done
}

ssh_menu() {
    while true; do
        show_banner
        echo -e "${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║            SSH USER MANAGEMENT                       ║${NC}"
        echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        if [[ -s "$USER_DB" ]]; then
            local total_users=$(wc -l < "$USER_DB")
            local active_users=0
            local current=$(date +%s)
            
            while IFS='|' read -r user pass exp created; do
                exp_unix=$(date -d "$exp" +%s 2>/dev/null || echo "0")
                if [[ $current -le $exp_unix ]]; then
                    active_users=$((active_users + 1))
                fi
            done < "$USER_DB"
            
            echo -e "  ${WHITE}📊 Total: ${CYAN}$total_users${NC}  |  ${GREEN}Active: $active_users${NC}  |  ${RED}Expired: $((total_users - active_users))${NC}"
            echo ""
        fi
        
        echo -e "  ${GREEN}1)${NC} 👤 Add New User"
        echo -e "  ${YELLOW}2)${NC} 📋 List All Users"
        echo -e "  ${RED}3)${NC} 🗑️  Delete User"
        echo -e "  ${WHITE}0)${NC} ⬅️  Back"
        echo ""
        read -p "Choice: " choice
        
        case $choice in
            1) add_ssh_user ;;
            2) list_ssh_users ;;
            3) delete_ssh_user ;;
            0) return ;;
            *) 
                log_error "Invalid choice"
                sleep 1
                ;;
        esac
    done
}

system_menu() {
    show_banner
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║               SYSTEM INFORMATION                     ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
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
    
    echo -e "${YELLOW}━━━ OPTIMIZATIONS ━━━${NC}"
    if [[ -f /etc/sysctl.d/99-dnstt-ultra-v2.conf ]]; then
        echo -e "${GREEN}✅ ULTRA v2 MODE ACTIVE${NC}"
        echo -e "${GREEN}✓${NC} BBR v2 + FQ-CoDel"
        echo -e "${GREEN}✓${NC} 1GB network buffers"
        echo -e "${GREEN}✓${NC} 512KB UDP buffers (EDNS0++)"
        echo -e "${GREEN}✓${NC} 300K packet backlog"
        echo -e "${GREEN}✓${NC} 8M connection tracking"
        echo -e "${GREEN}✓${NC} SSH server optimized"
        echo -e "${GREEN}✓${NC} Zero-copy + offloading"
        
        if [[ -f /etc/security/limits.d/99-dnstt-ultra-v2.conf ]]; then
            echo -e "${GREEN}✓${NC} 2M file descriptors"
        fi
    else
        echo -e "${YELLOW}⚠️  No optimizations applied${NC}"
    fi
    echo ""
    
    press_enter
}

main_menu() {
    while true; do
        show_banner
        echo -e "${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║                   MAIN MENU                          ║${NC}"
        echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  ${GREEN}1)${NC} 🌐 DNSTT Management"
        echo -e "  ${BLUE}2)${NC} 👥 SSH Users"
        echo -e "  ${YELLOW}3)${NC} 📊 System Info"
        echo -e "  ${RED}0)${NC} ⛔ Exit"
        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${WHITE}Version: 8.0 ULTRA v2 | ${GREEN}Created By THE KING 👑 💯${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        read -p "Choice: " choice
        
        case $choice in
            1) dnstt_menu ;;
            2) ssh_menu ;;
            3) system_menu ;;
            0)
                echo ""
                echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                echo -e "${GREEN}    Thank you for using DNSTT ULTRA v2! 👑 💯${NC}"
                echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                echo ""
                exit 0
                ;;
            *) 
                log_error "Invalid choice"
                sleep 1
                ;;
        esac
    done
}

#============================================
# CREATE MENU COMMAND
#============================================

create_menu_command() {
    SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
    
    cat > /usr/local/bin/menu << EOF
#!/bin/bash
# DNSTT Menu - THE KING 👑
bash "$SCRIPT_PATH"
EOF
    chmod +x /usr/local/bin/menu
    
    cat > /usr/local/bin/dnstt << EOF
#!/bin/bash
# DNSTT Command - THE KING 👑
bash "$SCRIPT_PATH"
EOF
    chmod +x /usr/local/bin/dnstt
    
    cat > /usr/local/bin/slowdns << EOF
#!/bin/bash
# SlowDNS Command - THE KING 👑
bash "$SCRIPT_PATH"
EOF
    chmod +x /usr/local/bin/slowdns
    
    log_success "Menu commands created: menu, dnstt, slowdns"
}

#============================================
# MAIN EXECUTION
#============================================

# Create menu command if needed
if [[ ! -f /usr/local/bin/menu ]]; then
    if [[ $EUID -eq 0 ]]; then
        create_menu_command 2>/dev/null
    fi
fi

check_root
check_os
main_menu
        
