#!/bin/bash

################################################################################
# SLOW DNS - DNSTT & SSH User Management Script
# MADE BY THE KING 👑💯
# WhatsApp: +255624932595
# DM on WhatsApp if you have problems.
################################################################################

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Directories and files
SLOWDNS_DIR="/etc/slowdns"
SLOWDNS_LOG_DIR="/var/log/slowdns"
SLOWDNS_LOG="$SLOWDNS_LOG_DIR/slowdns.log"
USERS_DB="$SLOWDNS_DIR/users.db"
DNSTT_KEY_DIR="$SLOWDNS_DIR"
DNSTT_PRIVATE_KEY="$DNSTT_KEY_DIR/server.key"
DNSTT_PUBLIC_KEY="$DNSTT_KEY_DIR/server.pub"
DNSTT_CONFIG="$SLOWDNS_DIR/dnstt.conf"
SSH_BANNER="/etc/issue.net"
DEFAULT_DOMAIN="tns.voltran.online"

# Initialize logging
init_logging() {
    mkdir -p "$SLOWDNS_LOG_DIR"
    touch "$SLOWDNS_LOG"
    chmod 640 "$SLOWDNS_LOG"
}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$SLOWDNS_LOG"
}

# Check root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}This script must be run as root!${NC}"
        echo -e "${YELLOW}Please run: sudo $0${NC}"
        exit 1
    fi
}

# Print banner
print_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
   _____ _      ______          _____  _   _  _____ 
  / ____| |    / __ \ \        / /   \| \ | |/ ____|
 | (___ | |   | |  | \ \  /\  / /| |) |  \| | (___  
  \___ \| |   | |  | |\ \/  \/ / | | < . ` |\___ \ 
  ____) | |___| |__| | \  /\  /  | |_| | |\  |____) |
 |_____/|______\____/   \/  \/   |____/|_| \_|_____/ 
                                                      
EOF
    echo -e "${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}         MADE BY THE KING 👑💯${NC}"
    echo -e "${YELLOW}         WhatsApp: +255624932595${NC}"
    echo -e "${CYAN}         DM on WhatsApp if you have problems.${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════${NC}"
    echo ""
}

# Detect architecture
detect_arch() {
    local arch=$(uname -m)
    case $arch in
        x86_64)
            echo "amd64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Install dependencies
install_dependencies() {
    echo -e "${CYAN}Installing dependencies...${NC}"
    log "Installing dependencies"
    
    apt-get update -qq
    apt-get install -y curl wget jq openssh-server ufw iptables-persistent net-tools dnsutils git golang-go bc > /dev/null 2>&1
    
    echo -e "${GREEN}✓ Dependencies installed successfully${NC}"
    log "Dependencies installed"
}

# Setup directories
setup_directories() {
    mkdir -p "$SLOWDNS_DIR"
    chmod 700 "$SLOWDNS_DIR"
    mkdir -p "$SLOWDNS_LOG_DIR"
    
    if [[ ! -f "$USERS_DB" ]]; then
        echo "[]" > "$USERS_DB"
        chmod 600 "$USERS_DB"
    fi
}

# Check port 53
check_port_53() {
    echo -e "${CYAN}Checking port 53...${NC}"
    
    if netstat -tuln | grep -q ":53 "; then
        echo -e "${YELLOW}⚠ Port 53 is in use${NC}"
        
        if systemctl is-active --quiet systemd-resolved; then
            echo -e "${YELLOW}systemd-resolved is using port 53${NC}"
            read -p "Stop and disable systemd-resolved? (y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                systemctl stop systemd-resolved
                systemctl disable systemd-resolved
                
                # Configure DNS manually
                rm -f /etc/resolv.conf
                echo "nameserver 8.8.8.8" > /etc/resolv.conf
                echo "nameserver 8.8.4.4" >> /etc/resolv.conf
                chattr +i /etc/resolv.conf 2>/dev/null || true
                
                echo -e "${GREEN}✓ systemd-resolved stopped${NC}"
                log "systemd-resolved stopped and disabled"
            else
                echo -e "${RED}Cannot proceed without freeing port 53${NC}"
                exit 1
            fi
        else
            echo -e "${RED}Another service is using port 53. Please stop it manually.${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}✓ Port 53 is available${NC}"
    fi
}

# Configure firewall
configure_firewall() {
    echo -e "${CYAN}Configuring firewall...${NC}"
    
    if command -v ufw &> /dev/null; then
        ufw --force enable
        ufw allow 53/udp
        ufw allow 22/tcp
        ufw reload
        echo -e "${GREEN}✓ UFW configured${NC}"
        log "UFW configured for port 53 UDP and 22 TCP"
    else
        iptables -A INPUT -p udp --dport 53 -j ACCEPT
        iptables -A INPUT -p tcp --dport 22 -j ACCEPT
        netfilter-persistent save 2>/dev/null || iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
        echo -e "${GREEN}✓ iptables configured${NC}"
        log "iptables configured for port 53 UDP and 22 TCP"
    fi
}

# Generate DNSTT keys
generate_dnstt_keys() {
    echo -e "${CYAN}Generating DNSTT keys...${NC}"
    
    local private_key=$(head -c 32 /dev/urandom | xxd -p -c 32)
    local public_key=$(echo -n "$private_key" | xxd -r -p | base64 -w 0)
    
    echo "$private_key" > "$DNSTT_PRIVATE_KEY"
    echo "$public_key" > "$DNSTT_PUBLIC_KEY"
    chmod 600 "$DNSTT_PRIVATE_KEY"
    chmod 644 "$DNSTT_PUBLIC_KEY"
    
    echo -e "${GREEN}✓ Keys generated${NC}"
    log "DNSTT keys generated"
}

# Download and build DNSTT server
download_dnstt() {
    local dnstt_bin="/usr/local/bin/dnstt-server"
    
    echo -e "${CYAN}Building DNSTT server...${NC}"
    
    # Build DNSTT from source
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    echo -e "${YELLOW}Cloning DNSTT repository...${NC}"
    git clone https://github.com/farukeryilmaz/dnstt.git 2>&1 | grep -v "Cloning" || true
    
    cd dnstt/dnstt-server
    echo -e "${YELLOW}Building server binary...${NC}"
    go build -o "$dnstt_bin" . 2>&1 | grep -v "go: downloading" || true
    
    cd /
    rm -rf "$temp_dir"
    
    chmod +x "$dnstt_bin"
    echo -e "${GREEN}✓ DNSTT server installed${NC}"
    log "DNSTT server installed at $dnstt_bin"
}

# Setup DNSTT systemd service
setup_dnstt_service() {
    local domain=$1
    local mtu=$2
    local forward_address="127.0.0.1:22"
    
    echo -e "${CYAN}Setting up DNSTT service...${NC}"
    
    # Save config
    cat > "$DNSTT_CONFIG" <<EOF
DOMAIN=$domain
MTU=$mtu
FORWARD_ADDRESS=$forward_address
PRIVATE_KEY=$(cat "$DNSTT_PRIVATE_KEY")
EOF
    
    # Create systemd service
    cat > /etc/systemd/system/dnstt.service <<EOF
[Unit]
Description=DNSTT DNS Tunnel Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/dnstt-server -udp :53 -privkey-file $DNSTT_PRIVATE_KEY -mtu $mtu $forward_address $domain
Restart=always
RestartSec=3
StandardOutput=append:$SLOWDNS_LOG_DIR/dnstt.log
StandardError=append:$SLOWDNS_LOG_DIR/dnstt-error.log

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable dnstt.service
    systemctl start dnstt.service
    
    echo -e "${GREEN}✓ DNSTT service started${NC}"
    log "DNSTT service configured and started"
}

# Print DNSTT connection details
print_dnstt_details() {
    local domain=$1
    local mtu=$2
    local public_key=$(cat "$DNSTT_PUBLIC_KEY")
    
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}          DNS TUNNEL CONNECTION DETAILS${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}Tunnel Domain/NS:${NC} ${YELLOW}$domain${NC}"
    echo -e "${CYAN}Public Key:${NC} ${YELLOW}$public_key${NC}"
    echo -e "${CYAN}MTU:${NC} ${YELLOW}$mtu${NC}"
    echo -e "${CYAN}Forward Target:${NC} ${YELLOW}127.0.0.1:22 (SSH)${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${MAGENTA}Configure your client with these details${NC}"
    echo ""
}

# DNSTT Setup
setup_dnstt() {
    print_banner
    echo -e "${WHITE}DNSTT INSTALLATION${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════${NC}"
    
    # Domain selection
    echo -e "${CYAN}Domain Configuration:${NC}"
    echo "1) Use default domain (${DEFAULT_DOMAIN})"
    echo "2) Enter custom NS domain"
    read -p "Choose option (1-2): " domain_choice
    
    local domain
    if [[ "$domain_choice" == "2" ]]; then
        read -p "Enter your NS domain: " domain
    else
        domain="$DEFAULT_DOMAIN"
    fi
    
    # MTU selection
    echo ""
    echo -e "${CYAN}MTU Configuration:${NC}"
    echo "1) 512"
    echo "2) 1200 (default)"
    echo "3) 1500"
    echo "4) 900"
    echo "5) Custom MTU"
    read -p "Choose MTU option (1-5): " mtu_choice
    
    local mtu
    case $mtu_choice in
        1) mtu=512 ;;
        2) mtu=1200 ;;
        3) mtu=1500 ;;
        4) mtu=900 ;;
        5)
            read -p "Enter custom MTU (300-1500): " mtu
            if [[ ! "$mtu" =~ ^[0-9]+$ ]] || [[ $mtu -lt 300 ]] || [[ $mtu -gt 1500 ]]; then
                echo -e "${RED}Invalid MTU value. Using default 1200${NC}"
                mtu=1200
            fi
            ;;
        *) mtu=1200 ;;
    esac
    
    echo ""
    install_dependencies
    setup_directories
    check_port_53
    configure_firewall
    
    if [[ ! -f "$DNSTT_PRIVATE_KEY" ]]; then
        generate_dnstt_keys
    fi
    
    download_dnstt
    setup_dnstt_service "$domain" "$mtu"
    print_dnstt_details "$domain" "$mtu"
    
    log "DNSTT setup completed: domain=$domain, mtu=$mtu"
    read -p "Press Enter to continue..."
}

check_dnstt_status() {
    print_banner
    echo -e "${WHITE}DNSTT SERVICE STATUS${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════${NC}"
    
    if systemctl is-active --quiet dnstt.service; then
        echo -e "${GREEN}● DNSTT service is running${NC}"
        echo ""
        systemctl status dnstt.service --no-pager -l
    else
        echo -e "${RED}● DNSTT service is not running${NC}"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

view_dnstt_config() {
    print_banner
    echo -e "${WHITE}DNSTT CONFIGURATION${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════${NC}"
    
    if [[ -f "$DNSTT_CONFIG" ]]; then
        source "$DNSTT_CONFIG"
        local public_key=$(cat "$DNSTT_PUBLIC_KEY")
        
        echo -e "${CYAN}Domain:${NC} $DOMAIN"
        echo -e "${CYAN}MTU:${NC} $MTU"
        echo -e "${CYAN}Forward Address:${NC} $FORWARD_ADDRESS"
        echo -e "${CYAN}Public Key:${NC} $public_key"
    else
        echo -e "${RED}DNSTT not configured${NC}"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

uninstall_dnstt() {
    print_banner
    echo -e "${RED}UNINSTALL DNSTT${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════${NC}"
    
    read -p "Are you sure you want to uninstall DNSTT? (y/n): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        systemctl stop dnstt.service 2>/dev/null || true
        systemctl disable dnstt.service 2>/dev/null || true
        rm -f /etc/systemd/system/dnstt.service
        rm -f /usr/local/bin/dnstt-server
        systemctl daemon-reload
        
        echo -e "${GREEN}✓ DNSTT uninstalled${NC}"
        log "DNSTT uninstalled"
    fi
    
    read -p "Press Enter to continue..."
}

# DNSTT Menu
menu_dnstt() {
    while true; do
        print_banner
        echo -e "${WHITE}DNSTT (DNS TUNNEL) MANAGEMENT${NC}"
        echo -e "${MAGENTA}═══════════════════════════════════════════════════════${NC}"
        echo -e "${CYAN}1)${NC} Install/Setup DNSTT"
        echo -e "${CYAN}2)${NC} Check DNSTT Status"
        echo -e "${CYAN}3)${NC} Restart DNSTT Service"
        echo -e "${CYAN}4)${NC} Stop DNSTT Service"
        echo -e "${CYAN}5)${NC} View DNSTT Configuration"
        echo -e "${CYAN}6)${NC} Uninstall DNSTT"
        echo -e "${CYAN}0)${NC} Back to Main Menu"
        echo -e "${MAGENTA}═══════════════════════════════════════════════════════${NC}"
        
        read -p "Choose option: " choice
        
        case $choice in
            1)
                setup_dnstt
                ;;
            2)
                check_dnstt_status
                ;;
            3)
                systemctl restart dnstt.service
                echo -e "${GREEN}✓ DNSTT service restarted${NC}"
                read -p "Press Enter to continue..."
                ;;
            4)
                systemctl stop dnstt.service
                echo -e "${YELLOW}⚠ DNSTT service stopped${NC}"
                read -p "Press Enter to continue..."
                ;;
            5)
                view_dnstt_config
                ;;
            6)
                uninstall_dnstt
                ;;
            0)
                return
                ;;
            *)
                echo -e "${RED}Invalid option${NC}"
                sleep 1
                ;;
        esac
    done
}

# SSH User Management Functions

add_ssh_user() {
    print_banner
    echo -e "${WHITE}ADD SSH USER${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════${NC}"
    
    read -p "Username: " username
    
    if id "$username" &>/dev/null; then
        echo -e "${RED}User already exists!${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    read -sp "Password: " password
    echo
    read -sp "Confirm password: " password2
    echo
    
    if [[ "$password" != "$password2" ]]; then
        echo -e "${RED}Passwords do not match!${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    read -p "Number of days (expiry): " days
    if [[ ! "$days" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Invalid number of days${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    read -p "Max simultaneous connections: " max_conn
    if [[ ! "$max_conn" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Invalid connection limit${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    # Create user
    useradd -m -s /bin/bash "$username"
    echo "$username:$password" | chpasswd
    
    # Set expiry
    local expiry_date=$(date -d "+${days} days" +%Y-%m-%d)
    chage -E "$expiry_date" "$username"
    
    # Add to users database
    local users=$(cat "$USERS_DB")
    local new_user=$(jq -n \
        --arg user "$username" \
        --arg exp "$expiry_date" \
        --arg conn "$max_conn" \
        --arg created "$(date '+%Y-%m-%d %H:%M:%S')" \
        '{username: $user, expiry: $exp, max_connections: $conn, created: $created, status: "active"}')
    
    echo "$users" | jq ". += [$new_user]" > "$USERS_DB"
    
    echo -e "${GREEN}✓ User $username created successfully${NC}"
    echo -e "${CYAN}Expires:${NC} $expiry_date"
    echo -e "${CYAN}Max connections:${NC} $max_conn"
    
    log "SSH user created: $username, expiry: $expiry_date, max_conn: $max_conn"
    read -p "Press Enter to continue..."
}

delete_ssh_user() {
    print_banner
    echo -e "${WHITE}DELETE SSH USER${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════${NC}"
    
    list_users_simple
    echo ""
    read -p "Username to delete: " username
    
    if ! id "$username" &>/dev/null; then
        echo -e "${RED}User does not exist!${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    read -p "Delete user $username? (y/n): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Remove from database
        local users=$(cat "$USERS_DB")
        echo "$users" | jq "map(select(.username != \"$username\"))" > "$USERS_DB"
        
        # Kill user sessions
        pkill -u "$username" 2>/dev/null || true
        
        # Remove system user
        userdel -r "$username" 2>/dev/null || userdel "$username"
        
        echo -e "${GREEN}✓ User $username deleted${NC}"
        log "SSH user deleted: $username"
    fi
    
    read -p "Press Enter to continue..."
}

edit_ssh_user() {
    print_banner
    echo -e "${WHITE}EDIT SSH USER${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════${NC}"
    
    list_users_simple
    echo ""
    read -p "Username to edit: " username
    
    if ! id "$username" &>/dev/null; then
        echo -e "${RED}User does not exist!${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo ""
    echo "What do you want to change?"
    echo "1) Password"
    echo "2) Expiry date"
    echo "3) Max connections"
    echo "4) Toggle active/inactive"
    read -p "Choose option (1-4): " edit_choice
    
    case $edit_choice in
        1)
            read -sp "New password: " new_password
            echo
            read -sp "Confirm password: " new_password2
            echo
            
            if [[ "$new_password" == "$new_password2" ]]; then
                echo "$username:$new_password" | chpasswd
                echo -e "${GREEN}✓ Password updated${NC}"
                log "Password updated for user: $username"
            else
                echo -e "${RED}Passwords do not match!${NC}"
            fi
            ;;
        2)
            read -p "Number of days from now: " days
            if [[ "$days" =~ ^[0-9]+$ ]]; then
                local expiry_date=$(date -d "+${days} days" +%Y-%m-%d)
                chage -E "$expiry_date" "$username"
                
                # Update database
                local users=$(cat "$USERS_DB")
                echo "$users" | jq "map(if .username == \"$username\" then .expiry = \"$expiry_date\" else . end)" > "$USERS_DB"
                
                echo -e "${GREEN}✓ Expiry updated to $expiry_date${NC}"
                log "Expiry updated for user: $username to $expiry_date"
            fi
            ;;
        3)
            read -p "New max connections: " max_conn
            if [[ "$max_conn" =~ ^[0-9]+$ ]]; then
                # Update database
                local users=$(cat "$USERS_DB")
                echo "$users" | jq "map(if .username == \"$username\" then .max_connections = \"$max_conn\" else . end)" > "$USERS_DB"
                
                echo -e "${GREEN}✓ Max connections updated${NC}"
                log "Max connections updated for user: $username to $max_conn"
            fi
            ;;
        4)
            local users=$(cat "$USERS_DB")
            local current_status=$(echo "$users" | jq -r ".[] | select(.username == \"$username\") | .status")
            local new_status
            
            if [[ "$current_status" == "active" ]]; then
                new_status="inactive"
                usermod -L "$username"
            else
                new_status="active"
                usermod -U "$username"
            fi
            
            echo "$users" | jq "map(if .username == \"$username\" then .status = \"$new_status\" else . end)" > "$USERS_DB"
            echo -e "${GREEN}✓ User status changed to $new_status${NC}"
            log "User status changed: $username to $new_status"
            ;;
    esac
    
    read -p "Press Enter to continue..."
}

list_users_simple() {
    local users=$(cat "$USERS_DB")
    local count=$(echo "$users" | jq 'length')
    
    if [[ $count -eq 0 ]]; then
        echo -e "${YELLOW}No users found${NC}"
        return
    fi
    
    echo "$users" | jq -r '.[] | .username' | while read -r user; do
        echo "- $user"
    done
}

list_ssh_users() {
    print_banner
    echo -e "${WHITE}SSH USERS LIST${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════${NC}"
    
    local users=$(cat "$USERS_DB")
    local count=$(echo "$users" | jq 'length')
    
    if [[ $count -eq 0 ]]; then
        echo -e "${YELLOW}No users found${NC}"
    else
        printf "%-15s %-12s %-10s %-10s %-10s\n" "USERNAME" "EXPIRY" "DAYS LEFT" "MAX CONN" "STATUS"
        echo "─────────────────────────────────────────────────────────────────────"
        
        echo "$users" | jq -r '.[] | @json' | while read -r user_json; do
            local username=$(echo "$user_json" | jq -r '.username')
            local expiry=$(echo "$user_json" | jq -r '.expiry')
            local max_conn=$(echo "$user_json" | jq -r '.max_connections')
            local status=$(echo "$user_json" | jq -r '.status')
            
            local days_left="N/A"
            if [[ "$expiry" != "null" ]]; then
                local exp_epoch=$(date -d "$expiry" +%s)
                local now_epoch=$(date +%s)
                days_left=$(( (exp_epoch - now_epoch) / 86400 ))
                
                if [[ $days_left -lt 0 ]]; then
                    days_left="EXPIRED"
                fi
            fi
            
            local color="${GREEN}"
            [[ "$status" == "inactive" ]] && color="${RED}"
            [[ "$days_left" == "EXPIRED" ]] && color="${RED}"
            
            echo -e "${color}$(printf "%-15s %-12s %-10s %-10s %-10s" "$username" "$expiry" "$days_left" "$max_conn" "$status")${NC}"
        done
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

set_ssh_banner() {
    print_banner
    echo -e "${WHITE}SET SSH LOGIN BANNER${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════${NC}"
    
    echo "1) Use default banner (MADE BY THE KING 👑👑)"
    echo "2) Enter custom banner"
    read -p "Choose option (1-2): " banner_choice
    
    local banner_text
    if [[ "$banner_choice" == "2" ]]; then
        echo "Enter banner text (press Ctrl+D when done):"
        banner_text=$(cat)
    else
        banner_text="═══════════════════════════════════════════════════════
MADE BY THE KING 👑👑

WhatsApp: +255624932595
DM on WhatsApp if you have problems.
═══════════════════════════════════════════════════════"
    fi
    
    echo "$banner_text" > "$SSH_BANNER"
    
    # Update sshd_config
    if ! grep -q "^Banner" /etc/ssh/sshd_config; then
        echo "Banner $SSH_BANNER" >> /etc/ssh/sshd_config
    else
        sed -i "s|^Banner.*|Banner $SSH_BANNER|" /etc/ssh/sshd_config
    fi
    
    systemctl reload sshd
    
    echo -e "${GREEN}✓ SSH banner updated${NC}"
    log "SSH banner updated"
    read -p "Press Enter to continue..."
}

view_logs() {
    print_banner
    echo -e "${WHITE}SLOWDNS LOGS${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════${NC}"
    
    echo "1) View SlowDNS logs"
    echo "2) View DNSTT logs"
    echo "3) View SSH auth logs"
    read -p "Choose option (1-3): " log_choice
    
    case $log_choice in
        1)
            if [[ -f "$SLOWDNS_LOG" ]]; then
                tail -n 50 "$SLOWDNS_LOG"
            else
                echo -e "${YELLOW}No logs found${NC}"
            fi
            ;;
        2)
            if [[ -f "$SLOWDNS_LOG_DIR/dnstt.log" ]]; then
                tail -n 50 "$SLOWDNS_LOG_DIR/dnstt.log"
            else
                echo -e "${YELLOW}No DNSTT logs found${NC}"
            fi
            ;;
        3)
            tail -n 50 /var/log/auth.log 2>/dev/null || tail -n 50 /var/log/secure 2>/dev/null || echo -e "${YELLOW}No auth logs found${NC}"
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
}

# SSH User Menu
menu_ssh() {
    while true; do
        print_banner
        echo -e "${WHITE}SSH USER MANAGEMENT${NC}"
        echo -e "${MAGENTA}═══════════════════════════════════════════════════════${NC}"
        echo -e "${CYAN}1)${NC} Add User"
        echo -e "${CYAN}2)${NC} Delete User"
        echo -e "${CYAN}3)${NC} Edit User"
        echo -e "${CYAN}4)${NC} List Users"
        echo -e "${CYAN}5)${NC} Set SSH Banner"
        echo -e "${CYAN}6)${NC} View Logs"
        echo -e "${CYAN}0)${NC} Back to Main Menu"
        echo -e "${MAGENTA}═══════════════════════════════════════════════════════${NC}"
        
        read -p "Choose option: " choice
        
        case $choice in
            1)
                add_ssh_user
                ;;
            2)
                delete_ssh_user
                ;;
            3)
                edit_ssh_user
                ;;
            4)
                list_ssh_users
                ;;
            5)
                set_ssh_banner
                ;;
            6)
                view_logs
                ;;
            0)
                return
                ;;
            *)
                echo -e "${RED}Invalid option${NC}"
                sleep 1
                ;;
        esac
    done
}

# Main Menu
main_menu() {
    while true; do
        print_banner
        echo -e "${WHITE}MAIN MENU${NC}"
        echo -e "${MAGENTA}═══════════════════════════════════════════════════════${NC}"
        echo -e "${CYAN}1)${NC} DNSTT (DNS Tunnel) Management"
        echo -e "${CYAN}2)${NC} SSH User Management"
        echo -e "${CYAN}3)${NC} View System Info"
        echo -e "${CYAN}4)${NC} Exit"
        echo -e "${MAGENTA}═══════════════════════════════════════════════════════${NC}"
        
        read -p "Choose option: " choice
        
        case $choice in
            1)
                menu_dnstt
                ;;
            2)
                menu_ssh
                ;;
            3)
                view_system_info
                ;;
            4)
                echo -e "${GREEN}Thank you for using SlowDNS!${NC}"
                echo -e "${YELLOW}WhatsApp: +255624932595${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option${NC}"
                sleep 1
                ;;
        esac
    done
}

view_system_info() {
    print_banner
    echo -e "${WHITE}SYSTEM INFORMATION${NC}"
    echo -e "${MAGENTA}═══════════════════════════════════════════════════════${NC}"
    
    echo -e "${CYAN}Hostname:${NC} $(hostname)"
    echo -e "${CYAN}OS:${NC} $(lsb_release -d | cut -f2)"
    echo -e "${CYAN}Kernel:${NC} $(uname -r)"
    echo -e "${CYAN}Architecture:${NC} $(uname -m)"
    echo -e "${CYAN}IP Address:${NC} $(hostname -I | awk '{print $1}')"
    echo ""
    echo -e "${CYAN}DNSTT Status:${NC}"
    if systemctl is-active --quiet dnstt.service; then
        echo -e "  ${GREEN}● Running${NC}"
    else
        echo -e "  ${RED}● Not running${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}SSH Users:${NC} $(cat "$USERS_DB" | jq 'length') users"
    echo ""
    
    read -p "Press Enter to continue..."
}

# Main execution
main() {
    check_root
    init_logging
    setup_directories
    
    # Set default SSH banner if not exists
    if [[ ! -f "$SSH_BANNER" ]]; then
        cat > "$SSH_BANNER" <<EOF
═══════════════════════════════════════════════════════
MADE BY THE KING 👑👑

WhatsApp: +255624932595
DM on WhatsApp if you have problems.
═══════════════════════════════════════════════════════
EOF
        
        if ! grep -q "^Banner" /etc/ssh/sshd_config; then
            echo "Banner $SSH_BANNER" >> /etc/ssh/sshd_config
            systemctl reload sshd 2>/dev/null || true
        fi
    fi
    
    main_menu
}

main "$@"
