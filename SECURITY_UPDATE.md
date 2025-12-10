# Typebot Installation Script - Security Update

## Critical Security Fix: CVE-2025-55182 Protection

This update fixes a critical vulnerability in the Typebot installation script that left servers exposed to **CVE-2025-55182 (React2Shell)**, a CVSS 10.0 remote code execution vulnerability affecting Next.js and React Server Components.

---

## What Was Fixed

### 1. Port Exposure Vulnerability ❌ → ✅

**Before (Vulnerable):**
```yaml
ports:
  - "8080:3000"   # Exposed to internet
  - "8081:3000"   # Exposed to internet
  - "9000:9000"   # Exposed to internet
  - "9001:9001"   # Exposed to internet
```

**After (Secure):**
```yaml
ports:
  - "127.0.0.1:8080:3000"   # Localhost only
  - "127.0.0.1:8081:3000"   # Localhost only
  - "127.0.0.1:9000:9000"   # Localhost only
  - "127.0.0.1:9001:9001"   # Localhost only
```

### 2. Firewall Protection Added

The script now automatically blocks direct access to application ports:
```bash
ufw deny 8080  # Block Typebot Builder
ufw deny 8081  # Block Typebot Viewer
ufw deny 9000  # Block MinIO API
ufw deny 9001  # Block MinIO Console
```

### 3. Automatic Security Updates

New feature: Weekly automatic updates every Sunday at 3 AM
- Pulls latest Docker images with security patches
- Creates automatic backups before updates
- Logs all update activities

Script: `/opt/typebot/update-typebot.sh`

### 4. Security Monitoring

New feature: Attack detection runs every 6 hours
- Monitors for CVE-2025-55182 exploitation attempts
- Detects suspicious processes (miners, cryptojackers)
- Tracks unusual network connections
- Logs Fail2ban activity

Script: `/opt/typebot/security-check.sh`

---

## How to Upgrade Existing Installations

If you installed Typebot using the old script, follow these steps:

### Step 1: Update Docker Configuration

```bash
ssh -p 2222 root@YOUR_SERVER_IP

cd /opt/typebot

# Backup current configuration
cp docker-compose.yml docker-compose.yml.backup

# Update port bindings to localhost only
sed -i 's/"8080:3000"/"127.0.0.1:8080:3000"/g' docker-compose.yml
sed -i 's/"8081:3000"/"127.0.0.1:8081:3000"/g' docker-compose.yml
sed -i 's/"9000:9000"/"127.0.0.1:9000:9000"/g' docker-compose.yml
sed -i 's/"9001:9001"/"127.0.0.1:9001:9001"/g' docker-compose.yml

# Verify changes
grep -A1 'ports:' docker-compose.yml
```

### Step 2: Block Ports with Firewall

```bash
# Block direct access to application ports
ufw deny 8080 comment 'Block Typebot Builder - use Nginx only'
ufw deny 8081 comment 'Block Typebot Viewer - use Nginx only'
ufw deny 9000 comment 'Block MinIO API - use Nginx only'
ufw deny 9001 comment 'Block MinIO Console - use Nginx only'

# Verify firewall rules
ufw status numbered | grep -E '8080|8081|9000|9001'
```

### Step 3: Update Typebot to Patched Version

```bash
cd /opt/typebot

# Stop containers
docker compose down

# Pull latest images (includes Next.js 15.5.7+ with CVE fix)
docker compose pull

# Start with new configuration
docker compose up -d

# Verify services are running
docker compose ps
```

### Step 4: Install Security Scripts

```bash
# Download and install security scripts
cd /opt/typebot
wget https://raw.githubusercontent.com/achiya-automation/typebot-installation-script/main/update-typebot.sh
wget https://raw.githubusercontent.com/achiya-automation/typebot-installation-script/main/security-check.sh
chmod +x update-typebot.sh security-check.sh

# Setup cron jobs
cat > /etc/cron.d/typebot-security << 'EOF'
# Typebot Security: Weekly updates (Sunday 3 AM)
0 3 * * 0 root /opt/typebot/update-typebot.sh

# Typebot Security: Security checks (every 6 hours)
0 */6 * * * root /opt/typebot/security-check.sh
EOF

chmod 644 /etc/cron.d/typebot-security
```

### Step 5: Verify Security

```bash
# Test that ports are blocked from outside
curl -I http://YOUR_SERVER_IP:8081
# Should return: Connection refused

# Test that localhost still works
curl -I http://127.0.0.1:8081
# Should return: HTTP/1.1 200 OK (or similar)

# Check UFW status
ufw status | grep -E '8080|8081|9000|9001'

# Run security check
/opt/typebot/security-check.sh
tail /var/log/typebot-security.log
```

---

## What This Protects Against

### CVE-2025-55182 (React2Shell)
- **CVSS Score:** 10.0 (Critical)
- **Affected:** Next.js 15.x, 16.x with React Server Components
- **Attack Vector:** Remote code execution without authentication
- **Impact:** Complete server compromise

**Attack Pattern Detected:**
```
/bin/sh: busybox
/bin/sh: curl
/bin/sh: wget
chmod: x86
./x86
```

### Additional Threats
- **Cryptominers:** Detects xmrig, kdevtmpfsi, and similar processes
- **SSH Brute-Force:** Fail2ban blocks after 3 failed attempts
- **Direct Port Access:** Firewall blocks unauthorized access

---

## Security Monitoring

### View Security Logs
```bash
# Security check logs
tail -f /var/log/typebot-security.log

# Update logs
tail -f /var/log/typebot-updates.log

# Container logs
docker logs -f typebot-typebot-viewer-1
```

### Manual Security Check
```bash
/opt/typebot/security-check.sh
```

### Manual Update
```bash
/opt/typebot/update-typebot.sh
```

### Check for Attack Attempts
```bash
docker logs typebot-typebot-viewer-1 2>&1 | grep -E "busybox|x86|wget|curl"
```

---

## Prevention Architecture

```
Internet
   ↓
Cloudflare (SSL/DDoS Protection)
   ↓
UFW Firewall (Blocks 8080, 8081, 9000, 9001)
   ↓
Nginx (Port 443 only - Reverse Proxy)
   ↓
Localhost (127.0.0.1:8080, 127.0.0.1:8081)
   ↓
Docker Containers (Typebot, MinIO)
```

**Attack Path Blocked:**
```
Attacker → Port 8081 ❌ BLOCKED BY UFW
Attacker → exploit CVE-2025-55182 ❌ CAN'T REACH PORT
```

**Legitimate Path:**
```
User → Cloudflare → Nginx (443) ✓
      → Localhost (8081) ✓
      → Typebot Container ✓
```

---

## Verification Checklist

After upgrading, verify these security measures:

- [ ] Ports bound to localhost only (`grep 127.0.0.1 docker-compose.yml`)
- [ ] UFW blocks ports 8080, 8081, 9000, 9001 (`ufw status`)
- [ ] External port access fails (`curl http://SERVER_IP:8081`)
- [ ] Nginx access works (`curl https://yourdomain.com`)
- [ ] Next.js version is 15.5.7+ (`docker exec typebot-typebot-viewer-1 cat /app/node_modules/next/package.json`)
- [ ] Security scripts exist (`ls -l /opt/typebot/*.sh`)
- [ ] Cron jobs configured (`cat /etc/cron.d/typebot-security`)
- [ ] No suspicious processes (`ps aux | grep -E 'miner|crypto'`)
- [ ] Fail2ban active (`fail2ban-client status sshd`)

---

## FAQ

### Q: Will this break my existing installation?
**A:** No. The changes only affect how ports are exposed. Nginx will continue to work normally, and your users won't notice any difference.

### Q: How do I know if I was attacked?
**A:** Check the logs:
```bash
docker logs typebot-typebot-viewer-1 2>&1 | grep -c "busybox"
```
If you see a count > 0, your server was targeted but the attack likely failed.

### Q: Should I disable automatic updates?
**A:** No. Security updates are critical. However, you can adjust the schedule by editing `/etc/cron.d/typebot-security`.

### Q: Can I run updates manually?
**A:** Yes: `sudo /opt/typebot/update-typebot.sh`

### Q: What if services fail after an update?
**A:** The update script creates automatic backups. Restore with:
```bash
cd /opt/typebot
docker compose down
cp docker-compose.yml.backup-YYYYMMDD-HHMMSS docker-compose.yml
cp .env.backup-YYYYMMDD-HHMMSS .env
docker compose up -d
```

---

## Support

If you encounter issues:
1. Check logs: `/var/log/typebot-security.log`
2. Verify firewall: `ufw status`
3. Check containers: `docker compose ps`
4. Test access: `curl -I http://127.0.0.1:8081`

For questions, open an issue on GitHub.

---

## Credits

- CVE-2025-55182 Analysis: [Trend Micro](https://www.trendmicro.com/en_us/research/25/l/CVE-2025-55182-analysis-poc-itw.html)
- React Security Advisory: [React.dev](https://react.dev/blog/2025/12/03/critical-security-vulnerability-in-react-server-components)
- Next.js Security Advisory: [Next.js](https://nextjs.org/blog/CVE-2025-66478)

---

**Last Updated:** December 10, 2025
**Script Version:** 2.0 (Security Hardened)
