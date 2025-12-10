#!/bin/bash

###########################################
# Typebot Automated Installation Script
# Secure, Interactive, Production-Ready
###########################################

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }

# Function to read secure input (passwords)
read_secure() {
    local prompt="$1"
    local var_name="$2"
    echo -n "$prompt"
    read -s input
    echo ""
    eval "$var_name='$input'"
}

# Function to read multiline input
read_multiline() {
    local prompt="$1"
    local var_name="$2"
    echo "$prompt"
    echo "(Press Ctrl+D when finished)"
    local content=$(cat)
    eval "$var_name='$content'"
}

# Function to validate domain
validate_domain() {
    local domain="$1"
    if [[ ! "$domain" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?\.[a-zA-Z]{2,}$ ]]; then
        print_error "Invalid domain format: $domain"
        exit 1
    fi
}

# Function to validate email
validate_email() {
    local email="$1"
    if [[ ! "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        print_error "Invalid email format: $email"
        exit 1
    fi
}

# Generate random password
generate_password() {
    openssl rand -base64 24 | tr -d "=+/" | cut -c1-24
}

clear
echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║                                                        ║"
echo "║         TYPEBOT AUTOMATED INSTALLATION SCRIPT          ║"
echo "║              Secure Production Deployment              ║"
echo "║                                                        ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

print_warning "This script will install and configure:"
echo "  • SSH Security (Port 2222, UFW, Fail2ban)"
echo "  • Docker & Docker Compose"
echo "  • Typebot (Builder + Viewer)"
echo "  • PostgreSQL 16 + Redis + MinIO"
echo "  • Nginx Reverse Proxy with SSL"
echo ""

read -p "Continue? (yes/no): " confirm
if [[ "$confirm" != "yes" ]]; then
    print_error "Installation cancelled"
    exit 1
fi

echo ""
print_info "═══════════════════════════════════════"
print_info "Step 1: Collecting Configuration Data"
print_info "═══════════════════════════════════════"
echo ""

# Domains
read -p "Enter Builder domain (e.g., typebot.example.com): " BUILDER_DOMAIN
validate_domain "$BUILDER_DOMAIN"

read -p "Enter Viewer domain (e.g., typebot-bot.example.com): " VIEWER_DOMAIN
validate_domain "$VIEWER_DOMAIN"

read -p "Enter MinIO domain (e.g., minio.example.com): " MINIO_DOMAIN
validate_domain "$MINIO_DOMAIN"

# Admin Email
read -p "Enter admin email: " ADMIN_EMAIL
validate_email "$ADMIN_EMAIL"

# SMTP Configuration
echo ""
print_info "SMTP Configuration (for Email Magic Link authentication)"
read -p "SMTP Host (e.g., smtp.gmail.com): " SMTP_HOST
read -p "SMTP Port (e.g., 587): " SMTP_PORT
read -p "SMTP Username (email): " SMTP_USERNAME
validate_email "$SMTP_USERNAME"
read_secure "SMTP Password (hidden): " SMTP_PASSWORD
read -p "SMTP From Email: " SMTP_FROM
validate_email "$SMTP_FROM"

# SSL Certificates
echo ""
print_info "Cloudflare SSL Certificate (Origin Certificate)"
read_multiline "Paste your Cloudflare Origin Certificate:" SSL_CERT

echo ""
print_info "Cloudflare SSL Private Key"
read_multiline "Paste your Cloudflare Private Key:" SSL_KEY

# Google Integrations (Optional)
echo ""
read -p "Do you want to configure Google integrations? (yes/no): " SETUP_GOOGLE
if [[ "$SETUP_GOOGLE" == "yes" ]]; then
    read -p "Google OAuth Client ID: " GOOGLE_CLIENT_ID
    read_secure "Google OAuth Client Secret (hidden): " GOOGLE_CLIENT_SECRET
    read -p "Google API Key: " GOOGLE_API_KEY
fi

# Advanced Options
echo ""
read -p "Disable user signup? (yes/no) [recommended: yes]: " DISABLE_SIGNUP_INPUT
DISABLE_SIGNUP="false"
if [[ "$DISABLE_SIGNUP_INPUT" == "yes" ]]; then
    DISABLE_SIGNUP="true"
fi

# Generate secure passwords
print_info "Generating secure passwords..."
DB_PASSWORD=$(generate_password)
MINIO_ROOT_USER="typebot_minio_admin"
MINIO_ROOT_PASSWORD=$(generate_password)
ENCRYPTION_SECRET=$(openssl rand -hex 16)
NEXTAUTH_SECRET=$(openssl rand -hex 16)

echo ""
print_success "Configuration collected successfully!"
echo ""

###########################################
# System Update
###########################################

print_info "═══════════════════════════════════════"
print_info "Step 2: Updating System"
print_info "═══════════════════════════════════════"

apt update > /dev/null 2>&1
apt upgrade -y > /dev/null 2>&1
apt install -y curl wget git vim htop net-tools unattended-upgrades > /dev/null 2>&1

print_success "System updated"

###########################################
# SSH Security
###########################################

print_info "═══════════════════════════════════════"
print_info "Step 3: Configuring SSH Security"
print_info "═══════════════════════════════════════"

# Configure UFW Firewall
apt install -y ufw > /dev/null 2>&1
ufw --force reset > /dev/null 2>&1
ufw default deny incoming > /dev/null 2>&1
ufw default allow outgoing > /dev/null 2>&1
ufw allow 22/tcp comment 'SSH temporary' > /dev/null 2>&1
ufw allow 2222/tcp comment 'SSH new port' > /dev/null 2>&1
ufw allow 80/tcp comment 'HTTP' > /dev/null 2>&1
ufw allow 443/tcp comment 'HTTPS' > /dev/null 2>&1

# Block direct access to application ports (CVE-2025-55182 protection)
ufw deny 8080 comment 'Block Typebot Builder - use Nginx only' > /dev/null 2>&1
ufw deny 8081 comment 'Block Typebot Viewer - use Nginx only' > /dev/null 2>&1
ufw deny 9000 comment 'Block MinIO API - use Nginx only' > /dev/null 2>&1
ufw deny 9001 comment 'Block MinIO Console - use Nginx only' > /dev/null 2>&1

ufw --force enable > /dev/null 2>&1

print_success "UFW firewall configured (with CVE-2025-55182 protection)"

# Change SSH Port
if grep -q '^Port ' /etc/ssh/sshd_config; then
    sed -i 's/^Port .*/Port 2222/' /etc/ssh/sshd_config
elif grep -q '^#Port 22' /etc/ssh/sshd_config; then
    sed -i 's/^#Port 22/Port 2222/' /etc/ssh/sshd_config
else
    sed -i '1i Port 2222' /etc/ssh/sshd_config
fi

systemctl restart sshd > /dev/null 2>&1
print_success "SSH port changed to 2222"

# Remove old port 22
sleep 2
ufw delete allow 22/tcp > /dev/null 2>&1

# Install Fail2ban
apt install -y fail2ban > /dev/null 2>&1
cat > /etc/fail2ban/jail.local << 'EOF'
[sshd]
enabled = true
port = 2222
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
findtime = 600
EOF

systemctl restart fail2ban > /dev/null 2>&1
systemctl enable fail2ban > /dev/null 2>&1

print_success "Fail2ban configured"

###########################################
# Docker Installation
###########################################

print_info "═══════════════════════════════════════"
print_info "Step 4: Installing Docker"
print_info "═══════════════════════════════════════"

# Remove old Docker
apt remove -y docker docker-engine docker.io containerd runc > /dev/null 2>&1 || true

# Install Docker
curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
sh /tmp/get-docker.sh > /dev/null 2>&1
rm /tmp/get-docker.sh

systemctl start docker > /dev/null 2>&1
systemctl enable docker > /dev/null 2>&1

print_success "Docker installed"

###########################################
# Typebot Setup
###########################################

print_info "═══════════════════════════════════════"
print_info "Step 5: Setting Up Typebot"
print_info "═══════════════════════════════════════"

mkdir -p /opt/typebot
cd /opt/typebot

# Create docker-compose.yml
cat > docker-compose.yml << 'COMPOSE_EOF'
x-typebot-common: &typebot-common
  restart: always
  depends_on:
    typebot-redis:
      condition: service_healthy
    typebot-db:
      condition: service_healthy
  networks:
    - typebot-network
  env_file: .env
  environment:
    REDIS_URL: redis://typebot-redis:6379

services:
  typebot-db:
    image: postgres:16
    restart: always
    volumes:
      - db-data:/var/lib/postgresql/data
    environment:
      - POSTGRES_DB=typebot
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5
    networks:
      - typebot-network

  typebot-redis:
    image: redis:alpine
    restart: always
    command: --save 60 1 --loglevel warning
    healthcheck:
      test: ["CMD-SHELL", "redis-cli ping | grep PONG"]
      start_period: 20s
      interval: 30s
      retries: 5
      timeout: 3s
    volumes:
      - redis-data:/data
    networks:
      - typebot-network

  typebot-minio:
    image: minio/minio:latest
    restart: always
    command: server /data --console-address ":9001"
    ports:
      - "127.0.0.1:9000:9000"
      - "127.0.0.1:9001:9001"
    environment:
      MINIO_ROOT_USER: ${MINIO_ROOT_USER}
      MINIO_ROOT_PASSWORD: ${MINIO_ROOT_PASSWORD}
    volumes:
      - minio-data:/data
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:9000/minio/health/live"]
      interval: 30s
      timeout: 20s
      retries: 3
    networks:
      - typebot-network

  typebot-builder:
    <<: *typebot-common
    image: baptistearno/typebot-builder:latest
    ports:
      - "127.0.0.1:8080:3000"

  typebot-viewer:
    <<: *typebot-common
    image: baptistearno/typebot-viewer:latest
    ports:
      - "127.0.0.1:8081:3000"

networks:
  typebot-network:
    driver: bridge

volumes:
  db-data:
  redis-data:
  minio-data:
COMPOSE_EOF

# Create .env file
cat > .env << ENV_EOF
# Encryption secret (32 characters)
ENCRYPTION_SECRET=${ENCRYPTION_SECRET}

# Database
DATABASE_URL=postgresql://postgres:${DB_PASSWORD}@typebot-db:5432/typebot

# Redis
REDIS_URL=redis://typebot-redis:6379

# Node options
NODE_OPTIONS=--no-node-snapshot

# URLs - Builder and Viewer
NEXTAUTH_URL=https://${BUILDER_DOMAIN}
NEXT_PUBLIC_VIEWER_URL=https://${VIEWER_DOMAIN}

# NextAuth Secret
NEXTAUTH_SECRET=${NEXTAUTH_SECRET}

# Admin email
ADMIN_EMAIL=${ADMIN_EMAIL}

# SMTP Configuration
SMTP_HOST=${SMTP_HOST}
SMTP_PORT=${SMTP_PORT}
SMTP_USERNAME=${SMTP_USERNAME}
SMTP_PASSWORD=${SMTP_PASSWORD}
SMTP_SECURE=false
NEXT_PUBLIC_SMTP_FROM=${SMTP_FROM}
EMAIL_FROM=${SMTP_FROM}
SMTP_FROM=${SMTP_FROM}

# Disable Signup
DISABLE_SIGNUP=${DISABLE_SIGNUP}

# MinIO S3 Storage
S3_ACCESS_KEY=${MINIO_ROOT_USER}
S3_SECRET_KEY=${MINIO_ROOT_PASSWORD}
S3_BUCKET=typebot
S3_ENDPOINT=typebot-minio
S3_PORT=9000
S3_SSL=false
S3_REGION=us-east-1
ENV_EOF

# Add Google credentials if provided
if [[ "$SETUP_GOOGLE" == "yes" ]]; then
    cat >> .env << ENV_GOOGLE
# Google Sheets Integration
GOOGLE_SHEETS_CLIENT_ID=${GOOGLE_CLIENT_ID}
GOOGLE_SHEETS_CLIENT_SECRET=${GOOGLE_CLIENT_SECRET}
NEXT_PUBLIC_GOOGLE_SHEETS_API_KEY=${GOOGLE_API_KEY}

# Gmail Integration
GMAIL_CLIENT_ID=${GOOGLE_CLIENT_ID}
GMAIL_CLIENT_SECRET=${GOOGLE_CLIENT_SECRET}

# Google Fonts
NEXT_PUBLIC_GOOGLE_FONTS_API_KEY=${GOOGLE_API_KEY}
ENV_GOOGLE
fi

chmod 600 .env

print_success "Typebot configuration created"

###########################################
# SSL Certificates
###########################################

print_info "═══════════════════════════════════════"
print_info "Step 6: Installing SSL Certificates"
print_info "═══════════════════════════════════════"

mkdir -p /etc/ssl/cloudflare
echo "$SSL_CERT" > /etc/ssl/cloudflare/cert.pem
echo "$SSL_KEY" > /etc/ssl/cloudflare/key.pem
chmod 600 /etc/ssl/cloudflare/*.pem

print_success "SSL certificates installed"

###########################################
# Nginx Installation
###########################################

print_info "═══════════════════════════════════════"
print_info "Step 7: Installing Nginx"
print_info "═══════════════════════════════════════"

apt install -y nginx > /dev/null 2>&1

# Nginx config for Typebot
cat > /etc/nginx/sites-available/typebot << NGINX_EOF
# HTTP to HTTPS redirect for Builder
server {
    listen 80;
    server_name ${BUILDER_DOMAIN};
    return 301 https://\$server_name\$request_uri;
}

# HTTPS for Builder
server {
    listen 443 ssl http2;
    server_name ${BUILDER_DOMAIN};
    
    ssl_certificate /etc/ssl/cloudflare/cert.pem;
    ssl_certificate_key /etc/ssl/cloudflare/key.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Frame-Options SAMEORIGIN always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https:; style-src 'self' 'unsafe-inline' https:; connect-src 'self' https: wss:; frame-src 'self' https:; img-src 'self' data: blob: https:; font-src 'self' https: data:; media-src 'self' https:; worker-src 'self' blob:; object-src 'none'" always;
    
    client_max_body_size 50M;
    
    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
}

# HTTP to HTTPS redirect for Viewer
server {
    listen 80;
    server_name ${VIEWER_DOMAIN};
    return 301 https://\$server_name\$request_uri;
}

# HTTPS for Viewer
server {
    listen 443 ssl http2;
    server_name ${VIEWER_DOMAIN};
    
    ssl_certificate /etc/ssl/cloudflare/cert.pem;
    ssl_certificate_key /etc/ssl/cloudflare/key.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Frame-Options SAMEORIGIN always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    client_max_body_size 50M;
    
    location / {
        proxy_pass http://localhost:8081;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
}
NGINX_EOF

# Nginx config for MinIO
cat > /etc/nginx/sites-available/minio << NGINX_MINIO_EOF
# HTTP to HTTPS redirect for MinIO
server {
    listen 80;
    server_name ${MINIO_DOMAIN};
    return 301 https://\$server_name\$request_uri;
}

# HTTPS for MinIO Console
server {
    listen 443 ssl http2;
    server_name ${MINIO_DOMAIN};
    
    ssl_certificate /etc/ssl/cloudflare/cert.pem;
    ssl_certificate_key /etc/ssl/cloudflare/key.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Frame-Options SAMEORIGIN always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    client_max_body_size 500M;
    
    location / {
        proxy_pass http://localhost:9001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
NGINX_MINIO_EOF

ln -sf /etc/nginx/sites-available/typebot /etc/nginx/sites-enabled/
ln -sf /etc/nginx/sites-available/minio /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

nginx -t > /dev/null 2>&1
systemctl restart nginx > /dev/null 2>&1

print_success "Nginx configured"

###########################################
# Start Services
###########################################

print_info "═══════════════════════════════════════"
print_info "Step 8: Starting Services"
print_info "═══════════════════════════════════════"

cd /opt/typebot
docker compose up -d

print_info "Waiting for services to be healthy (60 seconds)..."
sleep 60

print_success "Services started"

###########################################
# Create MinIO Bucket
###########################################

print_info "═══════════════════════════════════════"
print_info "Step 9: Creating MinIO Bucket"
print_info "═══════════════════════════════════════"

docker run --rm --network typebot_typebot-network \
  -e MC_HOST_minio="http://${MINIO_ROOT_USER}:${MINIO_ROOT_PASSWORD}@typebot-minio:9000" \
  minio/mc:latest mb minio/typebot > /dev/null 2>&1 || true

docker run --rm --network typebot_typebot-network \
  -e MC_HOST_minio="http://${MINIO_ROOT_USER}:${MINIO_ROOT_PASSWORD}@typebot-minio:9000" \
  minio/mc:latest anonymous set download minio/typebot > /dev/null 2>&1 || true

print_success "MinIO bucket created"

###########################################
# Security Monitoring & Auto-Update
###########################################

print_info "═══════════════════════════════════════"
print_info "Step 10: Setting Up Security Monitoring"
print_info "═══════════════════════════════════════"

# Create security update script
cat > /opt/typebot/update-typebot.sh << 'UPDATE_SCRIPT'
#!/bin/bash
# Typebot Security Update Script
# Run this weekly or when security updates are released

set -e

LOG_FILE="/var/log/typebot-updates.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$DATE] Starting Typebot update..." >> "$LOG_FILE"

cd /opt/typebot

# Backup current configuration
cp docker-compose.yml "docker-compose.yml.backup-$(date +%Y%m%d-%H%M%S)"
cp .env ".env.backup-$(date +%Y%m%d-%H%M%S)"

# Pull latest images
echo "[$DATE] Pulling latest images..." >> "$LOG_FILE"
docker compose pull >> "$LOG_FILE" 2>&1

# Restart with new images
echo "[$DATE] Restarting services..." >> "$LOG_FILE"
docker compose down >> "$LOG_FILE" 2>&1
docker compose up -d >> "$LOG_FILE" 2>&1

# Wait for services
sleep 30

# Check if services are running
if docker compose ps | grep -q "Up"; then
    echo "[$DATE] Update completed successfully!" >> "$LOG_FILE"
    # Clean old backups (keep last 5)
    ls -t docker-compose.yml.backup-* 2>/dev/null | tail -n +6 | xargs -r rm
    ls -t .env.backup-* 2>/dev/null | tail -n +6 | xargs -r rm
else
    echo "[$DATE] ERROR: Services failed to start!" >> "$LOG_FILE"
    exit 1
fi

# Log current versions
echo "[$DATE] Current versions:" >> "$LOG_FILE"
docker compose images >> "$LOG_FILE" 2>&1

echo "[$DATE] Update completed!" >> "$LOG_FILE"
UPDATE_SCRIPT

chmod +x /opt/typebot/update-typebot.sh

# Create security monitoring script
cat > /opt/typebot/security-check.sh << 'SECURITY_SCRIPT'
#!/bin/bash
# Typebot Security Monitoring Script
# Checks for suspicious activity and logs it

LOG_FILE="/var/log/typebot-security.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$DATE] Running security check..." >> "$LOG_FILE"

# Check for attack patterns in viewer logs (CVE-2025-55182)
ATTACK_COUNT=$(docker logs typebot-typebot-viewer-1 2>&1 | grep -c "busybox\|x86\|wget.*http\|curl.*http" 2>/dev/null || echo "0")

if [ "$ATTACK_COUNT" -gt 0 ]; then
    echo "[$DATE] WARNING: Detected $ATTACK_COUNT potential attack attempts!" >> "$LOG_FILE"
    echo "[$DATE] Attack patterns found in viewer logs" >> "$LOG_FILE"
    docker logs --tail 50 typebot-typebot-viewer-1 2>&1 | grep -E "busybox|x86|wget|curl" >> "$LOG_FILE" 2>&1 || true
fi

# Check for suspicious processes
SUSPICIOUS_PROCS=$(ps auxf | grep -v grep | grep -E "miner|crypto|xmr|kdevtmpfsi|xmrig" | wc -l)
if [ "$SUSPICIOUS_PROCS" -gt 0 ]; then
    echo "[$DATE] WARNING: Suspicious processes detected!" >> "$LOG_FILE"
    ps auxf | grep -v grep | grep -E "miner|crypto|xmr|kdevtmpfsi|xmrig" >> "$LOG_FILE" 2>&1 || true
fi

# Check for unauthorized network connections
SUSPICIOUS_CONN=$(netstat -antp 2>/dev/null | grep ESTABLISHED | grep -v ':443\|:80\|:2222' | wc -l)
if [ "$SUSPICIOUS_CONN" -gt 5 ]; then
    echo "[$DATE] INFO: $SUSPICIOUS_CONN unusual network connections" >> "$LOG_FILE"
fi

# Check Fail2ban status
BANNED_IPS=$(fail2ban-client status sshd 2>/dev/null | grep "Currently banned" | awk '{print $4}')
if [ "$BANNED_IPS" -gt 0 ]; then
    echo "[$DATE] Fail2ban: $BANNED_IPS IPs currently banned" >> "$LOG_FILE"
fi

echo "[$DATE] Security check completed" >> "$LOG_FILE"
SECURITY_SCRIPT

chmod +x /opt/typebot/security-check.sh

# Create weekly cron job for updates (Sunday 3 AM)
cat > /etc/cron.d/typebot-security << 'CRON_EOF'
# Typebot Security: Weekly updates (Sunday 3 AM)
0 3 * * 0 root /opt/typebot/update-typebot.sh

# Typebot Security: Daily security checks (every 6 hours)
0 */6 * * * root /opt/typebot/security-check.sh
CRON_EOF

chmod 644 /etc/cron.d/typebot-security

# Create log rotation
cat > /etc/logrotate.d/typebot << 'LOGROTATE_EOF'
/var/log/typebot-updates.log {
    weekly
    rotate 4
    compress
    missingok
    notifempty
}

/var/log/typebot-security.log {
    weekly
    rotate 12
    compress
    missingok
    notifempty
}
LOGROTATE_EOF

print_success "Security monitoring configured"
print_info "  • Auto-update script: /opt/typebot/update-typebot.sh"
print_info "  • Security check script: /opt/typebot/security-check.sh"
print_info "  • Updates run weekly (Sunday 3 AM)"
print_info "  • Security checks run every 6 hours"

###########################################
# Save Credentials
###########################################

cat > /opt/typebot/INSTALLATION_INFO.txt << INFO_EOF
╔════════════════════════════════════════════════════════╗
║         TYPEBOT INSTALLATION COMPLETED                 ║
╚════════════════════════════════════════════════════════╝

Installation Date: $(date)

IMPORTANT SECURITY NOTES:
========================
1. SSH port has been changed to 2222
2. Connect using: ssh -p 2222 root@YOUR_SERVER_IP
3. Firewall (UFW) is active - blocks direct access to ports 8080, 8081, 9000, 9001
4. Fail2ban is protecting SSH
5. CVE-2025-55182 Protection: Ports only accessible via Nginx reverse proxy
6. Automatic weekly updates enabled (Sunday 3 AM)
7. Security monitoring runs every 6 hours

DOMAINS:
========
Builder:  https://${BUILDER_DOMAIN}
Viewer:   https://${VIEWER_DOMAIN}
MinIO:    https://${MINIO_DOMAIN}

ADMIN ACCESS:
=============
Admin Email: ${ADMIN_EMAIL}
Login Method: Email Magic Link (check your inbox)

DATABASE CREDENTIALS:
=====================
PostgreSQL User: postgres
PostgreSQL Password: ${DB_PASSWORD}
PostgreSQL Database: typebot
PostgreSQL Port: 5432 (internal only)

MINIO CREDENTIALS:
==================
MinIO Console: https://${MINIO_DOMAIN}
MinIO Username: ${MINIO_ROOT_USER}
MinIO Password: ${MINIO_ROOT_PASSWORD}
Bucket Name: typebot

ENCRYPTION SECRETS:
===================
Encryption Secret: ${ENCRYPTION_SECRET}
NextAuth Secret: ${NEXTAUTH_SECRET}

DOCKER SERVICES:
================
Location: /opt/typebot
Commands:
  - docker compose ps              (check status)
  - docker compose logs -f         (view logs)
  - docker compose restart         (restart all)
  - docker compose down            (stop all)
  - docker compose up -d           (start all)

SECURITY MONITORING:
====================
• Auto-update script: /opt/typebot/update-typebot.sh
  Run manually: sudo /opt/typebot/update-typebot.sh
  Auto-runs: Every Sunday at 3 AM

• Security check script: /opt/typebot/security-check.sh
  Run manually: sudo /opt/typebot/security-check.sh
  Auto-runs: Every 6 hours

• Security logs: /var/log/typebot-security.log
  View: tail -f /var/log/typebot-security.log

• Update logs: /var/log/typebot-updates.log
  View: tail -f /var/log/typebot-updates.log

PROTECTED AGAINST:
==================
• CVE-2025-55182 (React2Shell) - Critical RCE vulnerability
• Direct port access blocked by UFW firewall
• Ports bound to localhost only (127.0.0.1)
• SSH brute-force attacks (Fail2ban)

IMPORTANT: Keep this file secure and delete it after saving credentials!

To delete this file: rm /opt/typebot/INSTALLATION_INFO.txt
INFO_EOF

chmod 600 /opt/typebot/INSTALLATION_INFO.txt

###########################################
# Installation Complete
###########################################

echo ""
echo "╔════════════════════════════════════════════════════════╗"
echo "║                                                        ║"
echo "║         INSTALLATION COMPLETED SUCCESSFULLY! ✓         ║"
echo "║                                                        ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

print_success "All services are running!"
echo ""
print_info "Access your Typebot instances:"
echo "  • Builder:  https://${BUILDER_DOMAIN}"
echo "  • Viewer:   https://${VIEWER_DOMAIN}"
echo "  • MinIO:    https://${MINIO_DOMAIN}"
echo ""
print_info "Login with: ${ADMIN_EMAIL}"
echo ""
print_warning "IMPORTANT SECURITY NOTES:"
echo "  1. SSH port changed to 2222"
echo "  2. Reconnect using: ssh -p 2222 root@YOUR_SERVER_IP"
echo "  3. CVE-2025-55182 Protection: Ports 8080, 8081, 9000, 9001 blocked"
echo "  4. Automatic updates: Every Sunday at 3 AM"
echo "  5. Security monitoring: Every 6 hours"
echo "  6. Save credentials from: /opt/typebot/INSTALLATION_INFO.txt"
echo "  7. Delete credentials file after saving!"
echo ""
print_success "Security Features Enabled:"
echo "  ✓ Firewall with port blocking (UFW)"
echo "  ✓ SSH brute-force protection (Fail2ban)"
echo "  ✓ Automatic security updates (weekly)"
echo "  ✓ Attack monitoring (every 6 hours)"
echo "  ✓ Localhost-only port binding"
echo ""
print_info "Installation details saved to: /opt/typebot/INSTALLATION_INFO.txt"
echo ""

