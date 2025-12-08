# slowdns-manager
Professional DNSTT &amp; SSH User Management Script with Full Features
# 🌐 SLOW DNS - Complete DNSTT & SSH Management System

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Bash-4.0%2B-green.svg)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-Linux-blue.svg)](https://www.linux.org/)

Professional DNS Tunnel (DNSTT) and SSH user management system with an intuitive interface and comprehensive features.

## ✨ Features

### 🌐 DNSTT Management
- ✅ Automatic DNSTT installation and configuration
- 🔑 Automatic cryptographic key generation
- 🌍 Custom or auto-generated nameserver (tns.voltran.online)
- 🚪 Automatic port 53 opening (UFW, Firewalld, iptables)
- 📊 Multiple MTU options: 512, 1200, 1280, 1420, or custom
- 🔄 Service management (start, stop, restart, status)
- 📋 Real-time connection details display

### 👥 SSH User Management
- ➕ Add users with customizable settings
- 📅 Flexible expiration dates (1 day to 1 year or custom)
- 🔢 Connection limit control per user
- 🔒 Secure password management
- 🗑️ Easy user deletion
- 📊 User list with active/expired status
- 📝 Customizable login banner
- ✅ Real-time user status checking

### 🎨 Interface Features
- Colorful ASCII art banner
- Intuitive menu navigation
- Real-time status updates
- Professional error handling
- System information dashboard

## 📋 Requirements

- **OS**: Ubuntu 18.04+ / Debian 9+ / CentOS 7+
- **Access**: Root privileges required
- **Network**: Port 53 must be available
- **Dependencies**: Auto-installed (wget, curl, ufw/firewalld, git, gcc)

## 🚀 Quick Start

### Installation
```bash
# Download the script
wget https://raw.githubusercontent.com/YOUR_USERNAME/slowdns-manager/main/slowdns.sh

# Make it executable
chmod +x slowdns.sh

# Run as root
sudo ./slowdns.sh
```

### One-Line Installation
```bash
wget -O slowdns.sh https://raw.githubusercontent.com/YOUR_USERNAME/slowdns-manager/main/slowdns.sh && chmod +x slowdns.sh && sudo ./slowdns.sh
```

## 📖 Usage Guide

### 1️⃣ Setting Up DNSTT

1. Run the script: `sudo ./slowdns.sh`
2. Select **"1) DNSTT Management"**
3. Choose **"1) Install/Setup DNSTT"**
4. Follow the prompts:
   - Enter your nameserver domain or press Enter for auto-generate
   - Select MTU value (default: 1200)
5. Save the connection details provided

### 2️⃣ Managing SSH Users

1. From main menu, select **"2) SSH User Management"**
2. Choose your action:
   - **Add User**: Create new SSH accounts
   - **List Users**: View all users and their status
   - **Delete User**: Remove SSH accounts
   - **Edit Banner**: Customize login message

### 3️⃣ MTU Options Explained

- **512**: Best for very slow/unstable connections
- **1200**: Default - Balanced performance (recommended)
- **1280**: Better performance for good connections
- **1420**: Maximum performance for excellent connections
- **Custom**: Specify your own value (256-1500)

## 🔧 Configuration### Important Files
- `/etc/firewall/dnstt/server.key` - Private key
- `/etc/firewall/dnstt/server.pub` - Public key
- `/etc/firewall/dnstt/domain.txt` - Nameserver domain
- `/etc/slowdns/users.txt` - User database
- `/etc/slowdns/banner` - Login banner

## 🔐 Security Features

- Automatic firewall configuration
- Secure key generation
- User expiration management
- Connection limit enforcement
- Process isolation for users

## 📊 System Requirements Check
```bash
# Check if port 53 is available
sudo netstat -tuln | grep :53

# Check firewall status
sudo ufw status  # For UFW
sudo firewall-cmd --state  # For Firewalld
```

## 🐛 Troubleshooting

### Port 53 Already in Use
```bash
# Find process using port 53
sudo netstat -tulpn | grep :53

# Stop the service (example: systemd-resolved)
sudo systemctl stop systemd-resolved
```

### DNSTT Service Not Starting
```bash
# Check service status
sudo systemctl status dnstt

# View logs
sudo journalctl -u dnstt -f
```

### User Cannot Connect
1. Verify user exists: `id username`
2. Check user expiration: `chage -l username`
3. Verify SSH service: `sudo systemctl status ssh`

## 📸 Screenshots

### Main Menu## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👑 Author

**Made by The King** 👑👑

## ⭐ Support

If you find this project useful, please consider giving it a star ⭐

## 📞 Support & Contact

- 🐛 Issues: [GitHub Issues](https://github.com/YOUR_USERNAME/slowdns-manager/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/YOUR_USERNAME/slowdns-manager/discussions)

## 📚 Additional Resources

- [DNSTT Documentation](https://github.com/username/dnstt)
- [SSH Best Practices](https://www.ssh.com/academy/ssh/best-practices)
- [DNS Tunnel Tutorial](https://example.com/dns-tunnel-guide)

## 🔄 Changelog

### Version 3.4.0 (Latest)
- ✅ Initial release
- 🌐 Full DNSTT support
- 👥 Complete SSH user management
- 🎨 Professional colorful interface
- 📊 Multiple MTU options
- 🔑 Automatic key generation
- 🚪 Multi-firewall support

---

**⚠️ Disclaimer**: This tool is for educational and legitimate network management purposes only. Always comply with your local laws and regulations.

### Configuration Files Location
