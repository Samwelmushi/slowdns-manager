#!/bin/bash

echo "📥 Installing SlowDNS Manager..."
echo "📦 Installing required packages..."

# Update packages
apt update -y >/dev/null 2>&1
apt install -y wget curl >/dev/null 2>&1

echo "⬇️ Downloading SlowDNS Manager script..."

RAW_URL="https://raw.githubusercontent.com/Samwelmushi/slowdns-manager/main/slowdns_script.sh"

# Download script
wget -q -O /usr/local/bin/slowdns_script.sh "$RAW_URL"

# Check if download succeeded
if [ ! -f /usr/local/bin/slowdns_script.sh ]; then
    echo "❌ Failed to download script from GitHub."
    echo "   Make sure slowdns_script.sh exists in your repo."
    exit 1
fi

# Make executable
chmod +x /usr/local/bin/slowdns_script.sh

echo "✅ SlowDNS Manager installed successfully!"
echo ""
echo "👉 Run it anytime using: slowdns_script.sh"
echo ""
echo "🚀 Starting script now..."
echo ""

# Run the script
/usr/local/bin/slowdns_script.sh
