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
