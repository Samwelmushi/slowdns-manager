#!/bin/bash

# SLOW DNS Easy Installer
# GitHub: https://github.com/Samwelmushi/slowdns-manager

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
echo "  ███████╗██╗      ██████╗ ██╗    ██╗    ██████╗ ███╗   ███╗███████╗"
echo "  ██╔════╝██║     ██╔═══██╗██║    ██║    ██╔══██╗████╗ ████║██╔════╝"
echo "  ███████╗██║     ██║   ██║██║ █╗ ██║    ██║  ██║██╔████╔██║███████╗"
echo "  ╚════██║██║     ██║   ██║██║███╗██║    ██║  ██║██║╚██╔╝██║╚════██║"
echo "  ███████║███████╗╚██████╔╝╚███╔███╔╝    ██████╔╝██║ ╚═╝ ██║███████║"
echo "  ╚══════╝╚══════╝ ╚═════╝  ╚══╝╚══╝     ╚═════╝ ╚═╝     ╚═╝╚══════╝"
echo -e "${NC}"
echo -e "${YELLOW}           Easy Installer - Made by The King 👑👑${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ This installer must be run as root!${NC}"
   echo -e "${YELLOW}Please run: sudo $0${NC}"
   exit 1
fi

echo -e "${YELLOW}📥 Downloading SLOW DNS Manager...${NC}"

# Download the main script
wget -q --show-progress https://raw.githubusercontent.com/Samwelmushi/slowdns-manager/main/slowdns.sh -O /usr/local/bin/slowdns

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Download successful!${NC}"
else
    echo -e "${RED}❌ Download failed! Please check your internet connection.${NC}"
    exit 1
fi

# Make executable
chmod +x /usr/local/bin/slowdns

echo -e "${GREEN}✅ Installation complete!${NC}"
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}You can now run the script from anywhere using:${NC}"
echo -e "${GREEN}   slowdns${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}🚀 Starting SLOW DNS Manager...${NC}"
echo ""
sleep 2

# Run the script
/usr/local/bin/slowdns
