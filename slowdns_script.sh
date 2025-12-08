#!/bin/bash

# SLOW DNS - Complete DNSTT & SSH Management System
# Version: 3.4.0
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

# Initialize
mkdir -p $DNSTT_DIR $SSH_DIR

# Create default banner
if [ ! -f "$BANNER_FILE" ]; then
    cat > $BANNER_FILE <<EOF
════════════════════════════════════════
    MADE BY THE KING 👑 👑
════════════════════════════════════════
EOF
fi

# Show banner
show_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
  ███████╗██╗      ██████╗ ██╗    ██╗    ██████╗ ███╗   ██╗███████╗
  ██╔════╝██║     ██╔═══██╗██║    ██║    ██╔══██╗████╗ ████║██╔════╝
  ███████╗██║     ██║   ██║██║ █╗ ██║    ██║  ██║██╔████╔██║███████╗
  ╚════██║██║     ██║   ██║██║███╗██║    ██║  ██║██║╚██╔╝██║╚════██║
  ███████║███████╗╚██████╔╝╚███╔███╔╝    ██████╔╝██║ ╚═╝ ██║███████║
  ╚══════╝╚══════╝ ╚═════╝  ╚══╝╚══╝     ╚═════╝ ╚═╝     ╚═╝╚══════╝
EOF
    echo -e "${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}           DNS Tunnel & SSH Management System v3.4.0${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# Check root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}✖ Must run as root!${NC}"
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
    cd /tmp
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
    apt-get update -qq
    apt-get install -y wget curl git build-essential iptables iptables-persistent netfilter-persistent -qq
    echo -e "${GREEN}✅ Dependencies installed!${NC}"
}

# Build DNSTT from source
build_dnstt() {
    echo -e "${YELLOW}🔨 Building DNSTT from source...${NC}"
    
    cd /tmp
    rm -rf dnstt
    
    # Clone official repository
    git clone https://github.com/tladesignz/dnstt.git
    cd dnstt/dnstt-server
    
    # Build
    export PATH=$PATH:/usr/local/go/bin
    /usr/local/go/bin/go build -o $DNSTT_SERVER
    
    if [ -f "$DNSTT_SERVER" ]; then
        chmod +x $DNSTT_SERVER
        echo -e "${GREEN}✅ DNSTT server built successfully!${NC}"
    else
        echo -e "${RED}✖ Build failed!${NC}"
        exit 1
    fi
    
    cd ~
}

# Setup firewall
setup_firewall() {
    echo -e "${YELLOW}🔥 Configuring firewall...${NC}"
    
    # Get network interface
    IFACE=$(ip route | grep default | awk '{print $5}' | head -1)
    if [ -z "$IFACE" ]; then
        IFACE="eth0"
    fi
    
    # Stop systemd-resolved (conflicts with port 53)
    if systemctl is-active --quiet systemd-resolved; then
        echo -e "${YELLOW}⚠️  Stopping systemd-resolved...${NC}"
        systemctl stop systemd-resolved
        systemctl disable systemd-resolved
        rm -f /etc/resolv.conf
        echo "nameserver 8.8.8.8" > /etc/resolv.conf
        echo "nameserver 8.8.4.4" >> /etc/resolv.conf
        chattr +i /etc/resolv.conf
    fi
    
    # Clear existing rules for these ports
    iptables -D INPUT -p udp --dport 5300 -j ACCEPT 2>/dev/null
    iptables -t nat -D PREROUTING -i $IFACE -p udp --dport 53 -j REDIRECT --to-ports 5300 2>/dev/null
    
    # Add new rules
    iptables -I INPUT -p udp --dport 5300 -j ACCEPT
    iptables -I INPUT -p tcp --dport 22 -j ACCEPT
    iptables -t nat -I PREROUTING -i $IFACE -p udp --dport 53 -j REDIRECT --to-ports 5300
    
    # IPv6
    ip6tables -I INPUT -p udp --dport 5300 -j ACCEPT 2>/dev/null
    ip6tables -t nat -I PREROUTING -i $IFACE -p udp --dport 53 -j REDIRECT --to-ports 5300 2>/dev/null
    
    # Save rules
    netfilter-persistent save 2>/dev/null
    iptables-save > /etc/iptables/rules.v4 2>/dev/null
    
    echo -e "${GREEN}✅ Firewall configured!${NC}"
}

# Generate keys
generate_keys() {
    echo -e "${YELLOW}🔑 Generating cryptographic keys...${NC}"
    
    cd $DNSTT_DIR
    
    # Generate using dnstt-server
    $DNSTT_SERVER -gen-key -privkey-file server.key -pubkey-file server.pub
    
    if [ -f "server.key" ] && [ -f "server.pub" ]; then
        chmod 600 server.key
        chmod 644 server.pub
        echo -e "${GREEN}✅ Keys generated!${NC}"
    else
        echo -e "${RED}✖ Key generation failed!${NC}"
        exit 1
    fi
}

# Setup DNSTT
setup_dnstt() {
    show_banner
    echo -e "${CYAN}╔═══════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║      DNSTT (DNS Tunnel) Setup         ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════╝${NC}"
    echo ""
    
    # Check if already installed
    if systemctl is-active --quiet dnstt; then
        echo -e "${YELLOW}⚠️  DNSTT is already running!${NC}"
        read -p "Reinstall? (y/n): " reinstall
        if [ "$reinstall" != "y" ]; then
            return
        fi
        systemctl stop dnstt
    fi
    
    # Install dependencies
    install_dependencies
    
    # Install Go
    install_go
    
    # Build DNSTT
    build_dnstt
    
    # Setup firewall
    setup_firewall
    
    # Domain input
    echo ""
    echo -e "${YELLOW}👉 Enter your nameserver domain:${NC}"
    echo -e "${CYAN}   Format: ns.yourdomain.com${NC}"
    echo -e "${CYAN}   [Press Enter for: tns.voltran.online]${NC}"
    read -p "Domain: " ns_domain
    
    if [ -z "$ns_domain" ]; then
        ns_domain="tns.voltran.online"
    fi
    
    # Ask for subdomain
    echo ""
    echo -e "${YELLOW}👉 Enter tunnel subdomain (short name):${NC}"
    echo -e "${CYAN}   Example: t (for t.yourdomain.com)${NC}"
    echo -e "${CYAN}   [Press Enter for: t]${NC}"
    read -p "Subdomain: " subdomain
    
    if [ -z "$subdomain" ]; then
        subdomain="t"
    fi
    
    # Extract main domain
    main_domain=$(echo $ns_domain | awk -F. '{print $(NF-1)"."$NF}')
    tunnel_domain="${subdomain}.${main_domain}"
    
    echo "$ns_domain" > $DNSTT_DIR/domain.txt
    echo "$tunnel_domain" > $DNSTT_DIR/tunnel_domain.txt
    
    echo -e "${GREEN}✅ NS Domain: $ns_domain${NC}"
    echo -e "${GREEN}✅ Tunnel Domain: $tunnel_domain${NC}"
    
    # Generate keys
    generate_keys
    
    # MTU selection with advanced options
    echo ""
    echo -e "${YELLOW}👉 Choose MTU (Packet Size):${NC}"
    echo -e "${WHITE}  1) 512  - Classic DNS (For restricted resolvers)${NC}"
    echo -e "${WHITE}  2) 768  - Extended compatibility${NC}"
    echo -e "${WHITE}  3) 1200 - Standard (Default) ⭐${NC}"
    echo -e "${WHITE}  4) 1232 - EDNS0 standard${NC}"
    echo -e "${WHITE}  5) 1280 - IPv6 minimum${NC}"
    echo -e "${WHITE}  6) 1420 - High performance${NC}"
    echo -e "${WHITE}  7) Custom MTU${NC}"
    echo ""
    echo -e "${CYAN}💡 Tip: Use 512 for custom/restricted DNS resolvers${NC}"
    echo -e "${CYAN}💡 Tip: Use 1200+ for public resolvers like Google/Cloudflare${NC}"
    echo ""
    read -p "Choice [1-7]: " mtu_choice
    
    case $mtu_choice in
        1) MTU=512 ;;
        2) MTU=768 ;;
        3|"") MTU=1200 ;;
        4) MTU=1232 ;;
        5) MTU=1280 ;;
        6) MTU=1420 ;;
        7)
            read -p "Enter MTU (256-1500): " custom_mtu
            if [[ $custom_mtu -ge 256 && $custom_mtu -le 1500 ]]; then
                MTU=$custom_mtu
            else
                echo -e "${RED}Invalid! Using 1200${NC}"
                MTU=1200
            fi
            ;;
        *) MTU=1200 ;;
    esac
    
    echo "$MTU" > $DNSTT_DIR/mtu.txt
    echo -e "${GREEN}✅ MTU set to: $MTU bytes${NC}"
    
    # Additional settings for low MTU (512)
    if [ $MTU -le 512 ]; then
        echo ""
        echo -e "${YELLOW}⚙️  Optimizing for low MTU (512)...${NC}"
        
        # Ask about custom DNS resolver
        echo -e "${CYAN}Do you have a custom DNS resolver?${NC}"
        echo "  1) Yes - I have custom DNS (like 169.255.187.58)"
        echo "  2) No - Using public DNS"
        read -p "Choice [1-2]: " dns_choice
        
        if [ "$dns_choice" = "1" ]; then
            read -p "Enter your DNS resolver IP (e.g., 169.255.187.58): " custom_dns
            if [ -n "$custom_dns" ]; then
                echo "$custom_dns" > $DNSTT_DIR/custom_dns.txt
                echo -e "${GREEN}✅ Will optimize for custom DNS: $custom_dns${NC}"
                
                # Add note about query size
                echo ""
                echo -e "${YELLOW}📝 Note for MTU 512:${NC}"
                echo -e "${WHITE}   - Query size: ~200 bytes${NC}"
                echo -e "${WHITE}   - Response size: ~400 bytes${NC}"
                echo -e "${WHITE}   - Bandwidth: Reduced but stable${NC}"
            fi
        fi
    fi
    
    # Detect SSH port
    SSH_PORT=$(ss -tlnp | grep sshd | awk '{print $4}' | cut -d: -f2 | head -1)
    SSH_PORT=${SSH_PORT:-22}
    echo "$SSH_PORT" > $DNSTT_DIR/ssh_port.txt
    
    # Create systemd service with proper MTU handling
    echo -e "${YELLOW}📝 Creating service...${NC}"
    
    # Extra options for low MTU
    EXTRA_OPTS=""
    if [ $MTU -le 512 ]; then
        EXTRA_OPTS="-udp-buffer-size 512"
        echo -e "${YELLOW}⚙️  Using classic DNS mode (512 bytes)${NC}"
    fi
    
    cat > /etc/systemd/system/dnstt.service <<EOF
[Unit]
Description=DNSTT Server (DNS Tunnel)
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=$DNSTT_DIR
ExecStart=$DNSTT_SERVER -udp :5300 -privkey-file $DNSTT_DIR/server.key -mtu $MTU $EXTRA_OPTS $tunnel_domain 127.0.0.1:$SSH_PORT
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal
SyslogIdentifier=dnstt

[Install]
WantedBy=multi-user.target
EOF

    # Start service
    systemctl daemon-reload
    systemctl enable dnstt
    systemctl restart dnstt
    
    sleep 3
    
    # Check status
    if systemctl is-active --quiet dnstt; then
        echo -e "${GREEN}✅ Service started successfully!${NC}"
    else
        echo -e "${RED}✖ Service failed! Check: journalctl -u dnstt${NC}"
        read -p "Press [Enter]..."
        return
    fi
    
    # Display details
    PUBLIC_IP=$(curl -s ifconfig.me || curl -s icanhazip.com)
    PUBKEY=$(cat $DNSTT_DIR/server.pub)
    
    echo ""
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║            ✅ DNSTT INSTALLED SUCCESSFULLY! ✅             ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━ CONNECTION DETAILS ━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${WHITE}🌐 Server IP:${NC}      ${YELLOW}$PUBLIC_IP${NC}"
    echo -e "${WHITE}🌐 NS Domain:${NC}      ${YELLOW}$ns_domain${NC}"
    echo -e "${WHITE}🔗 Tunnel Domain:${NC}  ${YELLOW}$tunnel_domain${NC}"
    echo -e "${WHITE}🔑 Public Key:${NC}     ${YELLOW}$PUBKEY${NC}"
    echo -e "${WHITE}🚪 SSH Port:${NC}       ${YELLOW}$SSH_PORT${NC}"
    echo -e "${WHITE}📊 MTU:${NC}            ${YELLOW}$MTU${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}📋 DNS Configuration (Add to your domain):${NC}"
    echo -e "${GREEN}   A    | $ns_domain | $PUBLIC_IP${NC}"
    echo -e "${GREEN}   NS   | $tunnel_domain | $ns_domain${NC}"
    echo ""
    echo -e "${YELLOW}📱 Client Command:${NC}"
    
    # Show appropriate client command based on MTU
    if [ $MTU -le 512 ]; then
        # For low MTU, recommend direct UDP to custom DNS
        custom_dns=$(cat $DNSTT_DIR/custom_dns.txt 2>/dev/null)
        if [ -n "$custom_dns" ]; then
            echo -e "${WHITE}   # For your custom DNS resolver:${NC}"
            echo -e "${CYAN}   dnstt-client -udp $custom_dns:53 \\${NC}"
            echo -e "${CYAN}     -pubkey $PUBKEY \\${NC}"
            echo -e "${CYAN}     $tunnel_domain 127.0.0.1:8080${NC}"
            echo ""
            echo -e "${WHITE}   # Alternative with Google DNS (slower):${NC}"
            echo -e "${CYAN}   dnstt-client -udp 8.8.8.8:53 \\${NC}"
            echo -e "${CYAN}     -pubkey $PUBKEY \\${NC}"
            echo -e "${CYAN}     $tunnel_domain 127.0.0.1:8080${NC}"
        else
            echo -e "${WHITE}   dnstt-client -udp 8.8.8.8:53 \\${NC}"
            echo -e "${WHITE}     -pubkey $PUBKEY \\${NC}"
            echo -e "${WHITE}     $tunnel_domain 127.0.0.1:8080${NC}"
        fi
    else
        # For normal MTU, use DoH
        echo -e "${WHITE}   dnstt-client -doh https://cloudflare-dns.com/dns-query \\${NC}"
        echo -e "${WHITE}     -pubkey $PUBKEY \\${NC}"
        echo -e "${WHITE}     $tunnel_domain 127.0.0.1:8080${NC}"
        echo ""
        echo -e "${YELLOW}   Alternative DoH resolvers:${NC}"
        echo -e "${CYAN}   - https://dns.google/dns-query${NC}"
        echo -e "${CYAN}   - https://doh.opendns.com/dns-query${NC}"
    fi
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Save to file with MTU-specific instructions
    cat > $DNSTT_DIR/connection_info.txt <<EOF
DNSTT Connection Details
Generated: $(date)
MTU Configuration: $MTU bytes

Server IP: $PUBLIC_IP
NS Domain: $ns_domain
Tunnel Domain: $tunnel_domain
Public Key: $PUBKEY
SSH Port: $SSH_PORT
MTU: $MTU

DNS Records (Add to your domain):
A    $ns_domain    $PUBLIC_IP
NS   $tunnel_domain    $ns_domain

EOF

    # Add client commands based on MTU
    if [ $MTU -le 512 ]; then
        cat >> $DNSTT_DIR/connection_info.txt <<EOF
Client Command (MTU 512 - Direct UDP):
===================================
For custom DNS resolver (169.255.187.58):
dnstt-client -udp 169.255.187.58:53 -pubkey $PUBKEY $tunnel_domain 127.0.0.1:8080

For Google DNS:
dnstt-client -udp 8.8.8.8:53 -pubkey $PUBKEY $tunnel_domain 127.0.0.1:8080

Note: MTU 512 provides maximum compatibility with restricted DNS resolvers
      but will have reduced bandwidth (~50-100 kbps typical)
EOF
    else
        cat >> $DNSTT_DIR/connection_info.txt <<EOF
Client Command (MTU $MTU - DoH/DoT):
===================================
Cloudflare DoH:
dnstt-client -doh https://cloudflare-dns.com/dns-query -pubkey $PUBKEY $tunnel_domain 127.0.0.1:8080

Google DoH:
dnstt-client -doh https://dns.google/dns-query -pubkey $PUBKEY $tunnel_domain 127.0.0.1:8080

Google DoT:
dnstt-client -dot dns.google:853 -pubkey $PUBKEY $tunnel_domain 127.0.0.1:8080

Direct UDP (fallback):
dnstt-client -udp 8.8.8.8:53 -pubkey $PUBKEY $tunnel_domain 127.0.0.1:8080
EOF
    fi
    
    echo -e "${GREEN}📄 Details saved to: $DNSTT_DIR/connection_info.txt${NC}"
    echo ""
    
    read -p "Press [Enter]..."
}

# Add SSH user
add_ssh_user() {
    show_banner
    echo -e "${CYAN}╔═══════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         Add New SSH User               ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════╝${NC}"
    echo ""
    
    read -p "👤 Username: " username
    
    if id "$username" &>/dev/null; then
        echo -e "${RED}✖ User exists!${NC}"
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
    
    # Create user
    useradd -m -s /bin/bash "$username"
    echo "$username:$password" | chpasswd
    
    # Set expiration
    exp_date=$(date -d "+$days days" +"%Y-%m-%d")
    chage -E "$exp_date" "$username"
    
    # Save to DB
    echo "$username|$password|$exp_date|$max_conn|$(date +"%Y-%m-%d")" >> $USER_DB
    
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
    echo -e "${CYAN}╔═══════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         Delete SSH User                ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════╝${NC}"
    echo ""
    
    read -p "👤 Username: " username
    
    if ! id "$username" &>/dev/null; then
        echo -e "${RED}✖ User not found!${NC}"
        read -p "Press [Enter]..."
        return
    fi
    
    pkill -u "$username"
    userdel -r "$username" 2>/dev/null
    sed -i "/^$username|/d" $USER_DB
    
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
        echo -e "${YELLOW}🔭 No users.${NC}"
    else
        printf "${WHITE}%-15s %-12s %-12s %-8s${NC}\n" "USERNAME" "PASSWORD" "EXPIRES" "STATUS"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        while IFS='|' read -r user pass exp_date max_conn created; do
            today=$(date +%s)
            exp_unix=$(date -d "$exp_date" +%s 2>/dev/null || echo "0")
            
            if [ $today -gt $exp_unix ]; then
                status="${RED}EXPIRED${NC}"
            else
                status="${GREEN}ACTIVE${NC}"
            fi
            
            printf "${WHITE}%-15s %-12s %-12s${NC} %b\n" "$user" "$pass" "$exp_date" "$status"
        done < $USER_DB
    fi
    
    echo ""
    read -p "Press [Enter]..."
}

# Edit banner
edit_banner() {
    show_banner
    echo -e "${CYAN}╔═══════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         Edit Login Banner              ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${YELLOW}Current:${NC}"
    cat $BANNER_FILE
    echo ""
    
    echo -e "${YELLOW}New banner (type END when done):${NC}"
    
    > $BANNER_FILE
    while IFS= read -r line; do
        [ "$line" = "END" ] && break
        echo "$line" >> $BANNER_FILE
    done
    
    echo -e "${GREEN}✅ Updated!${NC}"
    read -p "Press [Enter]..."
}

# Test connection with specific MTU
test_mtu_connection() {
    show_banner
    echo -e "${CYAN}╔═══════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         Test MTU Connection            ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════╝${NC}"
    echo ""
    
    if [ ! -f "$DNSTT_DIR/domain.txt" ]; then
        echo -e "${RED}✖ DNSTT not configured!${NC}"
        read -p "Press [Enter]..."
        return
    fi
    
    MTU=$(cat $DNSTT_DIR/mtu.txt 2>/dev/null || echo "1200")
    tunnel_domain=$(cat $DNSTT_DIR/tunnel_domain.txt)
    
    echo -e "${YELLOW}Current MTU: $MTU bytes${NC}"
    echo ""
    echo -e "${YELLOW}Testing DNS resolution...${NC}"
    
    # Test with dig
    echo ""
    echo -e "${CYAN}Test 1: Basic DNS query${NC}"
    dig @8.8.8.8 $tunnel_domain +short
    
    echo ""
    echo -e "${CYAN}Test 2: Check NS records${NC}"
    dig @8.8.8.8 $tunnel_domain NS +short
    
    echo ""
    echo -e "${CYAN}Test 3: Direct server query${NC}"
    PUBLIC_IP=$(curl -s ifconfig.me)
    dig @$PUBLIC_IP $tunnel_domain +short
    
    echo ""
    echo -e "${CYAN}Test 4: Service status${NC}"
    systemctl status dnstt --no-pager | head -10
    
    echo ""
    echo -e "${CYAN}Test 5: Recent errors${NC}"
    journalctl -u dnstt -n 10 --no-pager | grep -i error
    
    echo ""
    echo -e "${YELLOW}💡 Troubleshooting Tips:${NC}"
    if [ $MTU -le 512 ]; then
        echo -e "${WHITE}   - MTU 512 is active (Classic DNS mode)${NC}"
        echo -e "${WHITE}   - Use direct
