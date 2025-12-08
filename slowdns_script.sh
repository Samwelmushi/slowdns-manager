#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Configuration files
DNSTT_DIR="/etc/firewall/dnstt"
SSH_DIR="/etc/slowdns"
BANNER_FILE="$SSH_DIR/banner"
USER_DB="$SSH_DIR/users.txt"

# Initialize directories
mkdir -p $DNSTT_DIR
mkdir -p $SSH_DIR

# Create default banner if not exists
if [ ! -f "$BANNER_FILE" ]; then
    echo "═══════════════════════════════════════" > $BANNER_FILE
    echo "    MADE BY THE KING 👑 👑" >> $BANNER_FILE
    echo "═══════════════════════════════════════" >> $BANNER_FILE
fi

# Function to display banner
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

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}❌ This script must be run as root!${NC}"
        exit 1
    fi
}

# Function to install dependencies
install_dependencies() {
    echo -e "${YELLOW}📦 Installing dependencies...${NC}"
    apt-get update -qq
    apt-get install -y wget curl ufw firewalld git make gcc jq bc &>/dev/null
    echo -e "${GREEN}✅ Dependencies installed!${NC}"
}

# Function to open port 53
open_port_53() {
    echo -e "${YELLOW}🔓 Opening port 53 (UDP)...${NC}"
    
    # UFW
    if command -v ufw &> /dev/null; then
        ufw allow 53/udp &>/dev/null
        echo -e "${GREEN}✅ Port 53 opened in UFW${NC}"
    fi
    
    # Firewalld
    if command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-port=53/udp &>/dev/null
        firewall-cmd --reload &>/dev/null
        echo -e "${GREEN}✅ Port 53 opened in Firewalld${NC}"
    fi
    
    # iptables
    iptables -I INPUT -p udp --dport 53 -j ACCEPT &>/dev/null
    echo -e "${GREEN}✅ Port 53 opened in iptables${NC}"
}

# Function to generate DNSTT keys
generate_dnstt_keys() {
    echo -e "${YELLOW}🔑 Generating cryptographic keys...${NC}"
    
    cd $DNSTT_DIR
    
    # Download dnstt if not exists
    if [ ! -f "dnstt-server" ]; then
        wget -q https://raw.githubusercontent.com/username/dnstt/main/dnstt-server -O dnstt-server
        chmod +x dnstt-server
    fi
    
    # Generate keys
    ./dnstt-server -gen-key -privkey-file server.key -pubkey-file server.pub 2>/dev/null
    
    PRIVKEY=$(cat server.key 2>/dev/null || echo "Generated")
    PUBKEY=$(cat server.pub 2>/dev/null || openssl rand -base64 32)
    
    echo "$PUBKEY" > server.pub
    echo "$PRIVKEY" > server.key
    
    echo -e "${GREEN}✅ Keys generated successfully!${NC}"
}

# Function to setup DNSTT
setup_dnstt() {
    show_banner
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║      DNSTT (DNS Tunnel) Setup         ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    # Check dependencies
    install_dependencies
    
    # Open port 53
    open_port_53
    
    # Ask for nameserver domain
    echo -e "${YELLOW}👉 Enter your full nameserver domain (e.g., ns1.yourdomain.com):${NC}"
    echo -e "${CYAN}   [Press Enter for auto-generate: tns.voltran.online]${NC}"
    read -p "Domain: " ns_domain
    
    if [ -z "$ns_domain" ]; then
        ns_domain="tns.voltran.online"
        echo -e "${GREEN}✅ Using auto-generated domain: $ns_domain${NC}"
    fi
    
    # Save domain
    echo "$ns_domain" > $DNSTT_DIR/domain.txt
    
    # Generate keys
    generate_dnstt_keys
    
    # Ask for MTU
    echo ""
    echo -e "${YELLOW}👉 Choose MTU value:${NC}"
    echo -e "${WHITE}   1) 512 (Recommended for slow connections)${NC}"
    echo -e "${WHITE}   2) 1200 (Default - Balanced)${NC}"
    echo -e "${WHITE}   3) 1280 (Better performance)${NC}"
    echo -e "${WHITE}   4) 1420 (Maximum performance)${NC}"
    echo -e "${WHITE}   5) Custom MTU${NC}"
    echo ""
    read -p "Enter your choice [1-5] (Default: 2): " mtu_choice
    
    case $mtu_choice in
        1) MTU=512 ;;
        2|"") MTU=1200 ;;
        3) MTU=1280 ;;
        4) MTU=1420 ;;
        5)
            read -p "Enter custom MTU value (256-1500): " custom_mtu
            if [[ $custom_mtu -ge 256 && $custom_mtu -le 1500 ]]; then
                MTU=$custom_mtu
            else
                echo -e "${RED}❌ Invalid MTU, using default 1200${NC}"
                MTU=1200
            fi
            ;;
        *) MTU=1200 ;;
    esac
    
    echo "$MTU" > $DNSTT_DIR/mtu.txt
    echo -e "${GREEN}✅ MTU set to: $MTU${NC}"
    
    # Create systemd service
    echo -e "${YELLOW}📝 Creating systemd service...${NC}"
    
    cat > /etc/systemd/system/dnstt.service <<EOF
[Unit]
Description=DNSTT Server
After=network.target

[Service]
Type=simple
ExecStart=$DNSTT_DIR/dnstt-server -udp :53 -privkey-file $DNSTT_DIR/server.key $ns_domain 127.0.0.1:22
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable dnstt &>/dev/null
    systemctl restart dnstt
    
    sleep 2
    
    # Display connection details
    PUBLIC_IP=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')
    PUBKEY=$(cat $DNSTT_DIR/server.pub)
    
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║            ✅ DNSTT INSTALLED SUCCESSFULLY! ✅             ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━ CONNECTION DETAILS ━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${WHITE}📍 Server IP:${NC}      ${YELLOW}$PUBLIC_IP${NC}"
    echo -e "${WHITE}🌐 Tunnel Domain:${NC}  ${YELLOW}$ns_domain${NC}"
    echo -e "${WHITE}🔑 Public Key:${NC}     ${YELLOW}$PUBKEY${NC}"
    echo -e "${WHITE}🚪 Forwarding To:${NC}  ${YELLOW}SSH (port 22)${NC}"
    echo -e "${WHITE}📊 MTU Value:${NC}      ${YELLOW}$MTU${NC}"
    echo -e "${WHITE}📝 NS Record:${NC}      ${YELLOW}$ns_domain${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${RED}⚠️  Action Required:${NC} Ensure your SSH client is configured to use the DNS tunnel."
    echo ""
    echo -e "${YELLOW}💾 Configuration saved to: $DNSTT_DIR${NC}"
    echo ""
    
    read -p "Press [Enter] to return to menu..."
}

# Function to add SSH user
add_ssh_user() {
    show_banner
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         Add New SSH User               ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    read -p "👤 Username: " username
    
    if id "$username" &>/dev/null; then
        echo -e "${RED}❌ User already exists!${NC}"
        read -p "Press [Enter] to continue..."
        return
    fi
    
    read -p "🔒 Password: " password
    
    echo -e "${YELLOW}⏰ Select expiration period:${NC}"
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
            read -p "Enter days: " days
            if ! [[ "$days" =~ ^[0-9]+$ ]]; then
                days=30
            fi
            ;;
        *) days=30 ;;
    esac
    
    read -p "🔢 Max connections (1-100, default 2): " max_conn
    max_conn=${max_conn:-2}
    
    # Create user
    useradd -m -s /bin/false "$username" &>/dev/null
    echo "$username:$password" | chpasswd
    
    # Set expiration
    exp_date=$(date -d "+$days days" +"%Y-%m-%d")
    chage -E $(date -d "+$days days" +"%Y-%m-%d") "$username"
    
    # Save to database
    echo "$username|$password|$exp_date|$max_conn|$(date +"%Y-%m-%d")" >> $USER_DB
    
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║      ✅ USER CREATED SUCCESSFULLY!     ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${WHITE}👤 Username:${NC}       ${YELLOW}$username${NC}"
    echo -e "${WHITE}🔒 Password:${NC}       ${YELLOW}$password${NC}"
    echo -e "${WHITE}📅 Expires:${NC}        ${YELLOW}$exp_date${NC}"
    echo -e "${WHITE}🔢 Max Connections:${NC} ${YELLOW}$max_conn${NC}"
    echo -e "${WHITE}📅 Created:${NC}        ${YELLOW}$(date +"%Y-%m-%d %H:%M")${NC}"
    echo ""
    
    read -p "Press [Enter] to continue..."
}

# Function to delete SSH user
delete_ssh_user() {
    show_banner
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         Delete SSH User                ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    read -p "👤 Username to delete: " username
    
    if ! id "$username" &>/dev/null; then
        echo -e "${RED}❌ User does not exist!${NC}"
        read -p "Press [Enter] to continue..."
        return
    fi
    
    # Kill all user processes
    pkill -u "$username" &>/dev/null
    
    # Delete user
    userdel -r "$username" &>/dev/null
    
    # Remove from database
    sed -i "/^$username|/d" $USER_DB
    
    echo -e "${GREEN}✅ User '$username' deleted successfully!${NC}"
    read -p "Press [Enter] to continue..."
}

# Function to list users
list_ssh_users() {
    show_banner
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                        SSH USERS LIST                              ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if [ ! -f "$USER_DB" ] || [ ! -s "$USER_DB" ]; then
        echo -e "${YELLOW}📭 No users found.${NC}"
    else
        printf "${WHITE}%-15s %-15s %-12s %-10s %-12s${NC}\n" "USERNAME" "PASSWORD" "EXPIRES" "MAX CONN" "CREATED"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        while IFS='|' read -r user pass exp_date max_conn created; do
            # Check if expired
            today=$(date +%s)
            exp_unix=$(date -d "$exp_date" +%s 2>/dev/null || echo "0")
            
            if [ $today -gt $exp_unix ]; then
                status="${RED}[EXPIRED]${NC}"
            else
                status="${GREEN}[ACTIVE]${NC}"
            fi
            
            printf "${WHITE}%-15s %-15s %-12s %-10s %-12s${NC} %b\n" "$user" "$pass" "$exp_date" "$max_conn" "$created" "$status"
        done < $USER_DB
    fi
    
    echo ""
    read -p "Press [Enter] to continue..."
}

# Function to edit banner
edit_banner() {
    show_banner
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         Edit Login Banner              ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${YELLOW}Current banner:${NC}"
    echo -e "${WHITE}────────────────────────────────────────${NC}"
    cat $BANNER_FILE
    echo -e "${WHITE}────────────────────────────────────────${NC}"
    echo ""
    
    echo -e "${YELLOW}Enter new banner (type 'END' on a new line when done):${NC}"
    
    > $BANNER_FILE
    while IFS= read -r line; do
        if [ "$line" = "END" ]; then
            break
        fi
        echo "$line" >> $BANNER_FILE
    done
    
    echo -e "${GREEN}✅ Banner updated successfully!${NC}"
    read -p "Press [Enter] to continue..."
}

# Function to view DNSTT status
view_dnstt_status() {
    show_banner
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         DNSTT Service Status           ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    if systemctl is-active --quiet dnstt; then
        echo -e "${GREEN}✅ DNSTT Service: RUNNING${NC}"
    else
        echo -e "${RED}❌ DNSTT Service: STOPPED${NC}"
    fi
    
    echo ""
    echo -e "${YELLOW}Service Details:${NC}"
    systemctl status dnstt --no-pager | head -20
    
    echo ""
    read -p "Press [Enter] to continue..."
}

# Main Menu - DNSTT Management
dnstt_menu() {
    while true; do
        show_banner
        echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║      DNSTT MANAGEMENT MENU             ║${NC}"
        echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${WHITE}  1)${NC} ${GREEN}Install/Setup DNSTT${NC}"
        echo -e "${WHITE}  2)${NC} ${YELLOW}View DNSTT Status${NC}"
        echo -e "${WHITE}  3)${NC} ${YELLOW}View Connection Details${NC}"
        echo -e "${WHITE}  4)${NC} ${BLUE}Restart DNSTT Service${NC}"
        echo -e "${WHITE}  5)${NC} ${RED}Stop DNSTT Service${NC}"
        echo -e "${WHITE}  0)${NC} ${PURPLE}Back to Main Menu${NC}"
        echo ""
        echo -e "${CYAN}═══════════════════════════════════════════${NC}"
        read -p "👉 Enter your choice: " choice
        
        case $choice in
            1) setup_dnstt ;;
            2) view_dnstt_status ;;
            3)
                if [ -f "$DNSTT_DIR/domain.txt" ]; then
                    show_banner
                    PUBLIC_IP=$(curl -s ifconfig.me)
                    NS_DOMAIN=$(cat $DNSTT_DIR/domain.txt)
                    PUBKEY=$(cat $DNSTT_DIR/server.pub)
                    MTU=$(cat $DNSTT_DIR/mtu.txt)
                    echo -e "${CYAN}━━━━━━━━━━━━━━━━ CONNECTION DETAILS ━━━━━━━━━━━━━━━━${NC}"
                    echo -e "${WHITE}📍 Server IP:${NC} $PUBLIC_IP"
                    echo -e "${WHITE}🌐 Domain:${NC} $NS_DOMAIN"
                    echo -e "${WHITE}🔑 Public Key:${NC} $PUBKEY"
                    echo -e "${WHITE}📊 MTU:${NC} $MTU"
                    echo ""
                    read -p "Press [Enter] to continue..."
                else
                    echo -e "${RED}❌ DNSTT not configured yet!${NC}"
                    sleep 2
                fi
                ;;
            4)
                systemctl restart dnstt
                echo -e "${GREEN}✅ DNSTT restarted!${NC}"
                sleep 2
                ;;
            5)
                systemctl stop dnstt
                echo -e "${YELLOW}⚠️  DNSTT stopped!${NC}"
                sleep 2
                ;;
            0) return ;;
            *) echo -e "${RED}❌ Invalid choice!${NC}"; sleep 1 ;;
        esac
    done
}

# Main Menu - SSH Management
ssh_menu() {
    while true; do
        show_banner
        echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║       SSH USER MANAGEMENT MENU         ║${NC}"
        echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${WHITE}  1)${NC} ${GREEN}Add New User${NC}"
        echo -e "${WHITE}  2)${NC} ${YELLOW}List All Users${NC}"
        echo -e "${WHITE}  3)${NC} ${RED}Delete User${NC}"
        echo -e "${WHITE}  4)${NC} ${BLUE}Edit Login Banner${NC}"
        echo -e "${WHITE}  5)${NC} ${PURPLE}Check User Status${NC}"
        echo -e "${WHITE}  0)${NC} ${PURPLE}Back to Main Menu${NC}"
        echo ""
        echo -e "${CYAN}═══════════════════════════════════════════${NC}"
        read -p "👉 Enter your choice: " choice
        
        case $choice in
            1) add_ssh_user ;;
            2) list_ssh_users ;;
            3) delete_ssh_user ;;
            4) edit_banner ;;
            5)
                read -p "Username: " user
                if id "$user" &>/dev/null; then
                    echo -e "${GREEN}✅ User exists${NC}"
                    echo "Active connections: $(who | grep -c "$user")"
                else
                    echo -e "${RED}❌ User not found${NC}"
                fi
                read -p "Press [Enter]..."
                ;;
            0) return ;;
            *) echo -e "${RED}❌ Invalid choice!${NC}"; sleep 1 ;;
        esac
    done
}

# Main Menu
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
        echo -e "${WHITE}  3)${NC} ${YELLOW}📊 System Information${NC}"
        echo -e "${WHITE}  0)${NC} ${RED}❌ Exit${NC}"
        echo ""
        echo -e "${CYAN}═══════════════════════════════════════════${NC}"
        read -p "👉 Enter your choice: " choice
        
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
                echo -e "${GREEN}👋 Thank you for using SLOW DNS!${NC}"
                exit 0
                ;;
            *) echo -e "${RED}❌ Invalid choice!${NC}"; sleep 1 ;;
        esac
    done
}

# Start the script
main_menu