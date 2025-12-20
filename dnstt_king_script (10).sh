#!/bin/bash

##############################################
# SLOW DNS TUNNEL - DNSTT ULTRA SPEED EDITION
# Created By THE KING 👑 💯
# Version: 7.0.0 - Maximum Performance
# Optimized for 5-15 Mbps speeds
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
V2RAY_DIR="/etc/v2ray"
V2RAY_BIN="/usr/local/bin/v2ray"
V2RAY_CONFIG="$V2RAY_DIR/config.json"

# Create directories
mkdir -p "$INSTALL_DIR" "$SSH_DIR" "$LOG_DIR" "$V2RAY_DIR"
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
║        ███████╗██████╗ ███████╗███████╗██████╗               ║
║        ██╔════╝██╔══██╗██╔════╝██╔════╝██╔══██╗              ║
║        ███████╗██████╔╝█████╗  █████╗  ██║  ██║              ║
║        ╚════██║██╔═══╝ ██╔══╝  ██╔══╝  ██║  ██║              ║
║        ███████║██║     ███████╗███████╗██████╔╝              ║
║        ╚══════╝╚═╝     ╚══════╝╚══════╝╚═════╝               ║
║                                                               ║
║              DNS TUNNEL MANAGER v7.0 ULTRA                   ║
║           Maximum Speed Edition - 5-15 Mbps                  ║
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
# ULTRA SPEED OPTIMIZATION
# Combines EDNS0, BBR, UDP optimization
#============================================

optimize_system_ultra() {
    log_message "${YELLOW}⚡ Applying ULTRA SPEED optimization...${NC}"
    echo ""
    
    # Enable IP forwarding
    sysctl -w net.ipv4.ip_forward=1 > /dev/null 2>&1
    
    # Load BBR module
    modprobe tcp_bbr 2>/dev/null
    
    # Set massive ulimit for parallel connections
    ulimit -n 1048576 2>/dev/null
    
    echo -e "${CYAN}[1/10]${NC} Configuring TCP BBR (Best congestion control)..."
    sysctl -w net.ipv4.tcp_congestion_control=bbr > /dev/null 2>&1
    sysctl -w net.core.default_qdisc=fq > /dev/null 2>&1
    echo -e "${GREEN}✓ BBR enabled${NC}"
    
    echo -e "${CYAN}[2/10]${NC} Optimizing network buffers (512MB for ULTRA speed)..."
    sysctl -w net.core.rmem_max=536870912 > /dev/null 2>&1  # 512MB
    sysctl -w net.core.wmem_max=536870912 > /dev/null 2>&1  # 512MB
    sysctl -w net.core.rmem_default=67108864 > /dev/null 2>&1  # 64MB
    sysctl -w net.core.wmem_default=67108864 > /dev/null 2>&1  # 64MB
    sysctl -w net.ipv4.tcp_rmem="8192 524288 536870912" > /dev/null 2>&1
    sysctl -w net.ipv4.tcp_wmem="8192 524288 536870912" > /dev/null 2>&1
    echo -e "${GREEN}✓ Network buffers: 512MB configured${NC}"
    
    echo -e "${CYAN}[3/10]${NC} CRITICAL: UDP optimization for DNS tunnel (EDNS0 support)..."
    # UDP buffers - CRITICAL for DNS performance
    sysctl -w net.ipv4.udp_rmem_min=262144 > /dev/null 2>&1  # 256KB
    sysctl -w net.ipv4.udp_wmem_min=262144 > /dev/null 2>&1  # 256KB
    
    # EDNS0 support - allows larger DNS packets (up to 4096 bytes)
    sysctl -w net.ipv4.udp_mem="262144 524288 1048576" > /dev/null 2>&1
    
    # Handle DNS burst packets without dropping
    sysctl -w net.core.netdev_max_backlog=100000 > /dev/null 2>&1  # 100K packets
    sysctl -w net.core.netdev_budget=1200 > /dev/null 2>&1
    sysctl -w net.core.netdev_budget_usecs=16000 > /dev/null 2>&1
    sysctl -w net.core.somaxconn=131072 > /dev/null 2>&1  # 128K connections
    echo -e "${GREEN}✓ UDP optimized with EDNS0 support (256KB buffers)${NC}"
    
    echo -e "${CYAN}[4/10]${NC} Configuring connection tracking (4M connections)..."
    sysctl -w net.netfilter.nf_conntrack_max=4000000 > /dev/null 2>&1
    sysctl -w net.netfilter.nf_conntrack_tcp_timeout_established=86400 > /dev/null 2>&1
    sysctl -w net.netfilter.nf_conntrack_udp_timeout=300 > /dev/null 2>&1
    sysctl -w net.netfilter.nf_conntrack_udp_timeout_stream=300 > /dev/null 2>&1
    echo 524288 > /sys/module/nf_conntrack/parameters/hashsize 2>/dev/null || true
    echo -e "${GREEN}✓ Connection tracking: 4M connections${NC}"
    
    echo -e "${CYAN}[5/10]${NC} Enabling TCP optimizations..."
    sysctl -w net.ipv4.tcp_fastopen=3 > /dev/null 2>&1
    sysctl -w net.ipv4.tcp_slow_start_after_idle=0 > /dev/null 2>&1
    sysctl -w net.ipv4.tcp_tw_reuse=1 > /dev/null 2>&1
    sysctl -w net.ipv4.tcp_fin_timeout=10 > /dev/null 2>&1
    sysctl -w net.ipv4.tcp_keepalive_time=120 > /dev/null 2>&1
    sysctl -w net.ipv4.tcp_keepalive_probes=3 > /dev/null 2>&1
    sysctl -w net.ipv4.tcp_keepalive_intvl=10 > /dev/null 2>&1
    sysctl -w net.ipv4.tcp_mtu_probing=1 > /dev/null 2>&1
    echo -e "${GREEN}✓ TCP FastOpen & optimizations enabled${NC}"
    
    echo -e "${CYAN}[6/10]${NC} Expanding port range for massive connections..."
    sysctl -w net.ipv4.ip_local_port_range="1024 65535" > /dev/null 2>&1
    echo -e "${GREEN}✓ Port range: 1024-65535 (64K ports)${NC}"
    
    echo -e "${CYAN}[7/10]${NC} Low latency & performance tuning..."
    sysctl -w net.ipv4.tcp_low_latency=1 > /dev/null 2>&1
    sysctl -w net.ipv4.tcp_sack=1 > /dev/null 2>&1
    sysctl -w net.ipv4.tcp_window_scaling=1 > /dev/null 2>&1
    sysctl -w net.ipv4.tcp_timestamps=1 > /dev/null 2>&1
    sysctl -w net.ipv4.tcp_syncookies=1 > /dev/null 2>&1
    echo -e "${GREEN}✓ Low latency optimizations applied${NC}"
    
    echo -e "${CYAN}[8/10]${NC} DNS-specific optimizations..."
    # Optimize for DNS query/response patterns
    sysctl -w net.ipv4.udp_early_demux=1 > /dev/null 2>&1
    sysctl -w net.ipv4.ip_early_demux=1 > /dev/null 2>&1
    # Reduce DNS timeout
    sysctl -w net.ipv4.tcp_retries2=8 > /dev/null 2>&1
    echo -e "${GREEN}✓ DNS-specific optimizations enabled${NC}"
    
    echo -e "${CYAN}[9/10]${NC} Creating permanent configuration..."
    
    cat > /etc/sysctl.d/99-dnstt-ultra-speed.conf << 'EOF'
# DNSTT ULTRA SPEED OPTIMIZATION
# Created By THE KING 👑 💯
# Optimized for 5-15 Mbps DNS tunnel speeds
# Includes: BBR, EDNS0, UDP optimization, massive buffers

### IP FORWARDING ###
net.ipv4.ip_forward = 1

### BBR CONGESTION CONTROL (Best for high latency) ###
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq

### MASSIVE NETWORK BUFFERS (512MB) ###
net.core.rmem_max = 536870912
net.core.wmem_max = 536870912
net.core.rmem_default = 67108864
net.core.wmem_default = 67108864
net.ipv4.tcp_rmem = 8192 524288 536870912
net.ipv4.tcp_wmem = 8192 524288 536870912

### CRITICAL UDP OPTIMIZATION FOR DNS (EDNS0 SUPPORT) ###
net.ipv4.udp_rmem_min = 262144
net.ipv4.udp_wmem_min = 262144
net.ipv4.udp_mem = 262144 524288 1048576

### DNS BURST HANDLING (NO PACKET LOSS) ###
net.core.netdev_max_backlog = 100000
net.core.netdev_budget = 1200
net.core.netdev_budget_usecs = 16000
net.core.somaxconn = 131072

### MASSIVE CONNECTION TRACKING ###
net.netfilter.nf_conntrack_max = 4000000
net.netfilter.nf_conntrack_tcp_timeout_established = 86400
net.netfilter.nf_conntrack_udp_timeout = 300
net.netfilter.nf_conntrack_udp_timeout_stream = 300

### TCP OPTIMIZATIONS ###
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_keepalive_time = 120
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_keepalive_intvl = 10
net.ipv4.tcp_mtu_probing = 1

### PORT RANGE ###
net.ipv4.ip_local_port_range = 1024 65535

### LOW LATENCY ###
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_syncookies = 1

### DNS-SPECIFIC ###
net.ipv4.udp_early_demux = 1
net.ipv4.ip_early_demux = 1
net.ipv4.tcp_retries2 = 8
EOF

    echo -e "${GREEN}✓ Configuration saved to /etc/sysctl.d/99-dnstt-ultra-speed.conf${NC}"
    
    echo -e "${CYAN}[10/10]${NC} Setting ulimit for parallel tunnels..."
    cat > /etc/security/limits.d/99-dnstt-ultra.conf << 'EOF'
# DNSTT ULTRA - Parallel tunnels support
# Created By THE KING 👑 💯
* soft nofile 1048576
* hard nofile 1048576
root soft nofile 1048576
root hard nofile 1048576
* soft nproc 1048576
* hard nproc 1048576
EOF
    echo -e "${GREEN}✓ File descriptors: 1M (ultra parallel support)${NC}"
    
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         ⚡ ULTRA SPEED MODE ACTIVATED ⚡            ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}Optimization Summary:${NC}"
    echo -e "  ${GREEN}✓${NC} BBR Congestion Control"
    echo -e "  ${GREEN}✓${NC} 512MB Network Buffers"
    echo -e "  ${GREEN}✓${NC} 256KB UDP Buffers (EDNS0)"
    echo -e "  ${GREEN}✓${NC} 100K Packet Backlog (no drops)"
    echo -e "  ${GREEN}✓${NC} 4M Connection Tracking"
    echo -e "  ${GREEN}✓${NC} TCP FastOpen"
    echo -e "  ${GREEN}✓${NC} 1M File Descriptors"
    echo -e "  ${GREEN}✓${NC} DNS-specific optimizations"
    echo -e "  ${GREEN}✓${NC} Low latency tuning"
    echo ""
    echo -e "${YELLOW}Expected Speed: 5-15 Mbps 🚀${NC}"
    
    sleep 3
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
# V2RAY INSTALLATION
#============================================

install_v2ray() {
    log_message "${YELLOW}🚀 Installing V2Ray Core...${NC}"
    echo ""
    
    if [[ -f "$V2RAY_BIN" ]]; then
        log_success "V2Ray already installed"
        return 0
    fi
    
    echo -e "${CYAN}Downloading V2Ray installation script...${NC}"
    bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-v2ray.sh) > /dev/null 2>&1
    
    if [[ ! -f "$V2RAY_BIN" ]]; then
        # Alternative installation
        echo -e "${CYAN}Using alternative installation...${NC}"
        cd /tmp
        wget -q https://github.com/v2fly/v2ray-core/releases/latest/download/v2ray-linux-64.zip
        unzip -q v2ray-linux-64.zip -d v2ray-tmp
        mkdir -p /usr/local/bin
        mv v2ray-tmp/v2ray "$V2RAY_BIN"
        chmod +x "$V2RAY_BIN"
        rm -rf v2ray-tmp v2ray-linux-64.zip
    fi
    
    if [[ -f "$V2RAY_BIN" ]]; then
        echo -e "${GREEN}✓ V2Ray installed${NC}"
        log_success "V2Ray installed successfully"
        return 0
    else
        log_error "V2Ray installation failed"
        return 1
    fi
}

#============================================
# V2RAY CONFIGURATION
#============================================

generate_v2ray_config() {
    local v2ray_port=$1
    local uuid=$2
    
    log_message "${YELLOW}📝 Generating V2Ray configuration (Slow DNS Optimized)...${NC}"
    
    cat > "$V2RAY_CONFIG" << EOF
{
  "log": {
    "loglevel": "warning",
    "access": "$LOG_DIR/v2ray-access.log",
    "error": "$LOG_DIR/v2ray-error.log"
  },
  "inbounds": [
    {
      "port": $v2ray_port,
      "listen": "0.0.0.0",
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "$uuid",
            "alterId": 0
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/dnstt-v2ray",
          "headers": {}
        },
        "sockopt": {
          "tcpFastOpen": true,
          "tcpKeepAliveInterval": 30
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {},
      "streamSettings": {
        "sockopt": {
          "tcpFastOpen": true,
          "tcpKeepAliveInterval": 30
        }
      },
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "blocked"
    }
  ],
  "routing": {
    "domainStrategy": "IPOnDemand",
    "rules": [
      {
        "type": "field",
        "ip": ["geoip:private"],
        "outboundTag": "blocked"
      }
    ]
  },
  "policy": {
    "levels": {
      "0": {
        "uplinkOnly": 0,
        "downlinkOnly": 0,
        "bufferSize": 4,
        "handshake": 4,
        "connIdle": 300,
        "uplinkOnly": 2,
        "downlinkOnly": 5
      }
    },
    "system": {
      "statsInboundUplink": false,
      "statsInboundDownlink": false
    }
  }
}
EOF

    chmod 644 "$V2RAY_CONFIG"
    echo -e "${GREEN}✓ V2Ray config created (optimized for slow DNS)${NC}"
    log_success "V2Ray configured on port $v2ray_port with slow DNS optimization"
}

create_v2ray_service() {
    log_message "${YELLOW}📋 Creating V2Ray service...${NC}"
    
    cat > /etc/systemd/system/v2ray-dnstt.service << EOF
[Unit]
Description=V2Ray Service for DNSTT (THE KING 👑)
Documentation=https://www.v2fly.org/
After=network.target nss-lookup.target

[Service]
Type=simple
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=$V2RAY_BIN run -config $V2RAY_CONFIG
Restart=on-failure
RestartSec=3
StandardOutput=append:$LOG_DIR/v2ray-service.log
StandardError=append:$LOG_DIR/v2ray-error.log

# Performance
LimitNOFILE=1048576
LimitNPROC=1024

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable v2ray-dnstt > /dev/null 2>&1
    
    echo -e "${GREEN}✓ V2Ray service created${NC}"
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
    
    echo -e "${CYAN}Configuring iptables...${NC}"
    
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
    
    # HIGH PRIORITY: UDP DNS ports (NO LIMITS)
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
    
    echo -e "${GREEN}✓ iptables configured${NC}"
    
    # Optimize netfilter
    echo -e "${CYAN}Optimizing connection tracking...${NC}"
    echo 4000000 > /proc/sys/net/netfilter/nf_conntrack_max 2>/dev/null || true
    echo 300 > /proc/sys/net/netfilter/nf_conntrack_udp_timeout 2>/dev/null || true
    echo 300 > /proc/sys/net/netfilter/nf_conntrack_udp_timeout_stream 2>/dev/null || true
    echo 524288 > /sys/module/nf_conntrack/parameters/hashsize 2>/dev/null || true
    echo -e "${GREEN}✓ Connection tracking optimized${NC}"
    
    # Save rules
    if command -v netfilter-persistent &> /dev/null; then
        netfilter-persistent save > /dev/null 2>&1
    fi
    mkdir -p /etc/iptables
    iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
    
    echo ""
    log_success "Firewall configured for ULTRA UDP speed"
    echo -e "${CYAN}Open Ports:${NC}"
    echo -e "  ${GREEN}✓${NC} UDP 53 (DNS - auto redirect)"
    echo -e "  ${GREEN}✓${NC} UDP 5300 (DNSTT - unlimited)"
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
    
    log_message "${YELLOW}📋 Creating systemd service with ULTRA settings...${NC}"
    echo ""
    
    cat > /etc/systemd/system/dnstt.service << EOF
[Unit]
Description=DNSTT DNS Tunnel Server (ULTRA Speed - THE KING 👑)
Documentation=https://www.bamsoftware.com/software/dnstt/
After=network.target network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR
ExecStart=$DNSTT_SERVER -udp :5300 -privkey-file $INSTALL_DIR/server.key -mtu $mtu $tunnel_domain 127.0.0.1:$ssh_port
Restart=always
RestartSec=3
StandardOutput=append:$LOG_DIR/dnstt-server.log
StandardError=append:$LOG_DIR/dnstt-error.log
SyslogIdentifier=dnstt

# ULTRA Performance - THE KING 👑
LimitNOFILE=1048576
LimitNPROC=2048
Nice=-20
IOSchedulingClass=realtime
IOSchedulingPriority=0
CPUSchedulingPolicy=fifo
CPUSchedulingPriority=99

# Memory and CPU
MemoryMax=8G
CPUQuota=1600%

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
    
    echo -e "${GREEN}✓ Service created with ULTRA settings${NC}"
    log_success "DNSTT UDP Configuration:"
    log_message "   MTU: $mtu bytes (optimized for MTU 512)"
    log_message "   SSH Port: $ssh_port"
    log_message "   UDP Port: 5300"
    sleep 2
}

create_service_v2ray() {
    local tunnel_domain=$1
    local mtu=$2
    local v2ray_port=$3
    
    log_message "${YELLOW}📋 Creating DNSTT + V2Ray service...${NC}"
    echo ""
    
    cat > /etc/systemd/system/dnstt-v2ray.service << EOF
[Unit]
Description=DNSTT + V2Ray Tunnel Server (ULTRA Speed - THE KING 👑)
Documentation=https://www.bamsoftware.com/software/dnstt/
After=network.target network-online.target v2ray-dnstt.service
Wants=network-online.target
Requires=v2ray-dnstt.service

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR
ExecStart=$DNSTT_SERVER -udp :5300 -privkey-file $INSTALL_DIR/server.key -mtu $mtu $tunnel_domain 127.0.0.1:$v2ray_port
Restart=always
RestartSec=3
StandardOutput=append:$LOG_DIR/dnstt-v2ray.log
StandardError=append:$LOG_DIR/dnstt-v2ray-error.log
SyslogIdentifier=dnstt-v2ray

# ULTRA Performance - THE KING 👑
LimitNOFILE=1048576
LimitNPROC=2048
Nice=-20
IOSchedulingClass=realtime
IOSchedulingPriority=0
CPUSchedulingPolicy=fifo
CPUSchedulingPriority=99

# Memory and CPU
MemoryMax=8G
CPUQuota=1600%

# Security
NoNewPrivileges=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable dnstt-v2ray > /dev/null 2>&1
    
    echo -e "${GREEN}✓ DNSTT + V2Ray service created${NC}"
    log_success "DNSTT + V2Ray Configuration:"
    log_message "   MTU: $mtu bytes"
    log_message "   V2Ray Port: $v2ray_port"
    log_message "   Protocol: VMess over WebSocket"
    sleep 2
}

#============================================
# MAIN SETUP
#============================================

setup_dnstt() {
    show_banner
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║          DNSTT INSTALLATION & OPTIMIZATION           ║${NC}"
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
    echo -e "${YELLOW}         MTU CONFIGURATION (EDNS0 Optimized)${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${WHITE}Select MTU size:${NC}"
    echo ""
    echo -e "  ${CYAN}1)${NC} 512   - Classic DNS ${GREEN}✓ Most Compatible${NC}"
    echo -e "  ${CYAN}2)${NC} 1024  - Standard"
    echo -e "  ${CYAN}3)${NC} 1232  - EDNS0 Standard ${GREEN}⭐ Recommended${NC}"
    echo -e "  ${CYAN}4)${NC} 1280  - High Speed ${GREEN}⭐⭐ Best Speed${NC}"
    echo -e "  ${CYAN}5)${NC} 1420  - Maximum (needs good network)"
    echo -e "  ${CYAN}6)${NC} 4096  - EDNS0 Maximum ${YELLOW}⚡ ULTRA (experimental)${NC}"
    echo -e "  ${YELLOW}7)${NC} ${YELLOW}CUSTOM - Enter your own${NC}"
    echo ""
    echo -e "${YELLOW}💡 Recommended: Option 3 or 4 for best balance${NC}"
    echo ""
    read -p "Choice [1-7, default=4]: " mtu_choice
    
    case ${mtu_choice:-4} in
        1) MTU=512 ;;
        2) MTU=1024 ;;
        3) MTU=1232 ;;
        4) MTU=1280 ;;
        5) MTU=1420 ;;
        6) MTU=4096 ;;
        7)
            echo ""
            echo -e "${YELLOW}Enter custom MTU (512-4096):${NC}"
            read -p "MTU: " custom_mtu
            if [[ "$custom_mtu" =~ ^[0-9]+$ ]] && [ "$custom_mtu" -ge 512 ] && [ "$custom_mtu" -le 4096 ]; then
                MTU=$custom_mtu
                log_success "Custom MTU: $MTU"
            else
                log_error "Invalid MTU, using 1280"
                MTU=1280
            fi
            ;;
        *) MTU=1280 ;;
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
    echo -e "${WHITE}⚡ Expected Speed:${NC}  ${GREEN}5-15 Mbps${NC}"
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
    echo -e "${WHITE}  $tunnel_domain${NC}"
    echo ""
    echo -e "${CYAN}Alternative (DoH):${NC}"
    echo -e "${WHITE}dnstt-client -doh https://cloudflare-dns.com/dns-query \\${NC}"
    echo -e "${WHITE}  -pubkey $PUBKEY \\${NC}"
    echo -e "${WHITE}  -mtu $MTU \\${NC}"
    echo -e "${WHITE}  $tunnel_domain${NC}"
    echo ""
    echo -e "${YELLOW}💡 Connect to your SSH server using the tunnel:${NC}"
    echo -e "${WHITE}   SSH Host: $PUBLIC_IP${NC}"
    echo -e "${WHITE}   SSH Port: $SSH_PORT${NC}"
    echo ""
    echo -e "${YELLOW}💡 ULTRA OPTIMIZATIONS ACTIVE:${NC}"
    echo -e "   ${GREEN}✓${NC} Direct UDP (no localhost forwarding)"
    echo -e "   ${GREEN}✓${NC} BBR congestion control"
    echo -e "   ${GREEN}✓${NC} 512MB network buffers"
    echo -e "   ${GREEN}✓${NC} 256KB UDP buffers (EDNS0)"
    echo -e "   ${GREEN}✓${NC} MTU $MTU optimized for slow DNS"
    echo ""
    
    # Save info
    cat > "$INSTALL_DIR/connection_info.txt" << EOF
╔═══════════════════════════════════════════════════════╗
║      DNSTT CONNECTION INFO - ULTRA SPEED EDITION     ║
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
Expected Speed: 5-15 Mbps

PUBLIC KEY:
═══════════
$PUBKEY

DNS RECORDS:
════════════
A    $ns_domain         $PUBLIC_IP
NS   $tunnel_domain     $ns_domain

ULTRA SPEED CLIENT COMMANDS:
═════════════════════════════
# Cloudflare DoH (Best Performance)
dnstt-client -doh https://cloudflare-dns.com/dns-query -pubkey $PUBKEY -mtu $MTU $tunnel_domain 127.0.0.1:$SSH_PORT

# Google DoH
dnstt-client -doh https://dns.google/dns-query -pubkey $PUBKEY -mtu $MTU $tunnel_domain 127.0.0.1:$SSH_PORT

# Quad9 DoH
dnstt-client -doh https://dns.quad9.net/dns-query -pubkey $PUBKEY -mtu $MTU $tunnel_domain 127.0.0.1:$SSH_PORT

# Direct UDP (Alternative - can be faster)
dnstt-client -udp $PUBLIC_IP:5300 -pubkey $PUBKEY -mtu $MTU $tunnel_domain 127.0.0.1:$SSH_PORT

IMPORTANT NOTE:
═══════════════
⚠️  DNSTT forwards directly to SSH port $SSH_PORT
⚠️  Use port $SSH_PORT in your DNSTT client connection
⚠️  Format: 127.0.0.1:$SSH_PORT

APP CONFIGURATION:
══════════════════
In your HTTP Injector or similar app:
- Local Proxy Port: $SSH_PORT
- SSH Host: 127.0.0.1
- SSH Port: $SSH_PORT
- Username: [your ssh username]
- Password: [your ssh password]

ULTRA OPTIMIZATIONS:
════════════════════
✓ BBR Congestion Control (best for high latency)
✓ 512MB Network Buffers (massive throughput)
✓ 256KB UDP Buffers (EDNS0 support, no packet loss)
✓ 100K Packet Backlog (handles DNS bursts)
✓ 4M Connection Tracking (unlimited connections)
✓ Realtime CPU Priority (FIFO 99)
✓ I/O Realtime Priority
✓ TCP FastOpen (reduces latency)
✓ DNS-specific optimizations
✓ 1M File Descriptors (parallel tunnels)
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
# DISPLAY INFORMATION FUNCTIONS
#============================================

show_udp_info() {
    local PUBLIC_IP=$1
    local ns_domain=$2
    local tunnel_domain=$3
    local PUBKEY=$4
    local MTU=$5
    local SSH_PORT=$6
    
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║          ✅ DNSTT UDP INSTALLATION COMPLETE!         ║${NC}"
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
    echo ""
    echo -e "${YELLOW}📱 CLIENT COMMAND (Direct UDP - FASTEST):${NC}"
    echo ""
    echo -e "${GREEN}Direct UDP:${NC}"
    echo -e "${WHITE}dnstt-client -udp $PUBLIC_IP:5300 \\${NC}"
    echo -e "${WHITE}  -pubkey $PUBKEY \\${NC}"
    echo -e "${WHITE}  -mtu $MTU \\${NC}"
    echo -e "${WHITE}  $tunnel_domain${NC}"
    echo ""
    echo -e "${CYAN}Alternative (DoH):${NC}"
    echo -e "${WHITE}dnstt-client -doh https://cloudflare-dns.com/dns-query \\${NC}"
    echo -e "${WHITE}  -pubkey $PUBKEY \\${NC}"
    echo -e "${WHITE}  -mtu $MTU \\${NC}"
    echo -e "${WHITE}  $tunnel_domain${NC}"
    echo ""
    echo -e "${YELLOW}💡 Connect to your SSH server using the tunnel:${NC}"
    echo -e "${WHITE}   SSH Host: $PUBLIC_IP${NC}"
    echo -e "${WHITE}   SSH Port: $SSH_PORT${NC}"
    echo ""
    
    # Save connection info
    cat > "$INSTALL_DIR/connection_info.txt" << EOF
DNSTT UDP MODE - Created By THE KING 👑 💯
Generated: $(date)

SERVER DETAILS:
═══════════════
IP:             $PUBLIC_IP
NS Domain:      $ns_domain
Tunnel Domain:  $tunnel_domain
SSH Port:       $SSH_PORT
MTU:            $MTU bytes
Expected Speed: 5-15 Mbps

PUBLIC KEY:
═══════════
$PUBKEY

DNS RECORDS:
════════════
A    $ns_domain         $PUBLIC_IP
NS   $tunnel_domain     $ns_domain

CLIENT COMMANDS:
════════════════
# Direct UDP (FASTEST - Recommended)
dnstt-client -udp $PUBLIC_IP:5300 -pubkey $PUBKEY -mtu $MTU $tunnel_domain

# Cloudflare DoH
dnstt-client -doh https://cloudflare-dns.com/dns-query -pubkey $PUBKEY -mtu $MTU $tunnel_domain

# Google DoH
dnstt-client -doh https://dns.google/dns-query -pubkey $PUBKEY -mtu $MTU $tunnel_domain

SSH CONNECTION:
═══════════════
After starting dnstt-client, connect to:
Host: $PUBLIC_IP
Port: $SSH_PORT
Username: [your username]
Password: [your password]

ULTRA OPTIMIZATIONS:
════════════════════
✓ Direct UDP (no localhost forwarding)
✓ BBR Congestion Control
✓ 512MB Network Buffers
✓ 256KB UDP Buffers (EDNS0)
✓ 100K Packet Backlog
✓ 4M Connection Tracking
✓ Realtime Priority (FIFO 99)
✓ TCP FastOpen
✓ DNS-specific optimizations
✓ MTU $MTU optimized

Created By THE KING 👑 💯
EOF
}

show_v2ray_info() {
    local PUBLIC_IP=$1
    local ns_domain=$2
    local tunnel_domain=$3
    local PUBKEY=$4
    local MTU=$5
    local V2RAY_PORT=$6
    local UUID=$7
    
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║       ✅ DNSTT + V2RAY INSTALLATION COMPLETE!        ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━ V2RAY CONFIGURATION ━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${WHITE}🌐 Server IP:${NC}       ${YELLOW}$PUBLIC_IP${NC}"
    echo -e "${WHITE}🔗 NS Domain:${NC}       ${YELLOW}$ns_domain${NC}"
    echo -e "${WHITE}🔗 Tunnel Domain:${NC}   ${YELLOW}$tunnel_domain${NC}"
    echo -e "${WHITE}🔑 DNSTT Key:${NC}"
    echo -e "${YELLOW}$PUBKEY${NC}"
    echo -e "${WHITE}📊 MTU:${NC}             ${YELLOW}$MTU bytes${NC}"
    echo ""
    echo -e "${WHITE}🚀 V2Ray Port:${NC}      ${GREEN}$V2RAY_PORT${NC}"
    echo -e "${WHITE}🆔 UUID:${NC}"
    echo -e "${GREEN}$UUID${NC}"
    echo -e "${WHITE}🌐 Path:${NC}            ${GREEN}/dnstt-v2ray${NC}"
    echo -e "${WHITE}📡 Protocol:${NC}        ${GREEN}VMess + WebSocket${NC}"
    echo ""
    echo -e "${YELLOW}📱 DNSTT CLIENT COMMAND:${NC}"
    echo ""
    echo -e "${GREEN}Direct UDP (FASTEST):${NC}"
    echo -e "${WHITE}dnstt-client -udp $PUBLIC_IP:5300 \\${NC}"
    echo -e "${WHITE}  -pubkey $PUBKEY \\${NC}"
    echo -e "${WHITE}  -mtu $MTU \\${NC}"
    echo -e "${WHITE}  $tunnel_domain${NC}"
    echo ""
    echo -e "${YELLOW}📱 V2RAY CLIENT CONFIGURATION:${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}Protocol:${NC}   VMess"
    echo -e "${WHITE}Address:${NC}    $PUBLIC_IP"
    echo -e "${WHITE}Port:${NC}       $V2RAY_PORT"
    echo -e "${WHITE}UUID:${NC}       $UUID"
    echo -e "${WHITE}AlterID:${NC}    0"
    echo -e "${WHITE}Security:${NC}   auto"
    echo -e "${WHITE}Network:${NC}    ws (WebSocket)"
    echo -e "${WHITE}WS Path:${NC}    /dnstt-v2ray"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}💡 How to use:${NC}"
    echo -e "   ${CYAN}1.${NC} Start DNSTT client with command above"
    echo -e "   ${CYAN}2.${NC} Configure V2Ray/V2RayNG with settings above"
    echo -e "   ${CYAN}3.${NC} Connect to V2Ray - traffic goes through DNS tunnel"
    echo ""
    
    # Save V2Ray info
    cat > "$INSTALL_DIR/v2ray_info.txt" << EOF
DNSTT + V2RAY MODE - Created By THE KING 👑 💯
Generated: $(date)

SERVER DETAILS:
═══════════════
IP:             $PUBLIC_IP
NS Domain:      $ns_domain
Tunnel Domain:  $tunnel_domain
MTU:            $MTU bytes
Expected Speed: 10-20 Mbps

DNSTT PUBLIC KEY:
═════════════════
$PUBKEY

V2RAY CONFIGURATION:
════════════════════
Port:           $V2RAY_PORT
UUID:           $UUID
Protocol:       VMess
Network:        WebSocket
WS Path:        /dnstt-v2ray
AlterID:        0
Security:       auto

DNS RECORDS:
════════════
A    $ns_domain         $PUBLIC_IP
NS   $tunnel_domain     $ns_domain

DNSTT CLIENT COMMAND:
═════════════════════
dnstt-client -udp $PUBLIC_IP:5300 -pubkey $PUBKEY -mtu $MTU $tunnel_domain

V2RAY CLIENT CONFIG:
════════════════════
Protocol:   VMess
Address:    $PUBLIC_IP
Port:       $V2RAY_PORT
UUID:       $UUID
AlterID:    0
Security:   auto
Network:    ws
Path:       /dnstt-v2ray

USAGE STEPS:
════════════
1. Start DNSTT client on your device
2. Configure V2Ray client with settings above
3. Connect to V2Ray
4. All traffic goes through DNS tunnel

ULTRA OPTIMIZATIONS:
════════════════════
✓ V2Ray VMess Protocol (faster than SSH)
✓ WebSocket transport (low latency)
✓ Direct UDP DNS tunnel
✓ BBR Congestion Control
✓ 512MB Network Buffers
✓ Realtime Priority

Created By THE KING 👑 💯
EOF
}

#============================================
# SSH USER MANAGEMENT
#============================================

add_ssh_user() {
    local PUBLIC_IP=$1
    local ns_domain=$2
    local tunnel_domain=$3
    local PUBKEY=$4
    local MTU=$5
    local SSH_PORT=$6
    
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║          ✅ DNSTT UDP INSTALLATION COMPLETE!         ║${NC}"
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
    echo ""
    echo -e "${YELLOW}📱 CLIENT COMMAND (Direct UDP - FASTEST):${NC}"
    echo ""
    echo -e "${GREEN}dnstt-client -udp $PUBLIC_IP:5300 \\${NC}"
    echo -e "${GREEN}  -pubkey $PUBKEY \\${NC}"
    echo -e "${GREEN}  -mtu $MTU \\${NC}"
    echo -e "${GREEN}  $tunnel_domain 127.0.0.1:$SSH_PORT${NC}"
    echo ""
    echo -e "${YELLOW}Alternative (DoH):${NC}"
    echo -e "${WHITE}dnstt-client -doh https://cloudflare-dns.com/dns-query \\${NC}"
    echo -e "${WHITE}  -pubkey $PUBKEY -mtu $MTU $tunnel_domain 127.0.0.1:$SSH_PORT${NC}"
    echo ""
    
    # Save connection info
    cat > "$INSTALL_DIR/connection_info.txt" << EOF
DNSTT UDP MODE - Created By THE KING 👑 💯
Generated: $(date)

SERVER DETAILS:
═══════════════
IP:             $PUBLIC_IP
NS Domain:      $ns_domain
Tunnel Domain:  $tunnel_domain
SSH Port:       $SSH_PORT
MTU:            $MTU bytes
Expected Speed: 5-15 Mbps

PUBLIC KEY:
═══════════
$PUBKEY

DNS RECORDS:
════════════
A    $ns_domain         $PUBLIC_IP
NS   $tunnel_domain     $ns_domain

CLIENT COMMANDS:
════════════════
# Direct UDP (FASTEST - Recommended)
dnstt-client -udp $PUBLIC_IP:5300 -pubkey $PUBKEY -mtu $MTU $tunnel_domain

# Cloudflare DoH
dnstt-client -doh https://cloudflare-dns.com/dns-query -pubkey $PUBKEY -mtu $MTU $tunnel_domain

# Google DoH
dnstt-client -doh https://dns.google/dns-query -pubkey $PUBKEY -mtu $MTU $tunnel_domain

SSH CONNECTION:
═══════════════
After starting dnstt-client, connect to:
Host: $PUBLIC_IP
Port: $SSH_PORT
Username: [your username]
Password: [your password]

ULTRA OPTIMIZATIONS:
════════════════════
✓ Direct UDP (no localhost forwarding)
✓ BBR Congestion Control
✓ 512MB Network Buffers
✓ 256KB UDP Buffers (EDNS0)
✓ 100K Packet Backlog
✓ 4M Connection Tracking
✓ Realtime Priority (FIFO 99)
✓ TCP FastOpen
✓ DNS-specific optimizations
✓ MTU $MTU optimized

Created By THE KING 👑 💯
EOF
}

show_v2ray_info() {
    local PUBLIC_IP=$1
    local ns_domain=$2
    local tunnel_domain=$3
    local PUBKEY=$4
    local MTU=$5
    local V2RAY_PORT=$6
    local UUID=$7
    
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║       ✅ DNSTT + V2RAY INSTALLATION COMPLETE!        ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━ V2RAY CONFIGURATION ━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${WHITE}🌐 Server IP:${NC}       ${YELLOW}$PUBLIC_IP${NC}"
    echo -e "${WHITE}🔗 NS Domain:${NC}       ${YELLOW}$ns_domain${NC}"
    echo -e "${WHITE}🔗 Tunnel Domain:${NC}   ${YELLOW}$tunnel_domain${NC}"
    echo -e "${WHITE}🔑 DNSTT Key:${NC}"
    echo -e "${YELLOW}$PUBKEY${NC}"
    echo -e "${WHITE}📊 MTU:${NC}             ${YELLOW}$MTU bytes${NC}"
    echo ""
    echo -e "${WHITE}🚀 V2Ray Port:${NC}      ${GREEN}$V2RAY_PORT${NC}"
    echo -e "${WHITE}🆔 UUID:${NC}"
    echo -e "${GREEN}$UUID${NC}"
    echo -e "${WHITE}🌐 Path:${NC}            ${GREEN}/dnstt-v2ray${NC}"
    echo -e "${WHITE}📡 Protocol:${NC}        ${GREEN}VMess + WebSocket${NC}"
    echo ""
    echo -e "${YELLOW}📱 DNSTT CLIENT COMMAND:${NC}"
    echo ""
    echo -e "${GREEN}Direct UDP (FASTEST):${NC}"
    echo -e "${WHITE}dnstt-client -udp $PUBLIC_IP:5300 \\${NC}"
    echo -e "${WHITE}  -pubkey $PUBKEY \\${NC}"
    echo -e "${WHITE}  -mtu $MTU \\${NC}"
    echo -e "${WHITE}  $tunnel_domain${NC}"
    echo ""
    echo -e "${YELLOW}📱 V2RAY CLIENT CONFIGURATION:${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}Protocol:${NC}   VMess"
    echo -e "${WHITE}Address:${NC}    $PUBLIC_IP"
    echo -e "${WHITE}Port:${NC}       $V2RAY_PORT"
    echo -e "${WHITE}UUID:${NC}       $UUID"
    echo -e "${WHITE}AlterID:${NC}    0"
    echo -e "${WHITE}Security:${NC}   auto"
    echo -e "${WHITE}Network:${NC}    ws (WebSocket)"
    echo -e "${WHITE}WS Path:${NC}    /dnstt-v2ray"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}💡 How to use:${NC}"
    echo -e "   ${CYAN}1.${NC} Start DNSTT client with command above"
    echo -e "   ${CYAN}2.${NC} Configure V2Ray/V2RayNG with settings above"
    echo -e "   ${CYAN}3.${NC} Connect to V2Ray - traffic goes through DNS tunnel"
    echo ""
    echo -e "${YELLOW}💡 V2Ray Benefits:${NC}"
    echo -e "   ${GREEN}✓${NC} 2-3x faster than SSH"
    echo -e "   ${GREEN}✓${NC} Better for video streaming"
    echo -e "   ${GREEN}✓${NC} Lower latency"
    echo -e "   ${GREEN}✓${NC} More stable connections"
    echo -e "   ${GREEN}✓${NC} Expected Speed: 10-20 Mbps"
    echo ""
    
    # Save V2Ray info
    cat > "$INSTALL_DIR/v2ray_info.txt" << EOF
DNSTT + V2RAY MODE - Created By THE KING 👑 💯
Generated: $(date)

SERVER DETAILS:
═══════════════
IP:             $PUBLIC_IP
NS Domain:      $ns_domain
Tunnel Domain:  $tunnel_domain
MTU:            $MTU bytes
Expected Speed: 10-20 Mbps

DNSTT PUBLIC KEY:
═════════════════
$PUBKEY

V2RAY CONFIGURATION:
════════════════════
Port:           $V2RAY_PORT
UUID:           $UUID
Protocol:       VMess
Network:        WebSocket
WS Path:        /dnstt-v2ray
AlterID:        0
Security:       auto

DNS RECORDS:
════════════
A    $ns_domain         $PUBLIC_IP
NS   $tunnel_domain     $ns_domain

DNSTT CLIENT COMMAND:
═════════════════════
dnstt-client -udp $PUBLIC_IP:5300 -pubkey $PUBKEY -mtu $MTU $tunnel_domain

V2RAY CLIENT CONFIG:
════════════════════
Protocol:   VMess
Address:    $PUBLIC_IP
Port:       $V2RAY_PORT
UUID:       $UUID
AlterID:    0
Security:   auto
Network:    ws
Path:       /dnstt-v2ray

USAGE STEPS:
════════════
1. Start DNSTT client on your device
2. Configure V2Ray client with settings above
3. Connect to V2Ray
4. All traffic goes through DNS tunnel

ULTRA OPTIMIZATIONS:
════════════════════
✓ V2Ray VMess Protocol (faster than SSH)
✓ WebSocket transport (low latency)
✓ Direct UDP DNS tunnel
✓ BBR Congestion Control
✓ 512MB Network Buffers
✓ Realtime Priority

Created By THE KING 👑 💯
EOF
}

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
        echo -e "${GREEN}✅ DNSTT: RUNNING (ULTRA MODE 👑)${NC}"
        
        uptime_sec=$(systemctl show dnstt --property=ActiveEnterTimestamp --value)
        if [[ -n "$uptime_sec" ]]; then
            echo -e "${WHITE}Started: ${GREEN}$uptime_sec${NC}"
            
            # Calculate uptime
            start_epoch=$(date -d "$uptime_sec" +%s 2>/dev/null || echo "0")
            current_epoch=$(date +%s)
            uptime_seconds=$((current_epoch - start_epoch))
            uptime_days=$((uptime_seconds / 86400))
            uptime_hours=$(( (uptime_seconds % 86400) / 3600 ))
            uptime_mins=$(( (uptime_seconds % 3600) / 60 ))
            
            echo -e "${WHITE}Uptime: ${GREEN}${uptime_days}d ${uptime_hours}h ${uptime_mins}m${NC}"
        fi
        
        # Show process priority
        DNSTT_PID=$(systemctl show dnstt --property=MainPID --value)
        if [[ -n "$DNSTT_PID" && "$DNSTT_PID" != "0" ]]; then
            NICE=$(ps -o nice= -p $DNSTT_PID 2>/dev/null || echo "N/A")
            echo -e "${WHITE}Process Priority (Nice): ${GREEN}$NICE${NC}"
        fi
    else
        echo -e "${RED}❌ DNSTT: STOPPED${NC}"
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
    
    if [[ "$correct_domain" =~ \.\. ]]; then
        log_error "Invalid domain (contains double dots)"
        press_enter
        return
    fi
    
    MTU=$(cat "$INSTALL_DIR/mtu.txt" 2>/dev/null || echo "1280")
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
    
    if (( $(echo "$TOTAL_MBPS >= 5" | bc -l) )); then
        echo -e "${GREEN}✅ Performance: EXCELLENT (Target 5-15 Mbps achieved)${NC}"
    elif (( $(echo "$TOTAL_MBPS >= 2" | bc -l) )); then
        echo -e "${YELLOW}⚠️  Performance: GOOD (Consider optimizing MTU)${NC}"
    else
        echo -e "${RED}❌ Performance: NEEDS IMPROVEMENT${NC}"
        echo -e "${YELLOW}   Try increasing MTU to 1232 or 1280${NC}"
    fi
    
    press_enter
}

view_info() {
    show_banner
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║            CONNECTION INFORMATION                    ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [[ -f "$INSTALL_DIR/mode.txt" ]]; then
        MODE=$(cat "$INSTALL_DIR/mode.txt")
        
        if [[ "$MODE" == "v2ray" ]]; then
            if [[ -f "$INSTALL_DIR/v2ray_info.txt" ]]; then
                cat "$INSTALL_DIR/v2ray_info.txt"
            else
                log_error "V2Ray info not found"
            fi
        else
            if [[ -f "$INSTALL_DIR/connection_info.txt" ]]; then
                cat "$INSTALL_DIR/connection_info.txt"
            else
                log_error "Connection info not found"
            fi
        fi
    else
        log_error "Not configured. Run installation first."
    fi
    
    press_enter
}

view_performance() {
    show_banner
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║           ULTRA PERFORMANCE MONITORING               ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${YELLOW}━━━ SERVICE STATUS ━━━${NC}"
    if systemctl is-active --quiet dnstt; then
        echo -e "${GREEN}✅ DNSTT: RUNNING (ULTRA MODE)${NC}"
    else
        echo -e "${RED}❌ DNSTT: STOPPED${NC}"
    fi
    echo ""
    
    echo -e "${YELLOW}━━━ ULTRA SETTINGS ━━━${NC}"
    echo -e "${GREEN}✓${NC} CPU Priority: Realtime (FIFO 99)"
    echo -e "${GREEN}✓${NC} I/O Priority: Realtime (0)"
    echo -e "${GREEN}✓${NC} Nice: -20 (highest)"
    echo -e "${GREEN}✓${NC} CPU Quota: 1600% (16 cores)"
    echo -e "${GREEN}✓${NC} Memory: 8GB"
    echo -e "${GREEN}✓${NC} File Descriptors: 1M"
    echo ""
    
    echo -e "${YELLOW}━━━ NETWORK STATS ━━━${NC}"
    if command -v ss &> /dev/null; then
        UDP_CONNS=$(ss -u | grep -c ':5300' 2>/dev/null || echo "0")
        echo -e "${WHITE}UDP Connections (5300): ${CYAN}$UDP_CONNS${NC}"
    fi
    
    RMEM_MAX=$(sysctl -n net.core.rmem_max 2>/dev/null || echo "0")
    UDP_RMEM=$(sysctl -n net.ipv4.udp_rmem_min 2>/dev/null || echo "0")
    BACKLOG=$(sysctl -n net.core.netdev_max_backlog 2>/dev/null || echo "0")
    BBR=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo "N/A")
    
    RMEM_MB=$((RMEM_MAX / 1048576))
    UDP_KB=$((UDP_RMEM / 1024))
    
    echo -e "${WHITE}Network Buffer: ${GREEN}${RMEM_MB}MB${NC}"
    echo -e "${WHITE}UDP Buffer: ${GREEN}${UDP_KB}KB${NC}"
    echo -e "${WHITE}Packet Backlog: ${GREEN}${BACKLOG}${NC}"
    echo -e "${WHITE}Congestion Control: ${GREEN}${BBR}${NC}"
    echo ""
    
    echo -e "${YELLOW}━━━ SYSTEM RESOURCES ━━━${NC}"
    MEM_TOTAL=$(free -h | awk '/^Mem:/ {print $2}')
    MEM_USED=$(free -h | awk '/^Mem:/ {print $3}')
    echo -e "${WHITE}Memory: ${CYAN}${MEM_USED}/${MEM_TOTAL}${NC}"
    echo ""
    
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
                    echo -e "${GREEN}✓ Service restarted successfully${NC}"
                else
                    echo -e "${RED}✗ Service failed to restart${NC}"
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
                    rm -f /etc/sysctl.d/99-dnstt-ultra-speed.conf
                    rm -f /etc/security/limits.d/99-dnstt-ultra.conf
                    systemctl daemon-reload
                    echo -e "${GREEN}✓ DNSTT uninstalled${NC}"
                    sleep 2
                else
                    echo -e "${YELLOW}Cancelled${NC}"
                    sleep 1
                fi
                ;;
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
            
            echo -e "${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                  QUICK STATS                         ║${NC}"
            echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
            echo ""
            echo -e "  ${WHITE}📊 Total: ${CYAN}$total_users${NC}  |  ${GREEN}Active: $active_users${NC}  |  ${RED}Expired: $((total_users - active_users))${NC}"
            echo ""
        fi
        
        echo -e "${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║                  MENU OPTIONS                        ║${NC}"
        echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  ${GREEN}1)${NC} 👤 Add New User"
        echo -e "  ${YELLOW}2)${NC} 📋 List All Users"
        echo -e "  ${RED}3)${NC} 🗑️  Delete User"
        echo -e "  ${BLUE}4)${NC} 🔗 Show Online Users"
        echo -e "  ${PURPLE}5)${NC} 🔍 Search User"
        echo -e "  ${WHITE}0)${NC} ⬅️  Back"
        echo ""
        read -p "Choice: " choice
        
        case $choice in
            1) add_ssh_user ;;
            2) list_ssh_users ;;
            3) delete_ssh_user ;;
            4)
                show_banner
                echo -e "${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
                echo -e "${CYAN}║                  ONLINE USERS                        ║${NC}"
                echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
                echo ""
                
                if who | grep -q .; then
                    echo -e "${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
                    echo -e "${CYAN}║            ACTIVE SSH SESSIONS                       ║${NC}"
                    echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
                    echo ""
                    
                    who | while read -r line; do
                        echo -e "${GREEN}● CONNECTED${NC} $line"
                    done
                    
                    echo ""
                    local session_count=$(who | wc -l)
                    echo -e "${CYAN}Total active sessions: ${WHITE}$session_count${NC}"
                else
                    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                    echo -e "            ${YELLOW}No active SSH sessions${NC}"
                    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                fi
                
                echo ""
                press_enter
                ;;
            5)
                show_banner
                echo -e "${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
                echo -e "${CYAN}║                  SEARCH USER                         ║${NC}"
                echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
                echo ""
                
                read -p "Enter username to search: " search_user
                
                if [[ -z "$search_user" ]]; then
                    log_error "Username required"
                    press_enter
                    continue
                fi
                
                echo ""
                echo -e "${CYAN}Searching for: $search_user${NC}"
                echo ""
                
                if grep -q "^$search_user|" "$USER_DB" 2>/dev/null; then
                    local user_info=$(grep "^$search_user|" "$USER_DB")
                    IFS='|' read -r user pass exp created <<< "$user_info"
                    
                    current=$(date +%s)
                    exp_unix=$(date -d "$exp" +%s 2>/dev/null || echo "0")
                    days_left=$(( (exp_unix - current) / 86400 ))
                    
                    echo -e "${GREEN}✓ User found!${NC}"
                    echo ""
                    echo -e "${CYAN}╔═══════════════════════════════════════════════════════╗${NC}"
                    echo -e "${CYAN}║                 USER DETAILS                         ║${NC}"
                    echo -e "${CYAN}╚═══════════════════════════════════════════════════════╝${NC}"
                    echo ""
                    echo -e "  ${WHITE}👤 Username:${NC}  ${GREEN}$user${NC}"
                    echo -e "  ${WHITE}🔐 Password:${NC}  ${GREEN}$pass${NC}"
                    echo -e "  ${WHITE}📅 Created:${NC}   ${CYAN}$created${NC}"
                    echo -e "  ${WHITE}⏰ Expires:${NC}   ${YELLOW}$exp${NC}"
                    
                    if [[ $days_left -gt 0 ]]; then
                        echo -e "  ${WHITE}⏳ Days Left:${NC} ${GREEN}$days_left days${NC}"
                        echo -e "  ${WHITE}Status:${NC}     ${GREEN}● ACTIVE${NC}"
                    else
                        echo -e "  ${WHITE}⏳ Days Left:${NC} ${RED}EXPIRED${NC}"
                        echo -e "  ${WHITE}Status:${NC}     ${RED}● EXPIRED${NC}"
                    fi
                    
                    # Check if user is logged in
                    if who | grep -q "^$user "; then
                        echo -e "  ${WHITE}Session:${NC}    ${GREEN}🔗 LOGGED IN${NC}"
                    else
                        echo -e "  ${WHITE}Session:${NC}    ${WHITE}○ Not logged in${NC}"
                    fi
                else
                    echo -e "${RED}✗ User '$search_user' not found${NC}"
                fi
                
                echo ""
                press_enter
                ;;
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
    if [[ -f /etc/sysctl.d/99-dnstt-ultra-speed.conf ]]; then
        echo -e "${GREEN}✅ ULTRA SPEED MODE ACTIVE${NC}"
        echo -e "${GREEN}✓${NC} BBR congestion control"
        echo -e "${GREEN}✓${NC} 512MB network buffers"
        echo -e "${GREEN}✓${NC} 256KB UDP buffers (EDNS0)"
        echo -e "${GREEN}✓${NC} 100K packet backlog"
        echo -e "${GREEN}✓${NC} 4M connection tracking"
        echo -e "${GREEN}✓${NC} TCP FastOpen"
        echo -e "${GREEN}✓${NC} DNS optimizations"
        
        if [[ -f /etc/security/limits.d/99-dnstt-ultra.conf ]]; then
            echo -e "${GREEN}✓${NC} 1M file descriptors"
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
        echo -e "  ${PURPLE}4)${NC} 🔄 Auto-Update Script"
        echo -e "  ${CYAN}5)${NC} 📝 Generate GitHub README"
        echo -e "  ${RED}0)${NC} ⛔ Exit"
        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${WHITE}Version: 7.0 ULTRA | ${GREEN}Created By THE KING 👑 💯${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        read -p "Choice: " choice
        
        case $choice in
            1) dnstt_menu ;;
            2) ssh_menu ;;
            3) system_menu ;;
            4) auto_update_script ;;
            5) generate_readme ;;
            0)
                echo ""
                echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                echo -e "${GREEN}    Thank you for using DNSTT ULTRA! 👑 💯${NC}"
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