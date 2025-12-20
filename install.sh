installer:
  file_name: install.sh
  script_type: Bash
  purpose: >
    Automated installer for DNSTT SPEED v7.0 ULTRA.
    Installs DNSTT, V2Ray core, required dependencies,
    creates directories, downloads the main script,
    sets permissions, and creates command shortcuts.

metadata:
  project_name: DNSTT SPEED
  version: "7.0 ULTRA"
  author: "THE KING 👑"
  requires_root: true
  supported_os:
    - Ubuntu 20.04
    - Ubuntu 22.04
    - Ubuntu 24.04

environment_checks:
  - check: root_user
    condition: EUID == 0
    on_fail: Exit with error message "Please run as root"

variables:
  colors:
    red: "\\e[31m"
    green: "\\e[32m"
    cyan: "\\e[36m"
    reset: "\\e[0m"

system_update:
  description: Update package lists
  command: apt update -y

dependencies:
  description: Required packages for DNSTT and V2Ray
  packages:
    - curl
    - wget
    - dnsutils
    - net-tools
    - iproute2
    - screen
    - socat
    - unzip
    - cron
  install_command: apt install -y

directory_setup:
  create:
    - /etc/dnstt
    - /etc/v2ray
    - /var/log
    - /usr/local/bin
  permissions: root_only

dnstt_installation:
  description: Install DNSTT binary
  steps:
    - download:
        url: https://github.com/NTKERNEL/dnstt/releases/latest/download/dnstt-server-linux-amd64
        output: /usr/local/bin/dnstt-server
    - permission:
        path: /usr/local/bin/dnstt-server
        mode: "+x"

v2ray_installation:
  description: Install V2Ray core
  steps:
    - download_script:
        url: https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh
    - execute_script:
        command: bash install-release.sh
    - cleanup:
        files:
          - install-release.sh

main_script_installation:
  description: Download DNSTT SPEED main menu script
  steps:
    - download:
        url: https://raw.githubusercontent.com/Samwelmushi/slowdns-manager/main/dnstt_speed.sh
        output: /usr/local/bin/dnstt-speed
    - permission:
        path: /usr/local/bin/dnstt-speed
        mode: "+x"

command_shortcuts:
  create:
    - source: /usr/local/bin/dnstt-speed
      target: /usr/bin/dnstt
    - source: /usr/local/bin/dnstt-speed
      target: /usr/bin/dnstt-speed
  method: symbolic_link

log_files:
  create:
    - /var/log/dnstt.log
    - /var/log/v2ray.log
  ownership: root:root

services:
  managed_services:
    - dnstt
    - v2ray
  actions:
    - enable_on_boot
    - allow_restart_from_menu

post_install_message:
  success_message:
    - "DNSTT SPEED v7.0 ULTRA installed successfully"
    - "Use command: dnstt"
    - "Use command: dnstt-speed"
  warning_message:
    - "Configure your domain and DNS records before starting DNSTT"
    - "Recommended MTU size: 512"

installer_flow_summary:
  steps_order:
    - Check root privileges
    - Update system packages
    - Install dependencies
    - Create required directories
    - Install DNSTT binary
    - Install V2Ray core
    - Download main management script
    - Set permissions
    - Create command shortcuts
    - Display success message

security_notes:
  - No hidden payloads
  - No data collection
  - Runs only system-level commands required for DNSTT & V2Ray
  - User maintains full control of configuration

conversion_note:
  explanation: >
    This YAML file documents the full logic of install.sh.
    It can be manually converted back into a Bash script
    or used as structured documentation inside README.md.
    
