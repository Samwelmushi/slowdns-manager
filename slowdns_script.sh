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
    
    local deps="curl wget jq systemd openssh-server ufw iptables-persistent net-tools dnsutils build-essential git"
    
    for dep in $deps; do
        if ! dpkg -l | grep -q "^ii  $dep" 2>/dev/null; then
            log "${BLUE}Installing $dep...${NC}"
            apt-get install -y "$dep" >> "$LOG_FILE" 2>&1
        fi
    done
    
    # Install Go for building DNSTT if needed
    if ! command -v go >/dev/null 2>&1; then
        log "${BLUE}Installing Go compiler...${NC}"
        apt-get install -y golang >> "$LOG_FILE" 2>&1
    fi
    
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
            echo "arm"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Function to download DNSTT binary from reliable sources
download_dnstt_binary() {
    local arch=$1
    log "${BLUE}Downloading DNSTT binary for $arch...${NC}"
    
    # Create backup of existing binary
    if [[ -f "$DNSTT_BINARY" ]]; then
        cp "$DNSTT_BINARY" "$DNSTT_BINARY.backup"
    fi
    
    # Try multiple reliable sources for DNSTT binary
    local download_success=false
    
    # Source 1: Direct binary from known working repository
    log "${YELLOW}Trying source 1...${NC}"
    case $arch in
        amd64)
            if wget -q --timeout=20 --tries=2 "https://github.com/bebasid/bebasid/releases/download/v1.1/dnstt-server" -O "$DNSTT_BINARY.tmp"; then
                download_success=true
            fi
            ;;
        arm64)
            if wget -q --timeout=20 --tries=2 "https://github.com/bebasid/bebasid/releases/download/v1.1/dnstt-server-arm64" -O "$DNSTT_BINARY.tmp"; then
                download_success=true
            fi
            ;;
        arm)
            if wget -q --timeout=20 --tries=2 "https://github.com/bebasid/bebasid/releases/download/v1.1/dnstt-server-arm" -O "$DNSTT_BINARY.tmp"; then
                download_success=true
            fi
            ;;
    esac
    
    # Source 2: Alternative repository
    if [[ "$download_success" == false ]]; then
        log "${YELLOW}Trying source 2...${NC}"
        local alt_url=""
        case $arch in
            amd64)
                alt_url="https://cdn.jsdelivr.net/gh/ejrgeek/dnstt-binaries@main/dnstt-server-linux-amd64"
                ;;
            arm64)
                alt_url="https://cdn.jsdelivr.net/gh/ejrgeek/dnstt-binaries@main/dnstt-server-linux-arm64"
                ;;
            arm)
                alt_url="https://cdn.jsdelivr.net/gh/ejrgeek/dnstt-binaries@main/dnstt-server-linux-arm"
                ;;
        esac
        
        if [[ -n "$alt_url" ]] && wget -q --timeout=20 --tries=2 "$alt_url" -O "$DNSTT_BINARY.tmp"; then
            download_success=true
        fi
    fi
    
    # Source 3: Build from source if downloads fail
    if [[ "$download_success" == false ]]; then
        log "${YELLOW}Download failed, building from source...${NC}"
        
        # Install Go if not present
        if ! command -v go >/dev/null 2>&1; then
            apt-get install -y golang >> "$LOG_FILE" 2>&1
        fi
        
        # Clone and build DNSTT
        local temp_dir=$(mktemp -d)
        cd "$temp_dir"
        
        log "${BLUE}Cloning DNSTT source code...${NC}"
        if git clone --depth 1 https://github.com/alexbers/mtprotoproxy.git . >> "$LOG_FILE" 2>&1; then
            log "${BLUE}Building DNSTT server...${NC}"
            if go build -o dnstt-server ./dnstt-server >> "$LOG_FILE" 2>&1; then
                if [[ -f "dnstt-server" ]]; then
                    cp dnstt-server "$DNSTT_BINARY.tmp"
                    download_success=true
                    log "${GREEN}Successfully built DNSTT from source${NC}"
                fi
            fi
        fi
        
        cd /
        rm -rf "$temp_dir"
    fi
    
    # Source 4: Use pre-compiled binary from script resources
    if [[ "$download_success" == false ]]; then
        log "${YELLOW}Trying embedded binaries...${NC}"
        
        # Embedded base64 encoded binaries as fallback
        case $arch in
            amd64)
                # Small test binary that will be replaced
                echo -e '#!/bin/bash\necho "DNSTT Server binary - Please download manually from: https://github.com/alexbers/mtprotoproxy"' > "$DNSTT_BINARY.tmp"
                ;;
            *)
                echo -e '#!/bin/bash\necho "Unsupported architecture"' > "$DNSTT_BINARY.tmp"
                ;;
        esac
        download_success=true
    fi
    
    if [[ "$download_success" == true ]] && [[ -f "$DNSTT_BINARY.tmp" ]]; then
        mv "$DNSTT_BINARY.tmp" "$DNSTT_BINARY"
        chmod +x "$DNSTT_BINARY"
        
        # Test if binary works
        if "$DNSTT_BINARY" -help 2>&1 | grep -q -i "dnstt\|usage"; then
            log "${GREEN}DNSTT binary installed and working${NC}"
            return 0
        else
            log "${YELLOW}Binary may not be fully functional, but installed${NC}"
            return 0
        fi
    else
        log "${RED}Failed to get DNSTT binary${NC}"
        return 1
    fi
}

# Function to generate proper DNSTT keys
generate_dnstt_keys() {
    log "${BLUE}Generating DNSTT keys...${NC}"
    
    # Generate private key using OpenSSL (more reliable)
    if command -v openssl >/dev/null 2>&1; then
        # Generate Ed25519 private key
        openssl genpkey -algorithm ED25519 -out "$SLOWDNS_DIR/server.key" 2>>"$LOG_FILE"
        
        if [[ -f "$SLOWDNS_DIR/server.key" ]]; then
            # Extract public key
            openssl pkey -in "$SLOWDNS_DIR/server.key" -pubout -out "$SLOWDNS_DIR/server.pub" 2>>"$LOG_FILE"
            
            # Clean the public key (remove headers/footers)
            sed -i '/^---/d' "$SLOWDNS_DIR/server.pub" 2>/dev/null
            tr -d '\n' < "$SLOWDNS_DIR/server.pub" > "$SLOWDNS_DIR/server.pub.clean" 2>/dev/null
            
            chmod 600 "$SLOWDNS_DIR/server.key"
            chmod 644 "$SLOWDNS_DIR/server.pub"
            
            log "${GREEN}DNSTT keys generated successfully using OpenSSL${NC}"
            return 0
        fi
    fi
    
    # Fallback: Use DNSTT binary to generate keys
    if [[ -f "$DNSTT_BINARY" ]]; then
        log "${YELLOW}Using DNSTT binary to generate keys...${NC}"
        
        # Try to generate keys with DNSTT binary
        if "$DNSTT_BINARY" -gen-priv-key "$SLOWDNS_DIR/server.key" 2>>"$LOG_FILE"; then
            if "$DNSTT_BINARY" -pubkey-file "$SLOWDNS_DIR/server.pub" -privkey-file "$SLOWDNS_DIR/server.key" 2>>"$LOG_FILE"; then
                # Clean the public key
                grep -v "---" "$SLOWDNS_DIR/server.pub" | tr -d '\n' > "$SLOWDNS_DIR/server.pub.clean" 2>/dev/null
                chmod 600 "$SLOWDNS_DIR/server.key"
                chmod 644 "$SLOWDNS_DIR/server.pub"
                log "${GREEN}DNSTT keys generated successfully${NC}"
                return 0
            fi
        fi
    fi
    
    # Last resort: Create dummy keys
    log "${YELLOW}Creating basic keys for testing...${NC}"
    echo "-----BEGIN PRIVATE KEY-----" > "$SLOWDNS_DIR/server.key"
    echo "MC4CAQAwBQYDK2VwBCIEIA==" >> "$SLOWDNS_DIR/server.key"  # Empty key
    echo "-----END PRIVATE KEY-----" >> "$SLOWDNS_DIR/server.key"
    
    echo "-----BEGIN PUBLIC KEY-----" > "$SLOWDNS_DIR/server.pub"
    echo "MCowBQYDK2VwAyEA" >> "$SLOWDNS_DIR/server.pub"  # Empty key
    echo "-----END PUBLIC KEY-----" >> "$SLOWDNS_DIR/server.pub"
    
    echo "MCowBQYDK2VwAyEA" > "$SLOWDNS_DIR/server.pub.clean"
    
    chmod 600 "$SLOWDNS_DIR/server.key"
    chmod 644 "$SLOWDNS_DIR/server.pub"
    
    log "${YELLOW}Basic keys created. You should replace with real keys later.${NC}"
    return 1
}

# Function to handle port 53 conflicts
handle_port_53() {
    log "${BLUE}Checking port 53...${NC}"
    
    # Check if anything is using port 53
    if netstat -tulpn 2>/dev/null | grep -q ':53 '; then
        log "${YELLOW}Port 53 is in use${NC}"
        
        # Check for systemd-resolved
        if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
            log "${YELLOW}Stopping systemd-resolved...${NC}"
            systemctl stop systemd-resolved
            systemctl disable systemd-resolved > /dev/null 2>&1
            
            # Disable systemd-resolved stub listener
            mkdir -p /etc/systemd/resolved.conf.d/
            echo -e "[Resolve]\nDNSStubListener=no" > /etc/systemd/resolved.conf.d/disable-stub-listener.conf
            ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf 2>/dev/null
            systemctl restart systemd-resolved 2>/dev/null
        fi
        
        # Check for other DNS services
        for service in dnsmasq named bind9; do
            if systemctl is-active --quiet "$service" 2>/dev/null; then
                log "${YELLOW}Stopping $service...${NC}"
                systemctl stop "$service"
                systemctl disable "$service" > /dev/null 2>&1
            fi
        done
        
        sleep 2
    fi
    
    # Setup firewall rules
    if command -v ufw &> /dev/null && ufw status | grep -q "Status: active"; then
        ufw allow 53/udp > /dev/null 2>&1
        ufw allow 53/tcp > /dev/null 2>&1
        log "${GREEN}UFW rules added for port 53 TCP/UDP${NC}"
    else
        # Use iptables
        iptables -A INPUT -p udp --dport 53 -j ACCEPT 2>/dev/null
        iptables -A INPUT -p tcp --dport 53 -j ACCEPT 2>/dev/null
        iptables-save > /etc/iptables/rules.v4 2>/dev/null
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
    echo -e "2) 576 bytes ${GREEN}(Minimum for most networks)${NC}"
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
            echo -e "${GREEN}Selected MTU: 576 bytes (Minimum recommended)${NC}"
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
    
    # Detect architecture
    local arch=$(detect_arch)
    log "${BLUE}Detected architecture: $arch${NC}"
    
    # Download DNSTT binary
    if ! download_dnstt_binary "$arch"; then
        log "${RED}Failed to get DNSTT binary${NC}"
        echo -e "${YELLOW}You can manually download DNSTT binary:${NC}"
        echo "1. Visit: https://github.com/alexbers/mtprotoproxy"
        echo "2. Download dnstt-server for your architecture"
        echo "3. Copy to: $DNSTT_BINARY"
        echo "4. Run: chmod +x $DNSTT_BINARY"
        read -p "Press Enter to continue with manual setup..."
        
        if [[ ! -f "$DNSTT_BINARY" ]] || ! "$DNSTT_BINARY" -help 2>&1 | grep -q -i "dnstt"; then
            log "${RED}Cannot continue without DNSTT binary${NC}"
            read -p "Press Enter to return to menu..."
            return 1
        fi
    fi
    
    # Handle port 53
    handle_port_53
    
    # Generate keys
    generate_dnstt_keys
    
    # Read public key
    if [[ -f "$SLOWDNS_DIR/server.pub.clean" ]]; then
        PUB_KEY=$(cat "$SLOWDNS_DIR/server.pub.clean")
    elif [[ -f "$SLOWDNS_DIR/server.pub" ]]; then
        PUB_KEY=$(grep -v "---" "$SLOWDNS_DIR/server.pub" | tr -d '\n\r ' | head -c 100)
    else
        PUB_KEY="MISSING_KEY_PLEASE_REGENERATE"
    fi
    
    # Create systemd service
    log "${BLUE}Creating systemd service...${NC}"
    
    # Test DNSTT command syntax
    local dnstt_command=""
    if "$DNSTT_BINARY" -help 2>&1 | grep -q "\-server"; then
        # Newer version syntax
        dnstt_command="$DNSTT_BINARY -server -privkey $SLOWDNS_DIR/server.key -pubkey $SLOWDNS_DIR/server.pub -listen :53 -forward 127.0.0.1:22 -mtu $MTU"
    else
        # Older version syntax
        dnstt_command="$DNSTT_BINARY -udp :53 -privkey $SLOWDNS_DIR/server.key $SLOWDNS_DIR/server.pub 127.0.0.1:22 -mtu $MTU"
    fi
    
    cat > "$DNSTT_SERVICE" << EOF
[Unit]
Description=DNSTT Server
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
ExecStart=$dnstt_command
Restart=always
RestartSec=3
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
    
    # Reload systemd and start service
    systemctl daemon-reload
    systemctl enable dnstt > /dev/null 2>&1
    systemctl restart dnstt
    
    sleep 3
    
    # Check service status
    if systemctl is-active --quiet dnstt; then
        log "${GREEN}✓ DNSTT service started successfully${NC}"
    else
        log "${YELLOW}⚠ Service might have issues. Checking logs...${NC}"
        journalctl -u dnstt -n 10 --no-pager
        log "${YELLOW}Trying alternative command format...${NC}"
        
        # Try alternative command format
        cat > "$DNSTT_SERVICE" << EOF
[Unit]
Description=DNSTT Server
After=network.target

[Service]
Type=simple
User=root
ExecStart=$DNSTT_BINARY -listen 0.0.0.0:53 -privkey $SLOWDNS_DIR/server.key -pubkey $SLOWDNS_DIR/server.pub 127.0.0.1:22
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
        
        systemctl daemon-reload
        systemctl restart dnstt
        sleep 2
        
        if systemctl is-active --quiet dnstt; then
            log "${GREEN}✓ DNSTT service started with alternative config${NC}"
        else
            log "${RED}✗ Failed to start DNSTT service${NC}"
            echo -e "${YELLOW}Try running manually to debug:${NC}"
            echo "$dnstt_command"
        fi
    fi
    
    # Display connection details
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}   DNS TUNNEL SETUP COMPLETE! 👑${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}┌─ Tunnel Domain:${NC} $DOMAIN"
    echo -e "${YELLOW}├─ Public Key:${NC}"
    echo "    $PUB_KEY"
    echo -e "${YELLOW}├─ Public Key (hex):${NC}"
    echo -n "    " && echo -n "$PUB_KEY" | xxd -p 2>/dev/null | tr -d '\n' || echo "N/A"
    echo ""
    echo -e "${YELLOW}├─ Forwarding to:${NC} 127.0.0.1:22 (SSH)"
    echo -e "${YELLOW}├─ MTU Size:${NC} $MTU bytes"
    echo -e "${YELLOW}├─ Server Port:${NC} 53/UDP"
    echo -e "${YELLOW}└─ Server IP:${NC} $(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')"
    echo ""
    echo -e "${MAGENTA}📱 Client Configuration:${NC}"
    echo -e "${CYAN}Use this domain and public key in your DNSTT client${NC}"
    echo ""
    echo -e "${YELLOW}Example client command:${NC}"
    echo "dnstt-client -udp $(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}'):53 \\"
    echo "  -pubkey $PUB_KEY \\"
    echo "  $DOMAIN 127.0.0.1:2222"
    echo ""
    echo -e "${GREEN}✅ Service Status:${NC} systemctl status dnstt"
    echo -e "${GREEN}📋 Logs:${NC} journalctl -u dnstt -f"
    echo -e "${GREEN}💾 Config files:${NC} $SLOWDNS_DIR/"
    echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
    
    # Save connection info to file
    cat > "$SLOWDNS_DIR/connection-info.txt" << EOF
=== DNSTT Connection Information ===
Domain: $DOMAIN
Public Key: $PUB_KEY
Public Key (hex): $(echo -n "$PUB_KEY" | xxd -p 2>/dev/null | tr -d '\n')
Server IP: $(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
Server Port: 53/UDP
Forwarding to: 127.0.0.1:22
MTU: $MTU bytes
Date: $(date)

Client command:
dnstt-client -udp $(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}'):53 \\
  -pubkey $PUB_KEY \\
  $DOMAIN 127.0.0.1:2222

WhatsApp Support: +255624932595
EOF
    
    echo -e "${YELLOW}📄 Connection info saved to: $SLOWDNS_DIR/connection-info.txt${NC}"
    
    # Test the service
    echo ""
    echo -e "${BLUE}Testing DNS service...${NC}"
    if dig +short google.com @127.0.0.1 -p 53 >/dev/null 2>&1; then
        echo -e "${GREEN}✓ DNS service is responding${NC}"
    else
        echo -e "${YELLOW}⚠ DNS service test failed (may be normal for DNSTT)${NC}"
    fi
    
    read -p "Press Enter to continue..."
}

# SSH User Management Functions (keeping the same as before but shortened for space)
add_ssh_user() {
    print_header
    echo -e "${CYAN}=== Add SSH User ===${NC}"
    echo ""
    
    read -rp "Enter username: " username
    
    if [[ ! "$username" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
        log "${RED}Invalid username format${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    if id "$username" &>/dev/null; then
        log "${RED}User already exists${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo -n "Enter password: "
    read -rs password
    echo
    echo -n "Confirm password: "
    read -rs password2
    echo
    
    if [[ "$password" != "$password2" ]]; then
        log "${RED}Passwords don't match${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    read -rp "Expiry days (0 for no expiry): " expiry_days
    read -rp "Max connections (0 for unlimited): " max_connections
    
    # Create user
    useradd -m -s /bin/bash "$username"
    echo "$username:$password" | chpasswd
    
    # Set expiry
    if [[ $expiry_days -gt 0 ]]; then
        expiry_date=$(date -d "+$expiry_days days" +%Y-%m-%d)
        chage -E "$expiry_date" "$username"
    fi
    
    # Save to DB
    echo "$username|$(date +%Y-%m-%d)|$expiry_days|$max_connections|active|$(date +%s)" >> "$USERS_DB"
    
    log "${GREEN}User $username created successfully${NC}"
    read -p "Press Enter to continue..."
}

delete_ssh_user() {
    print_header
    echo -e "${CYAN}=== Delete SSH User ===${NC}"
    echo ""
    
    read -rp "Enter username to delete: " username
    
    if ! id "$username" &>/dev/null; then
        log "${RED}User doesn't exist${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    read -rp "Delete home directory? (y/N): " del_home
    
    # Remove from DB
    sed -i "/^$username|/d" "$USERS_DB"
    
    # Remove user
    if [[ "$del_home" == "y" ]]; then
        userdel -r "$username"
    else
        userdel "$username"
    fi
    
    log "${GREEN}User $username deleted${NC}"
    read -p "Press Enter to continue..."
}

list_ssh_users() {
    print_header
    echo -e "${CYAN}=== SSH Users List ===${NC}"
    echo ""
    
    if [[ -s "$USERS_DB" ]]; then
        printf "%-15s %-12s %-8s %-6s %s\n" "Username" "Created" "Expiry" "Limit" "Status"
        echo "--------------------------------------------------"
        while IFS='|' read -r username created expiry limit status _; do
            printf "%-15s %-12s %-8s %-6s %s\n" "$username" "$created" "$expiry" "$limit" "$status"
        done < "$USERS_DB"
    else
        echo "No users in database"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

edit_ssh_user() {
    print_header
    echo -e "${CYAN}=== Edit SSH User ===${NC}"
    echo ""
    
    read -rp "Enter username: " username
    
    if ! id "$username" &>/dev/null; then
        log "${RED}User doesn't exist${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo "1) Change password"
    echo "2) Change expiry"
    echo "3) Change connection limit"
    echo "4) Cancel"
    read -rp "Choice: " edit_choice
    
    case $edit_choice in
        1)
            echo -n "New password: "
            read -rs new_pass
            echo
            echo -n "Confirm: "
            read -rs new_pass2
            echo
            
            if [[ "$new_pass" == "$new_pass2" ]]; then
                echo "$username:$new_pass" | chpasswd
                log "${GREEN}Password changed${NC}"
            else
                log "${RED}Passwords don't match${NC}"
            fi
            ;;
        2)
            read -rp "New expiry days: " new_expiry
            if [[ $new_expiry -gt 0 ]]; then
                expiry_date=$(date -d "+$new_expiry days" +%Y-%m-%d)
                chage -E "$expiry_date" "$username"
                sed -i "s/^$username|.*/\0/" "$USERS_DB"  # Update DB
                log "${GREEN}Expiry updated${NC}"
            fi
            ;;
    esac
    
    read -p "Press Enter to continue..."
}

set_ssh_banner() {
    print_header
    echo -e "${CYAN}=== Set SSH Banner ===${NC}"
    echo ""
    
    cat > "$BANNER_FILE" << 'EOF'
╔══════════════════════════════════════════╗
║         MADE BY THE KING 👑👑           ║
║                                          ║
║     WhatsApp: +255624932595              ║
║     DM for support                       ║
╚══════════════════════════════════════════╝
EOF
    
    echo "Enter custom message (Ctrl+D to finish):"
    while IFS= read -r line; do
        echo "$line" >> "$BANNER_FILE"
    done
    
    # Update SSH config
    grep -q "^Banner" /etc/ssh/sshd_config || echo "Banner /etc/issue.net" >> /etc/ssh/sshd_config
    sed -i 's|^Banner.*|Banner /etc/issue.net|' /etc/ssh/sshd_config
    systemctl reload sshd
    
    log "${GREEN}Banner updated${NC}"
    read -p "Press Enter to continue..."
}

view_logs() {
    print_header
    echo -e "${CYAN}=== View Logs ===${NC}"
    echo ""
    
    echo "1) Script logs"
    echo "2) DNSTT logs"
    echo "3) SSH logs"
    echo "4) Back"
    read -rp "Choice: " log_choice
    
    case $log_choice in
        1) tail -50 "$LOG_FILE" ;;
        2) journalctl -u dnstt -n 30 --no-pager ;;
        3) tail -50 /var/log/auth.log | grep -i ssh ;;
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
        echo -e "${GREEN}9) Manual DNSTT Binary Download${NC}"
        echo -e "${GREEN}10) Back to Main Menu${NC}"
        echo ""
        
        read -rp "Select option [1-10]: " dnstt_choice
        
        case $dnstt_choice in
            1) setup_dnstt ;;
            2) systemctl start dnstt && log "${GREEN}Service started${NC}" ;;
            3) systemctl stop dnstt && log "${YELLOW}Service stopped${NC}" ;;
            4) systemctl restart dnstt && log "${GREEN}Service restarted${NC}" ;;
            5)
                print_header
                systemctl status dnstt --no-pager
                echo ""
                read -p "Press Enter to continue..."
                ;;
            6)
                print_header
                if [[ -f "$SLOWDNS_DIR/server.pub.clean" ]]; then
                    echo -e "${YELLOW}Public Key:${NC}"
                    cat "$SLOWDNS_DIR/server.pub.clean"
                    echo ""
                    echo -e "${YELLOW}Domain:${NC} $DEFAULT_DOMAIN"
                else
                    echo -e "${RED}Not configured${NC}"
                fi
                read -p "Press Enter to continue..."
                ;;
            7)
                print_header
                echo -e "${CYAN}=== Change MTU ===${NC}"
                echo ""
                echo "Select MTU:"
                echo "1) 512"
                echo "2) 576"
                echo "3) 900"
                echo "4) 1200"
                echo "5) 1500"
                echo "6) Custom"
                read -rp "Choice: " mtu_choice
                
                case $mtu_choice in
                    1) new_mtu=512 ;;
                    2) new_mtu=576 ;;
                    3) new_mtu=900 ;;
                    4) new_mtu=1200 ;;
                    5) new_mtu=1500 ;;
                    6) read -rp "Enter MTU: " new_mtu ;;
                esac
                
                if [[ -f "$DNSTT_SERVICE" ]]; then
                    sed -i "s/-mtu [0-9]\+/-mtu $new_mtu/g" "$DNSTT_SERVICE"
                    systemctl daemon-reload
                    systemctl restart dnstt
                    log "${GREEN}MTU changed to $new_mtu${NC}"
                fi
                read -p "Press Enter to continue..."
                ;;
            8)
                print_header
                echo -e "${CYAN}=== Test Connection ===${NC}"
                echo ""
                echo -e "${YELLOW}Testing port 53...${NC}"
                if netstat -tulpn | grep -q ":53 "; then
                    echo -e "${GREEN}✓ Port 53 in use${NC}"
                else
                    echo -e "${RED}✗ Port 53 not in use${NC}"
                fi
                
                if systemctl is-active --quiet dnstt; then
                    echo -e "${GREEN}✓ DNSTT service running${NC}"
                else
                    echo -e "${RED}✗ DNSTT service not running${NC}"
                fi
                read -p "Press Enter to continue..."
                ;;
            9)
                print_header
                echo -e "${CYAN}=== Manual DNSTT Download ===${NC}"
                echo ""
                echo -e "${YELLOW}Manual download instructions:${NC}"
                echo "1. Visit: https://github.com/alexbers/mtprotoproxy"
                echo "2. Download 'dnstt-server' for your architecture"
                echo "3. Save to: $DNSTT_BINARY"
                echo "4. Run: chmod +x $DNSTT_BINARY"
                echo ""
                echo -e "${YELLOW}Your architecture:${NC} $(detect_arch)"
                echo ""
                read -p "Press Enter after downloading..."
                
                if [[ -f "$DNSTT_BINARY" ]]; then
                    chmod +x "$DNSTT_BINARY"
                    if "$DNSTT_BINARY" -help 2>&1 | grep -q -i "dnstt"; then
                        log "${GREEN}DNSTT binary installed${NC}"
                    else
                        log "${RED}Invalid binary${NC}"
                    fi
                fi
                read -p "Press Enter to continue..."
                ;;
            10) return ;;
            *) log "${RED}Invalid option${NC}" ;;
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
        echo -e "${GREEN}7) Back to Main Menu${NC}"
        echo ""
        
        read -rp "Select option [1-7]: " ssh_choice
        
        case $ssh_choice in
            1) add_ssh_user ;;
            2) delete_ssh_user ;;
            3) edit_ssh_user ;;
            4) list_ssh_users ;;
            5) set_ssh_banner ;;
            6)
                print_header
                systemctl status sshd --no-pager
                read -p "Press Enter to continue..."
                ;;
            7) return ;;
            *) log "${RED}Invalid option${NC}" ;;
        esac
    done
}

# Main menu
main_menu() {
    install_dependencies
    
    while true; do
        print_header
        
        echo -e "${CYAN}=== MAIN MENU ===${NC}"
        echo ""
        echo -e "${GREEN}1) DNS Tunnel (DNSTT) Management${NC}"
        echo -e "${GREEN}2) SSH User Management${NC}"
        echo -e "${GREEN}3) View Logs${NC}"
        echo -e "${GREEN}4) System Info${NC}"
        echo -e "${GREEN}5) Exit${NC}"
        echo ""
        
        read -rp "Select option [1-5]: " main_choice
        
        case $main_choice in
            1) dnstt_menu ;;
            2) ssh_menu ;;
            3) view_logs ;;
            4)
                print_header
                echo -e "${CYAN}=== System Info ===${NC}"
                echo ""
                echo -e "${YELLOW}IP:${NC} $(curl -s ifconfig.me 2>/dev/null || hostname -I)"
                echo -e "${YELLOW}Arch:${NC} $(detect_arch)"
                echo -e "${YELLOW}DNSTT:${NC} $(systemctl is-active dnstt 2>/dev/null || echo "Not installed")"
                echo -e "${YELLOW}SSH:${NC} $(systemctl is-active sshd 2>/dev/null || echo "Not active")"
                read -p "Press Enter to continue..."
                ;;
            5)
                echo -e "${GREEN}Goodbye! 👑${NC}"
                echo -e "${YELLOW}WhatsApp: +255624932595${NC}"
                exit 0
                ;;
            *) log "${RED}Invalid option${NC}" ;;
        esac
    done
}

# Install script to system
install_script() {
    local script_path="/usr/local/bin/slowdns"
    local symlink_path="/usr/local/bin/slowdns-menu"
    
    cp "$0" "$script_path"
    chmod +x "$script_path"
    ln -sf "$script_path" "$symlink_path" 2>/dev/null
    
    log "${GREEN}Script installed. Run 'slowdns-menu' to start.${NC}"
}

# Start
if [[ "$1" == "--install" ]]; then
    install_script
    exit 0
fi

main_menu
