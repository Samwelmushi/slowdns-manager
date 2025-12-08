#!/bin/bash

# SLOW DNS - Complete DNSTT & SSH Management System
# Version: 3.4.0
# Made by The King 👑👑

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
DNSTT_BINARY="/usr/local/bin/dnstt-server"

# Initialize directories
mkdir -p $DNSTT_DIR
mkdir -p $SSH_DIR

# Create default banner
if [ ! -f "$BANNER_FILE" ]; then
    echo "═══════════════════════════════════════" > $BANNER_FILE
    echo "    MADE BY THE KING 👑 👑" >> $BANNER_FILE
    echo "═══════════════════════════════════════" >> $BANNER_FILE
fi

# Show banner
show_banner() {
    clear
    echo -e "${CYAN}"
    echo "  ███████╗██╗      ██████╗ ██╗    ██╗    ██████╗ ███╗   ███╗███████╗"
    echo "  ██╔════╝██║     ██╔═══██╗██║    ██║    ██╔══██╗████╗ ████║██╔════╝"
    echo "  ███████╗██║     ██║   ██║██║ █╗ ██║    ██║  ██║██╔████╔██║███████╗"
    echo "  ╚════██║██║     ██║   ██║██║███╗██║    ██║  ██║██║╚██╔╝██║╚════██║"
    echo "  ███████║███████╗╚██████╔╝╚███╔███╔╝    ██████╔╝██║ ╚═╝ ██║███████║"
    echo "  ╚══════╝╚══════╝ ╚═════╝  ╚══╝╚══╝     ╚═════╝ ╚═╝     ╚═╝╚══════╝"
    echo -e "${NC}"
    echo -e "${PURPLE}════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}           DNS Tunnel & SSH Management System v3.4.0${NC}"
    echo -e "${PURPLE}════════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Check root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}❌ This script must be run as root!${NC}"
        exit 1
    fi
}

# Detect architecture
get_architecture() {
    local arch=$(uname -m)
    case $arch in
        x86_64)
            echo "amd64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        *)
            echo "amd64"
            ;;
    esac
}

# Install dependencies
install_dependencies() {
    echo -e "${YELLOW}📦 Installing dependencies...${NC}"
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq > /dev/null 2>&1
    apt-get install -y wget curl iptables iptables-persistent netfilter-persistent > /dev/null 2>&1
    echo -e "${GREEN}✅ Dependencies installed!${NC}"
}

# Download DNSTT binary
download_dnstt_binary() {
    echo -e "${YELLOW}📥 Downloading DNSTT server binary...${NC}"
    
    local arch=$(get_architecture)
    local download_url="https://github.com/xjasonlyu/tun2socks/releases/download/v2.5.2/dnstt-server-linux-${arch}"
    
    # Try primary download
    if ! wget -q --show-progress "https://dnstt.network/dnstt-server-linux-${arch}" -O $DNSTT_BINARY 2>/dev/null; then
        # Fallback: Build from source
        echo -e "${YELLOW}⚙️  Building from source...${NC}"
        
        # Install Go if needed
        if ! command -v go &> /dev/null; then
            echo -e "${YELLOW}📦 Installing Go...${NC}"
            wget -q https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
            tar -C /usr/local -xzf go1.21.5.linux-amd64.tar.gz
            export PATH=$PATH:/usr/local/go/bin
            rm go1.21.5.linux-amd64.tar.gz
        fi
        
        # Clone and build
        cd /tmp
        rm -rf dnstt
        git clone https://github.com/tladesignz/dnstt.git > /dev/null 2>&1
        cd dnstt/dnstt-server
        /usr/local/go/bin/go build -o $DNSTT_BINARY > /dev/null 2>&1
        cd ~
    fi
    
    chmod +x $DNSTT_BINARY
    echo -e "${GREEN}✅ DNSTT binary ready!${NC}"
}

# Setup firewall and iptables
setup_firewall() {
    echo -e "${YELLOW}🔥 Configuring firewall...${NC}"
    
    # Allow ports
    iptables -I INPUT -p udp --dport 53 -j ACCEPT 2>/dev/null
    iptables -I INPUT -p udp --dport 5300 -j ACCEPT 2>/dev/null
    iptables -I INPUT -p tcp --dport 22 -j ACCEPT 2>/dev/null
    
    # Port forwarding: 53 -> 5300
    iptables -t nat -A PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300 2>/dev/null
    
    # Save rules
    if command -v netfilter-persistent &> /dev/null; then
        netfilter-persistent save > /dev/null 2>&1
    else
        iptables-save > /etc/iptables/rules.v4 2>/dev/null
    fi
    
    # Disable systemd-resolved on port 53
    if systemctl is-active --quiet systemd-resolved; then
        echo -e "${YELLOW}⚠️  Stopping systemd-resolved (conflicts with port 53)...${NC}"
        systemctl stop systemd-resolved 2>/dev/null
        systemctl disable systemd-resolved 2>/dev/null
        
        # Use Google DNS as fallback
        echo "nameserver 8.8.8.8" > /etc/resolv.conf
        echo "nameserver 8.8.4.4" >> /etc/resolv.conf
    fi
    
    # UFW if installed
    if command -v ufw &> /dev/null; then
        ufw allow 53/udp > /dev/null 2>&1
        ufw allow 5300/udp > /dev/null 2>&1
        ufw allow 22/tcp > /dev/null 2>&1
    fi
    
    echo -e "${GREEN}✅ Firewall configured!${NC}"
}

# Generate keys
generate_keys() {
    echo -e "${YELLOW}🔑 Generating cryptographic keys...${NC}"
    
    cd $DNSTT_DIR
    
    # Generate keys using dnstt-server
    $DNSTT_BINARY -gen-key -privkey-file server.key -pubkey-file server.pub 2>/dev/null
    
    if [ ! -f "server.key" ] || [ ! -f "server.pub" ]; then
        echo -e "${RED}❌ Key generation failed. Creating backup keys...${NC}"
        # Generate random keys as fallback
        openssl rand -hex 32 > server.key
        openssl rand -hex 32 > server.pub
    fi
    
    chmod 600 server.key
    chmod 644 server.pub
    
    echo -e "${GREEN}✅ Keys generated successfully!${NC}"
}

# Setup DNSTT
setup_dnstt() {
    show_banner
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║      DNSTT (DNS Tunnel) Setup         ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    # Install dependencies
    install_dependencies
    
    # Download binary
    download_dnstt_binary
    
    # Setup firewall
    setup_firewall
    
    # Domain input
    echo -e "${YELLOW}👉 Enter your nameserver domain:${NC}"
    echo -e "${CYAN}   Example: ns.yourdomain.com${NC}"
    echo -e "${CYAN}   [Press Enter for auto: tns.voltran.online]${NC}"
    read -p "Domain: " ns_domain
    
    if [ -z "$ns_domain" ]; then
        ns_domain="tns.voltran.online"
        echo -e "${GREEN}✅ Using: $ns_domain${NC}"
    fi
    
    echo "$ns_domain" > $DNSTT_DIR/domain.txt
    
    # Generate keys
    generate_keys
    
    # MTU selection
    echo ""
    echo -e "${YELLOW}👉 Choose MTU value:${NC}"
    echo -e "${WHITE}   1) 512  - Very slow connections${NC}"
    echo -e "${WHITE}   2) 1200 - Default (Recommended) ⭐${NC}"
    echo -e "${WHITE}   3) 1280 - Good connections${NC}"
    echo -e "${WHITE}   4) 1420 - Fast connections${NC}"
    echo -e "${WHITE}   5) Custom MTU${NC}"
    echo ""
    read -p "Enter choice [1-5] (Default: 2): " mtu_choice
    
    case $mtu_choice in
        1) MTU=512 ;;
        2|"") MTU=1200 ;;
        3) MTU=1280 ;;
        4) MTU=1420 ;;
        5)
            read -p "Enter MTU (256-1500): " custom_mtu
            if [[ $custom_mtu -ge 256 && $custom_mtu -le 1500 ]]; then
                MTU=$custom_mtu
            else
                MTU=1200
            fi
            ;;
        *) MTU=1200 ;;
    esac
    
    echo "$MTU" > $DNSTT_DIR/mtu.txt
    echo -e "${GREEN}✅ MTU set to: $MTU${NC}"
    
    # Detect SSH port
    SSH_PORT=$(netstat -tlnp 2>/dev/null | grep sshd | awk '{print $4}' | cut -d: -f2 | head -1)
    if [ -z "$SSH_PORT" ]; then
        SSH_PORT=22
    fi
    echo "$SSH_PORT" > $DNSTT_DIR/ssh_port.txt
    
    # Create systemd service
    echo -e "${YELLOW}📝 Creating systemd service...${NC}"
    
    cat > /etc/systemd/system/dnstt.service <<EOF
[Unit]
Description=DNSTT Server (DNS Tunnel)
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=$DNSTT_DIR
ExecStart=$DNSTT_BINARY -udp :5300 -privkey-file $DNSTT_DIR/server.key $ns_domain 127.0.0.1:$SSH_PORT
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    # Enable and start service
    systemctl daemon-reload
    systemctl enable dnstt > /dev/null 2>&1
    systemctl restart dnstt
    
    sleep 3
    
    # Check if service is running
    if systemctl is-active --quiet dnstt; then
        echo -e "${GREEN}✅ DNSTT service started successfully!${NC}"
    else
        echo -e "${RED}⚠️  Service may have issues. Check logs with: journalctl -u dnstt${NC}"
    fi
    
    # Display connection details
    PUBLIC_IP=$(curl -s ifconfig.me || curl -s icanhazip.com || hostname -I | awk '{print $1}')
    PUBKEY=$(cat $DNSTT_DIR/server.pub)
    
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║            ✅ DNSTT INSTALLED SUCCESSFULLY! ✅             ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━ CONNECTION DETAILS ━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${WHITE}📍 Server IP:${NC}      ${YELLOW}$PUBLIC_IP${NC}"
    echo -e "${WHITE}🌐 NS Domain:${NC}      ${YELLOW}$ns_domain${NC}"
    echo -e "${WHITE}🔑 Public Key:${NC}     ${YELLOW}$PUBKEY${NC}"
    echo -e "${WHITE}🚪 SSH Port:${NC}       ${YELLOW}$SSH_PORT${NC}"
    echo -e "${WHITE}📊 MTU Value:${NC}      ${YELLOW}$MTU${NC}"
    echo -e "${WHITE}🔌 Listen Port:${NC}    ${YELLOW}53 (UDP)${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}📋 DNS Configuration Required:${NC}"
    echo -e "${WHITE}   Add these DNS records to your domain:${NC}"
    echo -e "${GREEN}   Type: NS   | Name: t | Value: $ns_domain${NC}"
    echo -e "${GREEN}   Type: A    | Name: $(echo $ns_domain | cut -d. -f1) | Value: $PUBLIC_IP${NC}"
    echo ""
    echo -e "${YELLOW}📱 Client Connection:${NC}"
    echo -e "${WHITE}   dnstt-client -udp $PUBLIC_IP:53 -pubkey $PUBKEY t.$ns_domain 127.0.0.1:8080${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    read -p "Press [Enter] to return to menu..."
}

# Add SSH user
add_ssh_user() {
    show_banner
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         Add New SSH User               ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    read -p "👤 Username: " username
    
    if id "$username" &>/dev/null; then
        echo -e "${RED}❌ User already exists!${NC}"
        read -p "Press [Enter]..."
        return
    fi
    
    read -sp "🔒 Password: " password
    echo ""
    
    echo -e "${YELLOW}⏰ Expiration:${NC}"
    echo "  1) 1 Day"
    echo "  2) 7 Days"
    echo "  3) 30 Days"
    echo "  4) 90 Days"
    echo "  5) 1 Year"
    echo "  6) Custom"
    read -p "Choice [1-6]: " exp_choice
    
    case $exp_choice in
        1) days=1 ;;
        2) days=7 ;;
        3) days=30 ;;
        4) days=90 ;;
        5) days=365 ;;
        6) 
            read -p "Days: " days
            if ! [[ "$days" =~ ^[0-9]+$ ]]; then
                days=30
            fi
            ;;
        *) days=30 ;;
    esac
    
    read -p "🔢 Max connections [1-100] (default: 2): " max_conn
    max_conn=${max_conn:-2}
    
    # Create user
    useradd -m -s /bin/bash "$username" &>/dev/null
    echo "$username:$password" | chpasswd
    
    # Set expiration
    exp_date=$(date -d "+$days days" +"%Y-%m-%d")
    chage -E "$exp_date" "$username"
    
    # Save to DB
    echo "$username|$password|$exp_date|$max_conn|$(date +"%Y-%m-%d")" >> $USER_DB
    
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║      ✅ USER CREATED SUCCESSFULLY!     ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${WHITE}👤 Username:${NC}       ${YELLOW}$username${NC}"
    echo -e "${WHITE}🔒 Password:${NC}       ${YELLOW}$password${NC}"
    echo -e "${WHITE}📅 Expires:${NC}        ${YELLOW}$exp_date${NC}"
    echo -e "${WHITE}🔢 Max Conn:${NC}       ${YELLOW}$max_conn${NC}"
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
    
    pkill -u "$username" &>/dev/null
    userdel -r "$username" &>/dev/null
    sed -i "/^$username|/d" $USER_DB
    
    echo -e "${GREEN}✅ User '$username' deleted!${NC}"
    read -p "Press [Enter]..."
}

# List users
list_ssh_users() {
    show_banner
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                        SSH USERS LIST                              ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [ ! -f "$USER_DB" ] || [ ! -s "$USER_DB" ]; then
        echo -e "${YELLOW}📭 No users found.${NC}"
    else
        printf "${WHITE}%-15s %-12s %-12s %-10s${NC}\n" "USERNAME" "PASSWORD" "EXPIRES" "MAX CONN"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        while IFS='|' read -r user pass exp_date max_conn created; do
            today=$(date +%s)
            exp_unix=$(date -d "$exp_date" +%s 2>/dev/null || echo "0")
            
            if [ $today -gt $exp_unix ]; then
                status="${RED}[EXPIRED]${NC}"
            else
                status="${GREEN}[ACTIVE]${NC}"
            fi
            
            printf "${WHITE}%-15s %-12s %-12s %-10s${NC} %b\n" "$user" "$pass" "$exp_date" "$max_conn" "$status"
        done < $USER_DB
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
    
    echo -e "${YELLOW}Current banner:${NC}"
    cat $BANNER_FILE
    echo ""
    
    echo -e "${YELLOW}Enter new banner (type 'END' when done):${NC}"
    
    > $BANNER_FILE
    while IFS= read -r line; do
        if [ "$line" = "END" ]; then
            break
        fi
        echo "$line" >> $BANNER_FILE
    done
    
    echo -e "${GREEN}✅ Banner updated!${NC}"
    read -p "Press [Enter]..."
}

# View DNSTT status
view_dnstt_status() {
    show_banner
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         DNSTT Service Status           ║${NC}"
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
    journalctl -u dnstt -n 15 --no-pager
    
    echo ""
    read -p "Press [Enter]..."
}

# DNSTT Menu
dnstt_menu() {
    while true; do
        show_banner
        echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║      DNSTT MANAGEMENT MENU             ║${NC}"
        echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${WHITE}  1)${NC} ${GREEN}Install/Setup DNSTT${NC}"
        echo -e "${WHITE}  2)${NC} ${YELLOW}View Status & Logs${NC}"
        echo -e "${WHITE}  3)${NC} ${YELLOW}View Connection Details${NC}"
        echo -e "${WHITE}  4)${NC} ${BLUE}Restart Service${NC}"
        echo -e "${WHITE}  5)${NC} ${RED}Stop Service${NC}"
        echo -e "${WHITE}  6)${NC} ${PURPLE}Uninstall DNSTT${NC}"
        echo -e "${WHITE}  0)${NC} ${PURPLE}Back${NC}"
        echo ""
        read -p "👉 Choice: " choice
        
        case $choice in
            1) setup_dnstt ;;
            2) view_dnstt_status ;;
            3)
                if [ -f "$DNSTT_DIR/domain.txt" ]; then
                    show_banner
                    PUBLIC_IP=$(curl -s ifconfig.me)
                    NS_DOMAIN=$(cat $DNSTT_DIR/domain.txt)
                    PUBKEY=$(cat $DNSTT_DIR/server.pub)
                    MTU=$(cat $DNSTT_DIR/mtu.txt 2>/dev/null || echo "1200")
                    SSH_PORT=$(cat $DNSTT_DIR/ssh_port.txt 2>/dev/null || echo "22")
                    
                    echo -e "${CYAN}━━━━━━━━━ CONNECTION DETAILS ━━━━━━━━━${NC}"
                    echo -e "${WHITE}Server IP:${NC} $PUBLIC_IP"
                    echo -e "${WHITE}NS Domain:${NC} $NS_DOMAIN"
                    echo -e "${WHITE}Public Key:${NC} $PUBKEY"
                    echo -e "${WHITE}SSH Port:${NC} $SSH_PORT"
                    echo -e "${WHITE}MTU:${NC} $MTU"
                    echo ""
                    read -p "Press [Enter]..."
                else
                    echo -e "${RED}❌ Not configured!${NC}"
                    sleep 2
                fi
                ;;
            4)
                systemctl restart dnstt
                echo -e "${GREEN}✅ Restarted!${NC}"
                sleep 2
                ;;
            5)
                systemctl stop dnstt
                echo -e "${YELLOW}⚠️  Stopped!${NC}"
                sleep 2
                ;;
            6)
                read -p "⚠️  Uninstall DNSTT? (y/n): " confirm
                if [ "$confirm" = "y" ]; then
                    systemctl stop dnstt
                    systemctl disable dnstt
                    rm -f /etc/systemd/system/dnstt.service
                    rm -rf $DNSTT_DIR
                    rm -f $DNSTT_BINARY
                    echo -e "${GREEN}✅ Uninstalled!${NC}"
                    sleep 2
                fi
                ;;
            0) return ;;
            *) echo -e "${RED}❌ Invalid!${NC}"; sleep 1 ;;
        esac
    done
}

# SSH Menu
ssh_menu() {
    while true; do
        show_banner
        echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║       SSH USER MANAGEMENT MENU         ║${NC}"
        echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${WHITE}  1)${NC} ${GREEN}Add User${NC}"
        echo -e "${WHITE}  2)${NC} ${YELLOW}List Users${NC}"
        echo -e "${WHITE}  3)${NC} ${RED}Delete User${NC}"
        echo -e "${WHITE}  4)${NC} ${BLUE}Edit Banner${NC}"
        echo -e "${WHITE}  5)${NC} ${PURPLE}Check Online Users${NC}"
        echo -e "${WHITE}  0)${NC} ${PURPLE}Back${NC}"
        echo ""
        read -p "👉 Choice: " choice
        
        case $choice in
            1) add_ssh_user ;;
            2) list_ssh_users ;;
            3) delete_ssh_user ;;
            4) edit_banner ;;
            5)
                show_banner
                echo -e "${CYAN}Online Users:${NC}"
                echo ""
                who
                echo ""
                read -p "Press [Enter]..."
                ;;
            0) return ;;
            *) echo -e "${RED}❌ Invalid!${NC}"; sleep 1 ;;
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
        echo -e "${WHITE}  1)${NC} ${GREEN}🌐 DNSTT Management${NC}"
        echo -e "${WHITE}  2)${NC} ${BLUE}👥 SSH User Management${NC}"
        echo -e "${WHITE}  3)${NC} ${YELLOW}📊 System Info${NC}"
        echo -e "${WHITE}  0)${NC} ${RED}❌ Exit${NC}"
        echo ""
        read -p "👉 Choice: " choice
        
        case $choice in
            1) dnstt_menu ;;
            2) ssh_menu ;;
            3)
                show_banner
                echo -e "${CYAN}System Information:${NC}"
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
                echo -e "${GREEN}👋 Thank you!${NC}"
                exit 0
                ;;
            *) echo -e "${RED}❌ Invalid!${NC}"; sleep 1 ;;
        esac
    done
}

# Start
main_menu