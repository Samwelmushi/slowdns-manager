#!/bin/bash

##############################################
# SlowDNS Manager - Quick Installer
# Created By THE KING 👑 💯
# Version: 7.0.0
##############################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# GitHub repository details
GITHUB_USER="Samwelmushi"
GITHUB_REPO="slowdns-manager"
GITHUB_BRANCH="main"
SCRIPT_NAME="slowdns_script.sh"
GITHUB_URL="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${GITHUB_BRANCH}/${SCRIPT_NAME}"

# Installation directory
INSTALL_DIR="/usr/local/bin"
SCRIPT_PATH="${INSTALL_DIR}/${SCRIPT_NAME}"

#============================================
# BANNER
#============================================

show_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║        ███████╗██╗      ██████╗ ██╗    ██╗██████╗ ███╗   ██╗ ║
║        ██╔════╝██║     ██╔═══██╗██║    ██║██╔══██╗████╗  ██║ ║
║        ███████╗██║     ██║   ██║██║ █╗ ██║██║  ██║██╔██╗ ██║ ║
║        ╚════██║██║     ██║   ██║██║███╗██║██║  ██║██║╚██╗██║ ║
║        ███████║███████╗╚██████╔╝╚███╔███╔╝██████╔╝██║ ╚████║ ║
║        ╚══════╝╚══════╝ ╚═════╝  ╚══╝╚══╝ ╚═════╝ ╚═╝  ╚═══╝ ║
║                                                               ║
║                    MANAGER INSTALLER                         ║
║                                                               ║
║              CREATED BY THE KING 👑 💯                       ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo ""
}

#============================================
# CHECK ROOT
#============================================

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}ERROR: This installer must be run as root${NC}"
        echo -e "${YELLOW}Please run: sudo bash $0${NC}"
        exit 1
    fi
}

#============================================
# CHECK DEPENDENCIES
#============================================

check_dependencies() {
    echo -e "${CYAN}Checking dependencies...${NC}"
    
    # Check if wget is installed
    if ! command -v wget &> /dev/null; then
        echo -e "${YELLOW}Installing wget...${NC}"
        if command -v apt-get &> /dev/null; then
            apt-get update -qq > /dev/null 2>&1
            apt-get install -y wget > /dev/null 2>&1
        elif command -v yum &> /dev/null; then
            yum install -y wget > /dev/null 2>&1
        fi
    fi
    
    echo -e "${GREEN}✓ Dependencies checked${NC}"
    echo ""
}

#============================================
# DOWNLOAD SCRIPT
#============================================

download_script() {
    echo -e "${CYAN}Downloading SlowDNS Manager from GitHub...${NC}"
    echo ""
    echo -e "${WHITE}Source: ${YELLOW}$GITHUB_URL${NC}"
    echo ""
    
    # Create temp file
    TEMP_SCRIPT="/tmp/slowdns_temp_$$.sh"
    
    # Download with progress
    if wget --progress=bar:force -O "$TEMP_SCRIPT" "$GITHUB_URL" 2>&1 | \
        grep --line-buffered "%" | \
        sed -u -e "s/\.//g" | \
        awk '{printf("\r'${CYAN}'Downloading: '${GREEN}'%s'${NC}'", $2)}'; then
        
        echo ""
        echo ""
        echo -e "${GREEN}✓ Download completed successfully${NC}"
        
        # Verify file is not empty
        if [[ ! -s "$TEMP_SCRIPT" ]]; then
            echo -e "${RED}✗ Downloaded file is empty${NC}"
            rm -f "$TEMP_SCRIPT"
            return 1
        fi
        
        # Verify it's a bash script
        if ! head -1 "$TEMP_SCRIPT" | grep -q "^#!/bin/bash"; then
            echo -e "${RED}✗ Downloaded file is not a valid bash script${NC}"
            rm -f "$TEMP_SCRIPT"
            return 1
        fi
        
        return 0
    else
        echo ""
        echo ""
        echo -e "${RED}✗ Download failed${NC}"
        rm -f "$TEMP_SCRIPT"
        return 1
    fi
}

#============================================
# INSTALL SCRIPT
#============================================

install_script() {
    echo ""
    echo -e "${CYAN}Installing SlowDNS Manager...${NC}"
    
    # Create installation directory
    mkdir -p "$INSTALL_DIR"
    
    # Move script to installation directory
    mv "$TEMP_SCRIPT" "$SCRIPT_PATH"
    chmod +x "$SCRIPT_PATH"
    
    # Create symbolic links
    ln -sf "$SCRIPT_PATH" /usr/local/bin/slowdns 2>/dev/null || true
    ln -sf "$SCRIPT_PATH" /usr/local/bin/menu 2>/dev/null || true
    ln -sf "$SCRIPT_PATH" /usr/local/bin/dnstt 2>/dev/null || true
    
    echo -e "${GREEN}✓ Installation completed${NC}"
    echo ""
}

#============================================
# SHOW SUCCESS
#============================================

show_success() {
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         ✅ INSTALLATION SUCCESSFUL! ✅               ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}You can now run SlowDNS Manager using any of these commands:${NC}"
    echo ""
    echo -e "  ${CYAN}slowdns_script.sh${NC}  ${WHITE}- Run the main script${NC}"
    echo -e "  ${CYAN}slowdns${NC}            ${WHITE}- Quick access command${NC}"
    echo -e "  ${CYAN}menu${NC}               ${WHITE}- Open main menu${NC}"
    echo -e "  ${CYAN}dnstt${NC}              ${WHITE}- DNSTT management${NC}"
    echo ""
    echo -e "${YELLOW}Starting SlowDNS Manager now...${NC}"
    echo ""
    sleep 2
}

#============================================
# ERROR HANDLING
#============================================

show_error() {
    echo ""
    echo -e "${RED}╔═══════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║              ✗ INSTALLATION FAILED ✗                 ║${NC}"
    echo -e "${RED}╚═══════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Possible reasons:${NC}"
    echo -e "  ${WHITE}1. No internet connection${NC}"
    echo -e "  ${WHITE}2. GitHub is not accessible${NC}"
    echo -e "  ${WHITE}3. Repository URL has changed${NC}"
    echo -e "  ${WHITE}4. Firewall blocking the download${NC}"
    echo ""
    echo -e "${CYAN}Manual Installation:${NC}"
    echo ""
    echo -e "  ${WHITE}# Download the script directly${NC}"
    echo -e "  ${YELLOW}wget https://raw.githubusercontent.com/Samwelmushi/slowdns-manager/main/slowdns_script.sh${NC}"
    echo ""
    echo -e "  ${WHITE}# Make it executable${NC}"
    echo -e "  ${YELLOW}chmod +x slowdns_script.sh${NC}"
    echo ""
    echo -e "  ${WHITE}# Run it${NC}"
    echo -e "  ${YELLOW}sudo ./slowdns_script.sh${NC}"
    echo ""
    echo -e "${CYAN}For support:${NC}"
    echo -e "  ${WHITE}Visit: ${YELLOW}https://github.com/Samwelmushi/slowdns-manager/issues${NC}"
    echo ""
}

#============================================
# CLEANUP
#============================================

cleanup() {
    rm -f /tmp/slowdns_temp_*.sh 2>/dev/null || true
}

#============================================
# MAIN
#============================================

main() {
    # Set trap for cleanup
    trap cleanup EXIT
    
    # Show banner
    show_banner
    
    # Check root
    check_root
    
    # Check dependencies
    check_dependencies
    
    # Download script
    if ! download_script; then
        show_error
        exit 1
    fi
    
    # Install script
    install_script
    
    # Show success
    show_success
    
    # Run the script
    if [[ -x "$SCRIPT_PATH" ]]; then
        exec bash "$SCRIPT_PATH"
    else
        echo -e "${RED}Error: Could not execute the script${NC}"
        exit 1
    fi
}

# Run main function
main