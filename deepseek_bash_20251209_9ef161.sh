#!/bin/bash

# MADE BY THE KING 👑💯
# WhatsApp: +255624932595
# DM on WhatsApp if you have problems.

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Configuration
SLOWDNS_DIR="/etc/slowdns"
LOG_DIR="/var/log/slowdns"
LOG_FILE="$LOG_DIR/slowdns.log"
USERS_DB="$SLOWDNS_DIR/users.db"
BANNER_FILE="/etc/issue.net"
DNSTT_BINARY="/usr/local/bin/dnstt-server"
DNSTT_SERVICE="/etc/systemd/system/dnstt.service"
DEFAULT_DOMAIN="tns.voltran.online"
DEFAULT_MTU="1200"

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}This script must be run as root${NC}"
    exit 1
fi

# Create necessary directories
mkdir -p "$SLOWDNS_DIR" "$LOG_DIR"
chmod 700 "$SLOWDNS_DIR"
chmod 755 "$LOG_DIR"
touch "$LOG_FILE" "$USERS_DB"
chmod 600 "$USERS_DB"

# Logging function
log() {
    echo -e "$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $(echo "$1" | sed 's/\x1b\[[0-9;]*m//g')" >> "$LOG_FILE"
}

# Print header/banner
print_header() {
    clear
    echo -e "${CYAN}"
    echo -e "   _____ _                    ______  _   _ _____ "
    echo -e "  / ____| |                  |  ____|| \ | / ____|"
    echo -e " | (___ | | _____      _____ | |__   |  \| | (___  "
    echo -e "  \___ \| |/ _ \ \ /\ / / __||  __|  | . \` |\___ \ "
    echo -e "  ____) | | (_) \ V  V /\__ \| |____ | |\  |____) |"
    echo -e " |_____/|_|\___/ \_/\_/ |___/|______||_| \_|_____/ "
    echo -e "${NC}"
    echo -e "${MAGENTA}===================================================${NC}"
    echo -e "${GREEN}MADE BY THE KING 👑💯${NC}"
    echo -e "${YELLOW}WhatsApp: +255624932595${NC}"
    echo -e "${CYAN}DM on WhatsApp if you have problems.${NC}"
    echo -e "${MAGENTA}===================================================${NC}"
    echo ""
}

# Check and install dependencies
install_dependencies() {
    log "${YELLOW}Checking and installing dependencies...${NC}"
    
    apt-get update > /dev/null 2>&1
    
    local deps="curl wget jq systemd openssh-server ufw iptables-persistent net-tools dnsutils"
    
    for dep in $deps; do
        if ! dpkg -l | grep -q "^ii  $dep" 2>/dev/null; then
            log "${BLUE}Installing $dep...${NC}"
            apt-get install -y "$dep" >> "$LOG_FILE" 2>&1
        fi
    done
    
    log "${GREEN}Dependencies installed successfully${NC}"
}

# Function to detect architecture
detect_arch() {
    local arch=$(uname -m)
    case $arch in
        x86_64|amd64)
            echo "amd64"
            ;;
        aarch64|arm64)
            echo "arm64"
            ;;
        armv7l|armhf)
            echo "armv7"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Function to download DNSTT binary
download_dnstt_binary() {
    local arch=$1
    log "${BLUE}Downloading DNSTT binary for $arch...${NC}"
    
    # GitHub repository for DNSTT
    local repo="https://github.com/alexbers/mtprotoproxy"
    
    # Try multiple sources for DNSTT binary
    local download_url=""
    
    case $arch in
        amd64)
            # Try multiple possible URLs
            download_url="https://github.com/alexbers/mtprotoproxy/releases/download/v1.1.3/dnstt-server"
            ;;
        arm64)
            download_url="https://github.com/alexbers/mtprotoproxy/releases/download/v1.1.3/dnstt-server-arm64"
            ;;
        armv7)
            download_url="https://github.com/alexbers/mtprotoproxy/releases/download/v1.1.3/dnstt-server-armv7"
            ;;
    esac
    
    # Try to download from primary source
    if wget -q --timeout=30 --tries=3 "$download_url" -O "$DNSTT_BINARY.tmp"; then
        mv "$DNSTT_BINARY.tmp" "$DNSTT_BINARY"
        chmod +x "$DNSTT_BINARY"
        log "${GREEN}DNSTT binary downloaded successfully from primary source${NC}"
        return 0
    fi
    
    # Alternative: Build from source if download fails
    log "${YELLOW}Download failed, trying alternative source...${NC}"
    
    # Try to install Go and build from source
    if command -v go >/dev/null 2>&1 || apt-get install -y golang >/dev/null 2>&1; then
        log "${BLUE}Building DNSTT from source...${NC}"
        local temp_dir=$(mktemp -d)
        cd "$temp_dir"
        
        # Clone DNSTT source
        if git clone https://github.com/alexbers/mtprotoproxy.git . >/dev/null 2>&1; then
            go build -o dnstt-server ./dnstt-server >/dev/null 2>&1
            if [[ -f "dnstt-server" ]]; then
                cp dnstt-server "$DNSTT_BINARY"
                chmod +x "$DNSTT_BINARY"
                cd /
                rm -rf "$temp_dir"
                log "${GREEN}DNSTT built from source successfully${NC}"
                return 0
            fi
        fi
        cd /
        rm -rf "$temp_dir"
    fi
    
    # Last resort: Use pre-built binary from alternative source
    log "${YELLOW}Trying alternative download source...${NC}"
    if curl -fsSL "https://cdn.jsdelivr.net/gh/alexbers/mtprotoproxy@master/dnstt-server" -o "$DNSTT_BINARY"; then
        chmod +x "$DNSTT_BINARY"
        log "${GREEN}DNSTT binary downloaded from alternative source${NC}"
        return 0
    fi
    
    log "${RED}Failed to download or build DNSTT binary${NC}"
    return 1
}

# Function to generate proper DNSTT keys
generate_dnstt_keys() {
    log "${BLUE}Generating DNSTT keys...${NC}"
    
    # Generate private key using DNSTT binary
    if [[ -f "$DNSTT_BINARY" ]]; then
        # Generate private key
        "$DNSTT_BINARY" -gen-priv-key "$SLOWDNS_DIR/server.key"
        
        if [[ ! -f "$SLOWDNS_DIR/server.key" ]]; then
            # Fallback: generate ed25519 key
            openssl genpkey -algorithm ed25519 -out "$SLOWDNS_DIR/server.key" 2>/dev/null
        fi
        
        # Generate public key from private key
        "$DNSTT_BINARY" -pubkey-file "$SLOWDNS_DIR/server.pub" -privkey-file "$SLOWDNS_DIR/server.key"
        
        if [[ ! -f "$SLOWDNS_DIR/server.pub" ]]; then
            # Fallback: extract public key
            openssl pkey -in "$SLOWDNS_DIR/server.key" -pubout -out "$SLOWDNS_DIR/server.pub" 2>/dev/null
        fi
        
        chmod 600 "$SLOWDNS_DIR/server.key"
        chmod 644 "$SLOWDNS_DIR/server.pub"
        
        # Verify keys
        if [[ -f "$SLOWDNS_DIR/server.key" ]] && [[ -f "$SLOWDNS_DIR/server.pub" ]]; then
            # Extract clean public key (remove headers/footers)
            PUB_KEY=$(grep -v -- "-----" "$SLOWDNS_DIR/server.pub" | tr -d '\n\r ')
            if [[ -z "$PUB_KEY" ]]; then
                PUB_KEY=$(cat "$SLOWDNS_DIR/server.pub" | tr -d '\n\r ' | sed 's/-----.*-----//g')
            fi
            
            echo "$PUB_KEY" > "$SLOWDNS_DIR/server.pub.clean"
            log "${GREEN}DNSTT keys generated successfully${NC}"
            return 0
        fi
    fi
    
    log "${RED}Failed to generate DNSTT keys${NC}"
    return 1
}

# Function to handle port 53 conflicts
handle_port_53() {
    log "${BLUE}Checking port 53...${NC}"
    
    # Check if anything is using port 53
    local port_in_use=$(netstat -tulpn | grep ':53 ' | head -1)
    
    if [[ -n "$port_in_use" ]]; then
        log "${YELLOW}Port 53 is in use:${NC}"
        echo "$port_in_use"
        
        # Check for systemd-resolved
        if systemctl is-active --quiet systemd-resolved; then
            log "${YELLOW}Stopping systemd-resolved...${NC}"
            systemctl stop systemd-resolved
            systemctl disable systemd-resolved > /dev/null 2>&1
            
            # Disable systemd-resolved stub listener
            sed -i 's/#DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf
            sed -i 's/DNSStubListener=yes/DNSStubListener=no/' /etc/systemd/resolved.conf
            ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf
            systemctl restart systemd-resolved
        fi
        
        # Check for dnsmasq
        if systemctl is-active --quiet dnsmasq; then
            log "${YELLOW}Stopping dnsmasq...${NC}"
            systemctl stop dnsmasq
            systemctl disable dnsmasq > /dev/null 2>&1
        fi
        
        # Check for bind9/named
        if systemctl is-active --quiet named; then
            log "${YELLOW}Stopping bind9/named...${NC}"
            systemctl stop named
            systemctl disable named > /dev/null 2>&1
        fi
        
        sleep 2
        
        # Check again
        if netstat -tulpn | grep -q ':53 '; then
            log "${RED}Port 53 is still in use. Please manually stop the service using port 53${NC}"
            echo -e "${YELLOW}Run:${NC} netstat -tulpn | grep ':53 '"
            read -p "Press Enter to continue anyway or Ctrl+C to cancel..."
        fi
    fi
    
    # Setup firewall rules
    if command -v ufw &> /dev/null && ufw status | grep -q "Status: active"; then
        ufw allow 53/udp > /dev/null 2>&1
        log "${GREEN}UFW rule added for port 53 UDP${NC}"
    else
        # Use iptables
        iptables -A INPUT -p udp --dport 53 -j ACCEPT 2>/dev/null
        iptables -A INPUT -p tcp --dport 53 -j ACCEPT 2>/dev/null
        iptables-save > /etc/iptables/rules.v4 2>/dev/null
        ip6tables -A INPUT -p udp --dport 53 -j ACCEPT 2>/dev/null
        ip6tables -A INPUT -p tcp --dport 53 -j ACCEPT 2>/dev/null
        ip6tables-save > /etc/iptables/rules.v6 2>/dev/null
        log "${GREEN}iptables rules added for port 53 TCP/UDP${NC}"
    fi
    
    return 0
}

# Function to setup DNS Tunnel
setup_dnstt() {
    print_header
    echo -e "${CYAN}=== DNS Tunnel (DNSTT) Setup ===${NC}"
    echo ""
    
    # Domain selection
    echo -e "${YELLOW}Select domain option:${NC}"
    echo -e "1) Use default domain ($DEFAULT_DOMAIN)"
    echo -e "2) Enter custom domain"
    read -rp "Choice [1-2]: " domain_choice
    
    case $domain_choice in
        1)
            DOMAIN="$DEFAULT_DOMAIN"
            ;;
        2)
            read -rp "Enter your domain (e.g., dns.example.com): " DOMAIN
            if [[ -z "$DOMAIN" ]]; then
                DOMAIN="$DEFAULT_DOMAIN"
                log "${YELLOW}Using default domain: $DOMAIN${NC}"
            fi
            ;;
        *)
            DOMAIN="$DEFAULT_DOMAIN"
            ;;
    esac
    
    # MTU selection menu
    echo ""
    echo -e "${YELLOW}Select MTU size:${NC}"
    echo -e "1) 512 bytes ${GREEN}(Recommended for unstable connections)${NC}"
    echo -e "2) 576 bytes"
    echo -e "3) 900 bytes ${GREEN}(Good balance)${NC}"
    echo -e "4) 1200 bytes ${GREEN}(Default - Best performance)${NC}"
    echo -e "5) 1500 bytes ${GREEN}(Maximum - Requires stable connection)${NC}"
    echo -e "6) Custom MTU size"
    read -rp "Choice [1-6]: " mtu_choice
    
    case $mtu_choice in
        1) 
            MTU="512"
            echo -e "${GREEN}Selected MTU: 512 bytes (Good for unstable networks)${NC}"
            ;;
        2) 
            MTU="576"
            echo -e "${GREEN}Selected MTU: 576 bytes${NC}"
            ;;
        3) 
            MTU="900"
            echo -e "${GREEN}Selected MTU: 900 bytes (Balanced)${NC}"
            ;;
        4) 
            MTU="1200"
            echo -e "${GREEN}Selected MTU: 1200 bytes (Recommended)${NC}"
            ;;
        5) 
            MTU="1500"
            echo -e "${GREEN}Selected MTU: 1500 bytes (Maximum)${NC}"
            ;;
        6)
            while true; do
                read -rp "Enter custom MTU size (68-1500): " custom_mtu
                if [[ $custom_mtu =~ ^[0-9]+$ ]] && [ "$custom_mtu" -ge 68 ] && [ "$custom_mtu" -le 1500 ]; then
                    MTU="$custom_mtu"
                    echo -e "${GREEN}Selected MTU: $MTU bytes${NC}"
                    break
                else
                    echo -e "${RED}Invalid MTU. Must be between 68 and 1500${NC}"
                fi
            done
            ;;
        *)
            MTU="1200"
            echo -e "${GREEN}Using default MTU: 1200 bytes${NC}"
            ;;
    esac
    
    # Detect architecture and download DNSTT binary
    local arch=$(detect_arch)
    if [[ "$arch" == "unknown" ]]; then
        log "${RED}Unsupported architecture: $(uname -m)${NC}"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    if ! download_dnstt_binary "$arch"; then
        log "${RED}Failed to get DNSTT binary. Please check internet connection${NC}"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Handle port 53
    if ! handle_port_53; then
        log "${RED}Failed to free port 53${NC}"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Generate keys
    if ! generate_dnstt_keys; then
        log "${RED}Failed to generate DNSTT keys${NC}"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Read public key
    if [[ -f "$SLOWDNS_DIR/server.pub.clean" ]]; then
        PUB_KEY=$(cat "$SLOWDNS_DIR/server.pub.clean")
    else
        PUB_KEY=$(grep -v -- "-----" "$SLOWDNS_DIR/server.pub" | tr -d '\n\r ' 2>/dev/null)
    fi
    
    # Create systemd service with correct MTU
    log "${BLUE}Creating systemd service with MTU=$MTU...${NC}"
    
    cat > "$DNSTT_SERVICE" << EOF
[Unit]
Description=DNSTT Server
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/slowdns
ExecStart=$DNSTT_BINARY -udp :53 -privkey-file $SLOWDNS_DIR/server.key $SLOWDNS_DIR/server.pub 127.0.0.1:22 -mtu $MTU
Restart=always
RestartSec=3
LimitNOFILE=65536

# Security
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/etc/slowdns /var/log/slowdns

[Install]
WantedBy=multi-user.target
EOF
    
    # Alternative service format if above doesn't work
    if [[ ! -f "$DNSTT_BINARY" ]]; then
        log "${RED}DNSTT binary not found${NC}"
        return 1
    fi
    
    # Test if DNSTT binary works with the parameters
    echo -e "${BLUE}Testing DNSTT binary...${NC}"
    if timeout 2 "$DNSTT_BINARY" -version 2>&1 | grep -q "dnstt"; then
        log "${GREEN}DNSTT binary is working${NC}"
    else
        # Try different parameter format
        cat > "$DNSTT_SERVICE" << EOF
[Unit]
Description=DNSTT Server
After=network.target

[Service]
Type=simple
User=root
ExecStart=$DNSTT_BINARY -listen 0.0.0.0:53 -privkey $SLOWDNS_DIR/server.key -pubkey $SLOWDNS_DIR/server.pub -forward 127.0.0.1:22 -mtu $MTU
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
    fi
    
    # Reload systemd and start service
    systemctl daemon-reload
    systemctl enable dnstt > /dev/null 2>&1
    systemctl restart dnstt
    
    sleep 2
    
    # Check service status
    if systemctl is-active --quiet dnstt; then
        log "${GREEN}DNSTT service started successfully${NC}"
    else
        log "${YELLOW}Service might have issues. Checking logs...${NC}"
        journalctl -u dnstt -n 10 --no-pager
        log "${YELLOW}Trying alternative service configuration...${NC}"
        
        # Try simplest service configuration
        cat > "$DNSTT_SERVICE" << EOF
[Unit]
Description=DNSTT Server
After=network.target

[Service]
Type=simple
User=root
ExecStart=$DNSTT_BINARY -udp :53 -privkey $SLOWDNS_DIR/server.key $SLOWDNS_DIR/server.pub 127.0.0.1:22
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
        
        systemctl daemon-reload
        systemctl restart dnstt
        sleep 2
        
        if systemctl is-active --quiet dnstt; then
            log "${GREEN}DNSTT service started with alternative config${NC}"
        else
            log "${RED}Failed to start DNSTT service. Please check configuration${NC}"
            echo -e "${YELLOW}Try manual command:${NC}"
            echo "$DNSTT_BINARY -udp :53 -privkey $SLOWDNS_DIR/server.key $SLOWDNS_DIR/server.pub 127.0.0.1:22 -mtu $MTU"
        fi
    fi
    
    # Display connection details
    echo ""
    echo -e "${GREEN}===================================================${NC}"
    echo -e "${CYAN}DNS TUNNEL SETUP COMPLETE!${NC}"
    echo -e "${GREEN}===================================================${NC}"
    echo -e "${YELLOW}Tunnel Domain:${NC} $DOMAIN"
    echo -e "${YELLOW}Public Key:${NC}"
    echo "$PUB_KEY"
    echo -e "${YELLOW}Public Key (hex):${NC}"
    echo -n "$PUB_KEY" | xxd -p | tr -d '\n'
    echo ""
    echo -e "${YELLOW}Forwarding to:${NC} 127.0.0.1:22 (SSH)"
    echo -e "${YELLOW}MTU Size:${NC} $MTU bytes"
    echo -e "${YELLOW}Server Port:${NC} 53/UDP"
    echo -e "${YELLOW}Server IP:${NC} $(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')"
    echo ""
    echo -e "${MAGENTA}Client Configuration:${NC}"
    echo -e "Use this domain and public key in your DNSTT client"
    echo -e "Example client command:"
    echo -e "dnstt-client -udp <server_ip>:53 -pubkey $PUB_KEY <your_domain> 127.0.0.1:2222"
    echo ""
    echo -e "${GREEN}Service Status:${NC} systemctl status dnstt"
    echo -e "${GREEN}Logs:${NC} journalctl -u dnstt -f"
    echo -e "${GREEN}Config files:${NC} $SLOWDNS_DIR/"
    echo -e "${GREEN}===================================================${NC}"
    
    # Save connection info to file
    cat > "$SLOWDNS_DIR/connection-info.txt" << EOF
=== DNSTT Connection Information ===
Domain: $DOMAIN
Public Key: $PUB_KEY
Public Key (hex): $(echo -n "$PUB_KEY" | xxd -p | tr -d '\n')
Server IP: $(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
Server Port: 53/UDP
Forwarding to: 127.0.0.1:22
MTU: $MTU bytes

Client command example:
dnstt-client -udp $(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}'):53 \\
  -pubkey $PUB_KEY \\
  $DOMAIN 127.0.0.1:2222

Generated on: $(date)
EOF
    
    echo -e "${YELLOW}Connection info saved to: $SLOWDNS_DIR/connection-info.txt${NC}"
    
    read -p "Press Enter to continue..."
}

# SSH User Management Functions
add_ssh_user() {
    print_header
    echo -e "${CYAN}=== Add SSH User ===${NC}"
    echo ""
    
    read -rp "Enter username: " username
    
    # Validate username
    if [[ ! "$username" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
        log "${RED}Invalid username. Use lowercase letters, numbers, dash, underscore${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    # Check if user exists
    if id "$username" &>/dev/null; then
        log "${RED}User $username already exists${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    # Password input
    echo -n "Enter password: "
    read -rs password
    echo
    echo -n "Confirm password: "
    read -rs password2
    echo
    
    if [[ "$password" != "$password2" ]]; then
        log "${RED}Passwords do not match${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    if [[ ${#password} -lt 6 ]]; then
        log "${RED}Password must be at least 6 characters${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    read -rp "Expiry days (0 for no expiry): " expiry_days
    read -rp "Max simultaneous connections (0 for unlimited): " max_connections
    
    # Create user
    if useradd -m -s /bin/bash "$username" 2>/dev/null; then
        echo "$username:$password" | chpasswd
        log "${GREEN}User $username created successfully${NC}"
    else
        log "${RED}Failed to create user${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    # Set expiry date if specified
    if [[ $expiry_days -gt 0 ]]; then
        expiry_date=$(date -d "+$expiry_days days" +%Y-%m-%d)
        chage -E "$expiry_date" "$username" 2>/dev/null
    fi
    
    # Save user info to database
    local user_entry="$username|$(date +%Y-%m-%d)|$expiry_days|$max_connections|active|$(date +%s)"
    echo "$user_entry" >> "$USERS_DB"
    
    # Setup connection limiting
    if [[ $max_connections -gt 0 ]]; then
        # Add to SSH config
        if ! grep -q "Match User $username" /etc/ssh/sshd_config 2>/dev/null; then
            echo "" >> /etc/ssh/sshd_config
            echo "Match User $username" >> /etc/ssh/sshd_config
            echo "    MaxSessions $max_connections" >> /etc/ssh/sshd_config
            systemctl reload sshd
        fi
    fi
    
    echo ""
    echo -e "${GREEN}===================================================${NC}"
    echo -e "${CYAN}USER CREATED SUCCESSFULLY!${NC}"
    echo -e "${GREEN}===================================================${NC}"
    echo -e "${YELLOW}Username:${NC} $username"
    echo -e "${YELLOW}Password:${NC} ********"
    echo -e "${YELLOW}Expiry:${NC} $expiry_days days"
    echo -e "${YELLOW}Max Connections:${NC} $max_connections"
    echo -e "${YELLOW}Home Directory:${NC} /home/$username"
    echo -e "${GREEN}===================================================${NC}"
    
    read -p "Press Enter to continue..."
}

delete_ssh_user() {
    print_header
    echo -e "${CYAN}=== Delete SSH User ===${NC}"
    echo ""
    
    read -rp "Enter username to delete: " username
    
    if ! id "$username" &>/dev/null; then
        log "${RED}User $username does not exist${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo -e "${RED}WARNING: This action cannot be undone!${NC}"
    read -rp "Are you sure you want to delete user '$username'? (y/N): " confirm
    
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        log "${YELLOW}Deletion cancelled${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    read -rp "Delete home directory? (y/N): " del_home
    
    # Remove from SSH config
    sed -i "/Match User $username/,+2d" /etc/ssh/sshd_config 2>/dev/null
    systemctl reload sshd
    
    # Remove from database
    sed -i "/^$username|/d" "$USERS_DB"
    
    # Remove user
    if [[ "$del_home" == "y" || "$del_home" == "Y" ]]; then
        userdel -r "$username" 2>/dev/null
        log "${GREEN}User $username and home directory deleted${NC}"
    else
        userdel "$username" 2>/dev/null
        log "${GREEN}User $username deleted (home directory kept)${NC}"
    fi
    
    read -p "Press Enter to continue..."
}

list_ssh_users() {
    print_header
    echo -e "${CYAN}=== SSH Users List ===${NC}"
    echo ""
    
    echo -e "${GREEN}Active SSH Users:${NC}"
    echo "==================="
    printf "%-15s %-12s %-10s %-8s %-10s\n" "Username" "Created" "Expiry" "Limit" "Status"
    echo "------------------------------------------------------------"
    
    if [[ -s "$USERS_DB" ]]; then
        while IFS='|' read -r username created expiry limit status timestamp; do
            # Calculate days left
            days_left="N/A"
            if [[ $expiry -gt 0 ]]; then
                create_ts=$(date -d "$created" +%s 2>/dev/null || echo 0)
                if [[ $create_ts -gt 0 ]]; then
                    expiry_ts=$((create_ts + (expiry * 86400)))
                    now_ts=$(date +%s)
                    days_left=$(((expiry_ts - now_ts) / 86400))
                    if [[ $days_left -lt 0 ]]; then
                        status="expired"
                    fi
                fi
            fi
            
            printf "%-15s %-12s %-10s %-8s %-10s\n" "$username" "$created" "${days_left}d" "$limit" "$status"
        done < "$USERS_DB"
    else
        echo "No users in database"
    fi
    
    echo ""
    echo -e "${GREEN}Currently connected:${NC}"
    echo "====================="
    who
    
    echo ""
    read -p "Press Enter to continue..."
}

edit_ssh_user() {
    print_header
    echo -e "${CYAN}=== Edit SSH User ===${NC}"
    echo ""
    
    read -rp "Enter username to edit: " username
    
    if ! id "$username" &>/dev/null; then
        log "${RED}User $username does not exist${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    # Find user in database
    local user_entry=$(grep "^$username|" "$USERS_DB")
    if [[ -z "$user_entry" ]]; then
        log "${YELLOW}User not found in database, adding basic entry...${NC}"
        user_entry="$username|$(date +%Y-%m-%d)|0|2|active|$(date +%s)"
        echo "$user_entry" >> "$USERS_DB"
    fi
    
    IFS='|' read -r username created expiry limit status timestamp <<< "$user_entry"
    
    echo -e "${YELLOW}Current settings for $username:${NC}"
    echo -e "${GREEN}=========================================${NC}"
    echo -e "1) Username: $username"
    echo -e "2) Created: $created"
    echo -e "3) Expiry days: $expiry"
    echo -e "4) Max connections: $limit"
    echo -e "5) Status: $status"
    echo -e "${GREEN}=========================================${NC}"
    echo ""
    
    echo -e "${GREEN}Edit options:${NC}"
    echo "1) Change password"
    echo "2) Change expiry days"
    echo "3) Change connection limit"
    echo "4) Toggle active/inactive"
    echo "5) Cancel"
    
    read -rp "Choice [1-5]: " edit_choice
    
    case $edit_choice in
        1)
            echo -n "Enter new password: "
            read -rs new_pass
            echo
            echo -n "Confirm new password: "
            read -rs new_pass2
            echo
            
            if [[ "$new_pass" == "$new_pass2" ]]; then
                echo "$username:$new_pass" | chpasswd
                log "${GREEN}Password changed successfully for $username${NC}"
            else
                log "${RED}Passwords do not match${NC}"
            fi
            ;;
        2)
            read -rp "Enter new expiry days (0 for no expiry): " new_expiry
            if [[ $new_expiry =~ ^[0-9]+$ ]]; then
                if [[ $new_expiry -gt 0 ]]; then
                    expiry_date=$(date -d "+$new_expiry days" +%Y-%m-%d)
                    chage -E "$expiry_date" "$username" 2>/dev/null
                else
                    chage -E -1 "$username" 2>/dev/null
                fi
                sed -i "s/^$username|.*|$expiry|/$username|$created|$new_expiry|/" "$USERS_DB"
                log "${GREEN}Expiry updated to $new_expiry days${NC}"
            else
                log "${RED}Invalid number${NC}"
            fi
            ;;
        3)
            read -rp "Enter new connection limit: " new_limit
            if [[ $new_limit =~ ^[0-9]+$ ]]; then
                # Update SSH config
                sed -i "/Match User $username/,+2d" /etc/ssh/sshd_config 2>/dev/null
                if [[ $new_limit -gt 0 ]]; then
                    echo "" >> /etc/ssh/sshd_config
                    echo "Match User $username" >> /etc/ssh/sshd_config
                    echo "    MaxSessions $new_limit" >> /etc/ssh/sshd_config
                fi
                systemctl reload sshd
                
                sed -i "s/^$username|.*|$limit|/$username|$created|$expiry|$new_limit|/" "$USERS_DB"
                log "${GREEN}Connection limit updated to $new_limit${NC}"
            else
                log "${RED}Invalid number${NC}"
            fi
            ;;
        4)
            if [[ "$status" == "active" ]]; then
                new_status="inactive"
                usermod -L "$username" 2>/dev/null
                log "${YELLOW}User $username locked${NC}"
            else
                new_status="active"
                usermod -U "$username" 2>/dev/null
                log "${GREEN}User $username unlocked${NC}"
            fi
            sed -i "s/^$username|.*|$status|/$username|$created|$expiry|$limit|$new_status|/" "$USERS_DB"
            ;;
        5)
            log "${YELLOW}Edit cancelled${NC}"
            ;;
    esac
    
    read -p "Press Enter to continue..."
}

set_ssh_banner() {
    print_header
    echo -e "${CYAN}=== Set SSH Banner ===${NC}"
    echo ""
    
    echo -e "${YELLOW}Current banner:${NC}"
    echo "================="
    if [[ -f "$BANNER_FILE" ]]; then
        cat "$BANNER_FILE"
    else
        echo "No banner set"
    fi
    echo ""
    
    echo -e "${GREEN}Enter new banner text (press Ctrl+D on empty line when done):${NC}"
    echo "Default text will be included automatically"
    echo ""
    
    # Create banner with default text
    cat > "$BANNER_FILE" << EOF
╔══════════════════════════════════════════╗
║         MADE BY THE KING 👑👑           ║
║                                          ║
║     WhatsApp: +255624932595              ║
║     DM for support                       ║
╚══════════════════════════════════════════╝

EOF
    
    # Append custom text
    echo "=== Your Custom Message ===" >> "$BANNER_FILE"
    echo "Enter your message below (blank line + Ctrl+D to finish):"
    while IFS= read -r line; do
        if [[ -z "$line" ]]; then
            break
        fi
        echo "$line" >> "$BANNER_FILE"
    done
    
    # Add separator
    echo "" >> "$BANNER_FILE"
    echo "══════════════════════════════════════════" >> "$BANNER_FILE"
    echo "Login: $(date)" >> "$BANNER_FILE"
    
    # Update SSH configuration
    if ! grep -q "^Banner" /etc/ssh/sshd_config 2>/dev/null; then
        echo "" >> /etc/ssh/sshd_config
        echo "Banner /etc/issue.net" >> /etc/ssh/sshd_config
    else
        sed -i 's|^Banner.*|Banner /etc/issue.net|' /etc/ssh/sshd_config
    fi
    
    # Ensure PrintMotd is yes
    sed -i 's/^#PrintMotd.*/PrintMotd yes/' /etc/ssh/sshd_config
    sed -i 's/^PrintMotd.*/PrintMotd yes/' /etc/ssh/sshd_config
    
    systemctl reload sshd
    
    log "${GREEN}SSH banner updated successfully${NC}"
    echo ""
    echo -e "${YELLOW}New banner preview:${NC}"
    echo "==================="
    cat "$BANNER_FILE"
    
    read -p "Press Enter to continue..."
}

view_logs() {
    print_header
    echo -e "${CYAN}=== View Logs ===${NC}"
    echo ""
    
    echo -e "${GREEN}Select log type:${NC}"
    echo "1) Script logs"
    echo "2) DNSTT service logs"
    echo "3) SSH authentication logs"
    echo "4) System logs"
    echo "5) DNSTT connection info"
    echo "6) Back"
    
    read -rp "Choice [1-6]: " log_choice
    
    case $log_choice in
        1)
            echo -e "${YELLOW}Last 50 lines of script log:${NC}"
            echo "================================="
            tail -50 "$LOG_FILE" 2>/dev/null || echo "No log file found"
            ;;
        2)
            echo -e "${YELLOW}DNSTT service logs:${NC}"
            echo "====================="
            journalctl -u dnstt -n 30 --no-pager 2>/dev/null || echo "DNSTT service not running"
            ;;
        3)
            echo -e "${YELLOW}SSH authentication logs:${NC}"
            echo "========================="
            tail -50 /var/log/auth.log 2>/dev/null | grep -i ssh || tail -50 /var/log/secure 2>/dev/null | grep -i ssh
            ;;
        4)
            echo -e "${YELLOW}System logs (last 30 lines):${NC}"
            echo "==============================="
            tail -30 /var/log/syslog 2>/dev/null || tail -30 /var/log/messages 2>/dev/null
            ;;
        5)
            if [[ -f "$SLOWDNS_DIR/connection-info.txt" ]]; then
                echo -e "${YELLOW}DNSTT Connection Information:${NC}"
                echo "=================================="
                cat "$SLOWDNS_DIR/connection-info.txt"
            else
                echo -e "${RED}No connection info found${NC}"
                echo -e "${YELLOW}Run DNSTT setup first${NC}"
            fi
            ;;
        6)
            return
            ;;
        *)
            echo -e "${RED}Invalid choice${NC}"
            ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
}

# DNSTT management menu
dnstt_menu() {
    while true; do
        print_header
        
        echo -e "${CYAN}=== DNSTT MANAGEMENT ===${NC}"
        echo ""
        echo -e "${GREEN}1) Setup/Reconfigure DNS Tunnel${NC}"
        echo -e "${GREEN}2) Start DNSTT Service${NC}"
        echo -e "${GREEN}3) Stop DNSTT Service${NC}"
        echo -e "${GREEN}4) Restart DNSTT Service${NC}"
        echo -e "${GREEN}5) View DNSTT Status${NC}"
        echo -e "${GREEN}6) View Connection Details${NC}"
        echo -e "${GREEN}7) Change MTU Size${NC}"
        echo -e "${GREEN}8) Test DNSTT Connection${NC}"
        echo -e "${GREEN}9) Back to Main Menu${NC}"
        echo ""
        
        read -rp "Select option [1-9]: " dnstt_choice
        
        case $dnstt_choice in
            1)
                setup_dnstt
                ;;
            2)
                systemctl start dnstt 2>/dev/null
                if systemctl is-active --quiet dnstt; then
                    log "${GREEN}DNSTT service started${NC}"
                else
                    log "${RED}Failed to start DNSTT service${NC}"
                fi
                sleep 1
                ;;
            3)
                systemctl stop dnstt 2>/dev/null
                log "${YELLOW}DNSTT service stopped${NC}"
                sleep 1
                ;;
            4)
                systemctl restart dnstt 2>/dev/null
                if systemctl is-active --quiet dnstt; then
                    log "${GREEN}DNSTT service restarted${NC}"
                else
                    log "${RED}Failed to restart DNSTT service${NC}"
                fi
                sleep 1
                ;;
            5)
                print_header
                echo -e "${CYAN}=== DNSTT Service Status ===${NC}"
                echo ""
                systemctl status dnstt --no-pager 2>/dev/null || echo "DNSTT service not installed"
                echo ""
                echo -e "${YELLOW}Listening on port 53:${NC}"
                netstat -tulpn | grep ":53 " || echo "Nothing listening on port 53"
                echo ""
                read -p "Press Enter to continue..."
                ;;
            6)
                print_header
                echo -e "${CYAN}=== DNSTT Connection Details ===${NC}"
                echo ""
                if [[ -f "$SLOWDNS_DIR/server.pub" ]]; then
                    if [[ -f "$SLOWDNS_DIR/server.pub.clean" ]]; then
                        PUB_KEY=$(cat "$SLOWDNS_DIR/server.pub.clean")
                    else
                        PUB_KEY=$(grep -v -- "-----" "$SLOWDNS_DIR/server.pub" | tr -d '\n\r ' 2>/dev/null)
                    fi
                    
                    echo -e "${YELLOW}Public Key:${NC}"
                    echo "$PUB_KEY"
                    echo ""
                    echo -e "${YELLOW}Public Key (hex):${NC}"
                    echo -n "$PUB_KEY" | xxd -p | tr -d '\n'
                    echo -e "\n"
                    echo -e "${YELLOW}Domain:${NC} $DEFAULT_DOMAIN"
                    echo -e "${YELLOW}Server IP:${NC} $(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')"
                    echo -e "${YELLOW}Port:${NC} 53/UDP"
                    echo -e "${YELLOW}Forwarding to:${NC} 127.0.0.1:22"
                    
                    # Get current MTU from service file if exists
                    if [[ -f "$DNSTT_SERVICE" ]]; then
                        current_mtu=$(grep -oP '-mtu\s+\K[0-9]+' "$DNSTT_SERVICE" || echo "1200")
                        echo -e "${YELLOW}Current MTU:${NC} $current_mtu bytes"
                    fi
                else
                    log "${RED}DNSTT not configured. Run setup first.${NC}"
                fi
                echo ""
                read -p "Press Enter to continue..."
                ;;
            7)
                print_header
                echo -e "${CYAN}=== Change MTU Size ===${NC}"
                echo ""
                
                echo -e "${YELLOW}Select new MTU size:${NC}"
                echo "1) 512 bytes"
                echo "2) 576 bytes"
                echo "3) 900 bytes"
                echo "4) 1200 bytes (Default)"
                echo "5) 1500 bytes"
                echo "6) Custom MTU"
                echo "7) Cancel"
                
                read -rp "Choice [1-7]: " mtu_choice
                
                case $mtu_choice in
                    1) new_mtu="512" ;;
                    2) new_mtu="576" ;;
                    3) new_mtu="900" ;;
                    4) new_mtu="1200" ;;
                    5) new_mtu="1500" ;;
                    6)
                        read -rp "Enter custom MTU (68-1500): " new_mtu
                        if [[ ! $new_mtu =~ ^[0-9]+$ ]] || [ "$new_mtu" -lt 68 ] || [ "$new_mtu" -gt 1500 ]; then
                            log "${RED}Invalid MTU value${NC}"
                            read -p "Press Enter to continue..."
                            continue
                        fi
                        ;;
                    7)
                        continue
                        ;;
                    *)
                        log "${RED}Invalid choice${NC}"
                        read -p "Press Enter to continue..."
                        continue
                        ;;
                esac
                
                if [[ -f "$DNSTT_SERVICE" ]]; then
                    # Update service file with new MTU
                    sed -i "s/-mtu [0-9]\+/-mtu $new_mtu/g" "$DNSTT_SERVICE"
                    sed -i "s/MTU=[0-9]\+/MTU=$new_mtu/g" "$DNSTT_SERVICE"
                    
                    systemctl daemon-reload
                    systemctl restart dnstt
                    
                    if systemctl is-active --quiet dnstt; then
                        log "${GREEN}MTU changed to $new_mtu bytes. Service restarted.${NC}"
                    else
                        log "${RED}Failed to restart service with new MTU${NC}"
                    fi
                else
                    log "${RED}DNSTT service not configured${NC}"
                fi
                
                read -p "Press Enter to continue..."
                ;;
            8)
                print_header
                echo -e "${CYAN}=== Test DNSTT Connection ===${NC}"
                echo ""
                
                echo -e "${YELLOW}Testing DNS resolution...${NC}"
                
                # Test if DNS is responding
                if dig +short google.com @127.0.0.1 -p 53 >/dev/null 2>&1; then
                    echo -e "${GREEN}✓ DNS server is responding${NC}"
                else
                    echo -e "${RED}✗ DNS server not responding${NC}"
                fi
                
                # Test if service is running
                if systemctl is-active --quiet dnstt; then
                    echo -e "${GREEN}✓ DNSTT service is running${NC}"
                else
                    echo -e "${RED}✗ DNSTT service is not running${NC}"
                fi
                
                # Test port 53
                if netstat -tulpn | grep -q ":53 "; then
                    echo -e "${GREEN}✓ Port 53 is in use${NC}"
                else
                    echo -e "${RED}✗ Port 53 is not in use${NC}"
                fi
                
                # Check keys
                if [[ -f "$SLOWDNS_DIR/server.key" ]] && [[ -f "$SLOWDNS_DIR/server.pub" ]]; then
                    echo -e "${GREEN}✓ Keys exist${NC}"
                else
                    echo -e "${RED}✗ Keys missing${NC}"
                fi
                
                echo ""
                echo -e "${YELLOW}Current configuration:${NC}"
                if [[ -f "$DNSTT_SERVICE" ]]; then
                    grep -E "(ExecStart|MTU|mtu)" "$DNSTT_SERVICE" | head -5
                fi
                
                echo ""
                read -p "Press Enter to continue..."
                ;;
            9)
                return
                ;;
            *)
                log "${RED}Invalid option${NC}"
                sleep 1
                ;;
        esac
    done
}

# SSH management menu
ssh_menu() {
    while true; do
        print_header
        
        echo -e "${CYAN}=== SSH USER MANAGEMENT ===${NC}"
        echo ""
        echo -e "${GREEN}1) Add SSH User${NC}"
        echo -e "${GREEN}2) Delete SSH User${NC}"
        echo -e "${GREEN}3) Edit SSH User${NC}"
        echo -e "${GREEN}4) List SSH Users${NC}"
        echo -e "${GREEN}5) Set SSH Banner${NC}"
        echo -e "${GREEN}6) View SSH Status${NC}"
        echo -e "${GREEN}7) Change SSH Port${NC}"
        echo -e "${GREEN}8) Back to Main Menu${NC}"
        echo ""
        
        read -rp "Select option [1-8]: " ssh_choice
        
        case $ssh_choice in
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
                print_header
                echo -e "${CYAN}=== SSH Service Status ===${NC}"
                echo ""
                systemctl status sshd --no-pager
                echo ""
                echo -e "${YELLOW}SSH configuration:${NC}"
                grep -E "^Port|^PasswordAuthentication|^PermitRootLogin" /etc/ssh/sshd_config 2>/dev/null || echo "Cannot read sshd_config"
                echo ""
                echo -e "${YELLOW}Active SSH connections:${NC}"
                ss -tnp | grep ":22" | grep ESTAB | wc -l
                echo ""
                read -p "Press Enter to continue..."
                ;;
            7)
                print_header
                echo -e "${CYAN}=== Change SSH Port ===${NC}"
                echo ""
                
                current_port=$(grep "^Port" /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' | head -1)
                echo -e "${YELLOW}Current SSH port:${NC} ${current_port:-22}"
                
                read -rp "Enter new SSH port (1-65535): " new_port
                
                if [[ $new_port =~ ^[0-9]+$ ]] && [ "$new_port" -ge 1 ] && [ "$new_port" -le 65535 ]; then
                    # Update SSH config
                    sed -i "s/^Port.*/Port $new_port/" /etc/ssh/sshd_config
                    if ! grep -q "^Port" /etc/ssh/sshd_config; then
                        echo "Port $new_port" >> /etc/ssh/sshd_config
                    fi
                    
                    # Update firewall
                    if command -v ufw &> /dev/null && ufw status | grep -q "Status: active"; then
                        ufw delete allow 22/tcp 2>/dev/null
                        ufw allow "$new_port/tcp" >/dev/null 2>&1
                    else
                        iptables -D INPUT -p tcp --dport 22 -j ACCEPT 2>/dev/null
                        iptables -A INPUT -p tcp --dport "$new_port" -j ACCEPT 2>/dev/null
                        iptables-save > /etc/iptables/rules.v4 2>/dev/null
                    fi
                    
                    # Update DNSTT forwarding if service exists
                    if [[ -f "$DNSTT_SERVICE" ]]; then
                        sed -i "s/127.0.0.1:22/127.0.0.1:$new_port/g" "$DNSTT_SERVICE"
                        systemctl daemon-reload
                        systemctl restart dnstt
                    fi
                    
                    systemctl reload sshd
                    
                    log "${GREEN}SSH port changed to $new_port${NC}"
                    echo -e "${YELLOW}Note:${NC} You must update DNSTT client to connect to new port"
                else
                    log "${RED}Invalid port number${NC}"
                fi
                
                read -p "Press Enter to continue..."
                ;;
            8)
                return
                ;;
            *)
                log "${RED}Invalid option${NC}"
                sleep 1
                ;;
        esac
    done
}

# Main menu
main_menu() {
    while true; do
        print_header
        
        echo -e "${CYAN}=== MAIN MENU ===${NC}"
        echo ""
        echo -e "${GREEN}1) DNS Tunnel (DNSTT) Management${NC}"
        echo -e "${GREEN}2) SSH User Management${NC}"
        echo -e "${GREEN}3) View Logs${NC}"
        echo -e "${GREEN}4) Install/Update Script${NC}"
        echo -e "${GREEN}5) System Information${NC}"
        echo -e "${GREEN}6) Exit${NC}"
        echo ""
        
        read -rp "Select option [1-6]: " main_choice
        
        case $main_choice in
            1)
                dnstt_menu
                ;;
            2)
                ssh_menu
                ;;
            3)
                view_logs
                ;;
            4)
                install_script
                ;;
            5)
                print_header
                echo -e "${CYAN}=== System Information ===${NC}"
                echo ""
                echo -e "${YELLOW}Hostname:${NC} $(hostname)"
                echo -e "${YELLOW}IP Address:${NC} $(hostname -I | awk '{print $1}')"
                echo -e "${YELLOW}Public IP:${NC} $(curl -s ifconfig.me 2>/dev/null || echo "Not available")"
                echo -e "${YELLOW}Kernel:${NC} $(uname -r)"
                echo -e "${YELLOW}Uptime:${NC} $(uptime -p | sed 's/up //')"
                echo -e "${YELLOW}Load Average:${NC} $(uptime | awk -F'load average:' '{print $2}')"
                echo -e "${YELLOW}Memory:${NC} $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
                echo -e "${YELLOW}Disk Usage:${NC} $(df -h / | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}')"
                echo ""
                echo -e "${YELLOW}Services:${NC}"
                echo -e "DNSTT: $(systemctl is-active dnstt 2>/dev/null || echo "Not installed")"
                echo -e "SSH: $(systemctl is-active sshd 2>/dev/null || echo "Not active")"
                echo ""
                read -p "Press Enter to continue..."
                ;;
            6)
                echo -e "${GREEN}Goodbye! 👑${NC}"
                echo -e "${YELLOW}WhatsApp: +255624932595${NC}"
                exit 0
                ;;
            *)
                log "${RED}Invalid option${NC}"
                sleep 1
                ;;
        esac
    done
}

# Install script to system
install_script() {
    print_header
    echo -e "${CYAN}=== Install/Update Script ===${NC}"
    echo ""
    
    local script_path="/usr/local/bin/slowdns"
    local symlink_path="/usr/local/bin/slowdns-menu"
    
    # Copy current script
    cp "$0" "$script_path"
    chmod +x "$script_path"
    
    # Create symlink
    ln -sf "$script_path" "$symlink_path" 2>/dev/null
    
    # Create uninstall script
    cat > "/usr/local/bin/slowdns-uninstall" << 'EOF'
#!/bin/bash
echo "Uninstalling SlowDNS..."
systemctl stop dnstt 2>/dev/null
systemctl disable dnstt 2>/dev/null
rm -f /etc/systemd/system/dnstt.service
rm -f /usr/local/bin/dnstt-server
rm -f /usr/local/bin/slowdns
rm -f /usr/local/bin/slowdns-menu
rm -f /usr/local/bin/slowdns-uninstall
echo "SlowDNS uninstalled. Configs kept in /etc/slowdns/"
EOF
    chmod +x "/usr/local/bin/slowdns-uninstall"
    
    log "${GREEN}Script installed successfully!${NC}"
    echo ""
    echo -e "${YELLOW}Usage:${NC}"
    echo -e "  slowdns-menu              - Start management menu"
    echo -e "  slowdns-uninstall         - Uninstall script (keeps configs)"
    echo ""
    echo -e "${YELLOW}Files installed:${NC}"
    echo -e "  /usr/local/bin/slowdns          - Main script"
    echo -e "  /usr/local/bin/slowdns-menu     - Menu shortcut"
    echo -e "  /etc/slowdns/                   - Configuration directory"
    echo ""
    
    # Auto-start on boot
    read -rp "Create auto-start service? (y/N): " autostart
    if [[ "$autostart" == "y" || "$autostart" == "Y" ]]; then
        cat > /etc/systemd/system/slowdns-autostart.service << EOF
[Unit]
Description=SlowDNS Auto-start
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/slowdns-menu --auto
RemainAfterExit=no

[Install]
WantedBy=multi-user.target
EOF
        systemctl daemon-reload
        systemctl enable slowdns-autostart 2>/dev/null
        log "${GREEN}Auto-start service created${NC}"
    fi
    
    read -p "Press Enter to continue..."
}

# Initial setup
install_dependencies

# Start main menu
main_menu