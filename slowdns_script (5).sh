#!/bin/bash

# SLOW DNS - Professional DNSTT Management System
# Version: 4.0.0 - Fully Working Edition
# Made by The King 👑👑
# GitHub: https://github.com/Samwelmushi/slowdns-manager

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
BANNER_FILE="$SSH_DIR/banner"
USER_DB="$SSH_DIR/users.txt"
DNSTT_SERVER="/usr/local/bin/dnstt-server"

# Create directories
mkdir -p "$DNSTT_DIR" "$SSH_DIR"

# Banner file
if [ ! -f "$BANNER_FILE" ]; then
    cat > "$BANNER_FILE" <<'BANNER'
═══════════════════════════════════════
    MADE BY THE KING 👑 👑
═══════════════════════════════════════
BANNER
fi

# Show banner
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
    echo -e "${YELLOW}           DNS Tunnel & SSH Management System v4.0.0${NC}"
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

# Install Go
install_go() {
    if command -v go &> /dev/null; then
        echo -e "${GREEN}✅ Go installed${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}📦 Installing Go...${NC}"
    cd /tmp
    wget -q https://go.dev/dl/go1.21.5.linux-amd64.tar.gz || return 1
    rm -rf /usr/local/go
    tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
    rm -f go1.21.5.linux-amd64.tar.gz
    export PATH=$PATH:/usr/local/go/bin
    echo 'export PATH=$PATH:/usr/local/go/bin' >> /root/.bashrc
    echo -e "${GREEN}✅ Go installed${NC}"
    return 0
}

# Install dependencies
install_deps() {
    echo -e "${YELLOW}📦 Installing dependencies...${NC}"
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y > /dev/null 2>&1
    apt-get install -y wget curl git build-essential iptables iptables-persistent netfilter-persistent > /dev/null 2>&1
    echo -e "${GREEN}✅ Dependencies installed${NC}"
}

# Build DNSTT
build_dnstt() {
    echo -e "${YELLOW}🔨 Building DNSTT...${NC}"
    
    cd /tmp
    rm -rf dnstt
    
    if ! git clone https://github.com/tladesignz/dnstt.git > /dev/null 2>&1; then
        echo -e "${RED}❌ Git clone failed${NC}"
        return 1
    fi
    
    cd dnstt/dnstt-server
    
    export PATH=$PATH:/usr/local/go/bin
    export GOPATH=/root/go
    
    if ! /usr/local/go/bin/go build -o "$DNSTT_SERVER" > /dev/null 2>&1; then
        echo -e "${RED}❌ Build failed${NC}"
        return 1
    fi
    
    chmod +x "$DNSTT_SERVER"
    echo -e "${GREEN}✅ DNSTT built${NC}"
    cd ~
    return 0
}

# Setup firewall
setup_firewall() {
    echo -e "${YELLOW}🔥 Configuring firewall...${NC}"
    
    # Get interface
    IFACE=$(ip route | grep default | awk '{print $5}' | head -1)
    IFACE=${IFACE:-eth0}
    
    # Stop systemd-resolved
    if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
        echo -e "${YELLOW}⚠️  Stopping systemd-resolved...${NC}"
        systemctl stop systemd-resolved
        systemctl disable systemd-resolved
        rm -f /etc/resolv.conf
        cat > /etc/resolv.conf <<EOF
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF
        chattr +i /etc/resolv.conf
    fi
    
    # Clear old rules
    iptables -D INPUT -p udp --dport 5300 -j ACCEPT 2>/dev/null || true
    iptables -t nat -D PREROUTING -i "$IFACE" -p udp --dport 53 -j REDIRECT --to-ports 5300 2>/dev/null || true
    
    # Add new rules
    iptables -I INPUT -p udp --dport 5300 -j ACCEPT
    iptables -I INPUT -p tcp --dport 22 -j ACCEPT
    iptables -t nat -I PREROUTING -i "$IFACE" -p udp --dport 53 -j REDIRECT --to-ports 5300
    
    # IPv6
    ip6tables -I INPUT -p udp --dport 5300 -j ACCEPT 2>/dev/null || true
    ip6tables -t nat -I PREROUTING -i "$IFACE" -p udp --dport 53 -j REDIRECT --to-ports 5300 2>/dev/null || true
    
    # Save rules
    netfilter-persistent save > /dev/null 2>&1 || true
    iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
    
    echo -e "${GREEN}✅ Firewall configured${NC}"
}

# Generate keys
gen_keys() {
    echo -e "${YELLOW}🔑 Generating keys...${NC}"
    
    cd "$DNSTT_DIR"
    
    if ! "$DNSTT_SERVER" -gen-key -privkey-file server.key -pubkey-file server.pub; then
        echo -e "${RED}❌ Key generation failed${NC}"
        return 1
    fi
    
    chmod 600 server.key
    chmod 644 server.pub
    echo -e "${GREEN}✅ Keys generated${NC}"
    return 0
}

# Main setup
setup_dnstt() {
    show_banner
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║      DNSTT Setup                       ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    # Check if running
    if systemctl is-active --quiet dnstt 2>/dev/null; then
        echo -e "${YELLOW}⚠️  DNSTT running${NC}"
        read -p "Reinstall? (y/n): " ans
        [ "$ans" != "y" ] && return
        systemctl stop dnstt
    fi
    
    # Install
    install_deps || { echo -e "${RED}Failed to install dependencies${NC}"; return 1; }
    install_go || { echo -e "${RED}Failed to install Go${NC}"; return 1; }
    build_dnstt || { echo -e "${RED}Failed to build DNSTT${NC}"; return 1; }
    setup_firewall
    
    # Domain
    echo ""
    echo -e "${YELLOW}👉 Nameserver domain:${NC}"
    echo -e "${CYAN}   (e.g., ns.yourdomain.com)${NC}"
    echo -e "${CYAN}   [Enter for: tns.voltran.online]${NC}"
    read -p "Domain: " ns_domain
    ns_domain=${ns_domain:-tns.voltran.online}
    
    echo ""
    echo -e "${YELLOW}👉 Tunnel subdomain:${NC}"
    echo -e "${CYAN}   (e.g., t for t.yourdomain.com)${NC}"
    echo -e "${CYAN}   [Enter for: t]${NC}"
    read -p "Subdomain: " sub
    sub=${sub:-t}
    
    # Extract main domain
    main=$(echo "$ns_domain" | awk -F. '{print $(NF-1)"."$NF}')
    tunnel="${sub}.${main}"
    
    echo "$ns_domain" > "$DNSTT_DIR/domain.txt"
    echo "$tunnel" > "$DNSTT_DIR/tunnel.txt"
    
    echo -e "${GREEN}✅ NS: $ns_domain${NC}"
    echo -e "${GREEN}✅ Tunnel: $tunnel${NC}"
    
    # Generate keys
    gen_keys || { echo -e "${RED}Failed to generate keys${NC}"; return 1; }
    
    # MTU
    echo ""
    echo -e "${YELLOW}👉 MTU:${NC}"
    echo "  1) 512  - Classic DNS (custom resolvers)"
    echo "  2) 768"
    echo "  3) 1200 - Standard ⭐"
    echo "  4) 1232"
    echo "  5) 1280"
    echo "  6) 1420"
    echo "  7) Custom"
    read -p "Choice [1-7]: " mtu_c
    
    case $mtu_c in
        1) MTU=512 ;;
        2) MTU=768 ;;
        3|"") MTU=1200 ;;
        4) MTU=1232 ;;
        5) MTU=1280 ;;
        6) MTU=1420 ;;
        7)
            read -p "MTU (256-1500): " c_mtu
            MTU=${c_mtu:-1200}
            ;;
        *) MTU=1200 ;;
    esac
    
    echo "$MTU" > "$DNSTT_DIR/mtu.txt"
    echo -e "${GREEN}✅ MTU: $MTU${NC}"
    
    # Custom DNS for MTU 512
    if [ "$MTU" -le 512 ]; then
        echo ""
        echo -e "${CYAN}Custom DNS resolver?${NC}"
        echo "  1) Yes"
        echo "  2) No"
        read -p "Choice: " dns_c
        
        if [ "$dns_c" = "1" ]; then
            read -p "DNS IP (e.g., 169.255.187.58): " custom_dns
            [ -n "$custom_dns" ] && echo "$custom_dns" > "$DNSTT_DIR/custom_dns.txt"
        fi
    fi
    
    # SSH port
    SSH_PORT=$(ss -tlnp 2>/dev/null | grep sshd | awk '{print $4}' | cut -d: -f2 | head -1)
    SSH_PORT=${SSH_PORT:-22}
    echo "$SSH_PORT" > "$DNSTT_DIR/ssh_port.txt"
    
    # Create service
    echo -e "${YELLOW}📝 Creating service...${NC}"
    
    cat > /etc/systemd/system/dnstt.service <<DNSTT_SERVICE
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

[Install]
WantedBy=multi-user.target
DNSTT_SERVICE

    # Start
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
    
    echo -e "${GREEN}✅ Service started${NC}"
    
    # Display info
    PUBLIC_IP=$(curl -s ifconfig.me || echo "YOUR_SERVER_IP")
    PUBKEY=$(cat "$DNSTT_DIR/server.pub")
    
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║            ✅ DNSTT INSTALLED! ✅                          ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━ DETAILS ━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${WHITE}📍 Server IP:${NC}      ${YELLOW}$PUBLIC_IP${NC}"
    echo -e "${WHITE}🌐 NS Domain:${NC}      ${YELLOW}$ns_domain${NC}"
    echo -e "${WHITE}🔗 Tunnel:${NC}         ${YELLOW}$tunnel${NC}"
    echo -e "${WHITE}🔑 Public Key:${NC}     ${YELLOW}$PUBKEY${NC}"
    echo -e "${WHITE}🚪 SSH Port:${NC}       ${YELLOW}$SSH_PORT${NC}"
    echo -e "${WHITE}📊 MTU:${NC}            ${YELLOW}$MTU${NC}"
    echo ""
    echo -e "${YELLOW}📋 DNS Records:${NC}"
    echo -e "${GREEN}   A    $ns_domain    $PUBLIC_IP${NC}"
    echo -e "${GREEN}   NS   $tunnel    $ns_domain${NC}"
    echo ""
    echo -e "${YELLOW}📱 Client:${NC}"
    
    if [ "$MTU" -le 512 ]; then
        custom_dns=$(cat "$DNSTT_DIR/custom_dns.txt" 2>/dev/null)
        dns_server=${custom_dns:-8.8.8.8}
        echo -e "${CYAN}   dnstt-client -udp $dns_server:53 \\${NC}"
        echo -e "${CYAN}     -pubkey $PUBKEY \\${NC}"
        echo -e "${CYAN}     $tunnel 127.0.0.1:8080${NC}"
    else
        echo -e "${CYAN}   dnstt-client -doh https://cloudflare-dns.com/dns-query \\${NC}"
        echo -e "${CYAN}     -pubkey $PUBKEY \\${NC}"
        echo -e "${CYAN}     $tunnel 127.0.0.1:8080${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Save info
    cat > "$DNSTT_DIR/info.txt" <<INFO
DNSTT Connection Info
Generated: $(date)

Server IP: $PUBLIC_IP
NS Domain: $ns_domain
Tunnel Domain: $tunnel
Public Key: $PUBKEY
SSH Port: $SSH_PORT
MTU: $MTU

DNS Records:
A    $ns_domain    $PUBLIC_IP
NS   $tunnel    $ns_domain

Client Command:
INFO

    if [ "$MTU" -le 512 ]; then
        custom_dns=$(cat "$DNSTT_DIR/custom_dns.txt" 2>/dev/null)
        echo "dnstt-client -udp ${custom_dns:-8.8.8.8}:53 -pubkey $PUBKEY $tunnel 127.0.0.1:8080" >> "$DNSTT_DIR/info.txt"
    else
        echo "dnstt-client -doh https://cloudflare-dns.com/dns-query -pubkey $PUBKEY $tunnel 127.0.0.1:8080" >> "$DNSTT_DIR/info.txt"
    fi
    
    echo -e "${GREEN}📄 Saved: $DNSTT_DIR/info.txt${NC}"
    echo ""
    
    read -p "Press Enter..."
}

# Add user
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
    echo "$user:$pass" | chpasswd
    
    exp=$(date -d "+$days days" +"%Y-%m-%d")
    chage -E "$exp" "$user"
    
    echo "$user|$pass|$exp|2|$(date +"%Y-%m-%d")" >> "$USER_DB"
    
    echo ""
    echo -e "${GREEN}✅ Created!${NC}"
    echo -e "${WHITE}User:${NC} $user"
    echo -e "${WHITE}Pass:${NC} $pass"
    echo -e "${WHITE}Expires:${NC} $exp"
    echo ""
    
    read -p "Press Enter..."
}

# Delete user
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

# List users
list_users() {
    show_banner
    echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                 SSH USERS                              ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [ ! -s "$USER_DB" ]; then
        echo -e "${YELLOW}No users${NC}"
    else
        printf "${WHITE}%-15s %-12s %-12s %-10s${NC}\n" "USER" "PASS" "EXPIRES" "STATUS"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        while IFS='|' read -r u p e m c; do
            now=$(date +%s)
            exp=$(date -d "$e" +%s 2>/dev/null || echo "0")
            
            if [ "$now" -gt "$exp" ]; then
                status="${RED}EXPIRED${NC}"
            else
                status="${GREEN}ACTIVE${NC}"
            fi
            
            printf "${WHITE}%-15s %-12s %-12s${NC} " "$u" "$p" "$e"
            echo -e "$status"
        done < "$USER_DB"
    fi
    
    echo ""
    read -p "Press Enter..."
}

# View status
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
    
    echo ""
    read -p "Press Enter..."
}

# Change MTU
change_mtu() {
    show_banner
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         Change MTU                     ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    [ ! -f "$DNSTT_DIR/mtu.txt" ] && { echo -e "${RED}Not configured${NC}"; sleep 2; return; }
    
    curr=$(cat "$DNSTT_DIR/mtu.txt")
    echo -e "${YELLOW}Current: $curr${NC}"
    echo ""
    
    echo "New MTU:"
    echo "  1) 512"
    echo "  2) 768"
    echo "  3) 1200"
    echo "  4) 1232"
    echo "  5) 1280"
    echo "  6) 1420"
    read -p "Choice: " c
    
    case $c in
        1) new=512 ;;
        2) new=768 ;;
        3) new=1200 ;;
        4) new=1232 ;;
        5) new=1280 ;;
        6) new=1420 ;;
        *) echo -e "${RED}Cancelled${NC}"; sleep 2; return ;;
    esac
    
    echo "$new" > "$DNSTT_DIR/mtu.txt"
    
    tunnel=$(cat "$DNSTT_DIR/tunnel.txt")
    ssh_port=$(cat "$DNSTT_DIR/ssh_port.txt")
    
    cat > /etc/systemd/system/dnstt.service <<SVC
[Unit]
Description=DNSTT Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$DNSTT_DIR
ExecStart=$DNSTT_SERVER -udp :5300 -privkey-file $DNSTT_DIR/server.key -mtu $new $tunnel 127.0.0.1:$ssh_port
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
SVC

    systemctl daemon-reload
    systemctl restart dnstt
    
    echo ""
    echo -e "${GREEN}✅ MTU: $curr → $new${NC}"
    sleep 2
}

# DNSTT menu
dnstt_menu() {
    while true; do
        show_banner
        echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║      DNSTT MANAGEMENT                  ║${NC}"
        echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
        echo ""
        echo "  1) Install/Setup"
        echo "  2) View Status"
        echo "  3) View Details"
        echo "  4) Change MTU"
        echo "  5) Restart"
        echo "  6) Stop"
        echo "  7) Uninstall"
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
            4) change_mtu ;;
            5)
                systemctl restart dnstt
                echo -e "${GREEN}✅ Restarted${NC}"
                sleep 2
                ;;
            6)
                systemctl stop dnstt
                echo -e "${YELLOW}⚠️  Stopped${NC}"
                sleep 2
                ;;
            7)
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

# SSH menu
ssh_menu() {
    while true; do
        show_banner
        echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║       SSH MANAGEMENT                   ║${NC}"
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

# Main
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