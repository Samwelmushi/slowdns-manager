#!/bin/bash

set -e

# Colors
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[1;33m"
NC="\033[0m"

echo -e "${YELLOW}📥 Installing SlowDNS Manager...${NC}"

# Check root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ Please run as root (sudo su)${NC}"
    exit 1
fi

# Install dependencies
echo -e "${YELLOW}📦 Installing required packages...${NC}"
apt update -qq
apt install -y wget curl jq bc make gcc ufw firewalld > /dev/null 2>&1

# Create app directory
INSTALL_DIR="/usr/local/bin"
SCRIPT_URL="https://raw.githubusercontent.com/Samwelmushi/slowdns-manager/main/slowdns.sh"
SCRIPT_PATH="$INSTALL_DIR/slowdns"

echo -e "${YELLOW}⬇️ Downloading SlowDNS Manager script...${NC}"

# Download main script
if wget -qO "$SCRIPT_PATH" "$SCRIPT_URL"; then
    chmod +x "$SCRIPT_PATH"
else
    echo -e "${RED}❌ Failed to download script from GitHub.${NC}"
    echo -e "${RED}   Check if slowdns.sh exists in your repo.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ SlowDNS Manager installed successfully!${NC}"
echo ""
echo -e "${GREEN}Run it anytime using:${NC}"
echo -e "${YELLOW}   slowdns${NC}"
echo ""
