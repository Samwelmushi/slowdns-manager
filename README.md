# 🌐 SLOW DNS - Complete DNSTT & SSH Management System

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Bash-4.0%2B-green.svg)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-Linux-blue.svg)](https://www.linux.org/)
[![GitHub stars](https://img.shields.io/github/stars/Samwelmushi/slowdns-manager?style=social)](https://github.com/Samwelmushi/slowdns-manager)

Professional DNS Tunnel (DNSTT) and SSH user management system with an intuitive interface and comprehensive features.

**Made by The King** 👑👑

---

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

---

## 📋 Requirements

- **OS**: Ubuntu 18.04+ / Debian 9+ / CentOS 7+
- **Access**: Root privileges required
- **Network**: Port 53 must be available
- **Dependencies**: Auto-installed (wget, curl, ufw/firewalld, git, gcc)

---

## 🚀 Quick Installation

### ⚡ One-Line Install (Recommended)
```bash
wget -qO- https://raw.githubusercontent.com/Samwelmushi/slowdns-manager/main/install.sh | sudo bash
```

### 📦 Manual Installation
```bash
# Download the installer
wget https://raw.githubusercontent.com/Samwelmushi/slowdns-manager/main/install.sh

# Make it executable
chmod +x install.sh

# Run as root
sudo ./install.sh
```

### 🔧 Alternative Method
```bash
# Download main script
sudo wget https://raw.githubusercontent.com/Samwelmushi/slowdns-manager/main/slowdns.sh -O /usr/local/bin/slowdns

# Make executable
sudo chmod +x /usr/local/bin/slowdns

# Run it
sudo slowdns
```

---

## 📖 Usage Guide

### 🎯 First Time Setup

After installation, run:
```bash
sudo slowdns
```

### 1️⃣ Setting Up DNSTT

1. From main menu, select **"1) DNSTT Management"**
2. Choose **"1) Install/Setup DNSTT"**
3. Follow the prompts:
   - Enter your nameserver domain or press Enter for auto-generate (tns.voltran.online)
   - Select MTU value (default: 1200 - recommended)
4. Save the connection details provided ✅

### 2️⃣ Managing SSH Users

1. From main menu, select **"2) SSH User Management"**
2. Choose your action:
   - **Add User**: Create new SSH accounts with custom settings
   - **List Users**: View all users and their status (ACTIVE/EXPIRED)
   - **Delete User**: Remove SSH accounts safely
   - **Edit Banner**: Customize login message

### 3️⃣ MTU Options Explained

| MTU Value | Best For | Description |
|-----------|----------|-------------|
| **512** | Very slow connections | Maximum stability, lowest speed |
| **1200** | ⭐ Default | Balanced performance (recommended) |
| **1280** | Good connections | Better performance |
| **1420** | Excellent connections | Maximum performance |
| **Custom** | Specific needs | Enter value between 256-1500 |

---

## 🔧 Configuration---

## 🔐 Security Features

- ✅ Automatic firewall configuration
- ✅ Secure key generation
- ✅ User expiration management
- ✅ Connection limit enforcement
- ✅ Process isolation for users
- ✅ Password encryption

---

## 📊 Example Usage

### Create a New User
```bash
sudo slowdns
# Select: 2 (SSH User Management)
# Select: 1 (Add New User)
# Username: john
# Password: secure123
# Expiration: 30 days
# Max connections: 2
```

### View DNSTT Status
```bash
sudo slowdns
# Select: 1 (DNSTT Management)
# Select: 2 (View DNSTT Status)
```

### List All Users
```bash
sudo slowdns
# Select: 2 (SSH User Management)
# Select: 2 (List All Users)
```

---

## 🐛 Troubleshooting

### Problem: Port 53 Already in Use
**Solution:**
```bash
# Find what's using port 53
sudo netstat -tulpn | grep :53

# If it's systemd-resolved, stop it
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved

# Run the script again
sudo slowdns
```

### Problem: DNSTT Service Not Starting
**Solution:**
```bash
# Check service status
sudo systemctl status dnstt

# View detailed logs
sudo journalctl -u dnstt -f

# Restart the service
sudo systemctl restart dnstt
```

### Problem: User Cannot Connect
**Solution:**
```bash
# 1. Verify user exists
id username

# 2. Check user expiration
sudo chage -l username

# 3. Verify SSH service is running
sudo systemctl status ssh

# 4. Check firewall rules
sudo ufw status
```

### Problem: Installation Fails
**Solution:**
```bash
# Make sure you have internet connection
ping -c 4 google.com

# Try manual installation
wget https://raw.githubusercontent.com/Samwelmushi/slowdns-manager/main/slowdns.sh
sudo chmod +x slowdns.sh
sudo ./slowdns.sh
```

---

## 📸 Screenshots

### Main Menu---

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. **Fork** the repository
2. Create your feature branch:
```bash
   git checkout -b feature/AmazingFeature
```
3. Commit your changes:
```bash
   git commit -m 'Add some AmazingFeature'
```
4. Push to the branch:
```bash
   git push origin feature/AmazingFeature
```
5. Open a **Pull Request**

### Ideas for Contributions
- 🌍 Add multi-language support
- 📊 Add bandwidth monitoring
- 🔔 Add notification system
- 📱 Create mobile app companion
- 🎨 Improve UI/UX
- 📝 Improve documentation
- 🐛 Bug fixes and improvements

---

## 📝 License
---

## 👑 Author

**Samwelmushi (The King)** 👑👑

- 🐙 GitHub: [@Samwelmushi](https://github.com/Samwelmushi)
- 📧 Issues: [Report a bug](https://github.com/Samwelmushi/slowdns-manager/issues)
- 💬 Discussions: [Join the conversation](https://github.com/Samwelmushi/slowdns-manager/discussions)

---

## ⭐ Show Your Support

If you find this project useful, please consider:

- ⭐ Starring this repository
- 🍴 Forking it
- 📢 Sharing it with others
- 🐛 Reporting bugs
- 💡 Suggesting new features

---

## 📞 Support & Contact

- 🐛 **Bug Reports**: [GitHub Issues](https://github.com/Samwelmushi/slowdns-manager/issues)
- 💬 **Questions**: [GitHub Discussions](https://github.com/Samwelmushi/slowdns-manager/discussions)
- 📖 **Documentation**: [Wiki](https://github.com/Samwelmushi/slowdns-manager/wiki)

---

## 📚 Additional Resources

- [DNSTT Official Documentation](https://github.com/username/dnstt)
- [SSH Security Best Practices](https://www.ssh.com/academy/ssh/best-practices)
- [DNS Tunnel Tutorial](https://en.wikipedia.org/wiki/DNS_tunneling)
- [Ubuntu Server Guide](https://ubuntu.com/server/docs)

---

## 🔄 Changelog

### Version 3.4.0 (Current - December 2025)
- ✅ Initial public release
- 🌐 Full DNSTT support with auto-configuration
- 👥 Complete SSH user management system
- 🎨 Professional colorful ASCII interface
- 📊 Multiple MTU options (512, 1200, 1280, 1420, custom)
- 🔑 Automatic cryptographic key generation
- 🚪 Multi-firewall support (UFW, Firewalld, iptables)
- 📝 Customizable login banner
- 📅 User expiration management
- 🔢 Connection limit control
- 📊 Real-time status monitoring
- ⚡ Easy one-line installation

---

## 📋 Roadmap

### Planned Features
- [ ] Web-based control panel
- [ ] Automatic backup system
- [ ] Email notifications
- [ ] Multi-server support
- [ ] Bandwidth usage statistics
- [ ] Docker support
- [ ] API for external integrations
- [ ] Mobile app for management

---

## ⚠️ Disclaimer

This tool is for **educational and legitimate network management purposes only**. 

- ✅ Always comply with your local laws and regulations
- ✅ Use only on networks you own or have permission to manage
- ✅ Respect user privacy and data protection laws
- ❌ Do not use for unauthorized access
- ❌ Do not use to bypass security measures

**The author is not responsible for any misuse of this software.**

---

## 🙏 Acknowledgments

Special thanks to:
- The open-source community
- All contributors and testers
- Everyone who provides feedback and suggestions

---

## 💰 Donation

If you want to support this project:

- ⭐ Star the repository
- 🍴 Fork and contribute
- 📢 Share with others
- ☕ [Buy me a coffee](https://www.buymeacoffee.com/samwelmushi) (optional)

---

<div align="center">

**Made with ❤️ by The King 👑👑**

⭐ Star this repo if you find it useful!

[Report Bug](https://github.com/Samwelmushi/slowdns-manager/issues) · [Request Feature](https://github.com/Samwelmushi/slowdns-manager/issues) · [Documentation](https://github.com/Samwelmushi/slowdns-manager/wiki)

</div>
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### Configuration Files Location
