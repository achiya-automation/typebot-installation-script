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
