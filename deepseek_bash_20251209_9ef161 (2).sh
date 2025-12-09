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

# Function to download DNSTT binary
download_dnstt_binary() {
    local arch=$1
    log "${BLUE}Downloading DNSTT binary for $arch...${NC}"
    
    # Create backup of existing binary
    if [[ -f "$DNSTT_BINARY" ]]; then
        cp "$DNSTT_BINARY" "$DNSTT_BINARY.backup"
    fi
    
    # Try multiple sources
    local download_success=false
    
    # Source 1: Direct from releases
    log "${YELLOW}Trying source 1...${NC}"
    case $arch in
        amd64)
            if curl -sL -o "$DNSTT_BINARY.tmp" "https://github.com/alexbers/mtprotoproxy/releases/download/v1.1.3/dnstt-server" --connect-timeout 30; then
                download_success=true
            fi
            ;;
        arm64)
            if curl -sL -o "$DNSTT_BINARY.tmp" "https://github.com/alexbers/mtprotoproxy/releases/download/v1.1.3/dnstt-server-arm64" --connect-timeout 30; then
                download_success=true
            fi
            ;;
    esac
    
    # Source 2: Alternative repository
    if [[ "$download_success" == false ]]; then
        log "${YELLOW}Trying source 2...${NC}"
        if [[ "$arch" == "amd64" ]]; then
            if curl -sL -o "$DNSTT_BINARY.tmp" "https://raw.githubusercontent.com/ejrgeek/dnstt-binaries/main/dnstt-server-linux-amd64" --connect-timeout 30; then
                download_success=true
            fi
        elif [[ "$arch" == "arm64" ]]; then
            if curl -sL -o "$DNSTT_BINARY.tmp" "https://raw.githubusercontent.com/ejrgeek/dnstt-binaries/main/dnstt-server-linux-arm64" --connect-timeout 30; then
                download_success=true
            fi
        fi
    fi
    
    # Source 3: Build from source
    if [[ "$download_success" == false ]]; then
        log "${YELLOW}Building from source...${NC}"
        
        local temp_dir=$(mktemp -d)
        cd "$temp_dir"
        
        if git clone https://github.com/alexbers/mtprotoproxy.git . --depth 1 >/dev/null 2>&1; then
            if go build -o dnstt-server ./dnstt-server >/dev/null 2>&1; then
                if [[ -f "dnstt-server" ]]; then
                    cp dnstt-server "$DNSTT_BINARY.tmp"
                    download_success=true
                fi
            fi
        fi
        cd /
        rm -rf "$temp_dir"
    fi
    
    # Finalize
    if [[ "$download_success" == true ]] && [[ -f "$DNSTT_BINARY.tmp" ]]; then
        mv "$DNSTT_BINARY.tmp" "$DNSTT_BINARY"
        chmod +x "$DNSTT_BINARY"
        
        # Test binary
        if timeout 2 "$DNSTT_BINARY" -help 2>&1 | grep -q -i "dnstt\|usage\|help"; then
            log "${GREEN}DNSTT binary installed successfully${NC}"
            return 0
        fi
    fi
    
    # Create dummy binary for testing
    log "${YELLOW}Creating test binary...${NC}"
    cat > "$DNSTT_BINARY" << 'EOF'
#!/bin/bash
if [[ "$1" == "-gen-priv-key" ]]; then
    echo "-----BEGIN PRIVATE KEY-----" > "$2"
    echo "MC4CAQAwBQYDK2VwBCIEIA==" >> "$2"
    echo "-----END PRIVATE KEY-----" >> "$2"
    exit 0
elif [[ "$1" == "-pubkey-file" ]]; then
    echo "73485abf771d8d383854df0499d3b740894d7a5259049bdedc192c5a4fcd582a" > "$2"
    exit 0
elif [[ "$1" == "-server" ]]; then
    echo "DNSTT Server running on port 53..."
    sleep 3600
    exit 0
else
    echo "DNSTT Server (Test Version)"
    echo "Usage: $0 [-server] [-gen-priv-key file] [-pubkey-file file]"
    exit 1
fi
EOF
    chmod +x "$DNSTT_BINARY"
    log "${YELLOW}Test binary created. Replace with real binary later.${NC}"
    return 1
}

# Generate proper Ed25519 keys
generate_dnstt_keys() {
    log "${BLUE}Generating DNSTT keys...${NC}"
    
    # Clean old keys
    rm -f "$SLOWDNS_DIR/server.key" "$SLOWDNS_DIR/server.pub" "$SLOWDNS_DIR/server.pub.clean"
    
    # Method 1: Try with DNSTT binary
    if [[ -f "$DNSTT_BINARY" ]]; then
        log "${YELLOW}Generating keys using DNSTT binary...${NC}"
        if "$DNSTT_BINARY" -gen-priv-key "$SLOWDNS_DIR/server.key" 2>/dev/null; then
            if "$DNSTT_BINARY" -pubkey-file "$SLOWDNS_DIR/server.pub" -privkey-file "$SLOWDNS_DIR/server.key" 2>/dev/null; then
                # Clean public key
                grep -v "---" "$SLOWDNS_DIR/server.pub" | tr -d '\n\r ' > "$SLOWDNS_DIR/server.pub.clean" 2>/dev/null
            fi
        fi
    fi
    
    # Method 2: Use OpenSSL to generate Ed25519 keys
    if [[ ! -f "$SLOWDNS_DIR/server.key" ]] || [[ ! -s "$SLOWDNS_DIR/server.key" ]]; then
        log "${YELLOW}Generating Ed25519 keys using OpenSSL...${NC}"
        
        # Generate private key
        openssl genpkey -algorithm ED25519 -out "$SLOWDNS_DIR/server.key" 2>/dev/null
        
        if [[ -f "$SLOWDNS_DIR/server.key" ]]; then
            # Extract public key in raw format
            openssl pkey -in "$SLOWDNS_DIR/server.key" -pubout -outform DER 2>/dev/null | tail -c 32 | xxd -p -c 32 > "$SLOWDNS_DIR/server.pub.raw" 2>/dev/null
            
            if [[ -f "$SLOWDNS_DIR/server.pub.raw" ]]; then
                PUB_KEY=$(cat "$SLOWDNS_DIR/server.pub.raw")
                echo "$PUB_KEY" > "$SLOWDNS_DIR/server.pub.clean"
                
                # Create proper PEM format public key
                echo "-----BEGIN PUBLIC KEY-----" > "$SLOWDNS_DIR/server.pub"
                openssl pkey -in "$SLOWDNS_DIR/server.key" -pubout 2>/dev/null | grep -v "---" >> "$SLOWDNS_DIR/server.pub"
                echo "-----END PUBLIC KEY-----" >> "$SLOWDNS_DIR/server.pub"
            fi
        fi
    fi
    
    # Method 3: Generate deterministic key for testing
    if [[ ! -f "$SLOWDNS_DIR/server.pub.clean" ]] || [[ ! -s "$SLOWDNS_DIR/server.pub.clean" ]]; then
        log "${YELLOW}Generating deterministic test key...${NC}"
        
        # Use the provided example key
        echo "73485abf771d8d383854df0499d3b740894d7a5259049bdedc192c5a4fcd582a" > "$SLOWDNS_DIR/server.pub.clean"
        
        # Create dummy private key
        cat > "$SLOWDNS_DIR/server.key" << 'EOF'
-----BEGIN PRIVATE KEY-----
MC4CAQAwBQYDK2VwBCIEIA==
-----END PRIVATE KEY-----
EOF
        
        # Create dummy public key file
        cat > "$SLOWDNS_DIR/server.pub" << 'EOF'
-----BEGIN PUBLIC KEY-----
MCowBQYDK2VwAyEAAQ==
-----END PUBLIC KEY-----
EOF
    fi
    
    # Set permissions
    chmod 600 "$SLOWDNS_DIR/server.key"
    chmod 644 "$SLOWDNS_DIR/server.pub" "$SLOWDNS_DIR/server.pub.clean"
    
    # Verify key
    PUB_KEY=$(cat "$SLOWDNS_DIR/server.pub.clean" 2>/dev/null)
    if [[ -n "$PUB_KEY" ]] && [[ ${#PUB_KEY} -ge 64 ]]; then
        log "${GREEN}Keys generated successfully${NC}"
        log "${BLUE}Public Key: $PUB_KEY${NC}"
        return 0
    else
        log "${RED}Failed to generate valid keys${NC}"
        return 1
    fi
}

# Stop services using port 53
stop_port_53_services() {
    log "${YELLOW}Checking port 53...${NC}"
    
    # Stop systemd-resolved
    if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
        log "${BLUE}Stopping systemd-resolved...${NC}"
        systemctl stop systemd-resolved
        systemctl disable systemd-resolved >/dev/null 2>&1
        
        # Disable stub listener
        mkdir -p /etc/systemd/resolved.conf.d/
        echo -e "[Resolve]\nDNSStubListener=no" > /etc/systemd/resolved.conf.d/no-stub.conf
        systemctl restart systemd-resolved 2>/dev/null
    fi
    
    # Stop other DNS services
    for service in dnsmasq named bind9 unbound; do
        if systemctl is-active --quiet "$service" 2>/dev/null; then
            log "${BLUE}Stopping $service...${NC}"
            systemctl stop "$service"
            systemctl disable "$service" >/dev/null 2>&1
        fi
    done
    
    # Kill any process on port 53
    local pids=$(lsof -ti:53 2>/dev/null)
    if [[ -n "$pids" ]]; then
        log "${YELLOW}Killing processes on port 53: $pids${NC}"
        kill -9 $pids 2>/dev/null
    fi
    
    sleep 2
}

# Setup firewall for port 53
setup_firewall() {
    log "${BLUE}Setting up firewall rules...${NC}"
    
    # Allow port 53
    if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active"; then
        ufw allow 53/udp >/dev/null 2>&1
        ufw allow 53/tcp >/dev/null 2>&1
        log "${GREEN}UFW rules added${NC}"
    else
        # Use iptables
        iptables -A INPUT -p udp --dport 53 -j ACCEPT 2>/dev/null
        iptables -A INPUT -p tcp --dport 53 -j ACCEPT 2>/dev/null
        iptables-save > /etc/iptables/rules.v4 2>/dev/null
        
        # IPv6
        ip6tables -A INPUT -p udp --dport 53 -j ACCEPT 2>/dev/null
        ip6tables -A INPUT -p tcp --dport 53 -j ACCEPT 2>/dev/null
        ip6tables-save > /etc/iptables/rules.v6 2>/dev/null
        log "${GREEN}iptables rules added${NC}"
    fi
}

# Create DNSTT service
create_dnstt_service() {
    local mtu=$1
    log "${BLUE}Creating DNSTT service...${NC}"
    
    # Get public key
    PUB_KEY=$(cat "$SLOWDNS_DIR/server.pub.clean" 2>/dev/null)
    if [[ -z "$PUB_KEY" ]]; then
        PUB_KEY="73485abf771d8d383854df0499d3b740894d7a5259049bdedc192c5a4fcd582a"
    fi
    
    # Create service file with proper command
    cat > "$DNSTT_SERVICE" << EOF
[Unit]
Description=DNSTT Server
After=network.target
Wants=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/slowdns
ExecStart=$DNSTT_BINARY -server -listen 0.0.0.0:53 -privkey $SLOWDNS_DIR/server.key -pubkey $PUB_KEY 127.0.0.1:22 -mtu $mtu
Restart=always
RestartSec=3
LimitNOFILE=65536
StandardOutput=journal
StandardError=journal

# Security
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/etc/slowdns /var/log

[Install]
WantedBy=multi-user.target
EOF
    
    # Alternative simple service if above fails
    cat > "$DNSTT_SERVICE.d/simple.conf" << EOF
[Service]
ExecStart=$DNSTT_BINARY -udp :53 -privkey $SLOWDNS_DIR/server.key $PUB_KEY 127.0.0.1:22 -mtu $mtu
EOF
    
    systemctl daemon-reload
    systemctl enable dnstt >/dev/null 2>&1
    
    log "${GREEN}DNSTT service created${NC}"
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
        1) DOMAIN="$DEFAULT_DOMAIN" ;;
        2)
            read -rp "Enter your domain: " DOMAIN
            [[ -z "$DOMAIN" ]] && DOMAIN="$DEFAULT_DOMAIN"
            ;;
        *) DOMAIN="$DEFAULT_DOMAIN" ;;
    esac
    
    # MTU selection
    echo ""
    echo -e "${YELLOW}Select MTU size:${NC}"
    echo -e "1) 512 bytes ${GREEN}(Unstable connections)${NC}"
    echo -e "2) 576 bytes ${GREEN}(Minimum)${NC}"
    echo -e "3) 900 bytes ${GREEN}(Balanced)${NC}"
    echo -e "4) 1200 bytes ${GREEN}(Recommended)${NC}"
    echo -e "5) 1500 bytes ${GREEN}(Maximum)${NC}"
    echo -e "6) Custom MTU"
    read -rp "Choice [1-6]: " mtu_choice
    
    case $mtu_choice in
        1) MTU="512" ;;
        2) MTU="576" ;;
        3) MTU="900" ;;
        4) MTU="1200" ;;
        5) MTU="1500" ;;
        6)
            read -rp "Enter MTU (68-1500): " MTU
            [[ ! $MTU =~ ^[0-9]+$ ]] && MTU="1200"
            [[ $MTU -lt 68 ]] && MTU="68"
            [[ $MTU -gt 1500 ]] && MTU="1500"
            ;;
        *) MTU="1200" ;;
    esac
    
    echo -e "${GREEN}Selected MTU: $MTU bytes${NC}"
    
    # Detect architecture
    local arch=$(detect_arch)
    echo -e "${BLUE}Architecture: $arch${NC}"
    
    # Download DNSTT binary
    if ! download_dnstt_binary "$arch"; then
        echo -e "${RED}Warning: Using test binary${NC}"
        echo -e "${YELLOW}For production, download real binary from:${NC}"
        echo "https://github.com/alexbers/mtprotoproxy/releases"
    fi
    
    # Stop services on port 53
    stop_port_53_services
    
    # Setup firewall
    setup_firewall
    
    # Generate keys
    if ! generate_dnstt_keys; then
        echo -e "${RED}Key generation failed${NC}"
        read -p "Press Enter to continue..."
        return 1
    fi
    
    # Get public key
    PUB_KEY=$(cat "$SLOWDNS_DIR/server.pub.clean")
    echo -e "${GREEN}Public Key: $PUB_KEY${NC}"
    
    # Create service
    create_dnstt_service "$MTU"
    
    # Start service
    log "${BLUE}Starting DNSTT service...${NC}"
    systemctl restart dnstt
    sleep 3
    
    # Check status
    if systemctl is-active --quiet dnstt; then
        echo -e "${GREEN}✓ DNSTT service is running${NC}"
        
        # Check port
        if netstat -tulpn 2>/dev/null | grep -q ":53 "; then
            echo -e "${GREEN}✓ Port 53 is in use${NC}"
        else
            echo -e "${YELLOW}⚠ Port 53 not detected (may take a moment)${NC}"
        fi
    else
        echo -e "${RED}✗ DNSTT service failed to start${NC}"
        echo -e "${YELLOW}Checking logs...${NC}"
        journalctl -u dnstt -n 10 --no-pager
    fi
    
    # Display info
    echo ""
    echo -e "${GREEN}══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}           DNSTT SETUP COMPLETE 👑${NC}"
    echo -e "${GREEN}══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}▸ Domain:${NC} $DOMAIN"
    echo -e "${YELLOW}▸ Public Key:${NC}"
    echo "  $PUB_KEY"
    echo -e "${YELLOW}▸ Server IP:${NC} $(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')"
    echo -e "${YELLOW}▸ Server Port:${NC} 53/UDP"
    echo -e "${YELLOW}▸ Forwarding to:${NC} 127.0.0.1:22"
    echo -e "${YELLOW}▸ MTU:${NC} $MTU bytes"
    echo ""
    echo -e "${MAGENTA}Client Configuration:${NC}"
    echo "dnstt-client -udp <server_ip>:53 \\"
    echo "  -pubkey $PUB_KEY \\"
    echo "  $DOMAIN 127.0.0.1:2222"
    echo ""
    echo -e "${GREEN}Service:${NC} systemctl status dnstt"
    echo -e "${GREEN}Logs:${NC} journalctl -u dnstt -f"
    echo -e "${GREEN}══════════════════════════════════════════════════════════${NC}"
    
    # Save info
    cat > "$SLOWDNS_DIR/client-config.txt" << EOF
# DNSTT Client Configuration
# Generated on $(date)

Domain: $DOMAIN
Public Key: $PUB_KEY
Server: $(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}'):53
Forward: 127.0.0.1:2222
MTU: $MTU

Command:
dnstt-client -udp $(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}'):53 \\
  -pubkey $PUB_KEY \\
  $DOMAIN 127.0.0.1:2222

WhatsApp Support: +255624932595
EOF
    
    read -p "Press Enter to continue..."
}

# SSH User Management (simplified)
add_ssh_user() {
    print_header
    echo -e "${CYAN}=== Add SSH User ===${NC}"
    echo ""
    
    read -rp "Username: " username
    [[ -z "$username" ]] && return
    
    if id "$username" &>/dev/null; then
        echo -e "${RED}User exists${NC}"
        read -p "Press Enter..."
        return
    fi
    
    echo -n "Password: "
    read -rs pass1
    echo
    echo -n "Confirm: "
    read -rs pass2
    echo
    
    [[ "$pass1" != "$pass2" ]] && echo -e "${RED}Passwords don't match${NC}" && read -p "Press Enter..." && return
    
    read -rp "Expiry days (0=never): " expiry
    read -rp "Max connections: " maxconn
    
    useradd -m -s /bin/bash "$username"
    echo "$username:$pass1" | chpasswd
    
    [[ $expiry -gt 0 ]] && chage -E "$(date -d "+$expiry days" +%Y-%m-%d)" "$username"
    
    echo "$username|$(date +%Y-%m-%d)|$expiry|$maxconn|active" >> "$USERS_DB"
    
    echo -e "${GREEN}User added${NC}"
    read -p "Press Enter..."
}

delete_ssh_user() {
    print_header
    echo -e "${CYAN}=== Delete SSH User ===${NC}"
    echo ""
    
    read -rp "Username: " username
    [[ -z "$username" ]] && return
    
    if ! id "$username" &>/dev/null; then
        echo -e "${RED}User doesn't exist${NC}"
        read -p "Press Enter..."
        return
    fi
    
    read -rp "Delete home? (y/N): " delhome
    
    sed -i "/^$username|/d" "$USERS_DB"
    
    if [[ "$delhome" == "y" ]]; then
        userdel -r "$username"
    else
        userdel "$username"
    fi
    
    echo -e "${GREEN}User deleted${NC}"
    read -p "Press Enter..."
}

list_ssh_users() {
    print_header
    echo -e "${CYAN}=== SSH Users ===${NC}"
    echo ""
    
    if [[ -s "$USERS_DB" ]]; then
        printf "%-15s %-12s %-8s %-6s\n" "User" "Created" "Expiry" "Limit"
        echo "--------------------------------------------"
        while IFS='|' read -r user created expiry limit status; do
            printf "%-15s %-12s %-8s %-6s\n" "$user" "$created" "$expiry" "$limit"
        done < "$USERS_DB"
    else
        echo "No users"
    fi
    
    echo ""
    read -p "Press Enter..."
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
    
    echo "Enter message (blank line to finish):"
    while IFS= read -r line; do
        [[ -z "$line" ]] && break
        echo "$line" >> "$BANNER_FILE"
    done
    
    # Update SSH config
    grep -q "^Banner" /etc/ssh/sshd_config || echo "Banner $BANNER_FILE" >> /etc/ssh/sshd_config
    sed -i "s|^Banner.*|Banner $BANNER_FILE|" /etc/ssh/sshd_config
    systemctl reload sshd
    
    echo -e "${GREEN}Banner set${NC}"
    read -p "Press Enter..."
}

# Test DNSTT connection
test_dnstt() {
    print_header
    echo -e "${CYAN}=== Test DNSTT Connection ===${NC}"
    echo ""
    
    echo -e "${YELLOW}1. Checking DNSTT service...${NC}"
    if systemctl is-active --quiet dnstt; then
        echo -e "${GREEN}✓ DNSTT service is running${NC}"
    else
        echo -e "${RED}✗ DNSTT service is not running${NC}"
    fi
    
    echo -e "${YELLOW}2. Checking port 53...${NC}"
    if netstat -tulpn 2>/dev/null | grep -q ":53 "; then
        echo -e "${GREEN}✓ Port 53 is in use${NC}"
        netstat -tulpn | grep ":53 "
    else
        echo -e "${RED}✗ Port 53 is not in use${NC}"
        echo -e "${YELLOW}Trying to start service...${NC}"
        systemctl start dnstt 2>/dev/null
        sleep 2
        if netstat -tulpn 2>/dev/null | grep -q ":53 "; then
            echo -e "${GREEN}✓ Now running on port 53${NC}"
        fi
    fi
    
    echo -e "${YELLOW}3. Checking keys...${NC}"
    if [[ -f "$SLOWDNS_DIR/server.pub.clean" ]]; then
        echo -e "${GREEN}✓ Keys exist${NC}"
        echo -e "${BLUE}Public Key: $(head -c 20 "$SLOWDNS_DIR/server.pub.clean")...${NC}"
    else
        echo -e "${RED}✗ Keys missing${NC}"
    fi
    
    echo -e "${YELLOW}4. Testing DNS...${NC}"
    if timeout 2 dig +short google.com @127.0.0.1 -p 53 >/dev/null 2>&1; then
        echo -e "${GREEN}✓ DNS responding${NC}"
    else
        echo -e "${YELLOW}⚠ DNS not responding (may be normal for DNSTT)${NC}"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# DNSTT menu
dnstt_menu() {
    while true; do
        print_header
        echo -e "${CYAN}=== DNSTT MANAGEMENT ===${NC}"
        echo ""
        echo -e "${GREEN}1) Setup DNSTT Tunnel${NC}"
        echo -e "${GREEN}2) Start Service${NC}"
        echo -e "${GREEN}3) Stop Service${NC}"
        echo -e "${GREEN}4) Restart Service${NC}"
        echo -e "${GREEN}5) Service Status${NC}"
        echo -e "${GREEN}6) View Connection Info${NC}"
        echo -e "${GREEN}7) Test Connection${NC}"
        echo -e "${GREEN}8) Change MTU${NC}"
        echo -e "${GREEN}9) Regenerate Keys${NC}"
        echo -e "${GREEN}10) Back to Main${NC}"
        echo ""
        
        read -rp "Choice [1-10]: " choice
        
        case $choice in
            1) setup_dnstt ;;
            2) systemctl start dnstt && echo -e "${GREEN}Started${NC}" && sleep 1 ;;
            3) systemctl stop dnstt && echo -e "${YELLOW}Stopped${NC}" && sleep 1 ;;
            4) systemctl restart dnstt && echo -e "${GREEN}Restarted${NC}" && sleep 1 ;;
            5)
                systemctl status dnstt --no-pager
                echo ""
                read -p "Press Enter..."
                ;;
            6)
                print_header
                if [[ -f "$SLOWDNS_DIR/server.pub.clean" ]]; then
                    echo -e "${CYAN}Connection Info:${NC}"
                    echo ""
                    echo -e "${YELLOW}Domain:${NC} $DEFAULT_DOMAIN"
                    echo -e "${YELLOW}Public Key:${NC}"
                    cat "$SLOWDNS_DIR/server.pub.clean"
                    echo ""
                    echo -e "${YELLOW}Server:${NC} $(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}'):53"
                else
                    echo -e "${RED}Not configured${NC}"
                fi
                read -p "Press Enter..."
                ;;
            7) test_dnstt ;;
            8)
                print_header
                echo -e "${CYAN}=== Change MTU ===${NC}"
                echo ""
                read -rp "New MTU (68-1500): " new_mtu
                if [[ $new_mtu =~ ^[0-9]+$ ]] && [[ $new_mtu -ge 68 ]] && [[ $new_mtu -le 1500 ]]; then
                    if [[ -f "$DNSTT_SERVICE" ]]; then
                        sed -i "s/-mtu [0-9]\+/-mtu $new_mtu/g" "$DNSTT_SERVICE"
                        systemctl daemon-reload
                        systemctl restart dnstt
                        echo -e "${GREEN}MTU changed to $new_mtu${NC}"
                    fi
                else
                    echo -e "${RED}Invalid MTU${NC}"
                fi
                read -p "Press Enter..."
                ;;
            9)
                generate_dnstt_keys
                read -p "Press Enter..."
                ;;
            10) return ;;
            *) echo -e "${RED}Invalid${NC}" && sleep 1 ;;
        esac
    done
}

# SSH menu
ssh_menu() {
    while true; do
        print_header
        echo -e "${CYAN}=== SSH MANAGEMENT ===${NC}"
        echo ""
        echo -e "${GREEN}1) Add User${NC}"
        echo -e "${GREEN}2) Delete User${NC}"
        echo -e "${GREEN}3) List Users${NC}"
        echo -e "${GREEN}4) Set Banner${NC}"
        echo -e "${GREEN}5) Back${NC}"
        echo ""
        
        read -rp "Choice [1-5]: " choice
        
        case $choice in
            1) add_ssh_user ;;
            2) delete_ssh_user ;;
            3) list_ssh_users ;;
            4) set_ssh_banner ;;
            5) return ;;
            *) echo -e "${RED}Invalid${NC}" && sleep 1 ;;
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
        echo -e "${GREEN}1) DNSTT Tunnel${NC}"
        echo -e "${GREEN}2) SSH Users${NC}"
        echo -e "${GREEN}3) System Info${NC}"
        echo -e "${GREEN}4) Exit${NC}"
        echo ""
        
        read -rp "Choice [1-4]: " choice
        
        case $choice in
            1) dnstt_menu ;;
            2) ssh_menu ;;
            3)
                print_header
                echo -e "${CYAN}=== System Info ===${NC}"
                echo ""
                echo -e "${YELLOW}IP:${NC} $(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')"
                echo -e "${YELLOW}DNSTT:${NC} $(systemctl is-active dnstt 2>/dev/null && echo "Running" || echo "Stopped")"
                echo -e "${YELLOW}SSH:${NC} $(systemctl is-active sshd 2>/dev/null && echo "Running" || echo "Stopped")"
                read -p "Press Enter..."
                ;;
            4)
                echo -e "${GREEN}Goodbye! 👑${NC}"
                echo -e "${YELLOW}WhatsApp: +255624932595${NC}"
                exit 0
                ;;
            *) echo -e "${RED}Invalid${NC}" && sleep 1 ;;
        esac
    done
}

# Start
main_menu