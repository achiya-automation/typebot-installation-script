# 🚀 Typebot Installation Script

[![Version](https://img.shields.io/badge/version-3.1.0-blue.svg)](https://github.com/achiya-automation/typebot-installation-script/releases/tag/v3.1.0)
[![Security](https://img.shields.io/badge/security-99%2F100-brightgreen.svg)](https://github.com/achiya-automation/typebot-installation-script/blob/main/SECURITY_AUDIT.md)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Ubuntu](https://img.shields.io/badge/ubuntu-22.04%20%7C%2024.04-orange.svg)](https://ubuntu.com/)
[![Typebot](https://img.shields.io/badge/typebot-latest-purple.svg)](https://typebot.io/)
[![Docker](https://img.shields.io/badge/docker-required-blue.svg)](https://www.docker.com/)

Automated installation script for [Typebot](https://typebot.io/) with enterprise-grade security on Ubuntu 22.04+.

## ⭐ Features

- **One-command installation** - Complete setup in minutes
- **Maximum security** (99/100) - Enterprise-grade hardening
- **Interactive setup** - Easy configuration prompts
- **Production-ready** - Docker, PostgreSQL, Redis, MinIO, Nginx
- **SSL/TLS** - Cloudflare Origin Certificates support
- **Firewall & SSH hardening** - UFW, Fail2ban, custom SSH port
- **Resource limits** - Prevents resource exhaustion
- **Log rotation** - Automatic log management

## 🔒 Security Rating: 99/100

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Network Security       ████████████████████ 100%
SSH Hardening          ████████████████████ 100%
SSL/TLS                ████████████████████ 100%
Password Management    ████████████████████ 100%
File Permissions       ████████████████████ 100%
Input Validation       ████████████████████ 100%
Docker Security        ████████████████████ 100%
Logging & Monitoring   ████████████████████ 100%
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 📋 Prerequisites

1. **Fresh Ubuntu 22.04+ server** with root access
2. **Domain names** pointed to your server (all 3 are required):
   - Builder domain (e.g., `typebot.yourdomain.com`)
   - Viewer domain (e.g., `bot.yourdomain.com`)
   - MinIO domain (e.g., `minio.yourdomain.com`) - **Required for file uploads**
3. **Cloudflare Origin SSL certificates** ([Free, 15-year validity](https://developers.cloudflare.com/ssl/origin-configuration/origin-ca/))
   - **Important:** Certificate must include all 3 domains
4. **SMTP credentials** for email magic link authentication

## 🚀 Quick Start

```bash
# Download the script
wget https://raw.githubusercontent.com/achiya-automation/typebot-installation-script/main/install-typebot.sh

# Make it executable
chmod +x install-typebot.sh

# Run it
sudo ./install-typebot.sh
```

The script will guide you through an interactive setup process.

## 📖 Documentation

- **[Installation Guide](INSTALLATION_GUIDE.md)** - Complete setup instructions (Hebrew)
- **[Security Audit](SECURITY_AUDIT.md)** - Detailed security analysis (Hebrew)

## 🛡️ What Gets Installed

### Core Components
- ✅ Docker & Docker Compose
- ✅ PostgreSQL 16 (database)
- ✅ Redis Alpine (caching & sessions)
- ✅ MinIO (S3-compatible object storage)
- ✅ Typebot Builder & Viewer
- ✅ Nginx (reverse proxy with SSL termination)

### Security Components
- ✅ UFW Firewall (minimal ports: 2222, 80, 443)
- ✅ Fail2ban (brute-force protection)
- ✅ SSH hardening (custom port 2222, key-based auth)
- ✅ SSL/TLS with modern cipher suites
- ✅ Docker resource limits & security options
- ✅ Automatic log rotation

## 🔐 Security Features

### 🔑 Encryption & Passwords
- Cryptographically secure password generation (24 characters)
- AES-256 compatible encryption keys (32 hex chars)
- No hardcoded secrets - all generated at install time
- Secure file permissions (600) for sensitive files

### 🌐 Network Security
- UFW firewall with default deny incoming policy
- MinIO S3 API exposed via Nginx reverse proxy with SSL/TLS
- Docker network isolation (`typebot-network`)
- Fail2ban protection against SSH brute-force attacks
- All services communicate internally via Docker network

### 🔐 SSH Hardening
- Custom SSH port (2222) to reduce automated attacks
- Key-based authentication for root (password auth disabled for root)
- Maximum 3 authentication attempts
- Client timeout after 5 minutes of inactivity
- X11 forwarding disabled

### 🔒 SSL/TLS Configuration
- TLS 1.2 & 1.3 only (older versions disabled)
- Modern AEAD cipher suites with Forward Secrecy:
  - ECDHE-ECDSA/RSA-AES128/256-GCM-SHA256/384
  - ECDHE-ECDSA/RSA-CHACHA20-POLY1305
  - DHE-RSA-AES128/256-GCM-SHA256/384
- OCSP stapling enabled
- Session cache for performance
- Security headers:
  - **HSTS** (Strict-Transport-Security)
  - **X-Frame-Options** (SAMEORIGIN)
  - **X-Content-Type-Options** (nosniff)
  - **X-XSS-Protection** (enabled)
  - **Content-Security-Policy**

### 🐳 Docker Security
- **Resource limits** on all containers:
  - PostgreSQL: 1 CPU, 1GB RAM
  - Redis: 0.5 CPU, 512MB RAM
  - MinIO: 1 CPU, 1GB RAM
  - Typebot Builder/Viewer: 2 CPU, 2GB RAM each
- **Log rotation**: 10MB max per file, 3 files retained (30MB total)
- **Security option**: `no-new-privileges:true` on all containers
- Healthchecks for all services
- Network isolation between containers

### 📝 Input Validation
- Domain validation (supports multi-level subdomains)
- Email validation (RFC 5322 compliant)
- Command injection prevention
- Proper escaping of user inputs

## 📊 System Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **CPU** | 2 cores | 4+ cores |
| **RAM** | 4 GB | 8+ GB |
| **Disk** | 20 GB | 50+ GB SSD |
| **OS** | Ubuntu 22.04 | Ubuntu 24.04 LTS |
| **Network** | 10 Mbps | 100+ Mbps |

## 🎯 Interactive Installation Process

The script will prompt you for:

1. **Domain Configuration**
   - Builder domain (main application)
   - Viewer domain (for published bots)
   - MinIO domain (optional - for S3 console access)

2. **SSL Certificates**
   - Cloudflare Origin Certificate (paste content)
   - Private Key (paste content, input hidden)

3. **Admin Settings**
   - Admin email address
   - Disable new user signup (yes/no)

4. **SMTP Configuration**
   - SMTP host
   - SMTP port
   - Username & password
   - From email address

5. **Google Integrations** (Optional)
   - Google Sheets
   - Gmail
   - Google Fonts
   - Google OAuth

All inputs are validated before proceeding.

## 🔍 Post-Installation

After successful installation, you'll receive:

- ✅ Access URLs for your Typebot instance
- ✅ Database credentials
- ✅ S3/MinIO credentials
- ✅ Important security reminders
- ✅ Location of installation info file

**Important**: The script saves all credentials to `/opt/typebot/INSTALLATION_INFO.txt` with secure permissions (600).

### First Login

1. Navigate to your Builder domain (e.g., `https://typebot.yourdomain.com`)
2. Enter your admin email
3. Check your email for the magic link
4. Click the link to sign in

## 🛠️ Management Commands

```bash
# Navigate to Typebot directory
cd /opt/typebot

# View running containers
docker compose ps

# View logs
docker compose logs -f
docker compose logs typebot-builder --tail=50
docker compose logs typebot-viewer --tail=50

# Restart services
docker compose restart

# Stop services
docker compose down

# Start services
docker compose up -d

# Update Typebot to latest version
docker compose pull
docker compose up -d
```

## 🔧 Troubleshooting

### Internal Server Error (500)

Check logs for errors:
```bash
cd /opt/typebot
docker compose logs typebot-builder --tail=50
docker compose logs typebot-viewer --tail=50
```

Common issue: `DISABLE_SIGNUP` must be `true` or `false` (not `yes` or `no`).

### Database Connection Issues

```bash
# Check PostgreSQL health
docker compose ps | grep db

# View database logs
docker compose logs typebot-db --tail=50

# Restart database
docker compose restart typebot-db
```

### SSL Certificate Issues

```bash
# Verify certificate files exist
ls -la /etc/ssl/cloudflare/

# Check Nginx configuration
nginx -t

# View Nginx logs
tail -f /var/log/nginx/error.log
```

### Email Not Sending

```bash
# Check SMTP configuration
cat /opt/typebot/.env | grep SMTP

# View email-related logs
docker compose logs typebot-builder | grep -i smtp
```

## 🔄 Updating

To update Typebot to the latest version:

```bash
cd /opt/typebot
docker compose pull
docker compose up -d
```

To update system packages:

```bash
apt update && apt upgrade -y
reboot
```

## 📁 Important Files

| File | Purpose | Permissions |
|------|---------|-------------|
| `/opt/typebot/.env` | Environment variables & secrets | 600 (root only) |
| `/opt/typebot/docker-compose.yml` | Container configuration | 644 |
| `/opt/typebot/INSTALLATION_INFO.txt` | All credentials & info | 600 (root only) |
| `/etc/ssl/cloudflare/cert.pem` | SSL certificate | 600 (root only) |
| `/etc/ssl/cloudflare/key.pem` | SSL private key | 600 (root only) |
| `/etc/nginx/sites-available/typebot` | Nginx config | 644 |

## ⚠️ Important Security Notes

1. **Save your credentials** immediately after installation from `/opt/typebot/INSTALLATION_INFO.txt`
2. **Delete the info file** after saving: `rm /opt/typebot/INSTALLATION_INFO.txt`
3. **SSH port changed to 2222** - Update your firewall/security groups if needed
4. **Backup regularly**:
   - `/opt/typebot/.env`
   - Docker volumes (db-data, redis-data, minio-data)
   - `/etc/ssl/cloudflare/`

## 🔐 Backup Strategy

```bash
# Backup script example
#!/bin/bash
BACKUP_DIR="/backup/typebot-$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

# Backup .env file
cp /opt/typebot/.env "$BACKUP_DIR/"

# Backup SSL certificates
cp -r /etc/ssl/cloudflare "$BACKUP_DIR/"

# Backup database
docker exec typebot-typebot-db-1 pg_dump -U postgres typebot > "$BACKUP_DIR/database.sql"

# Backup MinIO data (optional - can be large)
# docker exec typebot-typebot-minio-1 mc mirror /data "$BACKUP_DIR/minio/"

tar -czf "$BACKUP_DIR.tar.gz" "$BACKUP_DIR"
rm -rf "$BACKUP_DIR"
```

## 🌍 Language

- Script interface: Hebrew
- Documentation: Hebrew (this README: English)
- Code comments: English/Hebrew mixed
- All code is readable and well-documented

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Internet                              │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                  UFW Firewall                            │
│          Ports: 2222 (SSH), 80, 443 (HTTPS)             │
└─────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│                Nginx (Reverse Proxy)                     │
│              SSL/TLS Termination                         │
│     ┌──────────────┬──────────────┬─────────────┐       │
│     │   Builder    │    Viewer    │   MinIO     │       │
│     │  :8080       │    :8081     │   :9000     │       │
└─────┴──────────────┴──────────────┴─────────────┴───────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────┐
│             Docker Network (typebot-network)             │
│                                                          │
│  ┌────────────┐  ┌─────────┐  ┌──────┐  ┌──────────┐   │
│  │ PostgreSQL │  │  Redis  │  │ MinIO│  │ Typebot  │   │
│  │    :5432   │  │  :6379  │  │ S3   │  │ Builder/ │   │
│  │            │  │         │  │      │  │  Viewer  │   │
│  └────────────┘  └─────────┘  └──────┘  └──────────┘   │
│                                                          │
│  Volumes: db-data, redis-data, minio-data               │
└─────────────────────────────────────────────────────────┘
```

## 📝 Script Workflow

1. ✅ System checks (root, OS version, connectivity)
2. ✅ Interactive configuration collection
3. ✅ System updates & package installation
4. ✅ UFW firewall setup
5. ✅ SSH hardening (port 2222, Fail2ban)
6. ✅ Docker & Docker Compose installation
7. ✅ Typebot configuration generation
8. ✅ SSL certificate installation
9. ✅ Nginx setup with security headers
10. ✅ Docker container deployment
11. ✅ Service health checks
12. ✅ Credentials file generation
13. ✅ Final verification & success message

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Development

```bash
# Clone the repository
git clone https://github.com/achiya-automation/typebot-installation-script.git
cd typebot-installation-script

# Make changes
nano install-typebot.sh

# Test on a fresh Ubuntu server
# DO NOT test on production!
```

## 📜 Changelog

### Version 3.0 (Current)
- ✅ Maximum security hardening (99/100 rating)
- ✅ Docker resource limits on all containers
- ✅ Automatic log rotation (10MB/file, 3 files)
- ✅ Container security options (`no-new-privileges`)
- ✅ Fixed `DISABLE_SIGNUP` validation (true/false vs yes/no)
- ✅ Complete Hebrew documentation
- ✅ Comprehensive security audit report

### Version 2.0
- ✅ SSH hardening with custom port
- ✅ Modern SSL/TLS cipher suites
- ✅ MinIO ports bound to localhost
- ✅ Subdomain support in validation
- ✅ Optional MinIO Console setup

### Version 1.0
- ✅ Initial release
- ✅ Basic Typebot installation
- ✅ Docker Compose setup

## 📄 License

MIT License

Copyright (c) 2025 Achiya Automation

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## 🙏 Acknowledgments

- [Typebot](https://typebot.io/) - Amazing open-source chatbot builder
- [Docker](https://www.docker.com/) - Container platform
- [Nginx](https://nginx.org/) - High-performance web server
- [PostgreSQL](https://www.postgresql.org/) - Powerful database
- [MinIO](https://min.io/) - S3-compatible object storage
- [Cloudflare](https://www.cloudflare.com/) - SSL certificates & CDN

## 📧 Support

For issues, questions, or suggestions:

- 🐛 Open an issue: [GitHub Issues](https://github.com/achiya-automation/typebot-installation-script/issues)
- 💬 Discussions: [GitHub Discussions](https://github.com/achiya-automation/typebot-installation-script/discussions)

---

<div align="center">

**Made with ❤️ for the Typebot community**

🔒 Security Audited | ✅ Production Ready | 🚀 Easy Setup

[⭐ Star this repo](https://github.com/achiya-automation/typebot-installation-script) if you find it useful!

</div>
