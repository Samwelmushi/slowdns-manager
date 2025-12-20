project:
  name: DNSTT SPEED
  version: "7.0 ULTRA"
  title: DNS Tunnel Manager
  author: "THE KING 👑"
  repository: https://github.com/Samwelmushi/slowdns-manager
  description: >
    DNSTT SPEED is an advanced DNS Tunnel (DNSTT) management script with
    integrated V2Ray support. It allows DNSTT to be used as a transport
    layer for V2Ray protocols such as VLESS and VMESS, enabling secure
    and optimized tunneling over DNS on Ubuntu VPS servers.
    The script provides a menu-driven interface for managing DNSTT,
    V2Ray services, SSH users, system information, and updates.

screenshot:
  file: Screenshot_20251220-094750.jpg
  note: Upload this image to the root of the GitHub repository

core_technologies:
  - DNSTT (DNS Tunnel)
  - V2Ray Core
  - VLESS over DNSTT
  - VMESS over DNSTT
  - SSH Tunneling
  - UDP & TCP Forwarding

features:
  - High-speed optimized DNSTT tunnel
  - DNSTT service management (start, stop, restart)
  - Built-in V2Ray support over DNSTT
  - VLESS over DNSTT configuration support
  - VMESS over DNSTT configuration support
  - Local DNSTT listener for V2Ray inbound
  - SSH user management
  - System information monitoring
  - Auto-update script feature
  - Compatible with DNSTT-based VPN applications
  - Clean and safe installation
  - Optimized for low MTU environments (MTU 512 supported)
  - Designed for Ubuntu VPS servers

menu_interface:
  options:
    - "1) DNSTT Management"
    - "2) V2Ray Management"
    - "3) SSH Users"
    - "4) System Info"
    - "5) Auto-Update Script"
    - "0) Exit"

supported_operating_systems:
  - Ubuntu 20.04 LTS
  - Ubuntu 22.04 LTS
  - Ubuntu 24.04 LTS

requirements:
  - Root access
  - Ubuntu-based VPS
  - Active internet connection
  - Domain or subdomain pointed to VPS IP
  - UDP port availability for DNSTT

dnstt_v2ray_flow:
  explanation: >
    DNSTT SPEED uses DNSTT as a DNS-based transport tunnel.
    V2Ray listens locally (127.0.0.1) and routes traffic
    through the DNSTT tunnel, allowing VLESS or VMESS
    connections to bypass network restrictions.
  flow:
    - Client connects using V2Ray (VLESS / VMESS)
    - Traffic is forwarded to local DNSTT listener
    - DNSTT encapsulates traffic into DNS queries
    - DNS traffic reaches the VPS authoritative DNS
    - Data is decoded and forwarded to the internet

installation:
  steps:
    - description: Download the installer
      command: >
        wget https://raw.githubusercontent.com/Samwelmushi/slowdns-manager/main/install.sh
    - description: Make the installer executable
      command: chmod +x install.sh
    - description: Run the installer as root
      command: sudo ./install.sh

usage:
  commands:
    - dnstt
    - dnstt-speed
  description: >
    After installation, run the command to access the interactive menu.
    From the menu you can manage DNSTT services, V2Ray configurations,
    SSH users, and system monitoring.

performance:
  recommended_mtu: 512
  speed_range: "5–15 Mbps"
  notes:
    - DNSTT is latency-sensitive; DNS quality matters
    - V2Ray performance depends on routing and DNS response time
    - Best results achieved using authoritative DNS servers

installed_files:
  - path: /usr/local/bin/dnstt-speed
    purpose: Main DNSTT & V2Ray management script
  - path: /usr/bin/dnstt
    purpose: Shortcut command
  - path: /etc/dnstt/
    purpose: DNSTT configuration files
  - path: /etc/v2ray/
    purpose: V2Ray configuration files
  - path: /var/log/dnstt.log
    purpose: DNSTT service logs
  - path: /var/log/v2ray/
    purpose: V2Ray logs

vpn_client_compatibility:
  supported_clients:
    - V2RayNG
    - V2RayN
    - NekoRay
    - Shadowrocket
    - Hiddify
  transport:
    - DNSTT + VLESS
    - DNSTT + VMESS

security_notes:
  - DNSTT traffic appears as DNS queries
  - V2Ray provides encryption and authentication
  - Recommended to use UUID-based authentication
  - Keep system updated for security patches

disclaimer:
  text: >
    This project is provided for educational and research purposes only.
    The author is not responsible for misuse, abuse, or illegal activities
    performed using this script.

credits:
  created_by: THE KING 👑
  github: https://github.com/Samwelmushi
  message: "If you find this project useful, please give it a star ⭐"
  
