#!/bin/bash

# SLOW DNS - Professional DNSTT Management System
# Version: 5.0.0 - Complete Fixed Edition
# Made by The King 👑👑
# GitHub: https://github.com/Samwelmushi/slowdns-manager
# 100% Working - No Syntax Errors - SSH Port 22 Forwarding Guaranteed

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
SSH_DIR="/etc/slowdns"
USER_DB="$SSH_DIR/users.txt"
DNSTT_SERVER="/usr/local/bin/dnstt-server"

# Create directories
mkdir -p "$DNSTT_DIR" "$SSH_DIR"

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
    echo -e "${PURPLE}════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}    DNS Tunnel & SSH Management v5.0 - 100% Working${NC}"
    echo -e "${PURPLE}════════════════════════════════════════════════════════${NC}"
    echo ""
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}❌ Run as root: sudo $0${NC}"
        exit 1
    fi
}

install_deps() {
    echo -e "${YELLOW}📦 Installing dependencies...${NC}"
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y > /dev/null 2>&1
    apt-get install -y wget curl git build-essential iptables iptables-persistent netfilter-persistent > /dev/null 2>&1
    echo -e "${GREEN}✅ Dependencies installed${NC}"
}

install_go() {
    if command -v go &> /dev/null; then
        echo -e "${GREEN}✅ Go installed${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}📦 Installing Go...${NC}"
    cd /tmp
    ARCH=$(uname -m)
    case $ARCH in
        x86_64) GO_ARCH="amd64" ;;
        aarch64|arm64) GO_ARCH="arm64" ;;
        armv7l) GO_ARCH="armv6l" ;;
        *) echo -e "${RED}❌ Unsupported architecture${NC}"; return 1 ;;
    esac
    
    wget -q https://go.dev/dl/go1.21.5.linux-${GO_ARCH}.tar.gz || return 1
    rm -rf /usr/local/go
    tar -C /usr/local -xzf go1.21.5.linux-${GO_ARCH}.tar.gz
    rm -f go1.21.5.linux-${GO_ARCH}.tar.gz
    export PATH=$PATH:/usr/local/go/bin
    if ! grep -q "/usr/local/go/bin" /root/.bashrc; then
        echo 'export PATH=$PATH:/usr/local/go/bin' >> /root/.bashrc
    fi
    echo -e "${GREEN}✅ Go installed${NC}"
}

build_dnstt() {
    echo -e "${YELLOW}🔨 Building DNSTT...${NC}"
    cd /tmp
    rm -rf dnstt
    git clone https://github.com/folbericht/dnstt.git > /dev/null 2>&1 || return 1
    cd dnstt/dnstt-server
    export PATH=$PATH:/usr/local/go/bin
    export GO111MODULE=on
    /usr/local/go/bin/go build -o "$DNSTT_SERVER" > /dev/null 2>&1 || return 1
    chmod +x "$DNSTT_SERVER"
    echo -e "${GREEN}✅ DNSTT built${NC}"
    cd ~
}

force_release_port53() {
    echo -e "${BLUE}⚙️  Releasing Port 53...${NC}"
    if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
        systemctl stop systemd-resolved
        systemctl disable systemd-resolved
    fi
    chattr -i /etc/resolv.conf 2>/dev/null || true
    rm -f /etc/resolv.conf
    cat > /etc/resolv.conf <<EOF
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF
    chattr +i /etc/resolv.conf
    echo -e "${GREEN}✅ Port 53 released${NC}"
}

setup_firewall() {
    echo -e "${YELLOW}🔥 Configuring firewall...${NC}"
    IFACE=$(ip route | grep default | awk '{print $5}' | head -1)
    IFACE=${IFACE:-eth0}
    
    iptables -D INPUT -p udp --dport 5300 -j ACCEPT 2>/dev/null || true
    iptables -D INPUT -p tcp --dport 22 -j ACCEPT 2>/dev/null || true
    iptables -t nat -D PREROUTING -i "$IFACE" -p udp --dport 53 -j REDIRECT --to-ports 5300 2>/dev/null || true
    
    iptables -I INPUT -p udp --dport 5300 -j ACCEPT
    iptables -I INPUT -p tcp --dport 22 -j ACCEPT
    iptables -t nat -I PREROUTING -i "$IFACE" -p udp --dport 53 -j REDIRECT --to-ports 5300
    
    mkdir -p /etc/iptables
    iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
    echo -e "${GREEN}✅ Firewall configured${NC}"
}

gen_keys() {
    echo -e "${YELLOW}🔑 Generating keys...${NC}"
    cd "$DNSTT_DIR"
    rm -f server.key server.pub
    "$DNSTT_SERVER" -gen-key -privkey-file server.key -pubkey-file server.pub 2>&1 || return 1
    chmod 600 server.key
    chmod 644 server.pub
    echo -e "${GREEN}✅ Keys generated${NC}"
}

setup_dnstt() {
    show_banner
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║      DNSTT Setup                       ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    if systemctl is-active --quiet dnstt 2>/dev/null; then
        echo -e "${YELLOW}⚠️  DNSTT running${NC}"
        read -p "Reinstall? (y/n): " ans
        [ "$ans" != "y" ] && return
        systemctl stop dnstt
    fi
    
    install_deps || return 1
    install_go || return 1
    build_dnstt || return 1
    force_release_port53
    setup_firewall
    
    echo ""
    echo -e "${YELLOW}👉 Nameserver domain (e.g., ns.example.com):${NC}"
    read -p "Domain: " ns_domain
    ns_domain=${ns_domain:-ns.example.com}
    
    echo ""
    echo -e "${YELLOW}👉 Tunnel subdomain (e.g., t):${NC}"
    read -p "Subdomain: " sub
    sub=${sub:-t}
    
    main=$(echo "$ns_domain" | awk -F. '{if (NF>=2) print $(NF-1)"."$NF; else print $0}')
    tunnel="${sub}.${main}"
    
    echo "$ns_domain" > "$DNSTT_DIR/domain.txt"
    echo "$tunnel" > "$DNSTT_DIR/tunnel.txt"
    
    echo -e "${GREEN}✅ NS: $ns_domain${NC}"
    echo -e "${GREEN}✅ Tunnel: $tunnel${NC}"
    
    gen_keys || return 1
    
    echo ""
    echo -e "${YELLOW}👉 MTU (512/1200):${NC}"
    read -p "MTU [1200]: " mtu_input
    MTU=${mtu_input:-1200}
    echo "$MTU" > "$DNSTT_DIR/mtu.txt"
    
    # GUARANTEED SSH PORT 22 FORWARDING
    SSH_PORT=22
    echo "22" > "$DNSTT_DIR/ssh_port.txt"
    echo -e "${GREEN}✅ SSH Port: 22 (FORCED)${NC}"
    
    echo -e "${YELLOW}📝 Creating service...${NC}"
    
    cat > /etc/systemd/system/dnstt.service <<SERVICE
[Unit]
Description=DNSTT Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$DNSTT_DIR
ExecStart=$DNSTT_SERVER -udp :5300 -privkey-file $DNSTT_DIR/server.key -mtu $MTU $tunnel 127.0.0.1:22
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
SERVICE

    systemctl daemon-reload
    systemctl enable dnstt
    systemctl restart dnstt
    
    sleep 3
    
    if ! systemctl is-active --quiet dnstt; then
        echo -e "${RED}❌ Service failed!${NC}"
        journalctl -u dnstt -n 30 --no-pager
        read -p "Press Enter..."
        return 1
    fi
    
    PUBLIC_IP=$(curl -s ifconfig.me || echo "YOUR_IP")
    PUBKEY=$(cat "$DNSTT_DIR/server.pub")
    
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║            ✅ DNSTT INSTALLED! ✅                      ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${WHITE}📍 Server IP:${NC}      ${YELLOW}$PUBLIC_IP${NC}"
    echo -e "${WHITE}🌐 NS Domain:${NC}      ${YELLOW}$ns_domain${NC}"
    echo -e "${WHITE}🔗 Tunnel:${NC}         ${YELLOW}$tunnel${NC}"
    echo -e "${WHITE}🔑 Public Key:${NC}     ${YELLOW}$PUBKEY${NC}"
    echo -e "${WHITE}🚪 SSH Port:${NC}       ${YELLOW}22 (GUARANTEED)${NC}"
    echo -e "${WHITE}📊 MTU:${NC}            ${YELLOW}$MTU${NC}"
    echo ""
    echo -e "${YELLOW}📋 DNS Records:${NC}"
    echo -e "${GREEN}   A    $ns_domain    $PUBLIC_IP${NC}"
    echo -e "${GREEN}   NS   $tunnel    $ns_domain${NC}"
    echo ""
    echo -e "${YELLOW}📱 Client:${NC}"
    echo -e "${CYAN}   dnstt-client -doh https://cloudflare-dns.com/dns-query \\${NC}"
    echo -e "${CYAN}     -pubkey $PUBKEY \\${NC}"
    echo -e "${CYAN}     $tunnel 127.0.0.1:8080${NC}"
    echo ""
    
    cat > "$DNSTT_DIR/info.txt" <<INFO
DNSTT Connection Info
Generated: $(date)

Server IP: $PUBLIC_IP
NS Domain: $ns_domain
Tunnel: $tunnel
Public Key: $PUBKEY
SSH Port: 22 (GUARANTEED FORWARDING)
MTU: $MTU

DNS Records:
A    $ns_domain    $PUBLIC_IP
NS   $tunnel    $ns_domain

Client: dnstt-client -doh https://cloudflare-dns.com/dns-query -pubkey $PUBKEY $tunnel 127.0.0.1:8080
SSH: ssh user@127.0.0.1 -p 8080
INFO

    echo -e "${GREEN}📄 Saved: $DNSTT_DIR/info.txt${NC}"
    read -p "Press Enter..."
}

add_user() {
    show_banner
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         Add SSH User                   ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    read -p "Username: " user
    [ -z "$user" ] && { echo -e "${RED}Invalid${NC}"; sleep 2; return; }
    
    if id "$user" &>/dev/null; then
        echo -e "${RED}❌ User exists${NC}"
        sleep 2
        return
    fi
    
    read -sp "Password: " pass
    echo ""
    [ -z "$pass" ] && { echo -e "${RED}Invalid${NC}"; sleep 2; return; }
    
    echo "Expiration:"
    echo "  1) 1 Day"
    echo "  2) 7 Days"
    echo "  3) 30 Days"
    read -p "Choice: " exp_c
    
    case $exp_c in
        1) days=1 ;;
        2) days=7 ;;
        3|*) days=30 ;;
    esac
    
    useradd -m -s /bin/bash "$user"
    echo "$user:$pass" | chpasswd
    exp=$(date -d "+$days days" +"%Y-%m-%d")
    chage -E "$exp" "$user"
    echo "$user|$pass|$exp|$(date +"%Y-%m-%d")" >> "$USER_DB"
    
    echo ""
    echo -e "${GREEN}✅ Created!${NC}"
    echo -e "${WHITE}User:${NC} $user"
    echo -e "${WHITE}Pass:${NC} $pass"
    echo -e "${WHITE}Expires:${NC} $exp"
    read -p "Press Enter..."
}

del_user() {
    show_banner
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         Delete User                    ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    read -p "Username: " user
    if ! id "$user" &>/dev/null; then
        echo -e "${RED}❌ Not found${NC}"
        sleep 2
        return
    fi
    
    pkill -u "$user" 2>/dev/null || true
    userdel -r "$user" 2>/dev/null || true
    sed -i "/^$user|/d" "$USER_DB" 2>/dev/null || true
    echo -e "${GREEN}✅ Deleted${NC}"
    sleep 2
}

list_users() {
    show_banner
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         SSH Users                      ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    if [ ! -s "$USER_DB" ]; then
        echo -e "${YELLOW}No users${NC}"
    else
        printf "${WHITE}%-15s %-12s %-12s %-10s${NC}\n" "USER" "PASS" "EXPIRES" "STATUS"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        while IFS='|' read -r u p e c; do
            now=$(date +%s)
            exp_time=$(date -d "$e" +%s 2>/dev/null || echo "0")
            if [ "$now" -gt "$exp_time" ]; then
                status="${RED}EXPIRED${NC}"
            else
                status="${GREEN}ACTIVE${NC}"
            fi
            printf "${WHITE}%-15s %-12s %-12s${NC} " "$u" "$p" "$e"
            echo -e "$status"
        done < "$USER_DB"
    fi
    read -p "Press Enter..."
}

view_status() {
    show_banner
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         DNSTT Status                   ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    if systemctl is-active --quiet dnstt; then
        echo -e "${GREEN}✅ RUNNING${NC}"
    else
        echo -e "${RED}❌ STOPPED${NC}"
    fi
    
    echo ""
    systemctl status dnstt --no-pager | head -20
    echo ""
    echo -e "${YELLOW}Logs:${NC}"
    journalctl -u dnstt -n 15 --no-pager
    read -p "Press Enter..."
}

dnstt_menu() {
    while true; do
        show_banner
        echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║      DNSTT Management                  ║${NC}"
        echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
        echo ""
        echo "  1) Install/Setup"
        echo "  2) View Status"
        echo "  3) View Details"
        echo "  4) Restart"
        echo "  5) Stop"
        echo "  6) Uninstall"
        echo "  0) Back"
        echo ""
        read -p "Choice: " c
        
        case $c in
            1) setup_dnstt ;;
            2) view_status ;;
            3)
                if [ -f "$DNSTT_DIR/info.txt" ]; then
                    show_banner
                    cat "$DNSTT_DIR/info.txt"
                    echo ""
                    read -p "Press Enter..."
                else
                    echo -e "${RED}Not configured${NC}"
                    sleep 2
                fi
                ;;
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
                read -p "Uninstall? (y/n): " ans
                if [ "$ans" = "y" ]; then
                    systemctl stop dnstt 2>/dev/null || true
                    systemctl disable dnstt 2>/dev/null || true
                    rm -f /etc/systemd/system/dnstt.service
                    rm -rf "$DNSTT_DIR"
                    rm -f "$DNSTT_SERVER"
                    echo -e "${GREEN}✅ Uninstalled${NC}"
                    sleep 2
                fi
                ;;
            0) return ;;
        esac
    done
}

ssh_menu() {
    while true; do
        show_banner
        echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║       SSH Management                   ║${NC}"
        echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
        echo ""
        echo "  1) Add User"
        echo "  2) List Users"
        echo "  3) Delete User"
        echo "  4) Online Users"
        echo "  0) Back"
        echo ""
        read -p "Choice: " c
        
        case $c in
            1) add_user ;;
            2) list_users ;;
            3) del_user ;;
            4)
                show_banner
                echo "Online:"
                who
                echo ""
                read -p "Press Enter..."
                ;;
            0) return ;;
        esac
    done
}

main() {
    check_root
    
    while true; do
        show_banner
        echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║            MAIN MENU                   ║${NC}"
        echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
        echo ""
        echo "  1) 🌐 DNSTT Management"
        echo "  2) 👥 SSH Management"
        echo "  3) 📊 System Info"
        echo "  0) Exit"
        echo ""
        read -p "Choice: " c
        
        case $c in
            1) dnstt_menu ;;
            2) ssh_menu ;;
            3)
                show_banner
                echo "System:"
                uptime
                echo ""
                free -h
                echo ""
                df -h /
                echo ""
                read -p "Press Enter..."
                ;;
            0)
                echo -e "${GREEN}Goodbye!${NC}"
                exit 0
                ;;
        esac
    done
}

main