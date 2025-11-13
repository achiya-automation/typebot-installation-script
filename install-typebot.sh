#!/bin/bash

###########################################
# Typebot Complete Installation Script
# For Fresh Ubuntu Server (22.04+)
# Interactive with Optional Components
###########################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Functions
print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; exit 1; }
print_step() { echo -e "${PURPLE}━━━ $1 ━━━${NC}"; }

read_input() {
    local prompt="$1"
    local var_name="$2"
    local default="$3"
    if [[ -n "$default" ]]; then
        echo -ne "${CYAN}${prompt} [${default}]: ${NC}"
    else
        echo -ne "${CYAN}${prompt}: ${NC}"
    fi
    read input
    if [[ -z "$input" && -n "$default" ]]; then
        input="$default"
    fi
    eval "$var_name='$input'"
}

read_secure() {
    local prompt="$1"
    local var_name="$2"
    echo -ne "${CYAN}${prompt} (hidden): ${NC}"
    read -s input
    echo ""
    eval "$var_name='$input'"
}

read_yes_no() {
    local prompt="$1"
    local var_name="$2"
    local default="$3"
    while true; do
        if [[ "$default" == "yes" ]]; then
            echo -ne "${CYAN}${prompt} (yes/no) [yes]: ${NC}"
        else
            echo -ne "${CYAN}${prompt} (yes/no) [no]: ${NC}"
        fi
        read answer
        answer=${answer:-$default}
        case "$answer" in
            yes|y|YES|Y) eval "$var_name='yes'"; break ;;
            no|n|NO|N) eval "$var_name='no'"; break ;;
            *) echo "Please answer yes or no." ;;
        esac
    done
}

read_multiline() {
    local prompt="$1"
    local var_name="$2"
    echo -e "${CYAN}${prompt}${NC}"
    echo -e "${YELLOW}(Paste content, then press Ctrl+D on a new line)${NC}"
    local content=$(cat)
    eval "$var_name='$content'"
}

validate_domain() {
    local domain="$1"
    # Support subdomains: subdomain.domain.tld or domain.tld
    if [[ ! "$domain" =~ ^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$ ]]; then
        print_error "Invalid domain format: $domain"
    fi
}

validate_email() {
    local email="$1"
    if [[ ! "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        print_error "Invalid email format: $email"
    fi
}

generate_password() {
    openssl rand -base64 24 | tr -d "=+/" | cut -c1-24
}

# Banner
clear
cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║        ████████╗██╗   ██╗██████╗ ███████╗██████╗  ██████╗  ║
║        ╚══██╔══╝╚██╗ ██╔╝██╔══██╗██╔════╝██╔══██╗██╔═══██╗ ║
║           ██║    ╚████╔╝ ██████╔╝█████╗  ██████╔╝██║   ██║ ║
║           ██║     ╚██╔╝  ██╔═══╝ ██╔══╝  ██╔══██╗██║   ██║ ║
║           ██║      ██║   ██║     ███████╗██████╔╝╚██████╔╝ ║
║           ╚═╝      ╚═╝   ╚═╝     ╚══════╝╚═════╝  ╚═════╝  ║
║                                                              ║
║           Complete Automated Installation Script            ║
║                   For Fresh Ubuntu Server                   ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo ""

print_info "This script will install and configure:"
echo "  • SSH Security (Port 2222, UFW Firewall, Fail2ban)"
echo "  • Docker & Docker Compose (latest stable)"
echo "  • PostgreSQL 16 Database"
echo "  • Redis Cache"
echo "  • MinIO S3 Storage"
echo "  • Typebot Builder & Viewer"
echo "  • Nginx Reverse Proxy with SSL"
echo "  • Optional: Google Integrations"
echo ""

read_yes_no "Do you want to continue with the installation?" CONFIRM "yes"
if [[ "$CONFIRM" != "yes" ]]; then
    print_error "Installation cancelled by user"
fi

###########################################
# Configuration Collection
###########################################

echo ""
print_step "STEP 1: Domain Configuration"
echo ""

print_info "You need 2 required domains pointing to this server's IP address:"
echo "  1. Builder domain (main Typebot interface) - REQUIRED"
echo "  2. Viewer domain (for published bots) - REQUIRED"
echo "  3. MinIO domain (for file storage console) - OPTIONAL"
echo ""
print_warning "MinIO Console domain is OPTIONAL - only if you want web access to manage files"
echo ""

read_input "Enter Builder domain (e.g., typebot.example.com)" BUILDER_DOMAIN
validate_domain "$BUILDER_DOMAIN"

read_input "Enter Viewer domain (e.g., typebot-bot.example.com)" VIEWER_DOMAIN
validate_domain "$VIEWER_DOMAIN"

echo ""
read_yes_no "Do you want to set up MinIO Console web access?" SETUP_MINIO_CONSOLE "no"

if [[ "$SETUP_MINIO_CONSOLE" == "yes" ]]; then
    read_input "Enter MinIO domain (e.g., minio.example.com)" MINIO_DOMAIN
    validate_domain "$MINIO_DOMAIN"
    print_success "MinIO Console will be configured"
else
    MINIO_DOMAIN=""
    print_info "MinIO Console web access skipped (files will still work in Typebot)"
fi

print_success "Domains configured"

###########################################
# Admin Configuration
###########################################

echo ""
print_step "STEP 2: Admin Configuration"
echo ""

read_input "Enter admin email address" ADMIN_EMAIL
validate_email "$ADMIN_EMAIL"

read_yes_no "Disable user signup? (only admin can create accounts)" DISABLE_SIGNUP "yes"

print_success "Admin configuration saved"

###########################################
# SMTP Configuration
###########################################

echo ""
print_step "STEP 3: SMTP Configuration"
echo ""

print_info "SMTP is required for Email Magic Link authentication"
echo "For Gmail: Use App Password (not regular password)"
echo ""

read_input "SMTP Host" SMTP_HOST "smtp.gmail.com"
read_input "SMTP Port" SMTP_PORT "587"
read_input "SMTP Username (email)" SMTP_USERNAME
validate_email "$SMTP_USERNAME"
read_secure "SMTP Password" SMTP_PASSWORD
read_input "SMTP From Email" SMTP_FROM "$SMTP_USERNAME"
validate_email "$SMTP_FROM"

print_success "SMTP configured"

###########################################
# SSL Certificates
###########################################

echo ""
print_step "STEP 4: SSL Certificates"
echo ""

print_info "You need Cloudflare Origin SSL Certificate"
print_info "Get it from: Cloudflare Dashboard → SSL/TLS → Origin Server → Create Certificate"
echo ""

read_multiline "Paste your Cloudflare Origin Certificate (PEM format):" SSL_CERT

echo ""
read_multiline "Paste your Cloudflare Private Key (PEM format):" SSL_KEY

print_success "SSL certificates received"

###########################################
# Optional Components
###########################################

echo ""
print_step "STEP 5: Optional Google Integrations"
echo ""

read_yes_no "Do you want to enable Google integrations?" ENABLE_GOOGLE "no"

if [[ "$ENABLE_GOOGLE" == "yes" ]]; then
    echo ""
    print_info "You'll need credentials from Google Cloud Console:"
    print_info "https://console.cloud.google.com/apis/credentials"
    echo ""

    read_yes_no "Enable Google Sheets integration?" ENABLE_GOOGLE_SHEETS "yes"
    read_yes_no "Enable Gmail integration?" ENABLE_GMAIL "yes"
    read_yes_no "Enable Google Fonts?" ENABLE_GOOGLE_FONTS "yes"
    read_yes_no "Enable Google OAuth (Sign in with Google)?" ENABLE_GOOGLE_OAUTH "no"

    if [[ "$ENABLE_GOOGLE_SHEETS" == "yes" || "$ENABLE_GMAIL" == "yes" || "$ENABLE_GOOGLE_OAUTH" == "yes" ]]; then
        echo ""
        read_input "Google OAuth Client ID" GOOGLE_CLIENT_ID
        read_secure "Google OAuth Client Secret" GOOGLE_CLIENT_SECRET
    fi

    if [[ "$ENABLE_GOOGLE_SHEETS" == "yes" || "$ENABLE_GOOGLE_FONTS" == "yes" ]]; then
        echo ""
        read_input "Google API Key" GOOGLE_API_KEY
    fi

    print_success "Google integrations configured"
fi

###########################################
# Generate Secure Passwords
###########################################

echo ""
print_step "Generating Secure Credentials"
echo ""

DB_PASSWORD=$(generate_password)
MINIO_ROOT_USER="typebot_minio_admin"
MINIO_ROOT_PASSWORD=$(generate_password)
ENCRYPTION_SECRET=$(openssl rand -hex 16)
NEXTAUTH_SECRET=$(openssl rand -hex 16)

print_success "Secure credentials generated"

###########################################
# Summary
###########################################

echo ""
print_step "Installation Summary"
echo ""
echo "Builder Domain:    $BUILDER_DOMAIN"
echo "Viewer Domain:     $VIEWER_DOMAIN"
echo "MinIO Domain:      $MINIO_DOMAIN"
echo "Admin Email:       $ADMIN_EMAIL"
echo "Disable Signup:    $DISABLE_SIGNUP"
echo "Google Integrations: $ENABLE_GOOGLE"
echo ""

read_yes_no "Start installation now?" START_INSTALL "yes"
if [[ "$START_INSTALL" != "yes" ]]; then
    print_error "Installation cancelled"
fi

###########################################
# System Update
###########################################

echo ""
print_step "INSTALLING: System Update"
print_info "Updating package lists and upgrading system..."

apt update > /dev/null 2>&1
apt upgrade -y > /dev/null 2>&1
apt install -y curl wget git vim htop net-tools unattended-upgrades openssl > /dev/null 2>&1

print_success "System updated"

###########################################
# SSH Security
###########################################

echo ""
print_step "INSTALLING: SSH Security"

# UFW Firewall
print_info "Configuring UFW firewall..."
apt install -y ufw > /dev/null 2>&1
ufw --force reset > /dev/null 2>&1
ufw default deny incoming > /dev/null 2>&1
ufw default allow outgoing > /dev/null 2>&1
ufw allow 22/tcp comment 'SSH temporary' > /dev/null 2>&1
ufw allow 2222/tcp comment 'SSH new port' > /dev/null 2>&1
ufw allow 80/tcp comment 'HTTP' > /dev/null 2>&1
ufw allow 443/tcp comment 'HTTPS' > /dev/null 2>&1
ufw --force enable > /dev/null 2>&1
print_success "UFW firewall configured"

# SSH Hardening
print_info "Hardening SSH configuration..."
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup

# Change port
if grep -q '^Port ' /etc/ssh/sshd_config; then
    sed -i 's/^Port .*/Port 2222/' /etc/ssh/sshd_config
elif grep -q '^#Port 22' /etc/ssh/sshd_config; then
    sed -i 's/^#Port 22/Port 2222/' /etc/ssh/sshd_config
else
    echo "Port 2222" >> /etc/ssh/sshd_config
fi

# Additional SSH hardening
cat >> /etc/ssh/sshd_config << 'SSH_HARDENING'

# Security hardening
PermitRootLogin prohibit-password
PubkeyAuthentication yes
PasswordAuthentication yes
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
PrintMotd no
AcceptEnv LANG LC_*
MaxAuthTries 3
MaxSessions 10
ClientAliveInterval 300
ClientAliveCountMax 2
SSH_HARDENING

systemctl restart sshd > /dev/null 2>&1
sleep 2
ufw delete allow 22/tcp > /dev/null 2>&1 || true
print_success "SSH hardened and port changed to 2222"

# Fail2ban
print_info "Installing Fail2ban..."
apt install -y fail2ban > /dev/null 2>&1
cat > /etc/fail2ban/jail.local << 'F2B_EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = 2222
filter = sshd
logpath = /var/log/auth.log
F2B_EOF
systemctl restart fail2ban > /dev/null 2>&1
systemctl enable fail2ban > /dev/null 2>&1
print_success "Fail2ban configured"

###########################################
# Docker Installation
###########################################

echo ""
print_step "INSTALLING: Docker"

print_info "Installing Docker Engine..."
apt remove -y docker docker-engine docker.io containerd runc > /dev/null 2>&1 || true
curl -fsSL https://get.docker.com -o /tmp/get-docker.sh 2>/dev/null
sh /tmp/get-docker.sh > /dev/null 2>&1
rm /tmp/get-docker.sh
systemctl start docker > /dev/null 2>&1
systemctl enable docker > /dev/null 2>&1

print_success "Docker installed successfully"

###########################################
# Typebot Setup
###########################################

echo ""
print_step "INSTALLING: Typebot"

print_info "Creating Typebot directory structure..."
mkdir -p /opt/typebot
cd /opt/typebot

# Create docker-compose.yml
print_info "Creating Docker Compose configuration..."
cat > docker-compose.yml << 'DC_EOF'
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
      POSTGRES_DB: typebot
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5
    networks:
      - typebot-network
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
        reservations:
          memory: 256M
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    security_opt:
      - no-new-privileges:true

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
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          memory: 128M
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    security_opt:
      - no-new-privileges:true

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
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
        reservations:
          memory: 256M
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    security_opt:
      - no-new-privileges:true

  typebot-builder:
    <<: *typebot-common
    image: baptistearno/typebot-builder:latest
    ports:
      - "8080:3000"
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
        reservations:
          memory: 512M
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    security_opt:
      - no-new-privileges:true

  typebot-viewer:
    <<: *typebot-common
    image: baptistearno/typebot-viewer:latest
    ports:
      - "8081:3000"
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
        reservations:
          memory: 512M
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    security_opt:
      - no-new-privileges:true

networks:
  typebot-network:
    driver: bridge

volumes:
  db-data:
  redis-data:
  minio-data:
DC_EOF

# Convert yes/no to true/false for Typebot compatibility
[[ "$DISABLE_SIGNUP" == "yes" ]] && DISABLE_SIGNUP="true" || DISABLE_SIGNUP="false"

# Create .env file
print_info "Creating environment configuration..."
cat > .env << ENV_EOF
# Core Configuration
ENCRYPTION_SECRET=${ENCRYPTION_SECRET}
DATABASE_URL=postgresql://postgres:${DB_PASSWORD}@typebot-db:5432/typebot
REDIS_URL=redis://typebot-redis:6379
NODE_OPTIONS=--no-node-snapshot

# URLs
NEXTAUTH_URL=https://${BUILDER_DOMAIN}
NEXT_PUBLIC_VIEWER_URL=https://${VIEWER_DOMAIN}
NEXTAUTH_SECRET=${NEXTAUTH_SECRET}

# Admin
ADMIN_EMAIL=${ADMIN_EMAIL}
DISABLE_SIGNUP=${DISABLE_SIGNUP}

# SMTP
SMTP_HOST=${SMTP_HOST}
SMTP_PORT=${SMTP_PORT}
SMTP_USERNAME=${SMTP_USERNAME}
SMTP_PASSWORD=${SMTP_PASSWORD}
SMTP_SECURE=false
NEXT_PUBLIC_SMTP_FROM=${SMTP_FROM}
EMAIL_FROM=${SMTP_FROM}
SMTP_FROM=${SMTP_FROM}

# MinIO S3
S3_ACCESS_KEY=${MINIO_ROOT_USER}
S3_SECRET_KEY=${MINIO_ROOT_PASSWORD}
S3_BUCKET=typebot
S3_ENDPOINT=typebot-minio
S3_PORT=9000
S3_SSL=false
S3_REGION=us-east-1

# Docker Compose Variables (required by docker-compose.yml)
DB_PASSWORD=${DB_PASSWORD}
MINIO_ROOT_USER=${MINIO_ROOT_USER}
MINIO_ROOT_PASSWORD=${MINIO_ROOT_PASSWORD}
ENV_EOF

# Add Google integrations if enabled
if [[ "$ENABLE_GOOGLE" == "yes" ]]; then
    if [[ "$ENABLE_GOOGLE_SHEETS" == "yes" ]]; then
        cat >> .env << GS_EOF

# Google Sheets
GOOGLE_SHEETS_CLIENT_ID=${GOOGLE_CLIENT_ID}
GOOGLE_SHEETS_CLIENT_SECRET=${GOOGLE_CLIENT_SECRET}
NEXT_PUBLIC_GOOGLE_SHEETS_API_KEY=${GOOGLE_API_KEY}
GS_EOF
    fi

    if [[ "$ENABLE_GMAIL" == "yes" ]]; then
        cat >> .env << GM_EOF

# Gmail Integration
GMAIL_CLIENT_ID=${GOOGLE_CLIENT_ID}
GMAIL_CLIENT_SECRET=${GOOGLE_CLIENT_SECRET}
GM_EOF
    fi

    if [[ "$ENABLE_GOOGLE_FONTS" == "yes" ]]; then
        cat >> .env << GF_EOF

# Google Fonts
NEXT_PUBLIC_GOOGLE_FONTS_API_KEY=${GOOGLE_API_KEY}
GF_EOF
    fi

    if [[ "$ENABLE_GOOGLE_OAUTH" == "yes" ]]; then
        cat >> .env << GO_EOF

# Google OAuth
GOOGLE_AUTH_CLIENT_ID=${GOOGLE_CLIENT_ID}
GOOGLE_AUTH_CLIENT_SECRET=${GOOGLE_CLIENT_SECRET}
GO_EOF
    fi
fi

chmod 600 .env

print_success "Typebot configured"

###########################################
# SSL Certificates
###########################################

echo ""
print_step "INSTALLING: SSL Certificates"

print_info "Installing SSL certificates..."
mkdir -p /etc/ssl/cloudflare
echo "$SSL_CERT" > /etc/ssl/cloudflare/cert.pem
echo "$SSL_KEY" > /etc/ssl/cloudflare/key.pem
chmod 600 /etc/ssl/cloudflare/*.pem

print_success "SSL certificates installed"

###########################################
# Nginx
###########################################

echo ""
print_step "INSTALLING: Nginx Reverse Proxy"

print_info "Installing Nginx..."
apt install -y nginx > /dev/null 2>&1

print_info "Configuring Nginx for Typebot..."
cat > /etc/nginx/sites-available/typebot << 'NGINX_EOF'
# Builder - HTTP to HTTPS redirect
server {
    listen 80;
    server_name BUILDER_DOMAIN_PLACEHOLDER;
    return 301 https://$server_name$request_uri;
}

# Builder - HTTPS
server {
    listen 443 ssl http2;
    server_name BUILDER_DOMAIN_PLACEHOLDER;

    ssl_certificate /etc/ssl/cloudflare/cert.pem;
    ssl_certificate_key /etc/ssl/cloudflare/key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384';
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_stapling on;
    ssl_stapling_verify on;

    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Frame-Options SAMEORIGIN always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https:; style-src 'self' 'unsafe-inline' https:; connect-src 'self' https: wss:; frame-src 'self' https:; img-src 'self' data: blob: https:; font-src 'self' https: data:; media-src 'self' https:; worker-src 'self' blob:; object-src 'none'" always;

    client_max_body_size 50M;

    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
}

# Viewer - HTTP to HTTPS redirect
server {
    listen 80;
    server_name VIEWER_DOMAIN_PLACEHOLDER;
    return 301 https://$server_name$request_uri;
}

# Viewer - HTTPS
server {
    listen 443 ssl http2;
    server_name VIEWER_DOMAIN_PLACEHOLDER;

    ssl_certificate /etc/ssl/cloudflare/cert.pem;
    ssl_certificate_key /etc/ssl/cloudflare/key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384';
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_stapling on;
    ssl_stapling_verify on;

    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Frame-Options SAMEORIGIN always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;

    client_max_body_size 50M;

    location / {
        proxy_pass http://localhost:8081;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 300s;
        proxy_connect_timeout 75s;
    }
}
NGINX_EOF

sed -i "s/BUILDER_DOMAIN_PLACEHOLDER/${BUILDER_DOMAIN}/g" /etc/nginx/sites-available/typebot
sed -i "s/VIEWER_DOMAIN_PLACEHOLDER/${VIEWER_DOMAIN}/g" /etc/nginx/sites-available/typebot

# MinIO Nginx config (optional)
if [[ "$SETUP_MINIO_CONSOLE" == "yes" ]]; then
    print_info "Configuring Nginx for MinIO Console..."
    cat > /etc/nginx/sites-available/minio << 'NGINX_MINIO_EOF'
# MinIO - HTTP to HTTPS redirect
server {
    listen 80;
    server_name MINIO_DOMAIN_PLACEHOLDER;
    return 301 https://$server_name$request_uri;
}

# MinIO - HTTPS
server {
    listen 443 ssl http2;
    server_name MINIO_DOMAIN_PLACEHOLDER;

    ssl_certificate /etc/ssl/cloudflare/cert.pem;
    ssl_certificate_key /etc/ssl/cloudflare/key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384';
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_stapling on;
    ssl_stapling_verify on;

    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Frame-Options SAMEORIGIN always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;

    client_max_body_size 500M;

    location / {
        proxy_pass http://localhost:9001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINX_MINIO_EOF

    sed -i "s/MINIO_DOMAIN_PLACEHOLDER/${MINIO_DOMAIN}/g" /etc/nginx/sites-available/minio
    ln -sf /etc/nginx/sites-available/minio /etc/nginx/sites-enabled/
    print_success "MinIO Console Nginx configured"
else
    print_info "Skipping MinIO Console Nginx configuration"
fi

# Enable sites
ln -sf /etc/nginx/sites-available/typebot /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test and restart Nginx
nginx -t > /dev/null 2>&1
systemctl restart nginx > /dev/null 2>&1

print_success "Nginx configured"

###########################################
# Start Docker Services
###########################################

echo ""
print_step "STARTING: Docker Services"

print_info "Pulling Docker images (this may take a few minutes)..."
cd /opt/typebot
docker compose pull > /dev/null 2>&1

print_info "Starting services..."
docker compose up -d

print_info "Waiting for services to be healthy (60 seconds)..."
sleep 60

print_success "All services started"

###########################################
# MinIO Bucket Setup
###########################################

echo ""
print_step "CONFIGURING: MinIO Storage"

print_info "Creating MinIO bucket..."
docker run --rm --network typebot_typebot-network \
  -e MC_HOST_minio="http://${MINIO_ROOT_USER}:${MINIO_ROOT_PASSWORD}@typebot-minio:9000" \
  minio/mc:latest mb minio/typebot > /dev/null 2>&1 || true

docker run --rm --network typebot_typebot-network \
  -e MC_HOST_minio="http://${MINIO_ROOT_USER}:${MINIO_ROOT_PASSWORD}@typebot-minio:9000" \
  minio/mc:latest anonymous set download minio/typebot > /dev/null 2>&1 || true

print_success "MinIO bucket configured"

###########################################
# Save Installation Info
###########################################

echo ""
print_step "SAVING: Installation Information"

cat > /opt/typebot/INSTALLATION_INFO.txt << INFO_EOF
╔══════════════════════════════════════════════════════════════╗
║              TYPEBOT INSTALLATION COMPLETED                  ║
╚══════════════════════════════════════════════════════════════╝

Installation Date: $(date)
Server IP: $(curl -s ifconfig.me)

╔══════════════════════════════════════════════════════════════╗
║ IMPORTANT SECURITY NOTES                                     ║
╚══════════════════════════════════════════════════════════════╝

⚠ SSH PORT HAS BEEN CHANGED TO 2222 ⚠

To reconnect to this server, use:
  ssh -p 2222 root@$(curl -s ifconfig.me)

Firewall (UFW) is active and configured.
Fail2ban is protecting SSH from brute-force attacks.

╔══════════════════════════════════════════════════════════════╗
║ ACCESS URLS                                                  ║
╚══════════════════════════════════════════════════════════════╝

Builder (Admin Interface):
  https://${BUILDER_DOMAIN}

Viewer (Published Bots):
  https://${VIEWER_DOMAIN}

MinIO Console (File Storage):
  https://${MINIO_DOMAIN}

╔══════════════════════════════════════════════════════════════╗
║ ADMIN CREDENTIALS                                            ║
╚══════════════════════════════════════════════════════════════╝

Admin Email: ${ADMIN_EMAIL}
Login Method: Email Magic Link
  (Click the link sent to your email to sign in)

Signup Disabled: ${DISABLE_SIGNUP}

╔══════════════════════════════════════════════════════════════╗
║ DATABASE CREDENTIALS                                         ║
╚══════════════════════════════════════════════════════════════╝

PostgreSQL:
  Host: typebot-db (internal)
  Port: 5432
  Database: typebot
  User: postgres
  Password: ${DB_PASSWORD}

Redis:
  Host: typebot-redis (internal)
  Port: 6379

╔══════════════════════════════════════════════════════════════╗
║ MINIO CREDENTIALS                                            ║
╚══════════════════════════════════════════════════════════════╝

MinIO Console: https://${MINIO_DOMAIN}
Username: ${MINIO_ROOT_USER}
Password: ${MINIO_ROOT_PASSWORD}
Bucket: typebot

╔══════════════════════════════════════════════════════════════╗
║ ENCRYPTION SECRETS                                           ║
╚══════════════════════════════════════════════════════════════╝

Encryption Secret: ${ENCRYPTION_SECRET}
NextAuth Secret: ${NEXTAUTH_SECRET}

⚠ KEEP THESE SECRETS SAFE - REQUIRED FOR DATA DECRYPTION ⚠

╔══════════════════════════════════════════════════════════════╗
║ GOOGLE INTEGRATIONS                                          ║
╚══════════════════════════════════════════════════════════════╝

Google Integrations Enabled: ${ENABLE_GOOGLE}
INFO_EOF

if [[ "$ENABLE_GOOGLE" == "yes" ]]; then
    cat >> /opt/typebot/INSTALLATION_INFO.txt << GOOGLE_INFO
Google Sheets: ${ENABLE_GOOGLE_SHEETS}
Gmail: ${ENABLE_GMAIL}
Google Fonts: ${ENABLE_GOOGLE_FONTS}
Google OAuth: ${ENABLE_GOOGLE_OAUTH}
GOOGLE_INFO
fi

cat >> /opt/typebot/INSTALLATION_INFO.txt << INFO_EOF2

╔══════════════════════════════════════════════════════════════╗
║ DOCKER MANAGEMENT                                            ║
╚══════════════════════════════════════════════════════════════╝

Location: /opt/typebot

Useful Commands:
  cd /opt/typebot
  docker compose ps              # Check status
  docker compose logs -f         # View logs
  docker compose restart         # Restart all services
  docker compose down            # Stop all services
  docker compose up -d           # Start all services
  docker compose pull && docker compose up -d   # Update to latest

╔══════════════════════════════════════════════════════════════╗
║ BACKUP RECOMMENDATIONS                                       ║
╚══════════════════════════════════════════════════════════════╝

Important files to backup:
  • /opt/typebot/.env              (Configuration)
  • /opt/typebot/docker-compose.yml (Docker setup)
  • /etc/ssl/cloudflare/*          (SSL certificates)
  • Docker volumes:
    - typebot_db-data              (Database)
    - typebot_minio-data           (Files)

Backup command:
  docker compose down
  tar -czf typebot-backup-\$(date +%Y%m%d).tar.gz /opt/typebot /etc/ssl/cloudflare
  docker compose up -d

╔══════════════════════════════════════════════════════════════╗
║ TROUBLESHOOTING                                              ║
╚══════════════════════════════════════════════════════════════╝

If services are not accessible:
  1. Check if services are running:
       docker compose ps

  2. Check logs for errors:
       docker compose logs typebot-builder
       docker compose logs typebot-viewer

  3. Restart services:
       docker compose restart

  4. Check Nginx:
       nginx -t
       systemctl status nginx

  5. Check firewall:
       ufw status

╔══════════════════════════════════════════════════════════════╗
║ NEXT STEPS                                                   ║
╚══════════════════════════════════════════════════════════════╝

1. ⚠ Reconnect to server using port 2222:
   ssh -p 2222 root@$(curl -s ifconfig.me)

2. Visit https://${BUILDER_DOMAIN}

3. Sign in with: ${ADMIN_EMAIL}

4. Check your email for the magic link

5. Start building your first bot!

6. ⚠ IMPORTANT: Save this file securely and then delete it:
   rm /opt/typebot/INSTALLATION_INFO.txt

═══════════════════════════════════════════════════════════════

Installation completed successfully! 🎉
For support, visit: https://docs.typebot.io

═══════════════════════════════════════════════════════════════
INFO_EOF2

chmod 600 /opt/typebot/INSTALLATION_INFO.txt

print_success "Installation information saved"

###########################################
# Final Summary
###########################################

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                                                              ║"
echo "║              INSTALLATION COMPLETED SUCCESSFULLY! 🎉         ║"
echo "║                                                              ║"
echo "╔══════════════════════════════════════════════════════════════╗"
echo ""

print_success "All services are running and healthy!"
echo ""

print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_info "ACCESS YOUR TYPEBOT:"
print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  🌐 Builder:  https://${BUILDER_DOMAIN}"
echo "  🌐 Viewer:   https://${VIEWER_DOMAIN}"
if [[ "$SETUP_MINIO_CONSOLE" == "yes" ]]; then
    echo "  🌐 MinIO:    https://${MINIO_DOMAIN}"
fi
echo ""
print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_info "LOGIN CREDENTIALS:"
print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  📧 Admin Email: ${ADMIN_EMAIL}"
echo "  🔐 Method: Email Magic Link (check your inbox)"
echo ""

print_warning "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_warning "⚠  IMPORTANT SECURITY NOTICE ⚠"
print_warning "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
print_error "SSH PORT HAS BEEN CHANGED TO 2222"
echo ""
echo "  Your current SSH session on port 22 will remain active."
echo "  To reconnect later, use:"
echo ""
echo "  ${GREEN}ssh -p 2222 root@$(curl -s ifconfig.me)${NC}"
echo ""

print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_info "INSTALLATION DETAILS:"
print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  📄 Complete installation info saved to:"
echo "     /opt/typebot/INSTALLATION_INFO.txt"
echo ""
echo "  To view: cat /opt/typebot/INSTALLATION_INFO.txt"
echo ""
echo "  ⚠  SAVE THIS FILE SECURELY, THEN DELETE IT:"
echo "     rm /opt/typebot/INSTALLATION_INFO.txt"
echo ""

print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_info "NEXT STEPS:"
print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  1. Visit https://${BUILDER_DOMAIN}"
echo "  2. Enter your email: ${ADMIN_EMAIL}"
echo "  3. Check your email for the magic link"
echo "  4. Click the link to sign in"
echo "  5. Start creating your first bot!"
echo ""

print_success "Installation script completed! Enjoy Typebot! 🚀"
echo ""
