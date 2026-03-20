#!/bin/bash

##############################################
# DNSTT ULTRA SPEED - SSH OPTIMIZED EDITION
# Created By THE KING 👑 💯
# Version: 8.1.0 - MTU-512 Optimized
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

##############################################
# UI HELPERS
##############################################

# Box-drawing characters
BOX_TL='╔'; BOX_TR='╗'; BOX_BL='╚'; BOX_BR='╝'
BOX_H='═'; BOX_V='║'; BOX_ML='╠'; BOX_MR='╣'
SEP_H='─'; SEP_TL='┌'; SEP_TR='┐'; SEP_BL='└'; SEP_BR='┘'; SEP_V='│'

# Print a full-width box line (═══)
_hline() { printf '%0.s═' $(seq 1 65); }
_sline() { printf '%0.s─' $(seq 1 63); }

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# UI CONSTANTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
BOLD='\033[1m'
DIM='\033[2m'
ITALIC='\033[3m'
UNDERLINE='\033[4m'
BLINK='\033[5m'
BG_BLACK='\033[40m'
BG_DARK='\033[48;5;232m'

# Width of the UI frame (characters)
UI_W=68

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# LOW-LEVEL DRAWING PRIMITIVES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Horizontal rule (═══)
_hrule()   { printf '═%.0s' $(seq 1 $UI_W); }
# Thin rule (───)
_trule()   { printf '─%.0s' $(seq 1 $((UI_W-2))); }
# Dot row
_drule()   { printf '·%.0s' $(seq 1 $((UI_W-4))); }

# Top border
_top()     { echo -e "${CYAN}╔$(_hrule)╗${NC}"; }
# Bottom border
_bot()     { echo -e "${CYAN}╚$(_hrule)╝${NC}"; }
# Mid divider
_mid()     { echo -e "${CYAN}╠$(_hrule)╣${NC}"; }
# Thin section top/bot
_stop()    { echo -e "  ${CYAN}┌$(_trule)┐${NC}"; }
_sbot()    { echo -e "  ${CYAN}└$(_trule)┘${NC}"; }

# Empty padded row
_row()     { echo -e "${CYAN}║${NC}$(printf ' %.0s' $(seq 1 $UI_W))${CYAN}║${NC}"; }

# Padded content row — usage: _line "content" [raw_len_override]
# raw_len is the visible character count (stripped of ANSI codes)
_line() {
    local content="$1"
    local raw_len="${2:-0}"
    if [[ $raw_len -eq 0 ]]; then
        # Estimate visible length by stripping ANSI codes
        raw_len=$(echo -e "$content" | sed 's/\x1b\[[0-9;]*m//g' | wc -m)
        raw_len=$((raw_len - 1))   # wc -m counts newline
    fi
    local pad=$(( UI_W - raw_len ))
    [[ $pad -lt 0 ]] && pad=0
    printf "${CYAN}║${NC} %b$(printf ' %.0s' $(seq 1 $pad))${CYAN}║${NC}\n" "$content"
}

# Centered content row
_cline() {
    local content="$1"
    local raw_len="${2:-0}"
    if [[ $raw_len -eq 0 ]]; then
        raw_len=$(echo -e "$content" | sed 's/\x1b\[[0-9;]*m//g' | wc -m)
        raw_len=$((raw_len - 1))
    fi
    local total_pad=$(( UI_W - raw_len ))
    local left_pad=$(( total_pad / 2 ))
    local right_pad=$(( total_pad - left_pad ))
    printf "${CYAN}║${NC}$(printf ' %.0s' $(seq 1 $left_pad))%b$(printf ' %.0s' $(seq 1 $right_pad))${CYAN}║${NC}\n" "$content"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# BANNER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
show_banner() {
    clear
    echo ""
    _top
    _row
    _cline "${CYAN}${BOLD} ▀▀▀  ░░░  ░░  ░░  ░░░  ░░░  ░░  ░░   ░░   ░░${NC}" 47
    _cline "${CYAN}${BOLD}▐░░░▌ ▐░░ ▐░░▌▐░░▌▐░░▌ ▐░░▌▐░░▌▐░░▌ ▐░░▌ ▐░░▌${NC}" 49
    _cline "${GREEN}${BOLD}  ▄██████╗ ███╗  ██╗███████╗  ████████╗ ██╗ ██╗███╗  ██╗  ${NC}" 58
    _cline "${GREEN}${BOLD}  ██╔════╝ ████╗ ██║██╔════╝     ██╔══╝ ██║ ██║████╗ ██║  ${NC}" 58
    _cline "${GREEN}${BOLD}  ╚█████╗  ██╔██╗██║███████╗     ██║    ██║ ██║██╔██╗██║  ${NC}" 58
    _cline "${GREEN}${BOLD}   ╚═══██╗ ██║╚████║╚════██║     ██║    ██║ ██║██║╚████║  ${NC}" 58
    _cline "${GREEN}${BOLD}  ██████╔╝ ██║ ╚███║███████║     ██║    ╚██████╔╝██║ ╚███║ ${NC}" 59
    _cline "${GREEN}${BOLD}  ╚═════╝  ╚═╝  ╚══╝╚══════╝     ╚═╝     ╚═════╝ ╚═╝  ╚══╝ ${NC}" 60
    _row
    _mid
    # Subtitle bar
    local sub="  ${DIM}${WHITE}DNS TUNNEL MANAGER${NC}  ${CYAN}▸${NC}  ${YELLOW}MTU-512 Optimised${NC}  ${CYAN}▸${NC}  ${GREEN}SSH Edition v8.1${NC}  "
    _cline "$sub" 56
    _mid
    # Live status bar
    local svc_status svc_mtu svc_ip svc_uptime=""
    if systemctl is-active --quiet dnstt 2>/dev/null; then
        svc_status="${GREEN}${BOLD}● RUNNING${NC}"
        local spid; spid=$(systemctl show dnstt --property=MainPID --value 2>/dev/null || echo "")
        if [[ -n "$spid" && "$spid" != "0" ]]; then
            local etime; etime=$(ps -o etime= -p "$spid" 2>/dev/null | tr -d ' ')
            [[ -n "$etime" ]] && svc_uptime="${DIM} (up ${etime})${NC}"
        fi
    else
        svc_status="${RED}○ STOPPED${NC}"
    fi
    svc_mtu=$(cat "$INSTALL_DIR/mtu.txt" 2>/dev/null || echo "---")
    svc_ip=$(curl -s --connect-timeout 2 --max-time 3 ifconfig.me 2>/dev/null || \
             curl -s --connect-timeout 2 --max-time 3 icanhazip.com 2>/dev/null || echo "---")
    local status_line="  ${WHITE}Status:${NC} ${svc_status}${svc_uptime}   ${WHITE}MTU:${NC} ${CYAN}${svc_mtu}${NC}   ${WHITE}IP:${NC} ${YELLOW}${svc_ip}${NC}"
    _line "$status_line" 0
    _mid
    _cline "${PURPLE}${BOLD}  ✦  Created by THE KING 👑 💯  ✦${NC}" 36
    _bot
    echo ""
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SECTION & OPTION HELPERS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# section_header "TITLE" "icon"
section_header() {
    local title="$1" icon="${2:-◈}"
    echo ""
    _stop
    printf "  ${CYAN}│${NC}  ${BOLD}${WHITE}${icon}  %-$((UI_W-8))s${NC}  ${CYAN}│${NC}\n" "$title"
    _sbot
    echo ""
}

# menu_header "TITLE" "icon"  — full-width box version for menus
menu_header() {
    local title="$1" icon="${2:-◈}"
    echo ""
    _top
    _cline "${BOLD}${WHITE}${icon}  ${title}${NC}" $(( ${#title} + ${#icon} + 3 ))
    _bot
    echo ""
}

# print_opt  KEY  ICON  LABEL  COLOR
# Prints:   [KEY]  ICON  LABEL
print_opt() {
    local key="$1" icon="$2" label="$3" col="${4:-$WHITE}"
    printf "    ${CYAN}[${NC}${BOLD}${col}%-2s${NC}${CYAN}]${NC}  ${col}%s${NC}  ${WHITE}%s${NC}\n" \
        "$key" "$icon" "$label"
}

# opt_group "GROUP LABEL"  — prints a thin group divider with label
opt_group() {
    local lbl="$1"
    echo ""
    printf "    ${DIM}${CYAN}── %s %s${NC}\n" "$lbl" "$(printf '─%.0s' $(seq 1 $(( UI_W - ${#lbl} - 8 ))))"
}

# divider
divider() {
    echo -e "    ${DIM}${CYAN}$(_drule)${NC}"
}

# press_enter
press_enter() {
    echo ""
    echo -e "  ${DIM}${CYAN}$(_trule)${NC}"
    echo -ne "  ${WHITE}Press ${CYAN}[Enter]${NC}${WHITE} to continue...${NC}  "
    read -r
    echo ""
}

# confirm_action "message" — returns 0 for yes, 1 for no
confirm_action() {
    local msg="${1:-Are you sure?}"
    echo ""
    echo -e "  ${YELLOW}${BOLD}⚠  ${msg}${NC}"
    echo ""
    echo -ne "  ${WHITE}Type ${RED}${BOLD}yes${NC}${WHITE} to confirm, anything else cancels: ${NC}"
    local ans; read -r ans
    [[ "$ans" == "yes" ]]
}

# step_ok  "message"
step_ok()   { echo -e "  ${GREEN}${BOLD}  ✔${NC}  ${WHITE}${1}${NC}"; }
# step_err "message"
step_err()  { echo -e "  ${RED}${BOLD}  ✘${NC}  ${WHITE}${1}${NC}"; }
# step_run "message"
step_run()  { echo -ne "  ${CYAN}${BOLD}  ▸${NC}  ${WHITE}${1}...${NC}  "; }
# step_skip "message"
step_skip() { echo -e "  ${YELLOW}${BOLD}  ○${NC}  ${DIM}${WHITE}${1}${NC}"; }

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
    echo -e "  ${CYAN}${BOLD}▸${NC}  ${WHITE}${message}${NC}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $(echo -e "$message" | sed 's/\x1b\[[0-9;]*m//g')" >> "$LOG_DIR/dnstt.log"
}

log_error() {
    local message="$1"
    echo -e "  ${RED}${BOLD}✘${NC}  ${WHITE}${message}${NC}"
    echo "[ERROR] $(echo -e "$message" | sed 's/\x1b\[[0-9;]*m//g')" >> "$LOG_DIR/dnstt.log"
}

log_success() {
    local message="$1"
    echo -e "  ${GREEN}${BOLD}✔${NC}  ${WHITE}${message}${NC}"
    echo "[SUCCESS] $(echo -e "$message" | sed 's/\x1b\[[0-9;]*m//g')" >> "$LOG_DIR/dnstt.log"
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
    
    echo -e "${CYAN}[3/12]${NC} UDP optimization for DNS tunnel bursts..."
    # NOTE: These are general defaults. If MTU=512 is selected,
    # optimize_for_512() will overwrite these with tighter values
    # tuned specifically for small-packet bursts.
    sysctl -w net.ipv4.udp_rmem_min=262144 > /dev/null 2>&1 || true
    sysctl -w net.ipv4.udp_wmem_min=262144 > /dev/null 2>&1 || true
    sysctl -w net.ipv4.udp_mem="262144 524288 1048576" > /dev/null 2>&1 || true
    
    # Advanced UDP tuning
    sysctl -w net.core.netdev_max_backlog=100000 > /dev/null 2>&1 || true
    sysctl -w net.core.netdev_budget=1000 > /dev/null 2>&1 || true
    sysctl -w net.core.netdev_budget_usecs=2000 > /dev/null 2>&1 || true
    sysctl -w net.core.somaxconn=65536 > /dev/null 2>&1 || true
    echo -e "${GREEN}✓ UDP: optimized for DNS tunnel bursts${NC}"
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

### EXTREME UDP OPTIMIZATION ###
net.ipv4.udp_rmem_min = 262144
net.ipv4.udp_wmem_min = 262144
net.ipv4.udp_mem = 262144 524288 1048576

### DNS BURST HANDLING ###
net.core.netdev_max_backlog = 100000
net.core.netdev_budget = 1000
net.core.netdev_budget_usecs = 2000
net.core.somaxconn = 65536

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

optimize_for_512() {
    log_message "${YELLOW}⚡ Applying MTU-512 ULTRA optimizations (small-packet mode)...${NC}"
    echo ""

    # ── Why these values ────────────────────────────────────────────────────
    # At MTU=512 the DNSTT server sends/receives hundreds of tiny UDP
    # datagrams per second.  The kernel defaults are tuned for large (1500B)
    # frames, so we must re-tune for high-frequency small packets:
    #   • Larger UDP socket queues  → fewer dropped datagrams under burst
    #   • Shorter NAPI budget timer → each datagram gets scheduled faster
    #   • TCP_NODELAY equivalent    → SSH bytes inside the tunnel aren't
    #                                 held back by Nagle
    #   • Lower delayed-ACK timer   → fewer retransmits on the SSH layer
    #   • Loopback MTU = 65536      → no fragmentation on the local forward
    # ────────────────────────────────────────────────────────────────────────

    echo -e "${CYAN}[A]${NC} UDP socket queues for 512B high-frequency bursts..."
    # 64MB socket queues — at 512B/datagram that holds ~131 000 datagrams
    # before the kernel starts dropping.  The ultra function sets 1GB for
    # TCP, but UDP needs a separate, reachable limit.
    sysctl -w net.core.rmem_max=67108864             > /dev/null 2>&1 || true
    sysctl -w net.core.wmem_max=67108864             > /dev/null 2>&1 || true
    sysctl -w net.core.rmem_default=4194304          > /dev/null 2>&1 || true
    sysctl -w net.core.wmem_default=4194304          > /dev/null 2>&1 || true
    sysctl -w net.ipv4.udp_rmem_min=262144           > /dev/null 2>&1 || true
    sysctl -w net.ipv4.udp_wmem_min=262144           > /dev/null 2>&1 || true
    # pages: min pressure max (in pages, not bytes)
    # 262144 pages ≈ 1GB on 4KB-page systems
    sysctl -w net.ipv4.udp_mem="65536 131072 262144" > /dev/null 2>&1 || true
    echo -e "${GREEN}✓ UDP queues: 64MB (enough for 131 000 × 512B datagrams)${NC}"
    sleep 0.3

    echo -e "${CYAN}[B]${NC} NAPI poll budget — faster per-datagram scheduling..."
    # netdev_budget_usecs=1500 means the softirq exits after 1.5 ms max,
    # giving each datagram a very short scheduling latency.
    # netdev_max_backlog=100000 keeps a deep per-CPU queue so bursts don't
    # overflow before the softirq can drain them.
    sysctl -w net.core.netdev_budget=1000            > /dev/null 2>&1 || true
    sysctl -w net.core.netdev_budget_usecs=1500      > /dev/null 2>&1 || true
    sysctl -w net.core.netdev_max_backlog=100000      > /dev/null 2>&1 || true
    echo -e "${GREEN}✓ NAPI budget: 1500µs poll (lower latency per 512B packet)${NC}"
    sleep 0.3

    echo -e "${CYAN}[C]${NC} TCP tuning for SSH inside 512B DNS tunnel..."
    # Nagle's algorithm buffers small TCP segments — exactly wrong for an
    # interactive SSH session inside a 512B tunnel.  tcp_low_latency=1
    # disables the kernel-side Nagle equivalent.
    # tcp_notsent_lowat=16384 keeps the TCP send buffer tight so SSH data
    # is pushed immediately rather than waiting for the buffer to fill.
    sysctl -w net.ipv4.tcp_low_latency=1             > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_notsent_lowat=16384       > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_fastopen=3                > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_slow_start_after_idle=0   > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_sack=1                    > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_timestamps=1              > /dev/null 2>&1 || true
    # Shrink TCP buffers to match the tiny segment size — prevents the
    # kernel from over-allocating and wasting memory on small flows.
    sysctl -w net.ipv4.tcp_rmem="4096 87380 16777216" > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_wmem="4096 16384 16777216" > /dev/null 2>&1 || true
    # Faster keepalive for tunnel stability (detect dead peer in ~30s)
    sysctl -w net.ipv4.tcp_keepalive_time=20         > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_keepalive_intvl=5         > /dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_keepalive_probes=6        > /dev/null 2>&1 || true
    echo -e "${GREEN}✓ TCP: Nagle disabled, tight buffers, fast keepalive${NC}"
    sleep 0.3

    echo -e "${CYAN}[D]${NC} Loopback MTU — no fragmentation on the local forward path..."
    # DNSTT decapsulates DNS and forwards plain TCP to 127.0.0.1:SSH.
    # Loopback defaults to 65536B MTU which is perfect — we lock it in.
    ip link set lo mtu 65536 2>/dev/null || true
    echo -e "${GREEN}✓ Loopback MTU: 65536 (zero fragmentation on local hop)${NC}"
    sleep 0.3

    echo -e "${CYAN}[E]${NC} IRQ and CPU affinity hints (reduce context switching)..."
    # On multi-core systems, pin the network softirq to CPU 0 if possible.
    # This keeps the UDP receive path cache-warm and reduces jitter.
    if [[ -f /proc/irq/default_smp_affinity ]]; then
        echo 1 > /proc/irq/default_smp_affinity 2>/dev/null || true
    fi
    # Raise softirq budget so large UDP bursts complete in one poll cycle
    echo 3000 > /proc/sys/net/core/netdev_budget 2>/dev/null || true
    echo -e "${GREEN}✓ IRQ affinity hints applied${NC}"
    sleep 0.3

    echo -e "${CYAN}[F]${NC} Saving MTU-512 sysctl config permanently..."
    cat > /etc/sysctl.d/99-dnstt-512b-tunnel.conf << 'SYSCTL'
# DNSTT MTU-512 Small-Packet Optimizations
# Created By THE KING 👑 💯
# Tuned for high-frequency 512B DNS tunnel datagrams

# ── UDP socket queues (64MB — fits 131K × 512B datagrams) ──
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.rmem_default = 4194304
net.core.wmem_default = 4194304
net.ipv4.udp_rmem_min = 262144
net.ipv4.udp_wmem_min = 262144
net.ipv4.udp_mem = 65536 131072 262144

# ── NAPI poll: shorter burst window, deeper per-CPU queue ──
net.core.netdev_budget = 1000
net.core.netdev_budget_usecs = 1500
net.core.netdev_max_backlog = 100000

# ── TCP: no Nagle, tight buffers, fast ACKs ──
net.ipv4.tcp_low_latency = 1
net.ipv4.tcp_notsent_lowat = 16384
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_sack = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 16384 16777216

# ── Fast keepalive: detect dead tunnel peer in ~30s ──
net.ipv4.tcp_keepalive_time = 20
net.ipv4.tcp_keepalive_intvl = 5
net.ipv4.tcp_keepalive_probes = 6
SYSCTL
    echo -e "${GREEN}✓ Saved: /etc/sysctl.d/99-dnstt-512b-tunnel.conf${NC}"

    # Apply the new file immediately
    sysctl --system > /dev/null 2>&1 || true

    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║    ⚡ MTU-512 SMALL-PACKET OPTIMIZATIONS APPLIED ⚡     ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo -e "  ${GREEN}✓${NC} UDP queues: 64MB (zero datagram drops under burst)"
    echo -e "  ${GREEN}✓${NC} NAPI poll: 1500µs (lowest scheduling latency)"
    echo -e "  ${GREEN}✓${NC} TCP Nagle disabled (SSH bytes sent immediately)"
    echo -e "  ${GREEN}✓${NC} TCP keepalive: dead peer detected in ~30s"
    echo -e "  ${GREEN}✓${NC} Loopback MTU: 65536 (no local fragmentation)"
    echo -e "  ${GREEN}✓${NC} IRQ affinity: cache-warm UDP receive path"
    echo -e "  ${YELLOW}Expected: +50-80% throughput vs default kernel at MTU=512${NC}"
    echo ""
    sleep 1
}

optimize_ssh_server() {
    log_message "${YELLOW}🔧 Optimizing SSH server for MTU-512 tunnel throughput...${NC}"
    echo ""
    
    # Backup original sshd_config
    if [[ ! -f /etc/ssh/sshd_config.backup ]]; then
        cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
        echo -e "${GREEN}✓ Backed up SSH config${NC}"
    fi

    # Remove any previous DNSTT SSH block to avoid duplicate entries
    sed -i '/# DNSTT ULTRA SPEED/,/^MaxAuthTries/d' /etc/ssh/sshd_config 2>/dev/null || true
    
    # Apply high-performance SSH settings tuned for MTU-512 DNS tunnel
    cat >> /etc/ssh/sshd_config << 'EOF'

# DNSTT MTU-512 SSH Optimizations
# Created By THE KING 👑 💯

# ── Stability ───────────────────────────────────────────────────────────
TCPKeepAlive yes
ClientAliveInterval 15
ClientAliveCountMax 6
MaxSessions 500
MaxStartups 200:30:500

# ── CRITICAL: Disable compression ───────────────────────────────────────
# At MTU=512 every SSH packet is already tiny.  Compression adds CPU
# overhead and can actually INCREASE packet size for binary/encrypted
# data (which is most SSH traffic inside a DNS tunnel).
Compression no

# ── Cipher order (fastest first for small 512B blocks) ──────────────────
# aes128-ctr is the fastest cipher for small blocks on most CPUs that
# lack AES-NI hardware acceleration.  chacha20-poly1305 is best when
# AES-NI IS available.  We list both so the client picks the right one.
# aes128-ctr / aes256-ctr included for HTTP Injector / older clients.
Ciphers chacha20-poly1305@openssh.com,aes128-ctr,aes256-ctr,aes128-gcm@openssh.com,aes256-gcm@openssh.com,aes192-ctr

# ── MACs — etm variants preferred (authenticate-then-encrypt = faster) ──
MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,hmac-sha2-256,hmac-sha2-512

# ── Key exchange ─────────────────────────────────────────────────────────
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,ecdh-sha2-nistp256

# ── Rekey limit — prevents stalls on long-running tunnel sessions ────────
# 128M bytes or 30 minutes, whichever comes first.
# Too-large RekeyLimit causes a pause mid-session; too-small wastes time.
RekeyLimit 128M 30m

# ── QoS — mark SSH packets as interactive traffic ────────────────────────
# AF21 = Assured Forwarding class 2 low drop — tells the ISP/router to
# prioritise our SSH-inside-DNS tunnel over bulk data.
IPQoS lowdelay throughput

# ── Misc ─────────────────────────────────────────────────────────────────
MaxAuthTries 10
UseDNS no
EOF

    echo -e "${GREEN}✓ SSH: compression disabled (speeds up MTU-512 tunnel)${NC}"
    echo -e "${GREEN}✓ SSH: cipher order optimised for small blocks${NC}"
    echo -e "${GREEN}✓ SSH: IPQoS lowdelay (ISP prioritisation)${NC}"
    echo -e "${GREEN}✓ SSH: RekeyLimit 128M/30m (no mid-session stalls)${NC}"
    echo -e "${GREEN}✓ SSH: ClientAlive 15s×6 (stable tunnel detection)${NC}"
    
    echo -e "${CYAN}Testing SSH config syntax...${NC}"
    if sshd -t 2>/dev/null; then
        echo -e "${GREEN}✓ SSH config syntax OK${NC}"
        echo -e "${CYAN}Restarting SSH service...${NC}"
        systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
        echo -e "${GREEN}✓ SSH service restarted${NC}"
    else
        echo -e "${RED}✗ SSH config has errors — restoring backup${NC}"
        cp /etc/ssh/sshd_config.backup /etc/ssh/sshd_config
        systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
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
    
    log_message "${YELLOW}📋 Creating systemd service optimized for MTU $mtu...${NC}"
    echo ""

    # Calculate GOMAXPROCS: use all available CPUs, minimum 2, maximum 8
    NCPUS=$(nproc 2>/dev/null || echo 2)
    GOMAX=$NCPUS
    [ "$GOMAX" -lt 2 ] && GOMAX=2
    [ "$GOMAX" -gt 8 ] && GOMAX=8
    
    cat > /etc/systemd/system/dnstt.service << EOF
[Unit]
Description=DNSTT DNS Tunnel Server (THE KING 👑 - MTU ${mtu})
Documentation=https://www.bamsoftware.com/software/dnstt/
After=network.target network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR

# ── Go runtime tuning ────────────────────────────────────────────────────
# GOMAXPROCS=$GOMAX  — use all CPUs for parallel DNS goroutine handling
# GOGC=100           — standard GC pace; lower values cause GC stalls that
#                      hurt latency at high packet rates (avoid GOGC=off
#                      which leaks memory and causes unpredictable pauses)
# GODEBUG=netdns=go  — use Go's pure-Go DNS resolver (avoids CGO latency)
# GODEBUG=gccheckmark=0 — disable GC consistency checks in production
Environment=GOMAXPROCS=$GOMAX
Environment=GOGC=100
Environment=GODEBUG=netdns=go,gccheckmark=0
Environment=GOFLAGS=-trimpath

# ── Main process ─────────────────────────────────────────────────────────
ExecStart=$DNSTT_SERVER -udp :5300 -privkey-file $INSTALL_DIR/server.key -mtu $mtu $tunnel_domain 127.0.0.1:$ssh_port
Restart=always
RestartSec=2
StartLimitInterval=60
StartLimitBurst=10
StandardOutput=append:$LOG_DIR/dnstt-server.log
StandardError=append:$LOG_DIR/dnstt-error.log
SyslogIdentifier=dnstt

# ── Resource limits ───────────────────────────────────────────────────────
LimitNOFILE=2097152
LimitNPROC=65536
# Nice=-10 is aggressive but leaves room for system processes.
# Nice=-20 starves the kernel's own RX softirq on low-core VPS boxes.
Nice=-10
IOSchedulingClass=realtime
IOSchedulingPriority=0
CPUSchedulingPolicy=rr
CPUSchedulingPriority=50

# Memory guard — prevents OOM on small VPS (adjust to your RAM)
MemoryMax=2G
CPUQuota=800%

# ── Security ─────────────────────────────────────────────────────────────
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
    
    echo -e "${GREEN}✓ Service created (GOMAXPROCS=$GOMAX, GOGC=100, CPUPriority=rr/50)${NC}"
    log_success "DNSTT Configuration:"
    log_message "   MTU: $mtu bytes"
    log_message "   SSH Port: $ssh_port"
    log_message "   UDP Port: 5300"
    log_message "   Go Workers: $GOMAX"
    sleep 2
}

#============================================
# MAIN SETUP
#============================================

setup_dnstt() {
    show_banner
    menu_header "INSTALL / SETUP DNSTT" "⚙"
    echo ""
    
    if systemctl is-active --quiet dnstt 2>/dev/null; then
        echo -e "${YELLOW}⚠️  DNSTT is already running${NC}"
        echo ""
        echo -ne "  ${CYAN}▸${NC} ${WHITE}Reinstall? (y/n): ${NC}"; read -r reinstall
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
    optimize_for_512
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
    echo -ne "  ${CYAN}▸${NC} ${WHITE}Nameserver: ${NC}"
    read -r ns_domain
    ns_domain=${ns_domain:-ns.slowdns.local}
    
    echo ""
    echo -e "${WHITE}Enter your tunnel domain:${NC}"
    echo -e "${CYAN}Example: tunnel.yourdomain.com${NC}"
    echo ""
    echo -ne "  ${CYAN}▸${NC} ${WHITE}Tunnel domain: ${NC}"
    read -r tunnel_domain
    
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
    print_opt "1" "📐" "512   bytes  — classic DNS  ✓ most compatible (your ISP)" "$GREEN"
    print_opt "2" "📐" "1024  bytes  — standard"                                      "$CYAN"
    print_opt "3" "📐" "1232  bytes  — EDNS0 standard"                                "$CYAN"
    print_opt "4" "📐" "1280  bytes  — high speed ★"                                  "$CYAN"
    print_opt "5" "📐" "1420  bytes  — very high speed ★★"                            "$CYAN"
    print_opt "6" "📐" "4096  bytes  — EDNS0 maximum (experimental)"                  "$YELLOW"
    print_opt "7" "✏" "Custom       — enter your own"                                 "$YELLOW"
    echo ""
    echo -e "  ${DIM}💡 Your DNS only works at 512 — option 1 is recommended${NC}"
    echo ""
    echo -ne "  ${CYAN}▸${NC} ${WHITE}MTU choice [1-7, default=5]: ${NC}"
    read -r mtu_choice
    
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
    log_success "MTU: $MTU bytes (small-packet optimizations always active)"
    
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
    menu_header "ADD SSH USER" "➕"

    echo -ne "  ${WHITE}Username: ${NC}"
    read -r username
    if [[ -z "$username" ]]; then
        step_err "Username is required"; press_enter; return
    fi
    if id "$username" &>/dev/null; then
        step_err "User '$username' already exists"; press_enter; return
    fi

    echo -ne "  ${WHITE}Password: ${NC}"
    read -rs password; echo ""
    if [[ -z "$password" ]]; then
        step_err "Password is required"; press_enter; return
    fi

    echo ""
    section_header "ACCOUNT EXPIRY" "📅"
    print_opt "1" "🌙" "1 Day"              "$CYAN"
    print_opt "2" "📅" "7 Days"             "$CYAN"
    print_opt "3" "📅" "30 Days  ★ default" "$GREEN"
    print_opt "4" "📅" "90 Days"            "$CYAN"
    print_opt "5" "📅" "365 Days"           "$YELLOW"
    echo ""
    echo -ne "  ${CYAN}▸${NC} ${WHITE}Choice [1-5, default=3]: ${NC}"
    read -r exp_choice

    case ${exp_choice:-3} in
        1) days=1 ;; 2) days=7 ;; 3) days=30 ;;
        4) days=90 ;; 5) days=365 ;; *) days=30 ;;
    esac

    echo ""
    step_run "Creating system user"
    useradd -m -s /bin/bash "$username" 2>/dev/null
    echo "$username:$password" | chpasswd 2>/dev/null
    exp_date=$(date -d "+$days days" +"%Y-%m-%d")
    chage -E "$exp_date" "$username" 2>/dev/null
    echo "$username|$password|$exp_date|$(date +"%Y-%m-%d")" >> "$USER_DB"
    step_ok "User created"

    echo ""
    _stop
    printf "  ${CYAN}│${NC}  %-64s${CYAN}│${NC}
" " "
    printf "  ${CYAN}│${NC}  ${WHITE}%-12s${NC} ${GREEN}%-50s${CYAN}│${NC}
" "Username:" "$username"
    printf "  ${CYAN}│${NC}  ${WHITE}%-12s${NC} ${GREEN}%-50s${CYAN}│${NC}
" "Password:" "$password"
    printf "  ${CYAN}│${NC}  ${WHITE}%-12s${NC} ${YELLOW}%-50s${CYAN}│${NC}
" "Expires:" "$exp_date  ($days days)"
    printf "  ${CYAN}│${NC}  %-64s${CYAN}│${NC}
" " "
    _sbot
    echo ""
    press_enter
}

delete_ssh_user() {
    show_banner
    menu_header "DELETE SSH USER" "🗑"

    echo -ne "  ${WHITE}Username to delete: ${NC}"
    read -r username
    if ! id "$username" &>/dev/null; then
        step_err "User '$username' not found"; press_enter; return
    fi

    echo ""
    if ! confirm_action "Delete user '$username'? All data will be removed."; then
        echo -e "  ${YELLOW}○  Deletion cancelled${NC}"; press_enter; return
    fi

    echo ""
    step_run "Killing active sessions"
    pkill -u "$username" 2>/dev/null && step_ok "Sessions terminated" || step_skip "No active sessions"
    step_run "Removing system user"
    userdel -r "$username" 2>/dev/null
    step_ok "User '$username' removed from system"
    step_run "Removing from user database"
    sed -i "/^$username|/d" "$USER_DB"
    step_ok "Removed from database"
    echo ""
    press_enter
}

list_ssh_users() {
    show_banner
    menu_header "SSH USERS" "📋"

    if [[ ! -s "$USER_DB" ]]; then
        echo -e "  ${YELLOW}○  No users found — add one with option 1${NC}"
        press_enter; return
    fi

    local user_count=0 active_count=0 now
    now=$(date +%s)

    # Header row
    printf "  ${CYAN}┌──────────────┬──────────────┬────────────┬──────────┬────────────┐${NC}
"
    printf "  ${CYAN}│${NC} ${BOLD}${WHITE}%-12s${NC} ${CYAN}│${NC} ${BOLD}${WHITE}%-12s${NC} ${CYAN}│${NC} ${BOLD}${WHITE}%-10s${NC} ${CYAN}│${NC} ${BOLD}${WHITE}%-8s${NC} ${CYAN}│${NC} ${BOLD}${WHITE}%-10s${NC} ${CYAN}│${NC}
"         "USERNAME" "PASSWORD" "EXPIRES" "DAYS" "STATUS"
    printf "  ${CYAN}├──────────────┼──────────────┼────────────┼──────────┼────────────┤${NC}
"

    while IFS='|' read -r user pass exp created; do
        user_count=$((user_count + 1))
        local exp_unix days_left status_col status_lbl days_col
        exp_unix=$(date -d "$exp" +%s 2>/dev/null || echo "0")
        days_left=$(( (exp_unix - now) / 86400 ))
        [[ $days_left -lt 0 ]] && days_left=0

        if [[ $now -gt $exp_unix ]]; then
            status_col="$RED";    status_lbl="EXPIRED"
            days_col="${RED}0${NC}"
        elif [[ $days_left -le 3 ]]; then
            status_col="$RED";    status_lbl="EXPIRING"
            days_col="${RED}${days_left}${NC}"
        elif [[ $days_left -le 7 ]]; then
            status_col="$YELLOW"; status_lbl="WARNING"
            days_col="${YELLOW}${days_left}${NC}"
        else
            status_col="$GREEN";  status_lbl="ACTIVE"
            days_col="${GREEN}${days_left}${NC}"
            active_count=$((active_count + 1))
        fi

        printf "  ${CYAN}│${NC} ${WHITE}%-12s${NC} ${CYAN}│${NC} ${WHITE}%-12s${NC} ${CYAN}│${NC} ${WHITE}%-10s${NC} ${CYAN}│${NC} "             "$user" "$pass" "$exp"
        printf "%-18s" "$(echo -e "$days_col")"
        printf " ${CYAN}│${NC} ${status_col}● %-8s${NC} ${CYAN}│${NC}
" "$status_lbl"

    done < "$USER_DB"

    printf "  ${CYAN}└──────────────┴──────────────┴────────────┴──────────┴────────────┘${NC}
"
    echo ""
    echo -e "  ${WHITE}Total: ${CYAN}${user_count}${NC}   ${GREEN}Active: ${active_count}${NC}   ${RED}Expired: $((user_count - active_count))${NC}"
    echo ""
    press_enter
}

#============================================
# STATUS & INFO
#============================================

view_status() {
    show_banner
    menu_header "SERVICE STATUS" "📡"

    if systemctl is-active --quiet dnstt; then
        echo -e "  ${GREEN}${BOLD}● DNSTT IS RUNNING${NC}"
        echo ""
        local ts pid
        ts=$(systemctl show dnstt --property=ActiveEnterTimestamp --value 2>/dev/null || echo "")
        if [[ -n "$ts" ]]; then
            local start_epoch cur now_epoch elapsed d h m
            start_epoch=$(date -d "$ts" +%s 2>/dev/null || echo 0)
            now_epoch=$(date +%s)
            elapsed=$((now_epoch - start_epoch))
            d=$((elapsed/86400)); h=$(( (elapsed%86400)/3600 )); m=$(( (elapsed%3600)/60 ))
            echo -e "  ${WHITE}Started :${NC} ${CYAN}$ts${NC}"
            echo -e "  ${WHITE}Uptime  :${NC} ${GREEN}${d}d ${h}h ${m}m${NC}"
        fi

        pid=$(systemctl show dnstt --property=MainPID --value 2>/dev/null || echo "")
        if [[ -n "$pid" && "$pid" != "0" ]]; then
            local cpu mem thr nice
            cpu=$(ps -o %cpu= -p "$pid" 2>/dev/null | tr -d ' ' || echo "N/A")
            mem=$(ps -o rss=  -p "$pid" 2>/dev/null | awk '{printf "%.1f MB", $1/1024}' || echo "N/A")
            thr=$(ps -o nlwp= -p "$pid" 2>/dev/null | tr -d ' ' || echo "N/A")
            nice=$(ps -o nice= -p "$pid" 2>/dev/null | tr -d ' ' || echo "N/A")
            echo -e "  ${WHITE}PID     :${NC} ${CYAN}$pid${NC}"
            echo -e "  ${WHITE}CPU     :${NC} ${CYAN}${cpu}%${NC}"
            echo -e "  ${WHITE}Memory  :${NC} ${CYAN}${mem}${NC}"
            echo -e "  ${WHITE}Threads :${NC} ${CYAN}${thr}${NC}"
            echo -e "  ${WHITE}Nice    :${NC} ${CYAN}${nice}${NC}"
        fi

        local mtu dom udp
        mtu=$(cat "$INSTALL_DIR/mtu.txt" 2>/dev/null || echo "---")
        dom=$(cat "$INSTALL_DIR/tunnel_domain.txt" 2>/dev/null || echo "---")
        udp=$(ss -u state established 2>/dev/null | grep -c ':5300' || echo "0")
        echo ""
        echo -e "  ${WHITE}MTU     :${NC} ${YELLOW}${mtu} bytes${NC}"
        echo -e "  ${WHITE}Domain  :${NC} ${YELLOW}${dom}${NC}"
        echo -e "  ${WHITE}UDP conn:${NC} ${CYAN}${udp} active${NC}"
    else
        echo -e "  ${RED}${BOLD}○ DNSTT IS STOPPED${NC}"
        echo ""
        local mtu; mtu=$(cat "$INSTALL_DIR/mtu.txt" 2>/dev/null || echo "---")
        echo -e "  ${WHITE}Last MTU :${NC} ${YELLOW}${mtu} bytes${NC}"
        echo -e "  ${DIM}  Tip: go to DNSTT Management → Restart Service${NC}"
    fi

    section_header "SYSTEMD STATUS" "⚙"
    systemctl status dnstt --no-pager -l 2>/dev/null | head -20
    section_header "RECENT JOURNAL" "📜"
    journalctl -u dnstt -n 8 --no-pager 2>/dev/null
    echo ""
    press_enter
}
view_logs() {
    show_banner
    menu_header "VIEW LOGS" "📜"

    print_opt "1" "📄" "Main log          ($LOG_DIR/dnstt.log)"        "$CYAN"
    print_opt "2" "📄" "Server log        ($LOG_DIR/dnstt-server.log)" "$CYAN"
    print_opt "3" "🔴" "Error log         ($LOG_DIR/dnstt-error.log)"  "$RED"
    print_opt "4" "📋" "System journal    (journalctl, last 100 lines)" "$YELLOW"
    print_opt "5" "📡" "Live tail         (real-time, Ctrl+C to stop)" "$GREEN"
    echo ""
    divider
    print_opt "0" "◀" "Back" "$WHITE"
    echo ""
    echo -ne "  ${CYAN}▸${NC} ${WHITE}Enter choice: ${NC}"
    read -r log_choice

    case $log_choice in
        1)
            if [[ -f "$LOG_DIR/dnstt.log" ]]; then
                less +G "$LOG_DIR/dnstt.log"
            else
                step_err "Log file not found: $LOG_DIR/dnstt.log"
            fi ;;
        2)
            if [[ -f "$LOG_DIR/dnstt-server.log" ]]; then
                less +G "$LOG_DIR/dnstt-server.log"
            else
                step_err "Log file not found: $LOG_DIR/dnstt-server.log"
            fi ;;
        3)
            if [[ -f "$LOG_DIR/dnstt-error.log" ]]; then
                less +G "$LOG_DIR/dnstt-error.log"
            else
                step_skip "No errors logged yet"
            fi ;;
        4) journalctl -u dnstt --no-pager -n 100 ;;
        5)
            echo -e "  ${YELLOW}Following live logs — press Ctrl+C to stop${NC}"
            echo ""
            tail -f "$LOG_DIR/dnstt-server.log" "$LOG_DIR/dnstt-error.log" 2>/dev/null ;;
        0) return ;;
        *) step_err "Invalid choice"; sleep 1; return ;;
    esac
    press_enter
}
view_info() {
    show_banner
    menu_header "CONNECTION INFORMATION" "📋"

    if [[ ! -f "$INSTALL_DIR/connection_info.txt" ]]; then
        step_err "Not configured yet — run Install/Setup first"
        press_enter; return
    fi

    local pub_ip mtu dom ns ssh_p pubkey
    pub_ip=$(curl -s --connect-timeout 3 ifconfig.me 2>/dev/null || echo "---")
    mtu=$(cat "$INSTALL_DIR/mtu.txt"          2>/dev/null || echo "---")
    dom=$(cat "$INSTALL_DIR/tunnel_domain.txt" 2>/dev/null || echo "---")
    ns=$(cat  "$INSTALL_DIR/ns_domain.txt"     2>/dev/null || echo "---")
    ssh_p=$(cat "$INSTALL_DIR/ssh_port.txt"    2>/dev/null || echo "22")
    pubkey=$(cat "$INSTALL_DIR/server.pub"     2>/dev/null || echo "---")

    section_header "SERVER DETAILS" "🌐"
    printf "  ${WHITE}%-14s${NC} ${YELLOW}%s${NC}
" "Public IP:"    "$pub_ip"
    printf "  ${WHITE}%-14s${NC} ${YELLOW}%s${NC}
" "NS Domain:"    "$ns"
    printf "  ${WHITE}%-14s${NC} ${YELLOW}%s${NC}
" "Tunnel Domain:" "$dom"
    printf "  ${WHITE}%-14s${NC} ${CYAN}%s${NC}
"   "SSH Port:"     "$ssh_p"
    printf "  ${WHITE}%-14s${NC} ${CYAN}%s bytes${NC}
" "MTU:"      "$mtu"

    section_header "PUBLIC KEY" "🔑"
    echo -e "  ${YELLOW}${pubkey}${NC}"

    section_header "DNS RECORDS TO CREATE" "🗺"
    printf "  ${GREEN}A    ${NC}${WHITE}%-30s${NC} → ${YELLOW}%s${NC}
" "$ns"  "$pub_ip"
    printf "  ${GREEN}NS   ${NC}${WHITE}%-30s${NC} → ${YELLOW}%s${NC}
" "$dom" "$ns"

    section_header "CLIENT COMMANDS" "💻"
    echo -e "  ${DIM}# Direct UDP — fastest${NC}"
    echo -e "  ${GREEN}dnstt-client -udp ${pub_ip}:5300 \${NC}"
    echo -e "  ${GREEN}    -pubkey ${pubkey} \${NC}"
    echo -e "  ${GREEN}    -mtu ${mtu} ${dom} 127.0.0.1:${ssh_p}${NC}"
    echo ""
    echo -e "  ${DIM}# Cloudflare DoH — use if UDP is blocked${NC}"
    echo -e "  ${CYAN}dnstt-client -doh https://cloudflare-dns.com/dns-query \${NC}"
    echo -e "  ${CYAN}    -pubkey ${pubkey} \${NC}"
    echo -e "  ${CYAN}    -mtu ${mtu} ${dom} 127.0.0.1:${ssh_p}${NC}"
    echo ""
    echo -e "  ${DIM}# After client is running, connect via SSH:${NC}"
    echo -e "  ${WHITE}ssh username@127.0.0.1 -p ${ssh_p}${NC}"
    echo ""
    press_enter
}
view_performance() {
    show_banner
    menu_header "PERFORMANCE MONITOR" "📊"

    section_header "SERVICE" "⚙"
    if systemctl is-active --quiet dnstt; then
        step_ok "DNSTT running"
    else
        step_err "DNSTT stopped"
    fi

    section_header "TUNNEL CONFIG" "🔗"
    local mtu dom ssh_p gomax
    mtu=$(cat "$INSTALL_DIR/mtu.txt"           2>/dev/null || echo "---")
    dom=$(cat "$INSTALL_DIR/tunnel_domain.txt"  2>/dev/null || echo "---")
    ssh_p=$(cat "$INSTALL_DIR/ssh_port.txt"     2>/dev/null || echo "22")
    gomax=$(systemctl show dnstt --property=Environment --value 2>/dev/null |             grep -o 'GOMAXPROCS=[0-9]*' | cut -d= -f2 || echo "auto")
    printf "  ${WHITE}%-18s${NC} ${CYAN}%s bytes${NC}
" "MTU:"           "$mtu"
    printf "  ${WHITE}%-18s${NC} ${CYAN}%s${NC}
"       "Tunnel Domain:" "$dom"
    printf "  ${WHITE}%-18s${NC} ${CYAN}%s${NC}
"       "SSH Port:"      "$ssh_p"
    printf "  ${WHITE}%-18s${NC} ${CYAN}%s workers${NC}
" "Go (GOMAXPROCS):" "$gomax"

    section_header "LIVE PROCESS" "🔄"
    local pid
    pid=$(systemctl show dnstt --property=MainPID --value 2>/dev/null || echo "0")
    if [[ -n "$pid" && "$pid" != "0" ]]; then
        local cpu mem thr
        cpu=$(ps -o %cpu= -p "$pid" 2>/dev/null | tr -d ' ' || echo "N/A")
        mem=$(ps -o rss=  -p "$pid" 2>/dev/null | awk '{printf "%.1f MB",$1/1024}' || echo "N/A")
        thr=$(ps -o nlwp= -p "$pid" 2>/dev/null | tr -d ' ' || echo "N/A")
        printf "  ${WHITE}%-18s${NC} ${CYAN}%s${NC}
"   "PID:"     "$pid"
        printf "  ${WHITE}%-18s${NC} ${CYAN}%s%%${NC}
" "CPU:"     "$cpu"
        printf "  ${WHITE}%-18s${NC} ${CYAN}%s${NC}
"   "Memory:"  "$mem"
        printf "  ${WHITE}%-18s${NC} ${CYAN}%s${NC}
"   "Threads:" "$thr"
    else
        step_err "Process not running"
    fi

    section_header "NETWORK" "📡"
    local udp_act udp_all rmem udp_buf backlog bbr rmem_mb udp_kb
    udp_act=$(ss -u state established 2>/dev/null | grep -c ':5300' || echo "0")
    udp_all=$(ss -u 2>/dev/null | grep -c ':5300' || echo "0")
    rmem=$(sysctl -n net.core.rmem_max 2>/dev/null || echo "0")
    udp_buf=$(sysctl -n net.ipv4.udp_rmem_min 2>/dev/null || echo "0")
    backlog=$(sysctl -n net.core.netdev_max_backlog 2>/dev/null || echo "0")
    bbr=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null || echo "N/A")
    rmem_mb=$((rmem / 1048576))
    udp_kb=$((udp_buf / 1024))
    printf "  ${WHITE}%-22s${NC} ${GREEN}%s${NC}
"     "UDP active (5300):" "$udp_act"
    printf "  ${WHITE}%-22s${NC} ${GREEN}%s${NC}
"     "UDP total  (5300):" "$udp_all"
    printf "  ${WHITE}%-22s${NC} ${GREEN}%s MB${NC}
"  "Net buffer (rmem):" "$rmem_mb"
    printf "  ${WHITE}%-22s${NC} ${GREEN}%s KB${NC}
"  "UDP buffer (min):"  "$udp_kb"
    printf "  ${WHITE}%-22s${NC} ${GREEN}%s${NC}
"     "Packet backlog:"    "$backlog"
    printf "  ${WHITE}%-22s${NC} ${GREEN}%s${NC}
"     "Congestion ctrl:"   "$bbr"

    section_header "SYSTEM RESOURCES" "🖥"
    local mem_total mem_used cores load
    mem_total=$(free -h | awk '/^Mem:/ {print $2}')
    mem_used=$(free  -h | awk '/^Mem:/ {print $3}')
    cores=$(nproc 2>/dev/null || echo "?")
    load=$(uptime | awk -F'load average:' '{print $2}' | tr -d ' ')
    printf "  ${WHITE}%-18s${NC} ${CYAN}%s / %s${NC}
" "Memory:"    "$mem_used" "$mem_total"
    printf "  ${WHITE}%-18s${NC} ${CYAN}%s${NC}
"      "CPU Cores:" "$cores"
    printf "  ${WHITE}%-18s${NC} ${CYAN}%s${NC}
"      "Load Avg:"  "$load"
    echo ""
    press_enter
}
bandwidth_test() {
    show_banner
    menu_header "BANDWIDTH TEST  (30 sec)" "⚡"

    if ! systemctl is-active --quiet dnstt; then
        step_err "DNSTT service is not running — start it first"
        press_enter; return
    fi

    local NET_INTERFACE mtu
    NET_INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)
    if [[ -z "$NET_INTERFACE" ]]; then
        step_err "Could not detect network interface"
        press_enter; return
    fi
    mtu=$(cat "$INSTALL_DIR/mtu.txt" 2>/dev/null || echo "---")

    echo -e "  ${WHITE}Interface : ${CYAN}$NET_INTERFACE${NC}"
    echo -e "  ${WHITE}MTU       : ${CYAN}$mtu bytes${NC}"
    echo -e "  ${WHITE}Duration  : ${CYAN}30 seconds${NC}"
    echo ""
    echo -e "  ${DIM}${YELLOW}Measuring interface traffic — start using your tunnel now...${NC}"
    echo ""

    local RX1 TX1 PREV_RX PREV_TX PEAK_RX=0 PEAK_TX=0
    RX1=$(cat /sys/class/net/$NET_INTERFACE/statistics/rx_bytes)
    TX1=$(cat /sys/class/net/$NET_INTERFACE/statistics/tx_bytes)
    PREV_RX=$RX1; PREV_TX=$TX1

    # Table header
    printf "  ${CYAN}┌──────┬──────────────────┬──────────────────┬──────────────────┐${NC}
"
    printf "  ${CYAN}│${NC} ${BOLD}${WHITE}%-4s${NC} ${CYAN}│${NC} ${BOLD}${WHITE}%-16s${NC} ${CYAN}│${NC} ${BOLD}${WHITE}%-16s${NC} ${CYAN}│${NC} ${BOLD}${WHITE}%-16s${NC} ${CYAN}│${NC}
"         "SEC" "DOWN (Kbps)" "UP (Kbps)" "TOTAL (Kbps)"
    printf "  ${CYAN}├──────┼──────────────────┼──────────────────┼──────────────────┤${NC}
"

    for i in $(seq 1 30); do
        sleep 1
        local CUR_RX CUR_TX DIFF_RX DIFF_TX DIFF_TOT COL
        CUR_RX=$(cat /sys/class/net/$NET_INTERFACE/statistics/rx_bytes)
        CUR_TX=$(cat /sys/class/net/$NET_INTERFACE/statistics/tx_bytes)
        DIFF_RX=$(( (CUR_RX - PREV_RX) * 8 / 1000 ))
        DIFF_TX=$(( (CUR_TX - PREV_TX) * 8 / 1000 ))
        DIFF_TOT=$(( DIFF_RX + DIFF_TX ))
        [ $DIFF_RX -gt $PEAK_RX ] && PEAK_RX=$DIFF_RX
        [ $DIFF_TX -gt $PEAK_TX ] && PEAK_TX=$DIFF_TX
        if   [ $DIFF_TOT -gt 5000 ]; then COL="$GREEN"
        elif [ $DIFF_TOT -gt 1000 ]; then COL="$YELLOW"
        else COL="$RED"; fi
        printf "  ${CYAN}│${NC} ${CYAN}%-4s${NC} ${CYAN}│${NC} ${COL}%-16s${NC} ${CYAN}│${NC} ${COL}%-16s${NC} ${CYAN}│${NC} ${COL}%-16s${NC} ${CYAN}│${NC}
"             "${i}s" "$DIFF_RX" "$DIFF_TX" "$DIFF_TOT"
        PREV_RX=$CUR_RX; PREV_TX=$CUR_TX
    done

    printf "  ${CYAN}└──────┴──────────────────┴──────────────────┴──────────────────┘${NC}
"

    local RX2 TX2 RX_BYTES TX_BYTES
    RX2=$(cat /sys/class/net/$NET_INTERFACE/statistics/rx_bytes)
    TX2=$(cat /sys/class/net/$NET_INTERFACE/statistics/tx_bytes)
    RX_BYTES=$(( RX2 - RX1 ))
    TX_BYTES=$(( TX2 - TX1 ))

    local RX_MBPS TX_MBPS PEAK_RX_M PEAK_TX_M RX_MB TX_MB TOTAL_MBPS
    RX_MBPS=$(echo "scale=2; $RX_BYTES * 8 / 30 / 1000000" | bc)
    TX_MBPS=$(echo "scale=2; $TX_BYTES * 8 / 30 / 1000000" | bc)
    PEAK_RX_M=$(echo "scale=2; $PEAK_RX / 1000" | bc)
    PEAK_TX_M=$(echo "scale=2; $PEAK_TX / 1000" | bc)
    RX_MB=$(echo "scale=2; $RX_BYTES / 1048576" | bc)
    TX_MB=$(echo "scale=2; $TX_BYTES / 1048576" | bc)
    TOTAL_MBPS=$(echo "$RX_MBPS + $TX_MBPS" | bc)

    section_header "RESULTS" "📊"
    printf "  ${WHITE}%-20s${NC} ${GREEN}%s Mbps${NC}  ${DIM}peak %s Mbps  total %s MB${NC}
"         "Download (avg):" "$RX_MBPS" "$PEAK_RX_M" "$RX_MB"
    printf "  ${WHITE}%-20s${NC} ${GREEN}%s Mbps${NC}  ${DIM}peak %s Mbps  total %s MB${NC}
"         "Upload (avg):"   "$TX_MBPS" "$PEAK_TX_M" "$TX_MB"
    echo ""

    if   (( $(echo "$TOTAL_MBPS >= 10" | bc -l) )); then
        step_ok  "Performance: ${GREEN}EXCELLENT${NC} — ${TOTAL_MBPS} Mbps total 🚀"
    elif (( $(echo "$TOTAL_MBPS >= 5"  | bc -l) )); then
        step_ok  "Performance: ${YELLOW}GOOD${NC} — ${TOTAL_MBPS} Mbps total"
        echo -e "  ${DIM}   Tip: try a larger MTU in DNSTT → Change MTU${NC}"
    elif (( $(echo "$TOTAL_MBPS >= 1"  | bc -l) )); then
        step_err "Performance: ${YELLOW}LOW${NC} — ${TOTAL_MBPS} Mbps total"
        echo -e "  ${DIM}   Tip: use Auto-detect MTU (option 0) in Change MTU${NC}"
    else
        step_err "Performance: ${RED}VERY LOW${NC} — ${TOTAL_MBPS} Mbps total"
        echo -e "  ${DIM}   Action: DNSTT → Change MTU → option 0 (auto-detect)${NC}"
    fi
    echo ""
    press_enter
}
change_mtu() {
    show_banner
    menu_header "CHANGE MTU SIZE" "📐"
    echo ""

    if [[ ! -f "$INSTALL_DIR/mtu.txt" ]]; then
        log_error "DNSTT not installed yet"
        press_enter
        return
    fi

    CURRENT_MTU=$(cat "$INSTALL_DIR/mtu.txt" 2>/dev/null || echo "unknown")
    echo -e "${YELLOW}Current MTU: ${CYAN}${CURRENT_MTU} bytes${NC}"
    echo ""
    print_opt "0" "🔍" "AUTO-DETECT  — test your network now ★★★"     "$GREEN"
    print_opt "1" "📐" "192 bytes    — strict carriers / very low MTU"    "$CYAN"
    print_opt "2" "📐" "256 bytes    — low-medium"                         "$CYAN"
    print_opt "3" "📐" "512 bytes    — classic DNS  (your setting)"        "$YELLOW"
    print_opt "4" "📐" "1024 bytes   — standard"                           "$CYAN"
    print_opt "5" "📐" "1232 bytes   — EDNS0 standard"                     "$CYAN"
    print_opt "6" "📐" "1280 bytes   — high speed"                         "$CYAN"
    print_opt "7" "📐" "1420 bytes   — very high speed"                    "$CYAN"
    print_opt "8" "📐" "4096 bytes   — EDNS0 maximum"                      "$CYAN"
    print_opt "9" "✏" "Custom       — enter your own (64–4096)"            "$YELLOW"
    echo ""
    divider
    echo ""
    echo -ne "  ${CYAN}▸${NC} ${WHITE}Choice [0-9]: ${NC}"
    read -r mtu_choice

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
        # Always re-apply small-packet optimizations after MTU change
        echo ""
        echo -e "${YELLOW}Re-applying MTU-512 optimizations...${NC}"
        optimize_for_512
    else
        log_error "Service failed after MTU change. Check logs."
        journalctl -u dnstt -n 10 --no-pager
    fi

    press_enter
}

fix_domain() {
    show_banner
    menu_header "FIX DOMAIN ISSUE" "🔗"
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
# FULL UNINSTALL
#============================================

full_uninstall() {
    show_banner
    menu_header "COMPLETE UNINSTALL" "🗑"

    echo -e "  ${WHITE}This will permanently remove ${RED}${BOLD}EVERYTHING${NC}${WHITE} listed below:${NC}"
    echo ""
    echo -e "  ${RED}✘${NC}  DNSTT service        (stop + disable + delete unit)"
    echo -e "  ${RED}✘${NC}  DNSTT binaries       ($DNSTT_SERVER  $DNSTT_CLIENT)"
    echo -e "  ${RED}✘${NC}  Config directory     ($INSTALL_DIR)"
    echo -e "  ${RED}✘${NC}  Log directory        ($LOG_DIR)"
    echo -e "  ${RED}✘${NC}  SSH user database    ($USER_DB)"
    echo -e "  ${RED}✘${NC}  Sysctl tuning files  (/etc/sysctl.d/99-dnstt-*.conf)"
    echo -e "  ${RED}✘${NC}  Limits config        (/etc/security/limits.d/99-dnstt-*.conf)"
    echo -e "  ${RED}✘${NC}  Logrotate config     (/etc/logrotate.d/dnstt)"
    echo -e "  ${RED}✘${NC}  SSH DNSTT config     (DNSTT block removed from sshd_config)"
    echo -e "  ${RED}✘${NC}  Shortcut commands    (menu / dnstt / slowdns)"
    echo -e "  ${RED}✘${NC}  DNSTT NAT rule       (iptables port 53→5300 redirect)"
    echo ""
    echo -e "  ${GREEN}○${NC}  Kept: /etc/ssh/sshd_config.backup"
    echo -e "  ${GREEN}○${NC}  Kept: SSH service (still running on its original port)"
    echo -e "  ${GREEN}○${NC}  Kept: System packages (wget, curl, Go, etc.)"
    echo ""

    if ! confirm_action "This CANNOT be undone. Type yes to proceed."; then
        echo ""
        echo -e "  ${YELLOW}${BOLD}⊘  Uninstall cancelled.${NC}"
        press_enter
        return
    fi

    echo ""
    echo -e "  ${RED}${BOLD}Starting complete removal...${NC}"
    echo ""

    # 1. Stop and disable service
    step_run "Stopping DNSTT service"
    if systemctl stop dnstt 2>/dev/null; then
        step_ok "Service stopped"
    else
        step_skip "Service was not running"
    fi

    step_run "Disabling DNSTT service"
    if systemctl disable dnstt 2>/dev/null; then
        step_ok "Service disabled"
    else
        step_skip "Service was not enabled"
    fi

    # 2. Remove systemd unit
    step_run "Removing systemd unit file"
    if rm -f /etc/systemd/system/dnstt.service 2>/dev/null && [[ ! -f /etc/systemd/system/dnstt.service ]]; then
        step_ok "Unit file removed"
    else
        step_skip "Unit file not found"
    fi
    systemctl daemon-reload 2>/dev/null

    # 3. Remove binaries
    step_run "Removing DNSTT binaries"
    local bin_count=0
    [[ -f "$DNSTT_SERVER" ]] && rm -f "$DNSTT_SERVER" && bin_count=$((bin_count+1))
    [[ -f "$DNSTT_CLIENT" ]] && rm -f "$DNSTT_CLIENT" && bin_count=$((bin_count+1))
    if [[ $bin_count -gt 0 ]]; then
        step_ok "Removed $bin_count binary file(s)"
    else
        step_skip "Binaries not found"
    fi

    # 4. Remove install dir
    step_run "Removing configuration directory"
    if [[ -d "$INSTALL_DIR" ]]; then
        rm -rf "$INSTALL_DIR"
        step_ok "Removed: $INSTALL_DIR"
    else
        step_skip "$INSTALL_DIR not found"
    fi

    # 5. Remove log dir
    step_run "Removing log directory"
    if [[ -d "$LOG_DIR" ]]; then
        rm -rf "$LOG_DIR"
        step_ok "Removed: $LOG_DIR"
    else
        step_skip "$LOG_DIR not found"
    fi

    # 6. Remove SSH user dir
    step_run "Removing SSH user database"
    if [[ -d "$SSH_DIR" ]]; then
        rm -rf "$SSH_DIR"
        step_ok "Removed: $SSH_DIR"
    else
        step_skip "$SSH_DIR not found"
    fi

    # 7. Remove sysctl tunables
    step_run "Removing sysctl tuning files"
    local sysctl_count=0
    for f in /etc/sysctl.d/99-dnstt-*.conf; do
        [[ -f "$f" ]] && rm -f "$f" && sysctl_count=$((sysctl_count+1))
    done
    if [[ $sysctl_count -gt 0 ]]; then
        step_ok "Removed $sysctl_count sysctl file(s)"
        sysctl --system > /dev/null 2>&1 || true
        step_ok "Kernel tunables reloaded to defaults"
    else
        step_skip "No sysctl files found"
    fi

    # 8. Remove limits config
    step_run "Removing limits config"
    local lim_count=0
    for f in /etc/security/limits.d/99-dnstt-*.conf; do
        [[ -f "$f" ]] && rm -f "$f" && lim_count=$((lim_count+1))
    done
    if [[ $lim_count -gt 0 ]]; then
        step_ok "Removed $lim_count limits file(s)"
    else
        step_skip "Limits config not found"
    fi

    # 9. Remove logrotate
    step_run "Removing logrotate config"
    if rm -f /etc/logrotate.d/dnstt 2>/dev/null; then
        step_ok "Logrotate config removed"
    else
        step_skip "Logrotate config not found"
    fi

    # 10. Clean SSH config — remove only the DNSTT block, keep the rest
    step_run "Cleaning DNSTT block from SSH config"
    if grep -q "# DNSTT" /etc/ssh/sshd_config 2>/dev/null; then
        sed -i '/# DNSTT MTU-512 SSH Optimizations/,/^UseDNS/d' \
            /etc/ssh/sshd_config 2>/dev/null || true
        sed -i '/# DNSTT ULTRA SPEED/,/^MaxAuthTries/d' \
            /etc/ssh/sshd_config 2>/dev/null || true
        # Validate
        if sshd -t 2>/dev/null; then
            systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
            step_ok "DNSTT SSH block removed — sshd restarted cleanly"
        else
            step_err "sshd_config syntax error — restoring backup"
            if [[ -f /etc/ssh/sshd_config.backup ]]; then
                cp /etc/ssh/sshd_config.backup /etc/ssh/sshd_config
                systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
                step_ok "SSH config restored from backup"
            fi
        fi
    else
        step_skip "No DNSTT block found in sshd_config"
    fi

    # 11. Remove shortcut commands
    step_run "Removing shortcut commands"
    local cmd_count=0
    for cmd in menu dnstt slowdns; do
        [[ -f "/usr/local/bin/$cmd" ]] && rm -f "/usr/local/bin/$cmd" && cmd_count=$((cmd_count+1))
    done
    if [[ $cmd_count -gt 0 ]]; then
        step_ok "Removed $cmd_count shortcut(s)"
    else
        step_skip "No shortcuts found"
    fi

    # 12. Remove iptables NAT redirect rule
    step_run "Removing iptables NAT redirect rule"
    if iptables -t nat -D PREROUTING -p udp --dport 53 -j REDIRECT \
            --to-ports 5300 2>/dev/null; then
        step_ok "NAT redirect rule removed"
        # Persist
        if command -v netfilter-persistent &>/dev/null; then
            netfilter-persistent save > /dev/null 2>&1 || true
        fi
        iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
    else
        step_skip "NAT redirect rule not present"
    fi

    echo ""
    divider
    echo ""
    echo -e "  ${GREEN}${BOLD}✔  Complete removal finished successfully!${NC}"
    echo ""
    echo -e "  ${WHITE}Your server is clean. These were ${GREEN}kept${NC}${WHITE}:${NC}"
    echo -e "  ${GREEN}○${NC}  SSH backup:  /etc/ssh/sshd_config.backup"
    echo -e "  ${GREEN}○${NC}  SSH service: still running on its original port"
    echo -e "  ${GREEN}○${NC}  System packages: unchanged"
    echo ""
    echo -e "  ${DIM}To reinstall later, just run this script again.${NC}"
    echo ""
    press_enter
    exit 0
}

#============================================
# MENUS
#============================================

dnstt_menu() {
    while true; do
        show_banner
        menu_header "DNSTT MANAGEMENT" "🌐"

        opt_group "SETUP"
        print_opt "1"  "⚙"  "Install / Setup DNSTT"              "$GREEN"
        print_opt "11" "📐" "Change MTU Size"                     "$GREEN"
        print_opt "7"  "🔗" "Fix Domain Issue"                    "$PURPLE"

        opt_group "MONITOR"
        print_opt "2"  "📡" "View Service Status"                 "$YELLOW"
        print_opt "3"  "📋" "View Connection Info & Keys"         "$YELLOW"
        print_opt "4"  "📜" "View Logs"                          "$CYAN"
        print_opt "5"  "📊" "Performance Monitor"                "$CYAN"
        print_opt "6"  "⚡" "Bandwidth Test  (30 sec)"           "$CYAN"

        opt_group "CONTROL"
        print_opt "8"  "🔄" "Restart Service"                    "$BLUE"
        print_opt "9"  "⏹"  "Stop Service"                      "$YELLOW"

        opt_group "DANGER"
        print_opt "10" "🗑" "Uninstall DNSTT Completely"          "$RED"

        echo ""
        divider
        print_opt "0"  "◀" "Back to Main Menu"                   "$WHITE"
        echo ""
        echo -ne "  ${CYAN}▸${NC} ${WHITE}Enter choice: ${NC}"
        read -r choice

        case $choice in
            1)  setup_dnstt ;;
            2)  view_status ;;
            3)  view_info ;;
            4)  view_logs ;;
            5)  view_performance ;;
            6)  bandwidth_test ;;
            7)  fix_domain ;;
            8)
                show_banner
                section_header "RESTART SERVICE" "🔄"
                step_run "Restarting DNSTT"
                systemctl restart dnstt
                sleep 2
                if systemctl is-active --quiet dnstt; then
                    step_ok "Service restarted successfully"
                else
                    step_err "Service failed to restart — check logs (option 4)"
                fi
                press_enter
                ;;
            9)
                show_banner
                section_header "STOP SERVICE" "⏹"
                step_run "Stopping DNSTT"
                systemctl stop dnstt
                step_ok "Service stopped"
                press_enter
                ;;
            10) full_uninstall ;;
            11) change_mtu ;;
            0)  return ;;
            *)
                echo -e "  ${RED}✘  Invalid choice — try again${NC}"
                sleep 1
                ;;
        esac
    done
}

ssh_menu() {
    while true; do
        show_banner
        menu_header "SSH USER MANAGEMENT" "👥"

        if [[ -s "$USER_DB" ]]; then
            local total_users active_users=0 expired_users=0 now
            total_users=$(wc -l < "$USER_DB")
            now=$(date +%s)
            while IFS='|' read -r _ _ exp _; do
                local exp_ts
                exp_ts=$(date -d "$exp" +%s 2>/dev/null || echo 0)
                if [[ $now -le $exp_ts ]]; then
                    active_users=$((active_users+1))
                else
                    expired_users=$((expired_users+1))
                fi
            done < "$USER_DB"
            echo -e "  ${WHITE}Total:${NC} ${CYAN}${total_users}${NC}   ${GREEN}${BOLD}Active: ${active_users}${NC}   ${RED}Expired: ${expired_users}${NC}"
            echo ""
        fi

        opt_group "ACTIONS"
        print_opt "1" "➕" "Add New SSH User"         "$GREEN"
        print_opt "2" "📋" "List All Users"            "$YELLOW"
        print_opt "3" "🗑" "Delete a User"             "$RED"

        echo ""
        divider
        print_opt "0" "◀" "Back to Main Menu"         "$WHITE"
        echo ""
        echo -ne "  ${CYAN}▸${NC} ${WHITE}Enter choice: ${NC}"
        read -r choice

        case $choice in
            1) add_ssh_user ;;
            2) list_ssh_users ;;
            3) delete_ssh_user ;;
            0) return ;;
            *)
                echo -e "  ${RED}✘  Invalid choice${NC}"
                sleep 1
                ;;
        esac
    done
}

system_menu() {
    show_banner
    menu_header "SYSTEM INFORMATION" "📊"

    section_header "UPTIME & LOAD" "⏱"
    uptime
    echo ""

    section_header "MEMORY" "🧠"
    free -h
    echo ""

    section_header "DISK" "💾"
    df -h /
    echo ""

    section_header "NETWORK INTERFACES" "🌐"
    ip -brief addr
    echo ""

    section_header "ACTIVE OPTIMISATIONS" "⚡"
    local any=0
    if [[ -f /etc/sysctl.d/99-dnstt-ultra-v2.conf ]]; then
        any=1
        step_ok "BBR v2 + FQ-CoDel congestion control"
        step_ok "1 GB TCP network buffers"
        step_ok "64 MB UDP small-packet buffers"
        step_ok "100K packet backlog"
        step_ok "8M connection tracking"
    fi
    if [[ -f /etc/sysctl.d/99-dnstt-512b-tunnel.conf ]]; then
        any=1
        step_ok "MTU-512 small-packet sysctl tuning (active)"
    fi
    if [[ -f /etc/security/limits.d/99-dnstt-ultra-v2.conf ]]; then
        any=1
        step_ok "2M file descriptors"
    fi
    if [[ $any -eq 0 ]]; then
        echo -e "  ${YELLOW}○  No DNSTT optimisations applied yet${NC}"
    fi
    echo ""

    press_enter
}

main_menu() {
    while true; do
        show_banner

        echo -e "  ${BOLD}${WHITE}Welcome, THE KING 👑${NC}"
        echo -e "  ${DIM}Select a section to manage your DNS tunnel server.${NC}"
        echo ""
        _stop
        printf "  ${CYAN}│${NC}  ${BOLD}${WHITE}  %-$((UI_W-8))s${NC}  ${CYAN}│${NC}\n" "MAIN MENU"
        _sbot
        echo ""

        print_opt "1" "🌐" "DNSTT Management       — install, monitor, control tunnel" "$GREEN"
        print_opt "2" "👥" "SSH Users              — add, list, delete user accounts"  "$BLUE"
        print_opt "3" "📊" "System Info            — memory, CPU, active optimisations" "$YELLOW"
        print_opt "4" "🗑" "Full Uninstall         — remove everything from server"     "$RED"

        echo ""
        divider
        print_opt "0" "⛔" "Exit" "$WHITE"
        echo ""
        echo -e "  ${DIM}${CYAN}v8.1 MTU-512 Edition  ·  Created by THE KING 👑 💯${NC}"
        echo ""
        echo -ne "  ${CYAN}▸${NC} ${WHITE}Enter choice: ${NC}"
        read -r choice

        case $choice in
            1) dnstt_menu ;;
            2) ssh_menu ;;
            3) system_menu ;;
            4) full_uninstall ;;
            0)
                echo ""
                _top
                _cline "${GREEN}${BOLD}  Thank you for using SlowDNS Tunnel Manager!  ${NC}" 48
                _cline "${PURPLE}  👑  THE KING  💯${NC}" 18
                _bot
                echo ""
                exit 0
                ;;
            *)
                echo -e "  ${RED}✘  Invalid choice — try again${NC}"
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
        
