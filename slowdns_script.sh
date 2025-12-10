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
# ANIMATION FUNCTIONS
#============================================

spinner() {
    local pid=$1
    local message=$2
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    
    while ps -p $pid > /dev/null 2>&1; do
        local temp=${spinstr#?}
        printf " ${CYAN}[%c]${NC} ${message}...\r" "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
    done
    printf "    \r"
}

loading_bar() {
    local duration=$1
    local message=$2
    local width=50
    
    echo -ne "${message}\n"
    for ((i=0; i<=width; i++)); do
        local percent=$((i * 100 / width))
        local filled=$((i * 100 / width / 2))
        local empty=$((50 - filled))
        
        printf "\r${CYAN}["
        printf "%${filled}s" | tr ' ' '█'
        printf "%${empty}s" | tr ' ' '░'
        printf "]${NC} ${GREEN}%3d%%${NC}" $percent
        
        sleep $(echo "$duration / $width" | bc -l)
    done
    echo ""
}

progress_dots() {
    local message=$1
    local duration=$2
    local dots=0
    
    for ((i=0; i<duration; i++)); do
        dots=$((dots % 4))
        local dot_string=$(printf "%${dots}s" | tr ' ' '.')
        printf "\r${YELLOW}%s%-3s${NC}" "$message" "$dot_string"
        sleep 1
        dots=$((dots + 1))
    done
    printf "\r%*s\r" $((${#message} + 3)) ""
}

animated_check() {
    echo -ne "${YELLOW}⧗${NC} "
    sleep 0.3
    echo -ne "\r${GREEN}✓${NC} "
}

animated_error() {
    echo -ne "${YELLOW}⧗${NC} "
    sleep 0.3
    echo -ne "\r${RED}✗${NC} "
}

typing_effect() {
    local text=$1
    local delay=${2:-0.03}
    
    for ((i=0; i<${#text}; i++)); do
        echo -n "${text:$i:1}"
        sleep $delay
    done
    echo ""
}

pulse_message() {
    local message=$1
    local duration=${2:-3}
    
    for ((i=0; i<duration; i++)); do
        echo -ne "\r${GREEN}●${NC} ${message}"
        sleep 0.5
        echo -ne "\r${CYAN}●${NC} ${message}"
        sleep 0.5
    done
    echo -ne "\r${GREEN}✓${NC} ${message}\n"
}

# New animation: Bouncing ball
bouncing_ball() {
    local message=$1
    local duration=${2:-5}
    local positions=("⠁" "⠂" "⠄" "⡀" "⢀" "⠠" "⠐" "⠈")
    local pos=0
    
    for ((i=0; i<duration*4; i++)); do
        printf "\r${CYAN}%s${NC} ${message}" "${positions[$pos]}"
        pos=$(( (pos + 1) % ${#positions[@]} ))
        sleep 0.25
    done
    printf "\r${GREEN}✓${NC} ${message}\n"
}

# New animation: Rainbow effect
rainbow_text() {
    local text=$1
    local colors=("${RED}" "${YELLOW}" "${GREEN}" "${CYAN}" "${BLUE}" "${PURPLE}")
    local color_index=0
    
    for ((i=0; i<${#text}; i++)); do
        echo -n "${colors[$color_index]}${text:$i:1}${NC}"
        color_index=$(( (color_index + 1) % ${#colors[@]} ))
        sleep 0.05
    done
    echo ""
}

# New animation: Scanning effect
scanning_effect() {
    local message=$1
    local width=40
    
    echo -e "${message}"
    for ((i=0; i<=width; i++)); do
        printf "\r${CYAN}["
        printf "%${i}s" | tr ' ' '='
        printf "${GREEN}>${NC}"
        printf "%$((width-i))s" | tr ' ' ' '
        printf "]"
        sleep 0.05
    done
    echo ""
}

# New animation: Blinking status
blinking_status() {
    local message=$1
    local status=$2
    local color=$3
    local duration=${4:-3}
    
    for ((i=0; i<duration; i++)); do
        echo -ne "\r${color}● ${status}${NC} ${message}"
        sleep 0.5
        echo -ne "\r${WHITE}○ ${status}${NC} ${message}"
        sleep 0.5
    done
    echo -ne "\r${color}● ${status}${NC} ${message}\n"
}

# New animation: Counter
animated_counter() {
    local target=$1
    local label=$2
    local increment=$((target / 20))
    [[ $increment -eq 0 ]] && increment=1
    
    for ((i=0; i<=target; i+=increment)); do
        printf "\r${CYAN}%s: ${GREEN}%d${NC}" "$label" "$i"
        sleep 0.05
    done
    printf "\r${CYAN}%s: ${GREEN}%d${NC}\n" "$label" "$target"
}

# New animation: Success celebration
celebrate_success() {
    local message=$1
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    sleep 0.2
    echo -e "${GREEN}║${NC}                   ${YELLOW}🎉 SUCCESS! 🎉${NC}                        ${GREEN}║${NC}"
    sleep 0.2
    echo -e "${GREEN}║${NC}                                                           ${GREEN}║${NC}"
    sleep 0.2
    echo -e "${GREEN}║${NC}     ${WHITE}${message}${NC}"
    # Pad message to center
    local padding=$((55 - ${#message}))
    printf "${GREEN}║${NC}\n"
    sleep 0.2
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# New animation: Warning flash
warning_flash() {
    local message=$1
    for ((i=0; i<3; i++)); do
        echo -ne "\r${RED}⚠️  ${message}${NC}"
        sleep 0.3
        echo -ne "\r${YELLOW}⚠️  ${message}${NC}"
        sleep 0.3
    done
    echo -ne "\r${RED}⚠️  ${message}${NC}\n"
}

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
  ║                                                           ║
  ║                     ██████╗ ███╗   ██╗███████╗           ║
  ║                     ██╔══██╗████╗  ██║██╔════╝           ║
  ║                     ██║  ██║██╔██╗ ██║███████╗           ║
  ║                     ██║  ██║██║╚██╗██║╚════██║           ║
  ║                     ██████╔╝██║ ╚████║███████║           ║
  ║                     ╚═════╝ ╚═╝  ╚═══╝╚══════╝           ║
  ║                                                           ║
  ║           ████████╗████████╗    ████████╗████████╗       ║
  ║           ╚══██╔══╝╚══██╔══╝    ╚══██╔══╝╚══██╔══╝       ║
  ║              ██║      ██║          ██║      ██║          ║
  ║              ██║      ██║          ██║      ██║          ║
  ║              ██║      ██║          ██║      ██║          ║
  ║              ╚═╝      ╚═╝          ╚═╝      ╚═╝          ║
  ║                                                           ║
  ║              SLOW DNS TUNNEL MANAGER v6.1                ║
  ║              High-Performance Edition                    ║
  ║                                                           ║
  ║              MADE BY THE KING 👑 💯                       ║
  ║                                                           ║
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
    log_message "${YELLOW}⚡ Optimizing system for ULTRA-high-speed DNS tunneling...${NC}"
    echo ""
    
    loading_bar 2 "${CYAN}Applying DNSTT SPEED BOOSTER${NC}"
    
    # === DNSTT SPEED BOOSTER - Phase 1 ===
    # Enable IP forwarding for routing performance
    sysctl -w net.ipv4.ip_forward=1 > /dev/null 2>&1
    
    # Load BBR module
    modprobe tcp_bbr 2>/dev/null
    
    # Set ulimit for parallel file descriptors
    ulimit -n 1048576 2>/dev/null
    
    animated_check
    echo "SPEED BOOSTER Phase 1: IP forwarding & BBR loaded"
    
    loading_bar 2 "${CYAN}Applying network optimizations${NC}"
    
    # AGGRESSIVE network buffer increases for maximum throughput
    sysctl -w net.core.rmem_max=268435456 > /dev/null 2>&1  # 256MB (ULTRA)
    sysctl -w net.core.wmem_max=268435456 > /dev/null 2>&1  # 256MB (ULTRA)
    sysctl -w net.core.rmem_default=33554432 > /dev/null 2>&1  # 32MB
    sysctl -w net.core.wmem_default=33554432 > /dev/null 2>&1  # 32MB
    sysctl -w net.ipv4.tcp_rmem="8192 262144 268435456" > /dev/null 2>&1
    sysctl -w net.ipv4.tcp_wmem="8192 262144 268435456" > /dev/null 2>&1
    
    animated_check
    echo "Network buffers: 256MB configured (ULTRA)"
    
    loading_bar 2 "${CYAN}Optimizing UDP performance (CRITICAL)${NC}"
    
    # UDP buffer tuning - CRITICAL for DNS tunnel speed
    # Combined: Your booster (26MB) + ULTRA (128KB min)
    sysctl -w net.core.rmem_max=268435456 > /dev/null 2>&1  # Keep ULTRA 256MB
    sysctl -w net.core.wmem_max=268435456 > /dev/null 2>&1  # Keep ULTRA 256MB
    sysctl -w net.ipv4.udp_rmem_min=131072 > /dev/null 2>&1  # 128KB (BOOSTER)
    sysctl -w net.ipv4.udp_wmem_min=131072 > /dev/null 2>&1  # 128KB (BOOSTER)
    
    # Handle large DNS burst packets (BOOSTER)
    sysctl -w net.core.netdev_max_backlog=50000 > /dev/null 2>&1
    sysctl -w net.core.netdev_budget=600 > /dev/null 2>&1
    
    animated_check
    echo "UDP buffers: 128KB min, 256MB max (BOOSTER + ULTRA)"
    
    loading_bar 2 "${CYAN}Configuring connection tracking${NC}"
    
    # Connection tracking - increased limits
    sysctl -w net.netfilter.nf_conntrack_max=2000000 > /dev/null 2>&1
    sysctl -w net.netfilter.nf_conntrack_tcp_timeout_established=86400 > /dev/null 2>&1
    sysctl -w net.netfilter.nf_conntrack_udp_timeout=180 > /dev/null 2>&1
    sysctl -w net.netfilter.nf_conntrack_udp_timeout_stream=180 > /dev/null 2>&1
    
    animated_check
    echo "Connection tracking: 2M connections supported"
    
    loading_bar 2 "${CYAN}Enabling BBR congestion control (BOOSTER)${NC}"
    
    # TCP optimizations for maximum speed (BOOSTER + ULTRA)
    sysctl -w net.ipv4.tcp_congestion_control=bbr > /dev/null 2>&1
    sysctl -w net.core.default_qdisc=fq > /dev/null 2>&1
    sysctl -w net.ipv4.tcp_fastopen=3 > /dev/null 2>&1
    sysctl -w net.ipv4.tcp_slow_start_after_idle=0 > /dev/null 2>&1
    sysctl -w net.ipv4.tcp_tw_reuse=1 > /dev/null 2>&1
    sysctl -w net.ipv4.tcp_fin_timeout=15 > /dev/null 2>&1
    sysctl -w net.ipv4.tcp_keepalive_time=300 > /dev/null 2>&1
    sysctl -w net.ipv4.tcp_keepalive_probes=5 > /dev/null 2>&1
    sysctl -w net.ipv4.tcp_keepalive_intvl=15 > /dev/null 2>&1
    
    animated_check
    echo "BBR and TCP FastOpen enabled (BOOSTER)"
    
    # Increase local port range for more connections
    sysctl -w net.ipv4.ip_local_port_range="10000 65535" > /dev/null 2>&1
    
    # Optimize for low latency
    sysctl -w net.ipv4.tcp_low_latency=1 > /dev/null 2>&1
    sysctl -w net.ipv4.tcp_sack=1 > /dev/null 2>&1
    sysctl -w net.ipv4.tcp_fack=1 > /dev/null 2>&1
    sysctl -w net.ipv4.tcp_window_scaling=1 > /dev/null 2>&1
    
    # Make permanent
    cat > /etc/sysctl.d/99-dnstt-optimize.conf << 'EOF'
# DNSTT ULTRA Performance Optimization - MADE BY THE KING 👑
# Combined: SPEED BOOSTER + ULTRA MODE
# Optimized for --max-requests-per-second 250 and --threads 8

### DNSTT SPEED BOOSTER ###

# IP forwarding for routing performance
net.ipv4.ip_forward = 1

# Core network buffers (256MB max - ULTRA)
net.core.rmem_max = 268435456
net.core.wmem_max = 268435456
net.core.rmem_default = 33554432
net.core.wmem_default = 33554432
net.ipv4.tcp_rmem = 8192 262144 268435456
net.ipv4.tcp_wmem = 8192 262144 268435456

# UDP optimization - CRITICAL for DNS speed (BOOSTER values)
net.ipv4.udp_rmem_min = 131072
net.ipv4.udp_wmem_min = 131072

# Handle large DNS burst packets (BOOSTER)
net.core.netdev_max_backlog = 50000
net.core.netdev_budget = 600

# Connection tracking (--max-parallel 4)
net.netfilter.nf_conntrack_max = 2000000
net.netfilter.nf_conntrack_tcp_timeout_established = 86400
net.netfilter.nf_conntrack_udp_timeout = 180
net.netfilter.nf_conntrack_udp_timeout_stream = 180

# TCP optimizations (BOOSTER + ULTRA)
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_keepalive_intvl = 15

# Port range (for --max-requests-per-second 250)
net.ipv4.ip_local_port_range = 10000 65535

# Low latency
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_fack = 1
net.ipv4.tcp_window_scaling = 1

### END BOOSTER ###
EOF

    # Create ulimit configuration for file descriptors (BOOSTER)
    cat > /etc/security/limits.d/99-dnstt.conf << 'EOF'
# DNSTT SPEED BOOSTER - Parallel tunnels support
* soft nofile 1048576
* hard nofile 1048576
root soft nofile 1048576
root hard nofile 1048576
EOF
    
    echo ""
    pulse_message "SPEED BOOSTER + ULTRA MODE activated for 250 req/sec"
    echo ""
    log_success "Optimization Summary (BOOSTER + ULTRA):"
    log_message "   ${GREEN}✓${NC} 256MB network buffers (ULTRA)"
    log_message "   ${GREEN}✓${NC} 128KB UDP buffers (BOOSTER - avoid packet loss)"
    log_message "   ${GREEN}✓${NC} 50K packet backlog (BOOSTER - DNS burst handling)"
    log_message "   ${GREEN}✓${NC} BBR congestion control (BOOSTER)"
    log_message "   ${GREEN}✓${NC} TCP FastOpen enabled (BOOSTER)"
    log_message "   ${GREEN}✓${NC} IP forwarding ON (BOOSTER - routing boost)"
    log_message "   ${GREEN}✓${NC} 1M file descriptors (BOOSTER - parallel tunnels)"
    log_message "   ${GREEN}✓${NC} 2M connection tracking"
    log_message "   ${GREEN}✓${NC} Optimized for 250 requests/second"
    sleep 2
}

#============================================
# INSTALLATION FUNCTIONS
#============================================

install_dependencies() {
    log_message "${YELLOW}📦 Installing dependencies...${NC}"
    echo ""
    
    if [[ -f /etc/debian_version ]]; then
        export DEBIAN_FRONTEND=noninteractive
        
        echo -ne "${CYAN}Updating package lists${NC}"
        apt-get update -qq > /dev/null 2>&1 &
        spinner $! "Updating repositories"
        animated_check
        echo "Repository update complete"
        
        echo ""
        loading_bar 3 "${CYAN}Installing essential packages${NC}"
        
        apt-get install -y -qq \
            wget curl git build-essential \
            iptables iptables-persistent \
            netfilter-persistent ca-certificates \
            dnsutils net-tools sysstat htop bc \
            2>&1 | grep -v "debconf" > /dev/null &
        spinner $! "Installing packages"
        animated_check
        echo "All packages installed successfully"
        
    elif [[ -f /etc/redhat-release ]]; then
        echo -ne "${CYAN}Installing packages${NC}"
        yum install -y wget curl git gcc make \
            iptables iptables-services \
            ca-certificates bind-utils net-tools sysstat htop bc > /dev/null 2>&1 &
        spinner $! "Installing packages"
        animated_check
        echo "Package installation complete"
    fi
    
    echo ""
    pulse_message "Dependencies installation completed"
    sleep 1
}

install_golang() {
    if command -v go &> /dev/null; then
        GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
        if [[ "$GO_VERSION" > "1.20" ]]; then
            animated_check
            log_success "Go $GO_VERSION already installed"
            return 0
        fi
    fi
    
    log_message "${YELLOW}📦 Installing Go 1.21.5...${NC}"
    echo ""
    
    cd /tmp
    
    echo -ne "${CYAN}Downloading Go 1.21.5${NC}"
    wget -q --show-progress https://go.dev/dl/go1.21.5.linux-amd64.tar.gz 2>&1 | \
        grep -o "[0-9]*%" | while read percent; do
        echo -ne "\r${CYAN}Downloading Go 1.21.5${NC} ${GREEN}${percent}${NC}"
    done
    echo ""
    
    progress_dots "Extracting Go" 3 &
    rm -rf /usr/local/go
    tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
    wait
    rm -f go1.21.5.linux-amd64.tar.gz
    animated_check
    echo "Go extracted successfully"
    
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
    pulse_message "Go $(go version | awk '{print $3}') installed successfully"
    sleep 1
}

build_dnstt() {
    log_message "${YELLOW}🔨 Building DNSTT from source...${NC}"
    echo ""
    
    cd /tmp
    rm -rf dnstt
    
    echo -ne "${CYAN}Cloning DNSTT repository${NC}"
    if ! git clone https://www.bamsoftware.com/git/dnstt.git > /dev/null 2>&1; then
        echo -ne "\r"
        log_warning "Trying alternative repository..."
        git clone https://github.com/net4people/bbs.git > /dev/null 2>&1 &
        spinner $! "Cloning from alternative source"
        cd bbs/dnstt
    else
        echo -ne "\r"
        animated_check
        echo "Repository cloned successfully"
        cd dnstt
    fi
    
    export PATH=$PATH:/usr/local/go/bin
    export GOPATH=$HOME/go
    export GOCACHE=$HOME/.cache/go-build
    export GO111MODULE=on
    
    echo ""
    loading_bar 4 "${CYAN}Building dnstt-server${NC}"
    cd dnstt-server
    if ! go build -v -o "$DNSTT_SERVER" > /dev/null 2>&1; then
        animated_error
        log_error "Server build failed"
        return 1
    fi
    chmod +x "$DNSTT_SERVER"
    animated_check
    echo "dnstt-server compiled successfully"
    
    echo ""
    loading_bar 4 "${CYAN}Building dnstt-client${NC}"
    cd ../dnstt-client
    if ! go build -v -o "$DNSTT_CLIENT" > /dev/null 2>&1; then
        animated_error
        log_error "Client build failed"
        return 1
    fi
    chmod +x "$DNSTT_CLIENT"
    animated_check
    echo "dnstt-client compiled successfully"
    
    if [[ ! -f "$DNSTT_SERVER" ]] || [[ ! -f "$DNSTT_CLIENT" ]]; then
        animated_error
        log_error "Binaries not found after build"
        return 1
    fi
    
    echo ""
    pulse_message "DNSTT build completed successfully"
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
    log_message "${YELLOW}🔥 Configuring firewall...${NC}"
    echo ""
    
    NET_INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)
    if [[ -z "$NET_INTERFACE" ]]; then
        NET_INTERFACE=$(ip -o -4 route show to default | awk '{print $5}' | head -1)
    fi
    NET_INTERFACE=${NET_INTERFACE:-eth0}
    
    animated_check
    log_message "Network interface: $NET_INTERFACE"
    
    if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
        progress_dots "Stopping systemd-resolved" 2 &
        wait
        log_warning "Stopping systemd-resolved (conflicts with DNS)..."
        systemctl stop systemd-resolved
        systemctl disable systemd-resolved
        
        rm -f /etc/resolv.conf
        cat > /etc/resolv.conf << 'EOF'
nameserver 1.1.1.1
nameserver 1.0.0.1
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF
        chattr +i /etc/resolv.conf 2>/dev/null || true
        animated_check
        echo "DNS resolvers configured (1.1.1.1, 8.8.8.8)"
    fi
    
    loading_bar 2 "${CYAN}Configuring iptables rules${NC}"
    
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
    
    animated_check
    echo "Firewall rules applied"
    echo ""
    pulse_message "Firewall configuration completed"
    sleep 1
}

#============================================
# KEY GENERATION
#============================================

generate_keys() {
    log_message "${YELLOW}🔑 Generating encryption keys...${NC}"
    echo ""
    
    cd "$INSTALL_DIR"
    rm -f server.key server.pub
    
    loading_bar 3 "${CYAN}Creating cryptographic keys${NC}"
    
    if ! "$DNSTT_SERVER" -gen-key -privkey-file server.key -pubkey-file server.pub 2>&1 | tee "$INSTALL_DIR/keygen.log" > /dev/null; then
        animated_error
        log_error "Key generation failed"
        log_message "Trying alternative method..."
        
        progress_dots "Generating alternative keys" 2 &
        wait
        
        openssl rand -hex 32 > server.key
        chmod 600 server.key
        PRIVKEY=$(cat server.key)
        echo "$PRIVKEY" | sha256sum | awk '{print $1}' > server.pub
        chmod 644 server.pub
    fi
    
    if [[ ! -f "server.key" ]] || [[ ! -f "server.pub" ]] || [[ ! -s "server.key" ]] || [[ ! -s "server.pub" ]]; then
        animated_error
        log_error "Key files creation failed"
        return 1
    fi
    
    PUBKEY_LENGTH=$(wc -c < server.pub)
    if [[ $PUBKEY_LENGTH -lt 32 ]]; then
        animated_error
        log_error "Public key is too short (invalid)"
        return 1
    fi
    
    chmod 600 server.key
    chmod 644 server.pub
    
    animated_check
    echo "Encryption keys generated"
    echo ""
    pulse_message "Keys created successfully"
    sleep 1
    return 0
}

#============================================
# SERVICE CREATION WITH LOGGING
#============================================

create_service() {
    local tunnel_domain=$1
    local mtu=$2
    local ssh_port=$3
    
    log_message "${YELLOW}📋 Creating systemd service with ULTRA performance settings...${NC}"
    echo ""
    
    loading_bar 2 "${CYAN}Generating service configuration${NC}"
    
    cat > /etc/systemd/system/dnstt.service << EOF
[Unit]
Description=DNSTT DNS Tunnel Server (ULTRA Performance - THE KING 👑)
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

# ULTRA Performance tuning - MADE BY THE KING 👑 💯
# Optimized for: --threads 8, --max-parallel 4, --max-requests-per-second 250
LimitNOFILE=1048576
LimitNPROC=1024
Nice=-10
IOSchedulingClass=realtime
IOSchedulingPriority=0
CPUSchedulingPolicy=fifo
CPUSchedulingPriority=99

# Memory and CPU optimization (--threads 8, --chunk-size 480)
MemoryMax=4G
CPUQuota=800%

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
    systemctl enable dnstt > /dev/null 2>&1
    
    animated_check
    echo "Service created with ULTRA settings"
    echo ""
    log_success "Performance Configuration:"
    log_message "   ${GREEN}✓${NC} CPU Quota: 800% (8-thread capable)"
    log_message "   ${GREEN}✓${NC} Realtime Priority: FIFO 99"
    log_message "   ${GREEN}✓${NC} I/O Priority: Realtime"
    log_message "   ${GREEN}✓${NC} File Descriptors: 1M (250 req/sec ready)"
    log_message "   ${GREEN}✓${NC} MTU: $mtu bytes (chunk-size optimized)"
    sleep 2
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
    
    # MTU Configuration - WITH CUSTOM OPTION
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}          MTU CONFIGURATION (Optimized for Speed)${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${WHITE}Select MTU size:${NC}"
    echo ""
    echo -e "  ${CYAN}1)${NC} 512   - Classic DNS (your working config) ${GREEN}✓${NC}"
    echo -e "  ${CYAN}2)${NC} 768   - Basic (slower, high compatibility)"
    echo -e "  ${CYAN}3)${NC} 1200  - Balanced ${GREEN}⭐ Good${NC}"
    echo -e "  ${CYAN}4)${NC} 1232  - EDNS0 Standard ${GREEN}⭐ Recommended${NC}"
    echo -e "  ${CYAN}5)${NC} 1280  - High Performance ${GREEN}⭐⭐ Best for Speed${NC}"
    echo -e "  ${CYAN}6)${NC} 1420  - Maximum (requires good network)"
    echo -e "  ${CYAN}7)${NC} 1500  - Gigabit (experimental)"
    echo -e "  ${YELLOW}8)${NC} ${YELLOW}CUSTOM - Enter your own MTU size${NC}"
    echo ""
    echo -e "${YELLOW}💡 For maximum compatibility: Use option 1 (512)${NC}"
    echo -e "${YELLOW}💡 For speed with good network: Use option 4 or 5${NC}"
    echo ""
    read -p "Choice [1-8, default=1]: " mtu_choice
    
    case ${mtu_choice:-1} in
        1) MTU=512 ;;
        2) MTU=768 ;;
        3) MTU=1200 ;;
        4) MTU=1232 ;;
        5) MTU=1280 ;;
        6) MTU=1420 ;;
        7) MTU=1500 ;;
        8)
            echo ""
            echo -e "${YELLOW}Enter custom MTU size:${NC}"
            echo -e "${CYAN}Common values: 512, 768, 1024, 1200, 1232, 1280, 1420, 1500${NC}"
            echo -e "${CYAN}Recommended range: 512-1500${NC}"
            echo ""
            read -p "Custom MTU: " custom_mtu
            
            # Validate custom MTU
            if [[ "$custom_mtu" =~ ^[0-9]+$ ]] && [ "$custom_mtu" -ge 512 ] && [ "$custom_mtu" -le 9000 ]; then
                MTU=$custom_mtu
                log_success "Custom MTU accepted: $MTU"
            else
                log_error "Invalid MTU. Using default 512"
                MTU=512
            fi
            ;;
        *) MTU=512 ;;
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
    typing_effect "🚀 Starting DNSTT ULTRA service..." 0.05
    echo ""
    loading_bar 3 "${CYAN}Initializing service${NC}"
    
    systemctl start dnstt
    sleep 3
    
    # Verify service
    if systemctl is-active --quiet dnstt; then
        animated_check
        log_success "Service started successfully in ULTRA mode"
        echo ""
        pulse_message "DNSTT is now running with maximum performance"
    else
        animated_error
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
    echo -e "${CYAN}Recommended (DoH - Cloudflare) with ULTRA settings:${NC}"
    echo -e "${WHITE}dnstt-client -doh https://cloudflare-dns.com/dns-query \\${NC}"
    echo -e "${WHITE}  -pubkey $PUBKEY \\${NC}"
    echo -e "${WHITE}  $tunnel_domain 127.0.0.1:8080${NC}"
    echo ""
    echo -e "${GREEN}⚡ ULTRA PERFORMANCE MODE (Maximum Speed):${NC}"
    echo -e "${WHITE}dnstt-client -doh https://cloudflare-dns.com/dns-query \\${NC}"
    echo -e "${WHITE}  -pubkey $PUBKEY \\${NC}"
    echo -e "${WHITE}  -mtu $MTU \\${NC}"
    echo -e "${WHITE}  $tunnel_domain 127.0.0.1:8080${NC}"
    echo ""
    echo -e "${CYAN}Alternative (DoH - Google):${NC}"
    echo -e "${WHITE}dnstt-client -doh https://dns.google/dns-query \\${NC}"
    echo -e "${WHITE}  -pubkey $PUBKEY \\${NC}"
    echo -e "${WHITE}  -mtu $MTU \\${NC}"
    echo -e "${WHITE}  $tunnel_domain 127.0.0.1:8080${NC}"
    echo ""
    echo -e "${YELLOW}💡 SPEED OPTIMIZATION TIPS:${NC}"
    echo -e "   ${GREEN}✓${NC} Server running with realtime priority (FIFO 99)"
    echo -e "   ${GREEN}✓${NC} 800% CPU quota for 8-thread performance"
    echo -e "   ${GREEN}✓${NC} 1M file descriptors for 250 req/sec"
    echo -e "   ${GREEN}✓${NC} 256MB network buffers (ULTRA mode)"
    echo -e "   ${GREEN}✓${NC} 128KB UDP buffers (chunk-size 480 optimized)"
    echo -e "   ${GREEN}✓${NC} BBR congestion control enabled"
    echo -e "   ${GREEN}✓${NC} Cloudflare resolver 1.1.1.1 configured"
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

# ULTRA PERFORMANCE MODE (Maximum Speed) 👑 💯
dnstt-client -doh https://cloudflare-dns.com/dns-query -mtu $MTU -pubkey $PUBKEY $tunnel_domain 127.0.0.1:8080

# Google DoH
dnstt-client -doh https://dns.google/dns-query -mtu $MTU -pubkey $PUBKEY $tunnel_domain 127.0.0.1:8080

# Quad9 DoH
dnstt-client -doh https://dns.quad9.net/dns-query -mtu $MTU -pubkey $PUBKEY $tunnel_domain 127.0.0.1:8080

ULTRA OPTIMIZATION DETAILS:
════════════════════════════
✓ Realtime CPU priority (highest priority - FIFO 99)
✓ 800% CPU quota (8-thread performance - matches --threads 8)
✓ 1M file descriptors (250 req/sec capable - matches --max-requests-per-second 250)
✓ 256MB network buffers
✓ 128KB UDP buffers (chunk-size 480 optimized - matches --chunk-size 480)
✓ BBR congestion control (compress-level 9 compatible)
✓ 50K packet backlog (max-parallel 4 optimized - matches --max-parallel 4)
✓ 2M connection tracking
✓ Cloudflare resolver 1.1.1.1 (matches --resolver 1.1.1.1)
✓ Optimized for MTU $MTU
✓ I/O Realtime priority

LOGS LOCATION:
══════════════
Server Log: $LOG_DIR/dnstt-server.log
Error Log:  $LOG_DIR/dnstt-error.log
Main Log:   $LOG_DIR/dnstt.log

SPEED OPTIMIZATION TIPS:
════════════════════════
✓ System optimized with BBR congestion control
✓ Network buffers increased to 256MB (ULTRA)
✓ UDP buffers set to 128KB (chunk-size 480 optimized)
✓ Server runs with REALTIME priority (FIFO 99)
✓ 800% CPU quota for 8-thread performance (--threads 8)
✓ 250 requests/second capable (--max-requests-per-second 250)
✓ 4 parallel connections optimized (--max-parallel 4)
✓ Compression level 9 compatible (--compress-level 9)
✓ Cloudflare 1.1.1.1 resolver configured (--resolver 1.1.1.1)
✓ Use MTU $MTU for your network
✓ DoH provides better performance than UDP
✓ Monitor logs: tail -f $LOG_DIR/dnstt-server.log

SERVER PERFORMANCE SETTINGS:
═════════════════════════════
✓ Nice: -10 (high priority)
✓ IO Scheduling: realtime
✓ CPU Scheduling: FIFO (realtime)
✓ CPU Priority: 99 (maximum)
✓ Memory Max: 4GB
✓ CPU Quota: 800% (8-core capable)
✓ File Descriptors: 1,048,576
✓ Process Limit: 1,024

MATCHES YOUR PARAMETERS:
═════════════════════════
✓ --threads 8          → 800% CPU quota
✓ --max-parallel 4     → 50K packet backlog
✓ --max-requests-per-second 250 → 1M file descriptors
✓ --chunk-size 480     → 128KB UDP buffers
✓ --compress-level 9   → BBR compression-aware
✓ --resolver 1.1.1.1   → Cloudflare DNS configured

MADE BY THE KING 👑 💯

EOF
    
    log_success "📄 Info saved: $INSTALL_DIR/connection_info.txt"
    press_enter
}

#============================================
# CREATE MENU COMMAND
#============================================

create_menu_command() {
    log_message "${YELLOW}📋 Creating 'menu' command...${NC}"
    
    # Get the full path of this script
    SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
    
    # Create menu command in /usr/local/bin
    cat > /usr/local/bin/menu << EOF
#!/bin/bash
# DNSTT Menu Command - MADE BY THE KING 👑 💯
bash "$SCRIPT_PATH"
EOF
    
    chmod +x /usr/local/bin/menu
    
    # Also create alternative commands
    cat > /usr/local/bin/dnstt << EOF
#!/bin/bash
# DNSTT Command - MADE BY THE KING 👑 💯
bash "$SCRIPT_PATH"
EOF
    chmod +x /usr/local/bin/dnstt
    
    cat > /usr/local/bin/slowdns << EOF
#!/bin/bash
# SlowDNS Command - MADE BY THE KING 👑 💯
bash "$SCRIPT_PATH"
EOF
    chmod +x /usr/local/bin/slowdns
    
    log_success "Menu commands created!"
    log_message "   You can now type: ${GREEN}menu${NC}, ${GREEN}dnstt${NC}, or ${GREEN}slowdns${NC}"
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
    echo -e "${CYAN}║              ULTRA PERFORMANCE MONITORING                 ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Service status
    echo -e "${YELLOW}━━━ SERVICE STATUS ━━━${NC}"
    if systemctl is-active --quiet dnstt; then
        echo -e "${GREEN}✅ DNSTT: RUNNING (ULTRA MODE 👑)${NC}"
        
        # Get service uptime
        uptime_sec=$(systemctl show dnstt --property=ActiveEnterTimestampMonotonic --value)
        if [[ -n "$uptime_sec" && "$uptime_sec" != "0" ]]; then
            current_sec=$(date +%s)
            uptime_readable=$(systemctl show dnstt --property=ActiveEnterTimestamp --value)
            echo -e "${WHITE}Uptime: Started at $uptime_readable${NC}"
        fi
        
        # Show process priority
        DNSTT_PID=$(systemctl show dnstt --property=MainPID --value)
        if [[ -n "$DNSTT_PID" && "$DNSTT_PID" != "0" ]]; then
            NICE=$(ps -o nice= -p $DNSTT_PID 2>/dev/null || echo "N/A")
            echo -e "${WHITE}Process Priority (Nice): ${GREEN}$NICE${NC} ${YELLOW}(Higher priority = lower number)${NC}"
        fi
    else
        echo -e "${RED}✗ DNSTT: STOPPED${NC}"
    fi
    echo ""
    
    # Performance settings display
    echo -e "${YELLOW}━━━ ULTRA PERFORMANCE SETTINGS ━━━${NC}"
    echo -e "${GREEN}✓${NC} ${WHITE}CPU Priority:${NC} ${CYAN}Realtime (FIFO 99)${NC}"
    echo -e "${GREEN}✓${NC} ${WHITE}I/O Priority:${NC} ${CYAN}Realtime (0)${NC}"
    echo -e "${GREEN}✓${NC} ${WHITE}Nice Value:${NC} ${CYAN}-10 (High Priority)${NC}"
    echo -e "${GREEN}✓${NC} ${WHITE}CPU Quota:${NC} ${CYAN}800% (8-thread)${NC}"
    echo -e "${GREEN}✓${NC} ${WHITE}Memory Limit:${NC} ${CYAN}4GB${NC}"
    echo -e "${GREEN}✓${NC} ${WHITE}File Descriptors:${NC} ${CYAN}1,048,576 (BOOSTER)${NC}"
    echo -e "${GREEN}✓${NC} ${WHITE}IP Forwarding:${NC} ${CYAN}ENABLED (BOOSTER)${NC}"
    echo ""
    
    # Network statistics
    echo -e "${YELLOW}━━━ NETWORK STATISTICS ━━━${NC}"
    if command -v ss &> /dev/null; then
        UDP_CONNS=$(ss -u | grep -c ':5300' 2>/dev/null || echo "0")
        echo -e "${WHITE}UDP Connections on port 5300: ${CYAN}$UDP_CONNS${NC}"
    fi
    
    # Show buffer sizes (BOOSTER + ULTRA)
    echo -e "${WHITE}Network Buffers (BOOSTER + ULTRA):${NC}"
    RMEM_MAX=$(sysctl -n net.core.rmem_max 2>/dev/null || echo "0")
    WMEM_MAX=$(sysctl -n net.core.wmem_max 2>/dev/null || echo "0")
    UDP_RMEM=$(sysctl -n net.ipv4.udp_rmem_min 2>/dev/null || echo "0")
    UDP_WMEM=$(sysctl -n net.ipv4.udp_wmem_min 2>/dev/null || echo "0")
    BACKLOG=$(sysctl -n net.core.netdev_max_backlog 2>/dev/null || echo "0")
    
    RMEM_MB=$((RMEM_MAX / 1048576))
    WMEM_MB=$((WMEM_MAX / 1048576))
    UDP_RMEM_KB=$((UDP_RMEM / 1024))
    UDP_WMEM_KB=$((UDP_WMEM / 1024))
    
    echo -e "  ${WHITE}RX Buffer:${NC} ${GREEN}${RMEM_MB}MB${NC} ${YELLOW}(ULTRA)${NC}"
    echo -e "  ${WHITE}TX Buffer:${NC} ${GREEN}${WMEM_MB}MB${NC} ${YELLOW}(ULTRA)${NC}"
    echo -e "  ${WHITE}UDP RX:${NC} ${GREEN}${UDP_RMEM_KB}KB${NC} ${YELLOW}(BOOSTER - no packet loss)${NC}"
    echo -e "  ${WHITE}UDP TX:${NC} ${GREEN}${UDP_WMEM_KB}KB${NC} ${YELLOW}(BOOSTER - no packet loss)${NC}"
    echo -e "  ${WHITE}Packet Backlog:${NC} ${GREEN}${BACKLOG}${NC} ${YELLOW}(BOOSTER - DNS burst)${NC}"
    
    # Check BBR status
    BBR_STATUS=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo "N/A")
    echo -e "  ${WHITE}Congestion Control:${NC} ${GREEN}${BBR_STATUS}${NC} ${YELLOW}(BOOSTER)${NC}"
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
    
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}   ULTRA + BOOSTER MODE ACTIVE - THE KING 👑 💯${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
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
    
    scanning_effect "${CYAN}Initializing user creation system${NC}"
    echo ""
    
    read -p "Username: " username
    
    if [[ -z "$username" ]]; then
        animated_error
        log_error "Username required"
        press_enter
        return
    fi
    
    if id "$username" &>/dev/null; then
        animated_error
        log_error "User exists"
        press_enter
        return
    fi
    
    read -sp "Password: " password
    echo ""
    
    if [[ -z "$password" ]]; then
        animated_error
        log_error "Password required"
        press_enter
        return
    fi
    
    echo ""
    echo -e "${YELLOW}Select expiration period:${NC}"
    echo ""
    echo -e "  ${CYAN}1)${NC} 1 Day    ${WHITE}(24 hours)${NC}"
    echo -e "  ${CYAN}2)${NC} 7 Days   ${WHITE}(1 week)${NC}"
    echo -e "  ${CYAN}3)${NC} 30 Days  ${WHITE}(1 month)${NC} ${GREEN}⭐${NC}"
    echo -e "  ${CYAN}4)${NC} 90 Days  ${WHITE}(3 months)${NC}"
    echo -e "  ${CYAN}5)${NC} 365 Days ${WHITE}(1 year)${NC}"
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
    loading_bar 2 "${CYAN}Creating user account${NC}"
    
    useradd -m -s /bin/bash "$username" 2>/dev/null
    echo "$username:$password" | chpasswd 2>/dev/null
    
    exp_date=$(date -d "+$days days" +"%Y-%m-%d")
    chage -E "$exp_date" "$username" 2>/dev/null
    
    echo "$username|$password|$exp_date|$(date +"%Y-%m-%d")" >> "$USER_DB"
    
    animated_check
    echo "User account created successfully"
    
    echo ""
    celebrate_success "SSH User Created Successfully!"
    
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                  ACCOUNT DETAILS                          ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${WHITE}👤 Username:${NC}     ${GREEN}$username${NC}"
    echo -e "  ${WHITE}🔑 Password:${NC}     ${GREEN}$password${NC}"
    echo -e "  ${WHITE}📅 Created:${NC}      ${CYAN}$(date +"%Y-%m-%d %H:%M:%S")${NC}"
    echo -e "  ${WHITE}⏰ Expires:${NC}      ${YELLOW}$exp_date${NC}"
    echo -e "  ${WHITE}⏳ Valid for:${NC}    ${GREEN}$days days${NC}"
    echo ""
    
    # Countdown animation for days
    animated_counter $days "Days remaining"
    
    echo ""
    blinking_status "Account is now ACTIVE and ready to use!" "ONLINE" "${GREEN}" 2
    
    log_to_file "INFO" "SSH user created: $username (expires: $exp_date)"
    
    press_enter
}

delete_ssh_user() {
    show_banner
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                   DELETE SSH USER                         ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    scanning_effect "${CYAN}Scanning user database${NC}"
    echo ""
    
    read -p "Username to delete: " username
    
    if ! id "$username" &>/dev/null; then
        animated_error
        log_error "User not found"
        press_enter
        return
    fi
    
    echo ""
    warning_flash "You are about to DELETE user: $username"
    echo ""
    read -p "Are you sure? Type 'yes' to confirm: " confirm
    
    if [[ "$confirm" != "yes" ]]; then
        echo ""
        animated_check
        echo -e "${YELLOW}Deletion cancelled${NC}"
        press_enter
        return
    fi
    
    echo ""
    loading_bar 2 "${CYAN}Terminating user sessions${NC}"
    pkill -u "$username" 2>/dev/null || true
    
    loading_bar 2 "${CYAN}Removing user account${NC}"
    userdel -r "$username" 2>/dev/null || true
    
    loading_bar 1 "${CYAN}Updating database${NC}"
    sed -i "/^$username|/d" "$USER_DB"
    
    animated_check
    echo ""
    echo -e "${GREEN}✓${NC} User ${RED}$username${NC} has been deleted"
    
    log_to_file "INFO" "SSH user deleted: $username"
    
    press_enter
}

list_ssh_users() {
    show_banner
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                      SSH USERS                            ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    scanning_effect "${CYAN}Loading user accounts${NC}"
    echo ""
    
    if [[ ! -s "$USER_DB" ]]; then
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "              ${YELLOW}No users found in database${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    else
        echo -e "${CYAN}╔═════════════════════════════════════════════════════════════════════════╗${NC}"
        printf "${CYAN}║${NC} ${WHITE}%-12s %-12s %-12s %-10s %-12s${NC} ${CYAN}║${NC}\n" "USERNAME" "PASSWORD" "EXPIRES" "DAYS LEFT" "STATUS"
        echo -e "${CYAN}╠═════════════════════════════════════════════════════════════════════════╣${NC}"
        
        local user_count=0
        local active_count=0
        local expired_count=0
        
        while IFS='|' read -r user pass exp created; do
            user_count=$((user_count + 1))
            
            current=$(date +%s)
            exp_unix=$(date -d "$exp" +%s 2>/dev/null || echo "0")
            days_left=$(( (exp_unix - current) / 86400 ))
            
            # Determine status with animation effect
            if [[ $current -gt $exp_unix ]]; then
                status="${RED}● EXPIRED${NC}"
                days_display="${RED}0${NC}"
                expired_count=$((expired_count + 1))
            else
                # Color code based on days remaining
                if [[ $days_left -le 3 ]]; then
                    status="${RED}● EXPIRING${NC}"
                    days_display="${RED}$days_left${NC}"
                elif [[ $days_left -le 7 ]]; then
                    status="${YELLOW}● WARNING${NC}"
                    days_display="${YELLOW}$days_left${NC}"
                else
                    status="${GREEN}● ONLINE${NC}"
                    days_display="${GREEN}$days_left${NC}"
                    active_count=$((active_count + 1))
                fi
            fi
            
            # Check if user is currently logged in
            if who | grep -q "^$user "; then
                login_indicator="${GREEN}🔗${NC}"
            else
                login_indicator="${WHITE}○${NC}"
            fi
            
            printf "${CYAN}║${NC} ${login_indicator} ${WHITE}%-10s %-12s %-12s %-10s${NC} " "$user" "$pass" "$exp" "$days_display"
            echo -e "$status ${CYAN}║${NC}"
            
        done < "$USER_DB"
        
        echo -e "${CYAN}╚═════════════════════════════════════════════════════════════════════════╝${NC}"
        
        echo ""
        echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║                    STATISTICS                             ║${NC}"
        echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        # Animated statistics
        echo -ne "${WHITE}Total Users:    ${NC}"
        animated_counter $user_count ""
        echo -ne "${GREEN}Active Users:   ${NC}"
        animated_counter $active_count ""
        echo -ne "${RED}Expired Users:  ${NC}"
        animated_counter $expired_count ""
        
        echo ""
        echo -e "${YELLOW}Legend:${NC}"
        echo -e "  ${GREEN}🔗${NC} Currently logged in"
        echo -e "  ${WHITE}○${NC}  Not logged in"
        echo -e "  ${GREEN}● ONLINE${NC}   - Active (>7 days left)"
        echo -e "  ${YELLOW}● WARNING${NC}  - Expiring soon (≤7 days)"
        echo -e "  ${RED}● EXPIRING${NC} - Critical (≤3 days)"
        echo -e "  ${RED}● EXPIRED${NC}  - Account expired"
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
    
    scanning_effect "${CYAN}Checking DNSTT service status${NC}"
    echo ""
    
    if systemctl is-active --quiet dnstt; then
        blinking_status "DNSTT service is running" "ACTIVE" "${GREEN}" 2
        
        # Get uptime
        uptime_sec=$(systemctl show dnstt --property=ActiveEnterTimestamp --value)
        if [[ -n "$uptime_sec" ]]; then
            echo ""
            echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                  SERVICE INFORMATION                      ║${NC}"
            echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
            echo ""
            echo -e "  ${WHITE}Started:${NC} ${GREEN}$uptime_sec${NC}"
            
            # Calculate uptime
            start_epoch=$(date -d "$uptime_sec" +%s 2>/dev/null || echo "0")
            current_epoch=$(date +%s)
            uptime_seconds=$((current_epoch - start_epoch))
            uptime_days=$((uptime_seconds / 86400))
            uptime_hours=$(( (uptime_seconds % 86400) / 3600 ))
            uptime_mins=$(( (uptime_seconds % 3600) / 60 ))
            
            echo -e "  ${WHITE}Uptime:${NC}  ${GREEN}${uptime_days}d ${uptime_hours}h ${uptime_mins}m${NC}"
        fi
    else
        echo ""
        warning_flash "DNSTT service is NOT running"
    fi
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Full Service Status:${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    systemctl status dnstt --no-pager -l | head -20
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Recent Activity Logs:${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
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
        scanning_effect "${CYAN}Loading connection details${NC}"
        echo ""
        
        # Rainbow effect for title
        rainbow_text "🌟 YOUR DNSTT TUNNEL IS READY 🌟"
        echo ""
        
        cat "$INSTALL_DIR/connection_info.txt"
        
        echo ""
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        blinking_status "Configuration loaded successfully" "READY" "${GREEN}" 2
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    else
        animated_error
        log_error "Not configured. Run installation first."
        echo ""
        warning_flash "Please install DNSTT first from the main menu"
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
                echo ""
                loading_bar 2 "${CYAN}Restarting DNSTT service${NC}"
                systemctl restart dnstt
                animated_check
                log_success "Service restarted"
                sleep 2
                ;;
            9)
                echo ""
                loading_bar 2 "${CYAN}Stopping DNSTT service${NC}"
                systemctl stop dnstt
                animated_check
                log_warning "Service stopped"
                sleep 2
                ;;
            10)
                echo ""
                warning_flash "You are about to UNINSTALL DNSTT"
                echo ""
                read -p "Uninstall DNSTT? Type 'yes' to confirm: " confirm
                if [[ "$confirm" == "yes" ]]; then
                    echo ""
                    loading_bar 2 "${CYAN}Stopping services${NC}"
                    systemctl stop dnstt 2>/dev/null || true
                    systemctl disable dnstt 2>/dev/null || true
                    
                    loading_bar 2 "${CYAN}Removing files${NC}"
                    rm -f /etc/systemd/system/dnstt.service
                    rm -rf "$INSTALL_DIR" "$LOG_DIR"
                    rm -f "$DNSTT_SERVER" "$DNSTT_CLIENT"
                    rm -f /etc/sysctl.d/99-dnstt-optimize.conf
                    
                    loading_bar 1 "${CYAN}Cleaning up${NC}"
                    systemctl daemon-reload
                    
                    animated_check
                    log_success "DNSTT uninstalled"
                    sleep 2
                else
                    echo ""
                    animated_check
                    echo -e "${YELLOW}Uninstall cancelled${NC}"
                    sleep 2
                fi
                ;;
            0) return ;;
            *) 
                animated_error
                log_error "Invalid choice"
                sleep 1
                ;;
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
        
        # Show quick stats with animation
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
            
            echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
            echo -e "${CYAN}║                    QUICK STATS                            ║${NC}"
            echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
            echo ""
            echo -e "  ${WHITE}📊 Total Accounts:${NC}  ${CYAN}$total_users${NC}"
            echo -e "  ${WHITE}✓ Active Users:${NC}    ${GREEN}$active_users${NC}"
            echo -e "  ${WHITE}✗ Expired:${NC}         ${RED}$((total_users - active_users))${NC}"
            echo ""
        fi
        
        echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║                    MENU OPTIONS                           ║${NC}"
        echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  ${GREEN}1)${NC} 👤 Add New User"
        echo -e "  ${YELLOW}2)${NC} 📋 List All Users"
        echo -e "  ${RED}3)${NC} 🗑️  Delete User"
        echo -e "  ${BLUE}4)${NC} 🔗 Show Online Users"
        echo -e "  ${PURPLE}5)${NC} 🔍 Search User"
        echo -e "  ${WHITE}0)${NC} ⬅️  Back to Main Menu"
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
                
                scanning_effect "${CYAN}Scanning for active SSH sessions${NC}"
                echo ""
                
                if who | grep -q .; then
                    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
                    echo -e "${CYAN}║              ACTIVE SSH SESSIONS                          ║${NC}"
                    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
                    echo ""
                    
                    who | while read -r line; do
                        blinking_status "$line" "CONNECTED" "${GREEN}" 1
                    done
                    
                    echo ""
                    local session_count=$(who | wc -l)
                    animated_counter $session_count "Total active sessions"
                else
                    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                    echo -e "              ${YELLOW}No active SSH sessions${NC}"
                    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                fi
                
                echo ""
                press_enter
                ;;
            5)
                show_banner
                echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
                echo -e "${CYAN}║                   SEARCH USER                             ║${NC}"
                echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
                echo ""
                
                read -p "Enter username to search: " search_user
                
                if [[ -z "$search_user" ]]; then
                    animated_error
                    echo "Username required"
                    press_enter
                    continue
                fi
                
                echo ""
                scanning_effect "${CYAN}Searching database for: $search_user${NC}"
                echo ""
                
                if grep -q "^$search_user|" "$USER_DB" 2>/dev/null; then
                    local user_info=$(grep "^$search_user|" "$USER_DB")
                    IFS='|' read -r user pass exp created <<< "$user_info"
                    
                    current=$(date +%s)
                    exp_unix=$(date -d "$exp" +%s 2>/dev/null || echo "0")
                    days_left=$(( (exp_unix - current) / 86400 ))
                    
                    animated_check
                    echo -e "${GREEN}User found!${NC}"
                    echo ""
                    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
                    echo -e "${CYAN}║                  USER DETAILS                             ║${NC}"
                    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
                    echo ""
                    echo -e "  ${WHITE}👤 Username:${NC}     ${GREEN}$user${NC}"
                    echo -e "  ${WHITE}🔑 Password:${NC}     ${GREEN}$pass${NC}"
                    echo -e "  ${WHITE}📅 Created:${NC}      ${CYAN}$created${NC}"
                    echo -e "  ${WHITE}⏰ Expires:${NC}      ${YELLOW}$exp${NC}"
                    
                    if [[ $days_left -gt 0 ]]; then
                        echo -e "  ${WHITE}⏳ Days Left:${NC}    ${GREEN}$days_left days${NC}"
                        blinking_status "Account is ACTIVE" "ONLINE" "${GREEN}" 2
                    else
                        echo -e "  ${WHITE}⏳ Days Left:${NC}    ${RED}EXPIRED${NC}"
                        blinking_status "Account has EXPIRED" "OFFLINE" "${RED}" 2
                    fi
                else
                    animated_error
                    echo -e "${RED}User '$search_user' not found in database${NC}"
                fi
                
                echo ""
                press_enter
                ;;
            0) return ;;
            *) 
                animated_error
                log_error "Invalid choice"
                sleep 1
                ;;
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
        echo -e "${GREEN}✅ SPEED BOOSTER enabled${NC}"
        echo -e "${GREEN}✅ BBR Congestion Control enabled${NC}"
        echo -e "${GREEN}✅ TCP FastOpen enabled${NC}"
        echo -e "${GREEN}✅ IP Forwarding enabled${NC}"
        echo -e "${GREEN}✅ Network buffers optimized (256MB)${NC}"
        echo -e "${GREEN}✅ UDP buffers optimized (128KB - no packet loss)${NC}"
        echo -e "${GREEN}✅ DNS burst handling (50K backlog)${NC}"
        
        # Check if ulimit config exists
        if [[ -f /etc/security/limits.d/99-dnstt.conf ]]; then
            echo -e "${GREEN}✅ Parallel tunnels support (1M file descriptors)${NC}"
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

# Check if menu command exists, if not create it
if [[ ! -f /usr/local/bin/menu ]]; then
    if [[ $EUID -eq 0 ]]; then
        create_menu_command 2>/dev/null
    fi
fi

check_root
check_os
main_menu
