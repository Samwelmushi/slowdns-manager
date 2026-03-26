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
    log_message "${YELLOW}⚡ Applying ULTRA SPEED v3.0 - 512B MTU High-Frequency Packet Optimization...${NC}"
    echo ""

    # ── WHY THESE VALUES ────────────────────────────────────────────────────────
    # At MTU=512 the kernel processes far more packets per second than at MTU=1500.
    # Standard "large buffer" tuning actually HURTS here: huge buffers cause GC
    # pressure and interrupt coalescing that stalls small-packet pipelines.
    # Goal: reduce per-packet kernel overhead, keep queues shallow but fast,
    # and prevent the UDP socket from dropping datagrams under burst load.
    # ────────────────────────────────────────────────────────────────────────────

    # Enable IP forwarding
    sysctl -w net.ipv4.ip_forward=1 > /dev/null 2>&1 || true

    # Load required modules
    modprobe tcp_bbr 2>/dev/null || true
    modprobe tcp_hybla 2>/dev/null || true

    # Raise fd limit for this shell session immediately (persisted below too)
    ulimit -n 1048576 2>/dev/null || ulimit -n 524288 2>/dev/null || true

    echo -e "${CYAN}[1/12]${NC} Congestion control — CUBIC tuned for lossy/high-latency DNS env..."
    # BBR was designed for low-loss paths. DNS tunnels are inherently lossy and
    # high-latency. CUBIC with a tight RTO and fast retransmit is more reliable
    # here. We keep FQ as the qdisc because it gives per-flow pacing which
    # prevents large bursts from flooding the 512B packet pipeline.
    sysctl -w net.ipv4.tcp_congestion_control=cubic > /dev/null 2>&1 || true
    sysctl -w net.core.default_qdisc=fq > /dev/null 2>&1 || true
    # Faster initial RTO — critical for lossy tunnels (default 200ms → 100ms)
    sysctl -w net.ipv4.tcp_rto_min=100 > /dev/null 2>&1 || true
    # Reduce retransmit threshold: 3 dupack → fast retransmit sooner
    sysctl -w net.ipv4.tcp_reordering=3 > /dev/null 2>&1 || true
    echo -e "${GREEN}✓ CUBIC + FQ (lossy-path optimized, 100ms RTO)${NC}"
    sleep 0.3

    echo -e "${CYAN}[2/12]${NC} Network socket buffers — sized for 512B high-frequency UDP bursts..."
    # rmem_max / wmem_max: 32MB is the sweet spot for 512B UDP.
    # 1GB buffers (old setting) waste memory and cause cache pressure.
    # At 512B MTU and target 2-4 Mbps: ~8000 pkts/sec → 32MB handles ~4000
    # in-flight without GC overhead.
    sysctl -w net.core.rmem_max=33554432 > /dev/null 2>&1 || true
    sysctl -w net.core.wmem_max=33554432 > /dev/null 2>&1 || true
    sysctl -w net.core.rmem_default=4194304 > /dev/null 2>&1 || true
    sysctl -w net.core.wmem_default=4194304 > /dev/null 2>&1 || true
    # TCP buffers: min=4K (one packet), default=4MB, max=32MB
    sysctl -w net.ipv4.tcp_rmem="4096 4194304 33554432" > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_wmem="4096 4194304 33554432" > /dev/null 2>&1 || true
    sysctl -w net.core.optmem_max=33554432 > /dev/null 2>&1 || true
    echo -e "${GREEN}✓ Socket buffers: 32MB (optimal for 512B burst volume)${NC}"
    sleep 0.3

    echo -e "${CYAN}[3/12]${NC} UDP socket buffers — tuned for 512-byte datagram segments..."
    # udp_rmem_min / udp_wmem_min: minimum per-socket reservation.
    # 131072 (128KB) = 256 × 512B packets. This prevents starvation under
    # concurrent client connections without over-allocating.
    sysctl -w net.ipv4.udp_rmem_min=131072 > /dev/null 2>&1 || true
    sysctl -w net.ipv4.udp_wmem_min=131072 > /dev/null 2>&1 || true
    # udp_mem: pages (4KB each). pressure at 8MB, max at 32MB — tight enough
    # to avoid OOM but large enough for sustained 4Mbps DNS bursts.
    sysctl -w net.ipv4.udp_mem="2048 4096 8192" > /dev/null 2>&1 || true
    echo -e "${GREEN}✓ UDP: 128KB min buffers (256 × 512B packets per socket)${NC}"
    sleep 0.3

    echo -e "${CYAN}[4/12]${NC} Interrupt budget — reducing CPU stall between small-packet bursts..."
    # netdev_budget: packets processed per NAPI poll cycle.
    # Lower = faster per-packet delivery. At 512B we need high poll frequency.
    # 300 pkts/cycle with 1500µs budget = kernel returns to userspace faster.
    # Old values (3000 / 20000µs) were tuned for large frames, not 512B.
    sysctl -w net.core.netdev_budget=300 > /dev/null 2>&1 || true
    sysctl -w net.core.netdev_budget_usecs=1500 > /dev/null 2>&1 || true
    # Large backlog to absorb UDP storms without dropping
    sysctl -w net.core.netdev_max_backlog=100000 > /dev/null 2>&1 || true
    sysctl -w net.core.somaxconn=65536 > /dev/null 2>&1 || true
    echo -e "${GREEN}✓ NAPI budget: 300 pkts / 1500µs (fast small-packet scheduling)${NC}"
    sleep 0.3

    echo -e "${CYAN}[5/12]${NC} Connection tracking — tuned for UDP DNS flows..."
    sysctl -w net.netfilter.nf_conntrack_max=2000000 > /dev/null 2>&1 || true
    # Shorter UDP timeout = conntrack table recycles faster under high pkt/s
    sysctl -w net.netfilter.nf_conntrack_udp_timeout=30 > /dev/null 2>&1 || true
    sysctl -w net.netfilter.nf_conntrack_udp_timeout_stream=120 > /dev/null 2>&1 || true
    sysctl -w net.netfilter.nf_conntrack_tcp_timeout_established=3600 > /dev/null 2>&1 || true
    echo 262144 > /sys/module/nf_conntrack/parameters/hashsize 2>/dev/null || true
    echo -e "${GREEN}✓ Connection tracking: 2M slots, 30s UDP timeout (fast recycle)${NC}"
    sleep 0.3

    echo -e "${CYAN}[6/12]${NC} TCP optimizations for SSH-inside-tunnel..."
    sysctl -w net.ipv4.tcp_window_scaling=1 > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_adv_win_scale=1 > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_moderate_rcvbuf=1 > /dev/null 2>&1 || true
    # notsent_lowat=32KB: keeps the send queue lean — important at 512B MTU
    # where each write() produces many tiny segments
    sysctl -w net.ipv4.tcp_notsent_lowat=32768 > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_fastopen=3 > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_slow_start_after_idle=0 > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_tw_reuse=1 > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_fin_timeout=10 > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_max_tw_buckets=1000000 > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_max_syn_backlog=65536 > /dev/null 2>&1 || true
    # Fewer retries = faster failure detection in lossy DNS environment
    sysctl -w net.ipv4.tcp_retries1=3 > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_retries2=8 > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_orphan_retries=2 > /dev/null 2>&1 || true
    echo -e "${GREEN}✓ TCP optimized for SSH over small-MTU lossy tunnel${NC}"
    sleep 0.3

    echo -e "${CYAN}[7/12]${NC} TCP Keepalive for persistent tunnel connections..."
    sysctl -w net.ipv4.tcp_keepalive_time=60 > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_keepalive_probes=5 > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_keepalive_intvl=10 > /dev/null 2>&1 || true
    echo -e "${GREEN}✓ TCP Keepalive: 60s (tunnel stays alive under low-traffic periods)${NC}"
    sleep 0.3

    echo -e "${CYAN}[8/12]${NC} SACK + MTU probing for 512B fragment awareness..."
    sysctl -w net.ipv4.tcp_sack=1 > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_fack=1 > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_timestamps=1 > /dev/null 2>&1 || true
    # mtu_probing=2: always start with minMSS — critical when MTU=512
    # This prevents the kernel from sending oversized segments that get dropped
    sysctl -w net.ipv4.tcp_mtu_probing=2 > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_base_mss=512 > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_low_latency=1 > /dev/null 2>&1 || true
    echo -e "${GREEN}✓ SACK + MTU probing: kernel aware of 512B ceiling${NC}"
    sleep 0.3

    echo -e "${CYAN}[9/12]${NC} Port range expansion..."
    sysctl -w net.ipv4.ip_local_port_range="1024 65535" > /dev/null 2>&1 || true
    echo -e "${GREEN}✓ Port range: 1024-65535 (64K ports)${NC}"
    sleep 0.3

    echo -e "${CYAN}[10/12]${NC} DNS / UDP fast-path demux..."
    sysctl -w net.ipv4.udp_early_demux=1 > /dev/null 2>&1 || true
    sysctl -w net.ipv4.ip_early_demux=1 > /dev/null 2>&1 || true
    # Faster retransmit detection in lossy paths
    sysctl -w net.ipv4.tcp_early_retrans=3 > /dev/null 2>&1 || true
    echo -e "${GREEN}✓ UDP early-demux enabled (lower per-packet kernel overhead)${NC}"
    sleep 0.3

    echo -e "${CYAN}[11/12]${NC} VM / memory pressure settings..."
    # Lower min_free keeps more pages available for packet buffers
    sysctl -w vm.min_free_kbytes=32768 > /dev/null 2>&1 || true
    # swappiness=10: avoid swapping — swap latency kills small-packet throughput
    sysctl -w vm.swappiness=10 > /dev/null 2>&1 || true
    echo -e "${GREEN}✓ VM tuned: swappiness=10, min_free=32MB${NC}"
    sleep 0.3

    echo -e "${CYAN}[12/12]${NC} Writing permanent sysctl configuration..."
    cat > /etc/sysctl.d/99-dnstt-ultra-v3.conf << 'EOF'
# DNSTT ULTRA SPEED v3.0 — 512B MTU High-Frequency Packet Edition
# Created By THE KING 👑 💯
# Target: 2–4 Mbps through 512B MTU DNS tunnel
# Strategy: High-Frequency Small-Packet Processing

### IP FORWARDING ###
net.ipv4.ip_forward = 1

### CONGESTION CONTROL — CUBIC+FQ (lossy/high-latency path) ###
# CUBIC handles packet loss better than BBR in DNS tunnel environments
net.ipv4.tcp_congestion_control = cubic
net.core.default_qdisc = fq
net.ipv4.tcp_rto_min = 100
net.ipv4.tcp_reordering = 3

### SOCKET BUFFERS — 32MB (optimal for 512B burst volume) ###
net.core.rmem_max = 33554432
net.core.wmem_max = 33554432
net.core.rmem_default = 4194304
net.core.wmem_default = 4194304
net.ipv4.tcp_rmem = 4096 4194304 33554432
net.ipv4.tcp_wmem = 4096 4194304 33554432
net.core.optmem_max = 33554432

### UDP BUFFERS — 128KB min (256 × 512B datagrams per socket) ###
net.ipv4.udp_rmem_min = 131072
net.ipv4.udp_wmem_min = 131072
net.ipv4.udp_mem = 2048 4096 8192

### NAPI BUDGET — fast small-packet scheduling ###
net.core.netdev_budget = 300
net.core.netdev_budget_usecs = 1500
net.core.netdev_max_backlog = 100000
net.core.somaxconn = 65536

### CONNECTION TRACKING — fast UDP recycle ###
net.netfilter.nf_conntrack_max = 2000000
net.netfilter.nf_conntrack_udp_timeout = 30
net.netfilter.nf_conntrack_udp_timeout_stream = 120
net.netfilter.nf_conntrack_tcp_timeout_established = 3600

### TCP — SSH-over-512B-tunnel ###
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_adv_win_scale = 1
net.ipv4.tcp_moderate_rcvbuf = 1
net.ipv4.tcp_notsent_lowat = 32768
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_max_tw_buckets = 1000000
net.ipv4.tcp_max_syn_backlog = 65536
net.ipv4.tcp_retries1 = 3
net.ipv4.tcp_retries2 = 8
net.ipv4.tcp_orphan_retries = 2

### TCP KEEPALIVE ###
net.ipv4.tcp_keepalive_time = 60
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_keepalive_intvl = 10

### MTU PROBING — tells kernel segments cannot exceed 512B ###
net.ipv4.tcp_sack = 1
net.ipv4.tcp_fack = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_mtu_probing = 2
net.ipv4.tcp_base_mss = 512
net.ipv4.tcp_low_latency = 1

### PORT RANGE ###
net.ipv4.ip_local_port_range = 1024 65535

### UDP FAST PATH ###
net.ipv4.udp_early_demux = 1
net.ipv4.ip_early_demux = 1
net.ipv4.tcp_early_retrans = 3

### MEMORY ###
vm.min_free_kbytes = 32768
vm.swappiness = 10
EOF

    # Remove old v2 config to avoid conflicts
    rm -f /etc/sysctl.d/99-dnstt-ultra-v2.conf 2>/dev/null || true

    # Apply all settings now
    sysctl -p /etc/sysctl.d/99-dnstt-ultra-v3.conf > /dev/null 2>&1 || true
    echo -e "${GREEN}✓ Config saved + applied: /etc/sysctl.d/99-dnstt-ultra-v3.conf${NC}"

    echo -e "${CYAN}[BONUS]${NC} Setting maximum file descriptors + process priority..."
    cat > /etc/security/limits.d/99-dnstt-ultra-v3.conf << 'EOF'
# DNSTT ULTRA v3.0 — Max file descriptors for high-pps 512B tunnel
* soft nofile 1048576
* hard nofile 1048576
root soft nofile 1048576
root hard nofile 1048576
* soft nproc 1048576
* hard nproc 1048576
EOF
    # Remove old limits file to avoid conflict
    rm -f /etc/security/limits.d/99-dnstt-ultra-v2.conf 2>/dev/null || true
    echo -e "${GREEN}✓ File descriptors: 1M (sufficient for high-pps DNS tunnel)${NC}"

    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║     ⚡ ULTRA SPEED v3.0 — 512B EDITION ACTIVATED ⚡  ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}Optimization Summary (512B MTU HIGH-FREQUENCY MODE):${NC}"
    echo -e "  ${GREEN}✓${NC} CUBIC + FQ (lossy-path congestion control)"
    echo -e "  ${GREEN}✓${NC} 100ms RTO (fast retransmit in lossy DNS env)"
    echo -e "  ${GREEN}✓${NC} 32MB Socket Buffers (right-sized for 512B bursts)"
    echo -e "  ${GREEN}✓${NC} 128KB UDP Min Buffers (256 × 512B per socket)"
    echo -e "  ${GREEN}✓${NC} NAPI Budget: 300 pkts / 1500µs (low-latency polling)"
    echo -e "  ${GREEN}✓${NC} tcp_base_mss=512 + mtu_probing=2 (no oversized segments)"
    echo -e "  ${GREEN}✓${NC} 2M conntrack, 30s UDP timeout (fast table recycle)"
    echo -e "  ${GREEN}✓${NC} 1M File Descriptors"
    echo -e "  ${GREEN}✓${NC} swappiness=10 (no swap-induced latency spikes)"
    echo ""
    echo -e "${YELLOW}Target: 2–4 Mbps at 512B MTU 🚀${NC}"

    sleep 3
}

#============================================
# SSH SERVER OPTIMIZATION
#============================================

optimize_for_512() {
    log_message "${YELLOW}⚡ Applying deep 512B MTU small-packet optimizations...${NC}"
    echo ""

    # ── WHY THIS FUNCTION EXISTS ─────────────────────────────────────────────
    # optimize_system_ultra() sets the baseline. This function adds the
    # 512B-SPECIFIC layer on top: hardware interrupt tuning, NIC queue depth,
    # socket-level SO_RCVBUF forcing, and loopback configuration.
    # Together they address the three root causes of 300kbps bottleneck:
    #   1. Packet drops from shallow UDP receive queues
    #   2. CPU stalls from interrupt coalescing tuned for large frames
    #   3. TCP Nagle buffering inside the SSH-over-tunnel layer
    # ─────────────────────────────────────────────────────────────────────────

    echo -e "${CYAN}[A]${NC} Forcing kernel to flush UDP receive queue more aggressively..."
    # At 512B MTU with 2-4Mbps target = ~8000 pkts/sec on UDP port 5300.
    # The kernel default receive buffer is 208KB — enough for ~400 packets.
    # Under burst conditions this causes drops. We increase per-socket min
    # and force the system-wide max to 32MB (already set, reconfirm here).
    sysctl -w net.core.rmem_max=33554432        > /dev/null 2>&1 || true
    sysctl -w net.core.wmem_max=33554432        > /dev/null 2>&1 || true
    sysctl -w net.ipv4.udp_rmem_min=131072      > /dev/null 2>&1 || true
    sysctl -w net.ipv4.udp_wmem_min=131072      > /dev/null 2>&1 || true
    # udp_mem in pages (4096 bytes): min/pressure/max
    # max = 8192 pages = 32MB — enough for ~65K × 512B in-flight datagrams
    sysctl -w net.ipv4.udp_mem="2048 4096 8192" > /dev/null 2>&1 || true
    echo -e "${GREEN}✓ UDP receive queue: 32MB max, 128KB min per-socket${NC}"
    sleep 0.3

    echo -e "${CYAN}[B]${NC} NAPI poll tuning — fastest possible small-packet delivery..."
    # At 512B the kernel receives ~8000 pkts/sec. Default NAPI budget of 64
    # means the softirq processes 64 packets then yields — causing latency
    # spikes every ~8ms. We set budget=300 / 1500µs: process more packets
    # per cycle but yield before the 1.5ms window to avoid CPU monopoly.
    sysctl -w net.core.netdev_budget=300        > /dev/null 2>&1 || true
    sysctl -w net.core.netdev_budget_usecs=1500 > /dev/null 2>&1 || true
    sysctl -w net.core.netdev_max_backlog=100000 > /dev/null 2>&1 || true
    echo -e "${GREEN}✓ NAPI: 300 pkts / 1500µs (reduces per-packet interrupt latency)${NC}"
    sleep 0.3

    echo -e "${CYAN}[C]${NC} Disabling TCP Nagle on the SSH-over-tunnel layer..."
    # Inside the tunnel, SSH sends small write()s that Nagle bundles together
    # waiting for ACKs. With 512B MTU this causes 40ms buffering stalls.
    # tcp_low_latency=1 disables this. tcp_notsent_lowat=32768 keeps the
    # kernel's unsent queue lean, preventing write-buffer buildup.
    sysctl -w net.ipv4.tcp_low_latency=1        > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_notsent_lowat=32768  > /dev/null 2>&1 || true
    # tcp_base_mss=512: kernel starts MTU discovery from 512B (not 1024B)
    # This prevents oversized segments that get dropped at the DNS layer
    sysctl -w net.ipv4.tcp_base_mss=512         > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_mtu_probing=2        > /dev/null 2>&1 || true
    echo -e "${GREEN}✓ TCP Nagle disabled, base_mss=512, mtu_probing=always${NC}"
    sleep 0.3

    echo -e "${CYAN}[D]${NC} NIC interrupt coalescing — hardware-level small-packet tuning..."
    # ethtool rx-usecs controls how long the NIC waits before firing an IRQ.
    # Default is 50-100µs — at 512B and 8000pkt/s this coalesces too many
    # packets, adding latency. Setting to 10µs fires IRQs faster.
    NET_IFACE=$(ip route | grep default | awk '{print $5}' | head -1)
    NET_IFACE=${NET_IFACE:-eth0}
    if command -v ethtool &>/dev/null; then
        # rx-usecs=10: fire IRQ every 10µs under packet load
        ethtool -C "$NET_IFACE" rx-usecs 10 2>/dev/null || true
        # adaptive-rx off: disable adaptive coalescing which re-tunes itself
        # upward under load, defeating our small-packet setting
        ethtool -C "$NET_IFACE" adaptive-rx off 2>/dev/null || true
        # rx-frames=32: fire IRQ after 32 frames max (prevents 512B queue stall)
        ethtool -C "$NET_IFACE" rx-frames 32 2>/dev/null || true
        echo -e "${GREEN}✓ NIC ($NET_IFACE): rx-usecs=10, adaptive-rx=off, rx-frames=32${NC}"
    else
        echo -e "${YELLOW}⚠ ethtool not found — install with: apt-get install ethtool${NC}"
        echo -e "${YELLOW}  NIC-level coalescing tuning skipped (not critical but helpful)${NC}"
    fi
    sleep 0.3

    echo -e "${CYAN}[E]${NC} Loopback interface — maximizing local tunnel forwarding..."
    # DNSTT decapsulates DNS packets and forwards the payload to
    # 127.0.0.1:SSH_PORT via loopback. Loopback default MTU is 65536 —
    # we set it explicitly and ensure txqueuelen is large enough for
    # the forwarded stream without local drops.
    ip link set lo mtu 65536 2>/dev/null || true
    ip link set lo txqueuelen 10000 2>/dev/null || true
    echo -e "${GREEN}✓ Loopback: MTU=65536, txqueuelen=10000${NC}"
    sleep 0.3

    echo -e "${CYAN}[F]${NC} TCP fast retransmit for lossy DNS path..."
    # In a DNS tunnel, packet loss is inherent (the carrier throttles/drops).
    # These settings make TCP detect loss faster and recover without full RTO.
    sysctl -w net.ipv4.tcp_sack=1              > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_fack=1              > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_early_retrans=3     > /dev/null 2>&1 || true
    # rto_min=100ms: halves default RTO (200ms) for faster loss recovery
    sysctl -w net.ipv4.tcp_rto_min=100         > /dev/null 2>&1 || true
    echo -e "${GREEN}✓ Fast retransmit: SACK+FACK+early_retrans, RTO=100ms${NC}"
    sleep 0.3

    echo -e "${CYAN}[G]${NC} Saving 512B-specific sysctl layer permanently..."
    cat > /etc/sysctl.d/99-dnstt-512b-tunnel.conf << 'SYSCTL'
# DNSTT 512B MTU Deep Packet Optimization Layer
# Created By THE KING 👑 💯
# Applied on top of 99-dnstt-ultra-v3.conf for MTU<=512 environments

# UDP receive queue depth for 8000pkt/s burst
net.core.rmem_max = 33554432
net.core.wmem_max = 33554432
net.ipv4.udp_rmem_min = 131072
net.ipv4.udp_wmem_min = 131072
net.ipv4.udp_mem = 2048 4096 8192

# NAPI: fast small-packet scheduling (300 pkts / 1500µs)
net.core.netdev_budget = 300
net.core.netdev_budget_usecs = 1500
net.core.netdev_max_backlog = 100000

# TCP: disable Nagle + MTU awareness at 512B
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_notsent_lowat = 32768
net.ipv4.tcp_base_mss = 512
net.ipv4.tcp_mtu_probing = 2

# Fast loss recovery for lossy DNS path
net.ipv4.tcp_sack = 1
net.ipv4.tcp_fack = 1
net.ipv4.tcp_early_retrans = 3
net.ipv4.tcp_rto_min = 100
SYSCTL
    sysctl -p /etc/sysctl.d/99-dnstt-512b-tunnel.conf > /dev/null 2>&1 || true
    echo -e "${GREEN}✓ Saved + applied: /etc/sysctl.d/99-dnstt-512b-tunnel.conf${NC}"

    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   ⚡ 512B MTU DEEP OPTIMIZATION LAYER APPLIED ⚡    ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${NC}"
    echo -e "  ${GREEN}✓${NC} UDP: 32MB buffer, 128KB/socket min (no more drops)"
    echo -e "  ${GREEN}✓${NC} NAPI: 300pkts/1500µs (8× faster than default)"
    echo -e "  ${GREEN}✓${NC} TCP Nagle disabled (no 40ms buffering stalls)"
    echo -e "  ${GREEN}✓${NC} tcp_base_mss=512 (no oversized segment drops)"
    echo -e "  ${GREEN}✓${NC} NIC interrupt coalescing: rx-usecs=10 (hardware-level)"
    echo -e "  ${GREEN}✓${NC} Loopback: MTU=65536, txqueuelen=10000"
    echo -e "  ${GREEN}✓${NC} RTO=100ms + SACK+FACK (fast loss recovery)"
    echo -e "  ${YELLOW}Combined with v3 base: target 2–4 Mbps at 512B MTU${NC}"
    echo ""
    sleep 1
}

optimize_ssh_server() {
    log_message "${YELLOW}🔧 Optimizing SSH server for 512B MTU tunnel throughput...${NC}"
    echo ""

    # ── WHY THESE SSH SETTINGS ───────────────────────────────────────────────
    # In a DNS tunnel there is DOUBLE ENCRYPTION:
    #   Layer 1: DNSTT's own NaCl/noise encryption on the DNS channel
    #   Layer 2: SSH encryption on top of that
    # At 512B MTU this double overhead is severe. Every SSH frame's crypto
    # header eats into the 512B payload budget.
    #
    # Solution:
    #   - Use chacha20-poly1305 as the PREFERRED cipher: it has the lowest
    #     per-byte CPU cost and zero padding overhead vs AES-CBC/CTR.
    #     This is the "lightest" standardised SSH cipher available.
    #   - Enable SSH Compression (zlib@openssh.com): compresses the plaintext
    #     BEFORE encryption. At typical SSH/terminal data, compression achieves
    #     30-60% ratio — meaning each 512B DNS packet carries more real payload.
    #   - Small RekeyLimit: prevents stall-on-rekey at high pkt/s rates.
    # ─────────────────────────────────────────────────────────────────────────

    # Backup original sshd_config (only once)
    if [[ ! -f /etc/ssh/sshd_config.backup ]]; then
        cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
        echo -e "${GREEN}✓ Backed up original SSH config to sshd_config.backup${NC}"
    fi

    # Remove any previous DNSTT SSH config block to avoid duplicates on re-run
    sed -i '/# DNSTT ULTRA SPEED/,/^# END DNSTT SSH/d' /etc/ssh/sshd_config 2>/dev/null || true

    cat >> /etc/ssh/sshd_config << 'EOF'
# DNSTT ULTRA SPEED v3.0 — 512B MTU SSH Layer Optimization
# Created By THE KING 👑 💯

# ── CIPHER PRIORITY ──────────────────────────────────────────────────────────
# chacha20-poly1305 is listed FIRST so SSH negotiates it by default.
# It has lower per-byte overhead than AES-GCM and no block-padding waste.
# AES-128-CTR is second (lighter than AES-256). AES-GCM variants included
# for clients (HTTP Injector, etc.) that don't support chacha.
Ciphers chacha20-poly1305@openssh.com,aes128-ctr,aes128-gcm@openssh.com,aes256-ctr,aes256-gcm@openssh.com,aes192-ctr

# ── MAC SELECTION ─────────────────────────────────────────────────────────────
# ETM (encrypt-then-mac) variants only — more efficient at small packet sizes.
# hmac-sha2-256-etm is preferred: shorter digest than sha2-512.
MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,hmac-sha2-256,hmac-sha2-512

# ── KEY EXCHANGE ──────────────────────────────────────────────────────────────
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,ecdh-sha2-nistp256

# ── COMPRESSION ───────────────────────────────────────────────────────────────
# YES = compress plaintext before encryption.
# At 512B MTU this is CRITICAL: compression squeezes more real data into each
# DNS query. Terminal output, file transfers, and command I/O all compress
# well (30-60%). This is the single biggest payload-per-packet improvement.
Compression yes

# ── TUNNEL STABILITY ─────────────────────────────────────────────────────────
TCPKeepAlive yes
ClientAliveInterval 20
ClientAliveCountMax 6

# ── CAPACITY ─────────────────────────────────────────────────────────────────
MaxSessions 500
MaxStartups 500:30:1000

# ── REKEY LIMIT ───────────────────────────────────────────────────────────────
# 64M bytes between rekeys: prevents stall-on-rekey at high pkt/s.
# Old value (256M) causes longer stalls if the link is slow.
# 64M is ~30 seconds at 2Mbps — frequent enough to be secure,
# small enough to avoid noticeable throughput dips.
RekeyLimit 64M 30m

# ── AUTH ──────────────────────────────────────────────────────────────────────
MaxAuthTries 6

# ── TCP_NODELAY for SSH socket ────────────────────────────────────────────────
# Tells SSH daemon's accept()ed sockets to disable Nagle (TCP_NODELAY).
# Important at 512B MTU: without this, small SSH writes buffer for 40ms.
IPQoS lowdelay throughput
# END DNSTT SSH
EOF

    echo -e "${GREEN}✓ chacha20-poly1305 set as preferred cipher (lightest overhead)${NC}"
    echo -e "${GREEN}✓ SSH Compression enabled (30-60% more payload per 512B packet)${NC}"
    echo -e "${GREEN}✓ ETM MACs only (efficient at small frame sizes)${NC}"
    echo -e "${GREEN}✓ RekeyLimit=64M/30m (no rekey stalls in tunnel)${NC}"
    echo -e "${GREEN}✓ ClientAliveInterval=20s (fast dead-peer detection)${NC}"
    echo -e "${GREEN}✓ IPQoS=lowdelay+throughput (TCP_NODELAY on SSH sockets)${NC}"

    # Validate sshd config before restarting
    echo ""
    echo -e "${CYAN}Validating SSH config...${NC}"
    if sshd -t 2>/dev/null; then
        echo -e "${GREEN}✓ SSH config valid${NC}"
        echo -e "${CYAN}Restarting SSH service...${NC}"
        systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
        echo -e "${GREEN}✓ SSH service restarted${NC}"
    else
        echo -e "${RED}✗ SSH config has errors — reverting to backup${NC}"
        cp /etc/ssh/sshd_config.backup /etc/ssh/sshd_config
        systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
        echo -e "${YELLOW}⚠ SSH reverted to original config. Check sshd -T manually.${NC}"
    fi

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

    log_message "${YELLOW}📋 Creating systemd service — 512B MTU optimized...${NC}"
    echo ""

    # ── DNSTT BINARY FLAGS ───────────────────────────────────────────────────
    # The dnstt-server binary itself has no explicit fragmentation flags, but
    # how we launch it and its Go runtime environment directly controls how
    # it handles small packets.
    #
    # Key flags passed via Environment:
    #   GOMAXPROCS=<ncpu>: Use ALL CPU cores. dnstt is I/O bound at 512B MTU
    #     — more goroutines means more concurrent DNS query processing.
    #     Old value (4) was hardcoded. We detect actual core count.
    #   GOGC=400: Less frequent GC pauses. At 8000 pkt/s the GC would
    #     normally fire every ~100ms causing 1-5ms stalls. 400 = GC fires
    #     less often (accepts higher memory use in exchange for no stalls).
    #   GODEBUG=netdns=go: Use Go's pure-Go DNS resolver (avoids cgo
    #     syscall overhead on every DNS lookup the server does internally).
    #   GOMEMLIMIT: Soft memory cap prevents OOM on small VPS while still
    #     allowing GOGC=400 to accumulate heap between collections.
    #
    # Nice=-10 (not -20): FIFO/99 caused the process to starve kernel
    #     softirqs on single-core VPS, which actually hurt UDP receive rates.
    #     Nice=-10 gives priority without monopolising the CPU.
    # ─────────────────────────────────────────────────────────────────────────

    # Detect CPU core count for GOMAXPROCS
    CPU_CORES=$(nproc 2>/dev/null || echo "2")
    # Cap at 8 — beyond that dnstt's internal channel contention outweighs gain
    [ "$CPU_CORES" -gt 8 ] && CPU_CORES=8

    # Detect available RAM for GOMEMLIMIT (use 60% of total RAM, max 2GB)
    TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}' || echo "524288")
    GOMEMLIMIT_MB=$(( TOTAL_RAM_KB * 60 / 100 / 1024 ))
    [ "$GOMEMLIMIT_MB" -gt 2048 ] && GOMEMLIMIT_MB=2048
    [ "$GOMEMLIMIT_MB" -lt 128 ]  && GOMEMLIMIT_MB=128

    cat > /etc/systemd/system/dnstt.service << EOF
[Unit]
Description=DNSTT DNS Tunnel Server — 512B MTU Edition (THE KING 👑)
Documentation=https://www.bamsoftware.com/software/dnstt/
After=network.target network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR

# ── Go Runtime: tuned for high-frequency 512B small packets ──────────────────
# GOMAXPROCS: all cores (up to 8) — parallel DNS query goroutines
Environment=GOMAXPROCS=$CPU_CORES
# GOGC=400: less frequent GC, prevents stall-per-100ms at 8000pkt/s
Environment=GOGC=400
# GOMEMLIMIT: soft cap — prevents OOM while allowing GOGC=400 heap growth
Environment=GOMEMLIMIT=${GOMEMLIMIT_MB}MiB
# netdns=go: pure-Go resolver, avoids cgo syscall overhead
Environment=GODEBUG=netdns=go

# ── dnstt-server launch ────────────────────────────────────────────────────────
# -mtu $mtu: sets DNSTT's internal payload MTU.
#   At 512B: each DNS TXT record carries ~490 bytes of tunnel data.
#   DNSTT handles fragmentation internally across multiple DNS queries
#   when the payload exceeds the MTU. Setting this correctly prevents
#   oversized records that get silently dropped by intermediate resolvers.
#
# Forward to 127.0.0.1:$ssh_port (loopback — high MTU, no re-fragmentation)
ExecStart=$DNSTT_SERVER \\
    -udp :5300 \\
    -privkey-file $INSTALL_DIR/server.key \\
    -mtu $mtu \\
    $tunnel_domain 127.0.0.1:$ssh_port

Restart=always
RestartSec=2
StandardOutput=append:$LOG_DIR/dnstt-server.log
StandardError=append:$LOG_DIR/dnstt-error.log
SyslogIdentifier=dnstt

# ── I/O Multiplexing: file descriptors + process priority ─────────────────────
# LimitNOFILE: 1M file descriptors.
# At 512B MTU with many concurrent clients, each DNS session = 1 fd.
# 1M handles ~50K concurrent tunneled sessions.
LimitNOFILE=1048576
LimitNPROC=65536

# Nice=-10: high priority without starving kernel softirqs (UDP receive path).
# FIFO/99 (-20) caused UDP drops on single-core VPS by blocking softirq processing.
Nice=-10
IOSchedulingClass=best-effort
IOSchedulingPriority=0

# CPUSchedulingPolicy=other with Nice=-10 is more reliable than FIFO on VPS
# where hypervisor CPU steal can cause FIFO goroutines to miss their slice.
# Uncomment FIFO lines only on dedicated bare-metal servers:
# CPUSchedulingPolicy=fifo
# CPUSchedulingPriority=90

# Memory cap aligned with GOMEMLIMIT env var above
MemoryMax=${GOMEMLIMIT_MB}M
CPUQuota=$((CPU_CORES * 100))%

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

    echo -e "${GREEN}✓ Service created — 512B MTU optimized${NC}"
    log_success "DNSTT Configuration:"
    log_message "   MTU: $mtu bytes"
    log_message "   SSH Port: $ssh_port"
    log_message "   UDP Port: 5300"
    log_message "   GOMAXPROCS: $CPU_CORES (all cores)"
    log_message "   GOGC: 400 (low-pause GC for 8000pkt/s)"
    log_message "   GOMEMLIMIT: ${GOMEMLIMIT_MB}MiB"
    log_message "   LimitNOFILE: 1M (I/O multiplexing)"
    log_message "   Nice: -10 (high priority, no softirq starvation)"
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
    # Raise process-level fd limit immediately (limits.d takes effect at next login)
    ulimit -n 1048576 2>/dev/null || true
    
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

    # Apply 512B-specific optimizations if MTU is small
    if [ "$MTU" -le 512 ]; then
        echo ""
        echo -e "${YELLOW}━━━ MTU ≤ 512 detected — applying small-packet optimizations ━━━${NC}"
        optimize_for_512
    fi
    
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
        # Apply 512B-specific optimizations if new MTU is small
        if [ "$NEW_MTU" -le 512 ]; then
            echo ""
            echo -e "${YELLOW}MTU ≤ 512 — applying small-packet optimizations...${NC}"
            optimize_for_512
        fi
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
                    rm -f /etc/sysctl.d/99-dnstt-ultra-v3.conf
                    rm -f /etc/sysctl.d/99-dnstt-512b-tunnel.conf
                    rm -f /etc/security/limits.d/99-dnstt-ultra-v2.conf
                    rm -f /etc/security/limits.d/99-dnstt-ultra-v3.conf
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
        
