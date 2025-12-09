#!/bin/bash

# SLOW DNS - Complete DNSTT & SSH Management System
# Version: 3.5.0 - Final Stable Release
# Made by The King 👑👑
# GitHub: https://github.com/Samwelmushi/slowdns-manager

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Configuration
DNSTT_DIR="/etc/dnstt"
SSH_DIR="/etc/slowdns"
BANNER_FILE="$SSH_DIR/banner"
USER_DB="$SSH_DIR/users.txt"
DNSTT_SERVER="/usr/local/bin/dnstt-server"

# Create directories
mkdir -p "$DNSTT_DIR" "$SSH_DIR"

# Create default banner
if [ ! -f "$BANNER_FILE" ]; then
    cat > "$BANNER_FILE" <<'EOF'
═══════════════════════════════════════
    MADE BY THE KING 👑 👑
═══════════════════════════════════════
EOF
fi

# Show banner
show_banner() {
    clear
    echo -e "${CYAN}"
    cat <<'EOF'
  ███████╗██╗      ██████╗ ██╗    ██╗    ██████╗ ███╗   ███╗███████╗
  ██╔════╝██║     ██╔═══██╗██║    ██║    ██╔══██╗████╗ ████║██╔════╝
  ███████╗██║     ██║   ██║██║ █╗ ██║    ██║  ██║██╔████╔██║███████╗
  ╚════██║██║     ██║   ██║██║███╗██║    ██║  ██║██║╚██╔╝██║╚════██║
  ███████║███████╗╚██████╔╝╚███╔███╔╝    ██████╔╝██║ ╚═╝ ██║███████║
  ╚══════╝╚══════╝ ╚═════╝  ╚══╝╚══╝     ╚═════╝ ╚═╝     ╚═╝╚══════╝
EOF
    echo -e "${NC}"
    echo -e "${PURPLE}════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}           DNS Tunnel & SSH Management System v3.5.0${NC}"
    echo -e "${PURPLE}════════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Check root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}❌ Must run as root!${NC}"
        exit 1
    fi
}

# Install Go
install_go() {
    if command -v go &> /dev/null; then
        echo -e "${GREEN}✅ Go already installed${NC}"
        return
    fi
    
    echo -e "${YELLOW}📦 Installing Go...${NC}"
    cd /tmp || exit
    wget -q https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
    rm -rf /usr/local/go
    tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
    rm go1.21.5.linux-amd64.tar.gz
    export PATH=$PATH:/usr/local/go/bin
    echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
    echo -e "${GREEN}✅ Go installed!${NC}"
}

# Install dependencies
install_dependencies() {
    echo -e "${YELLOW}📦 Installing dependencies...${NC}"
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq > /dev/null 2>&1
    apt-get install -y wget curl git build-essential iptables iptables-persistent netfilter-persistent -qq > /dev/null 2>&1
    echo -e "${GREEN}✅ Dependencies installed!${NC}"
}

# Build DNSTT
build_dnstt() {
    echo -e "${YELLOW}🔨 Building DNSTT from source...${NC}"
    
    cd /tmp || exit
    rm -rf dnstt
    
    git clone https://github.com/tladesignz/dnstt.git > /dev/null 2>&1
    cd dnstt/dnstt-server || exit
    
    export PATH=$PATH:/usr/local/go/bin
    /usr/local/go/bin/go build -o "$DNSTT_SERVER" > /dev/null 2>&1
    
    if [ -f "$DNSTT_SERVER" ]; then
        chmod +x "$DNSTT_SERVER"
        echo -e "${GREEN}✅ DNSTT built successfully!${NC}"
    else
        echo -e "${RED}❌ Build failed!${NC}"
        exit 1
    fi
    
    cd ~ || exit
}

# Setup firewall
setup_firewall() {
    echo -e "${YELLOW}🔥 Configuring firewall...${NC}"
    
    IFACE=$(ip route | grep default | awk '{print $5}' | head -1)
    IFACE=${IFACE:-eth0}
    
    if systemctl is-active --quiet systemd-resolved; then
        echo -e "${YELLOW}⚠️  Stopping systemd-resolved...${NC}"
        systemctl stop systemd-resolved > /dev/null 2>&1
        systemctl disable systemd-resolved > /dev/null 2>&1
        rm -f /etc/resolv.conf
        echo "nameserver 8.8.8.8" > /etc/resolv.conf
        echo "nameserver 8.8.4.4" >> /etc/resolv.conf
        chattr +i /etc/resolv.conf > /dev/null 2>&1
    fi
    
    iptables -D INPUT -p udp --dport 5300 -j ACCEPT > /dev/null 2>&1
    iptables -t nat -D PREROUTING -i "$IFACE" -p udp --dport 53 -j REDIRECT --to-ports 5300 > /dev/null 2>&1
    
    iptables -I INPUT -p udp --dport 5300 -j ACCEPT
    iptables -I INPUT -p tcp --dport 22 -j ACCEPT
    iptables -t nat -I PREROUTING -i "$IFACE" -p udp --dport 53 -j REDIRECT --to-ports 5300
    
    ip6tables -I INPUT -p udp --dport 5300 -j ACCEPT > /dev/null 2>&1
    ip6tables -t nat -I PREROUTING -i "$IFACE" -p udp --dport 53 -j REDIRECT --to-ports 5300 > /dev/null 2>&1
    
    netfilter-persistent save > /dev/null 2>&1
    iptables-save > /etc/iptables/rules.v4 2>/dev/null
    
    echo -e "${GREEN}✅ Firewall configured!${NC}"
}

# Generate keys
generate_keys() {
    echo -e "${YELLOW}🔑 Generating keys...${NC}"
    
    cd "$DNSTT_DIR" || exit
    
    "$DNSTT_SERVER" -gen-key -privkey-file server.key -pubkey-file server.pub > /dev/null 2>&1
    
    if [ -f "server.key" ] && [ -f "server.pub" ]; then
        chmod 600 server.key
        chmod 644 server.pub
        echo -e "${GREEN}✅ Keys generated!${NC}"
    else
        echo -e "${RED}❌ Key generation failed!${NC}"
        exit 1
    fi
}

# Setup DNSTT
setup_dnstt() {
    show_banner
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║      DNSTT Setup                       ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    if systemctl is-active --quiet dnstt; then
        echo -e "${YELLOW}⚠️  DNSTT is running!${NC}"
        read -p "Reinstall? (y/n): " reinstall
        if [ "$reinstall" != "y" ]; then
            return
        fi
        systemctl stop dnstt
    fi
    
    install_dependencies
    install_go
    build_dnstt
    setup_firewall
    
    echo ""
    echo -e "${YELLOW}👉 Enter nameserver domain:${NC}"
    echo -e "${CYAN}   Example: ns.yourdomain.com${NC}"
    echo -e "${CYAN}   [Press Enter for: tns.voltran.online]${NC}"
    read -p "Domain: " ns_domain
    
    ns_domain=${ns_domain:-tns.voltran.online}
    
    echo ""
    echo -e "${YELLOW}👉 Enter tunnel subdomain:${NC}"
    echo -e "${CYAN}   Example: t (for t.yourdomain.com)${NC}"
    echo -e "${CYAN}   [Press Enter for: t]${NC}"
    read -p "Subdomain: " subdomain
    
    subdomain=${subdomain:-t}
    
    main_domain=$(echo "$ns_domain" | awk -F. '{print $(NF-1)"."$NF}')
    tunnel_domain="${subdomain}.${main_domain}"
    
    echo "$ns_domain" > "$DNSTT_DIR/domain.txt"
    echo "$tunnel_domain" > "$DNSTT_DIR/tunnel_domain.txt"
    
    echo -e "${GREEN}✅ NS Domain: $ns_domain${NC}"
    echo -e "${GREEN}✅ Tunnel Domain: $tunnel_domain${NC}"
    
    generate_keys
    
    echo ""
    echo -e "${YELLOW}👉 Choose MTU:${NC}"
    echo "  1) 512  - Classic DNS (Custom resolvers)"
    echo "  2) 768  - Extended compatibility"
    echo "  3) 1200 - Standard (Default) ⭐"
    echo "  4) 1232 - EDNS0 standard"
    echo "  5) 1280 - IPv6 minimum"
    echo "  6) 1420 - High performance"
    echo "  7) Custom MTU"
    echo ""
    read -p "Choice [1-7]: " mtu_choice
    
    case $mtu_choice in
        1) MTU=512 ;;
        2) MTU=768 ;;
        3) MTU=1200 ;;
        4) MTU=1232 ;;
        5) MTU=1280 ;;
        6) MTU=1420 ;;
        7)
            read -p "Enter MTU (256-1500): " custom_mtu
            MTU=${custom_mtu:-1200}
            ;;
        *) MTU=1200 ;;
    esac
    
    echo "$MTU" > "$DNSTT_DIR/mtu.txt"
    echo -e "${GREEN}✅ MTU set to: $MTU${NC}"
    
    if [ "$MTU" -le 512 ]; then
        echo ""
        echo -e "${YELLOW}⚙️  MTU 512 detected${NC}"
        echo -e "${CYAN}Do you have a custom DNS resolver?${NC}"
        echo "  1) Yes - I have custom DNS"
        echo "  2) No - Using public DNS"
        read -p "Choice: " dns_choice
        
        if [ "$dns_choice" = "1" ]; then
            read -p "Enter DNS IP (e.g., 169.255.187.58): " custom_dns
            if [ -n "$custom_dns" ]; then
                echo "$custom_dns" > "$DNSTT_DIR/custom_dns.txt"
                echo -e "${GREEN}✅ Custom DNS saved: $custom_dns${NC}"
            fi
        fi
    fi
    
    SSH_PORT=$(ss -tlnp 2>/dev/null | grep sshd | awk '{print $4}' | cut -d: -f2 | head -1)
    SSH_PORT=${SSH_PORT:-22}
    echo "$SSH_PORT" > "$DNSTT_DIR/ssh_port.txt"
    
    echo -e "${YELLOW}📝 Creating service...${NC}"
    
    cat > /etc/systemd/system/dnstt.service <<EOF
[Unit]
Description=DNSTT Server
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=$DNSTT_DIR
ExecStart=$DNSTT_SERVER -udp :5300 -privkey-file $DNSTT_DIR/server.key -mtu $MTU $tunnel_domain 127.0.0.1:$SSH_PORT
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable dnstt > /dev/null 2>&1
    systemctl restart dnstt
    
    sleep 3
    
    if systemctl is-active --quiet dnstt; then
        echo -e "${GREEN}✅ Service started!${NC}"
    else
        echo -e "${RED}❌ Service failed!${NC}"
        journalctl -u dnstt -n 20 --no-pager
        read -p "Press [Enter]..."
        return
    fi
    
    PUBLIC_IP=$(curl -s ifconfig.me || curl -s icanhazip.com || hostname -I | awk '{print $1}')
    PUBKEY=$(cat "$DNSTT_DIR/server.pub")
    
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║            ✅ DNSTT INSTALLED SUCCESSFULLY! ✅             ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━ CONNECTION DETAILS ━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${WHITE}📍 Server IP:${NC}      ${YELLOW}$PUBLIC_IP${NC}"
    echo -e "${WHITE}🌐 NS Domain:${NC}      ${YELLOW}$ns_domain${NC}"
    echo -e "${WHITE}🔗 Tunnel Domain:${NC}  ${YELLOW}$tunnel_domain${NC}"
    echo -e "${WHITE}🔑 Public Key:${NC}     ${YELLOW}$PUBKEY${NC}"
    echo -e "${WHITE}🚪 SSH Port:${NC}       ${YELLOW}$SSH_PORT${NC}"
    echo -e "${WHITE}📊 MTU:${NC}            ${YELLOW}$MTU${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}📋 DNS Records (Add to your domain):${NC}"
    echo -e "${GREEN}   A    | $ns_domain | $PUBLIC_IP${NC}"
    echo -e "${GREEN}   NS   | $tunnel_domain | $ns_domain${NC}"
    echo ""
    echo -e "${YELLOW}📱 Client Command:${NC}"
    
    if [ "$MTU" -le 512 ]; then
        custom_dns=$(cat "$DNSTT_DIR/custom_dns.txt" 2>/dev/null)
        if [ -n "$custom_dns" ]; then
            echo -e "${CYAN}   dnstt-client -udp $custom_dns:53 \\${NC}"
        else
            echo -e "${CYAN}   dnstt-client -udp 8.8.8.8:53 \\${NC}"
        fi
        echo -e "${CYAN}     -pubkey $PUBKEY \\${NC}"
        echo -e "${CYAN}     $tunnel_domain 127.0.0.1:8080${NC}"
    else
        echo -e "${CYAN}   dnstt-client -doh https://cloudflare-dns.com/dns-query \\${NC}"
        echo -e "${CYAN}     -pubkey $PUBKEY \\${NC}"
        echo -e "${CYAN}     $tunnel_domain 127.0.0.1:8080${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    cat > "$DNSTT_DIR/connection_info.txt" <<EOF
DNSTT Connection Details
Generated: $(date)

Server IP: $PUBLIC_IP
NS Domain: $ns_domain
Tunnel Domain: $tunnel_domain
Public Key: $PUBKEY
SSH Port: $SSH_PORT
MTU: $MTU

DNS Records:
A    $ns_domain    $PUBLIC_IP
NS   $tunnel_domain    $ns_domain

Client Command:
EOF

    if [ "$MTU" -le 512 ]; then
        custom_dns=$(cat "$DNSTT_DIR/custom_dns.txt" 2>/dev/null)
        if [ -n "$custom_dns" ]; then
            echo "dnstt-client -udp $custom_dns:53 -pubkey $PUBKEY $tunnel_domain 127.0.0.1:8080" >> "$DNSTT_DIR/connection_info.txt"
        else
            echo "dnstt-client -udp 8.8.8.8:53 -pubkey $PUBKEY $tunnel_domain 127.0.0.1:8080" >> "$DNSTT_DIR/connection_info.txt"
        fi
    else
        echo "dnstt-client -doh https://cloudflare-dns.com/dns-query -pubkey $PUBKEY $tunnel_domain 127.0.0.1:8080" >> "$DNSTT_DIR/connection_info.txt"
    fi
    
    echo -e "${GREEN}📄 Saved to: $DNSTT_DIR/connection_info.txt${NC}"
    echo ""
    
    read -p "Press [Enter]..."
}

# Add SSH user
add_ssh_user() {
    show_banner
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         Add SSH User                   ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    read -p "👤 Username: " username
    
    if id "$username" &>/dev/null; then
        echo -e "${RED}❌ User exists!${NC}"
        read -p "Press [Enter]..."
        return
    fi
    
    read -sp "🔒 Password: " password
    echo ""
    
    echo "⏰ Expiration:"
    echo "  1) 1 Day"
    echo "  2) 7 Days"
    echo "  3) 30 Days"
    echo "  4) 90 Days"
    echo "  5) 1 Year"
    echo "  6) Custom"
    read -p "Choice: " exp_choice
    
    case $exp_choice in
        1) days=1 ;;
        2) days=7 ;;
        3) days=30 ;;
        4) days=90 ;;
        5) days=365 ;;
        6) 
            read -p "Days: " days
            days=${days:-30}
            ;;
        *) days=30 ;;
    esac
    
    read -p "🔢 Max connections (default 2): " max_conn
    max_conn=${max_conn:-2}
    
    useradd -m -s /bin/bash "$username" > /dev/null 2>&1
    echo "$username:$password" | chpasswd
    
    exp_date=$(date -d "+$days days" +"%Y-%m-%d")
    chage -E "$exp_date" "$username"
    
    echo "$username|$password|$exp_date|$max_conn|$(date +"%Y-%m-%d")" >> "$USER_DB"
    
    echo ""
    echo -e "${GREEN}✅ User created!${NC}"
    echo -e "${WHITE}Username:${NC} $username"
    echo -e "${WHITE}Password:${NC} $password"
    echo -e "${WHITE}Expires:${NC} $exp_date"
    echo ""
    
    read -p "Press [Enter]..."
}

# Delete user
delete_ssh_user() {
    show_banner
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         Delete SSH User                ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    read -p "👤 Username: " username
    
    if ! id "$username" &>/dev/null; then
        echo -e "${RED}❌ User not found!${NC}"
        read -p "Press [Enter]..."
        return
    fi
    
    pkill -u "$username" > /dev/null 2>&1
    userdel -r "$username" > /dev/null 2>&1
    sed -i "/^$username|/d" "$USER_DB"
    
    echo -e "${GREEN}✅ User deleted!${NC}"
    read -p "Press [Enter]..."
}

# List users
list_ssh_users() {
    show_banner
    echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                 SSH USERS LIST                         ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [ ! -f "$USER_DB" ] || [ ! -s "$USER_DB" ]; then
        echo -e "${YELLOW}📭 No users.${NC}"
    else
        printf "${WHITE}%-15s %-12s %-12s %-10s${NC}\n" "USERNAME" "PASSWORD" "EXPIRES" "STATUS"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        while IFS='|' read -r user pass exp_date max_conn created; do
            today=$(date +%s)
            exp_unix=$(date -d "$exp_date" +%s 2>/dev/null || echo "0")
            
            if [ "$today" -gt "$exp_unix" ]; then
                status="${RED}EXPIRED${NC}"
            else
                status="${GREEN}ACTIVE${NC}"
            fi
            
            printf "${WHITE}%-15s %-12s %-12s${NC} " "$user" "$pass" "$exp_date"
            echo -e "$status"
        done < "$USER_DB"
    fi
    
    echo ""
    read -p "Press [Enter]..."
}

# Edit banner
edit_banner() {
    show_banner
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         Edit Login Banner              ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${YELLOW}Current:${NC}"
    cat "$BANNER_FILE"
    echo ""
    
    echo -e "${YELLOW}New banner (type END when done):${NC}"
    
    > "$BANNER_FILE"
    while IFS= read -r line; do
        [ "$line" = "END" ] && break
        echo "$line" >> "$BANNER_FILE"
    done
    
    echo -e "${GREEN}✅ Updated!${NC}"
    read -p "Press [Enter]..."
}

# View status
view_dnstt_status() {
    show_banner
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         DNSTT Status                   ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    if systemctl is-active --quiet dnstt; then
        echo -e "${GREEN}✅ Status: RUNNING${NC}"
    else
        echo -e "${RED}❌ Status: STOPPED${NC}"
    fi
    
    echo ""
    systemctl status dnstt --no-pager -l | head -20
    
    echo ""
    echo -e "${YELLOW}Recent logs:${NC}"
    journalctl -u dnstt -n 20 --no-pager
    
    echo ""
    read -p "Press [Enter]..."
}

# Change MTU
change_mtu() {
    show_banner
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         Change MTU                     ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    if [ ! -f "$DNSTT_DIR/mtu.txt" ]; then
        echo -e "${RED}❌ Not configured!${NC}"
        read -p "Press [Enter]..."
        return
    fi
    
    current_mtu=$(cat "$DNSTT_DIR/mtu.txt")
    echo -e "${YELLOW}Current MTU: $current_mtu${NC}"
    echo ""
    
    echo "Choose new MTU:"
    echo "  1) 512"
    echo "  2) 768"
    echo "  3) 1200"
    echo "  4) 1232"
    echo "  5) 1280"
    echo "  6) 1420"
    echo "  7) Custom"
    read -p "Choice: " mtu_choice
    
    case $mtu_choice in
        1) NEW_MTU=512 ;;
        2) NEW_MTU=768 ;;
        3) NEW_MTU=1200 ;;
        4) NEW_MTU=1232 ;;
        5) NEW_MTU=1280 ;;
        6) NEW_MTU=1420 ;;
        7)
            read -p "Enter MTU: " custom_mtu
            NEW_MTU=${custom_mtu:-1200}
            ;;
        *)
            echo -e "${RED}❌ Cancelled${NC}"
            sleep 2
            return
            ;;
    esac
    
    echo "$NEW_MTU" > "$DNSTT_DIR/mtu.txt"
    
    tunnel_domain=$(cat "$DNSTT_DIR/tunnel_domain.txt")
    SSH_PORT=$(cat "$DNSTT_DIR/ssh_port.txt")
    
    cat > /etc/systemd/system/dnstt.service <<EOF
[Unit]
Description=DNSTT Server
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=$DNSTT_DIR
ExecStart=$DNSTT_SERVER -udp :5300 -privkey-file $DNSTT_DIR/server.key -mtu $NEW_MTU $tunnel_domain 127.0.0.1:$SSH_PORT
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl restart dnstt
    
    echo ""
    echo -e "${GREEN}✅ MTU changed: $current_mtu → $NEW_MTU${NC}"
    echo ""
    
    read -p "Press [Enter]..."
}

# DNSTT Menu
dnstt_menu() {
    while true; do
        show_banner
        echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║      DNSTT MANAGEMENT                  ║${NC}"
        echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
        echo ""
        echo "  1) Install/Setup DNSTT"
        echo "  2) View Status & Logs"
        echo "  3) View Connection Details"
        echo "  4) Change MTU"
        echo "  5) Restart Service"
        echo "  6) Stop Service"
        echo "  7) Uninstall DNSTT"
        echo "  0) Back"
        echo ""
        read -p "Choice: " choice
        
        case $choice in
            1) setup_dnstt ;;
            2) view_dnstt_status ;;
            3)
                if [ -f "$DNSTT_DIR/connection_info.txt" ]; then
                    show_banner
                    cat "$DNSTT_DIR/connection_info.txt"
                    echo ""
                    read -p "Press [Enter]..."
                else
                    echo -e "${RED}❌ Not configured!${NC}"
                    sleep 2
                fi
                ;;
            4) change_mtu ;;
            5)
                systemctl restart dnstt
                echo -e "${GREEN}✅ Restarted!${NC}"
                sleep 2
                ;;
            6)
                systemctl stop dnstt
                echo -e "${YELLOW}⚠️  Stopped!${NC}"
                sleep 2
                ;;
            7)
                read -p "Uninstall? (y/n): " confirm
                if [ "$confirm" = "y" ]; then
                    systemctl stop dnstt
                    systemctl disable dnstt
                    rm -f /etc/systemd/system/dnstt.service
                    rm -rf "$DNSTT_DIR"
                    rm -f "$DNSTT_SERVER"
                    echo -e "${GREEN}✅ Uninstalled!${NC}"
                    sleep 2
                fi
                ;;
            0) return ;;
            *)
                echo -e "${RED}Invalid!${NC}"
                sleep 1
                ;;
        esac
    done
}

# SSH Menu
ssh_menu() {
    while true; do
        show_banner
        echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║       SSH USER MANAGEMENT              ║${NC}"
        echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
        echo ""
        echo "  1) Add User"
        echo "  2) List Users"
        echo "  3) Delete User"
        echo "  4) Edit Banner"
        echo "  5) Online Users"
        echo "  0) Back"
        echo ""
        read -p "Choice: " choice
        
        case $choice in
            1) add_ssh_user ;;
            2) list_ssh_users ;;
            3) delete_ssh_user ;;
            4) edit_banner ;;
            5)
                show_banner
                echo -e "${CYAN}Online Users:${NC}"
                who
                echo ""
                read -p "Press [Enter]..."
                ;;
            0) return ;;
            *)
                echo -e "${RED}Invalid!${NC}"
                sleep 1
                ;;
        esac
    done
}

# Main menu
main_menu() {
    check_root
    
    while true; do
        show_banner
        echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║            MAIN MENU                   ║${NC}"
        echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
        echo ""
        echo "  1) 🌐 DNSTT Management"
        echo "  2) 👥 SSH User Management"
        echo "  3) 📊 System Info"
        echo "  0) Exit"
        echo ""
        read -p "Choice: " choice
        
        case $choice in
            1) dnstt_menu ;;
            2) ssh_menu ;;
            3)
                show_banner
                echo "System Info:"
                echo ""
                uptime
                echo ""
                free -h
                echo ""
                df -h /
                echo ""
                read -p "Press [Enter]..."
                ;;
            0)
                echo -e "${GREEN}👋 Goodbye!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid!${NC}"
                sleep 1
                ;;
        esac
    done
}

# Start
main_menu