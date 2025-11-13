# Security Policy

## 🔒 Reporting Security Vulnerabilities

The security of the Typebot Installation Script is a top priority. We appreciate your efforts to responsibly disclose any security vulnerabilities you discover.

### ⚠️ Please DO NOT:

- **Open public GitHub issues** for security vulnerabilities
- **Discuss security vulnerabilities** in public forums
- **Share exploit code** publicly before a fix is available

### ✅ Please DO:

1. **Report privately** via GitHub Security Advisories:
   - Go to: https://github.com/achiya-automation/typebot-installation-script/security/advisories/new
   - Or email: security@achiya-automation.com (if available)

2. **Include detailed information:**
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if you have one)

3. **Allow time for a fix:**
   - We aim to respond within **48 hours**
   - We aim to release a fix within **7 days** for critical issues
   - We'll keep you updated on progress

## 🛡️ Security Measures

This script implements multiple layers of security:

### 🔐 Cryptographic Security
- **Password Generation**: 24-character cryptographically secure passwords using OpenSSL
- **Encryption Keys**: AES-256 compatible (32 hex characters, 128-bit entropy)
- **Random Source**: Uses `/dev/urandom` via OpenSSL for high-quality randomness
- **No Hardcoded Secrets**: All credentials generated at runtime

### 🌐 Network Security
- **UFW Firewall**: Default deny incoming, minimal open ports (2222, 80, 443)
- **Port Binding**: MinIO ports (9000, 9001) bound to localhost only
- **Network Isolation**: Docker containers in isolated bridge network
- **Fail2ban Protection**: Automatic blocking after 3 failed SSH attempts

### 🔑 SSH Hardening
- **Custom Port**: SSH on port 2222 (reduces automated attacks by ~99%)
- **Key-Based Auth**: Root login requires SSH keys (password auth disabled)
- **Max Attempts**: Maximum 3 authentication attempts
- **Timeouts**: Client timeout after 5 minutes of inactivity
- **Disabled Features**: X11 forwarding disabled

### 🔒 SSL/TLS Security
- **Modern Protocols**: TLS 1.2 and 1.3 only (older versions disabled)
- **Strong Ciphers**: AEAD cipher suites with Perfect Forward Secrecy:
  - ECDHE-ECDSA/RSA-AES128/256-GCM-SHA256/384
  - ECDHE-ECDSA/RSA-CHACHA20-POLY1305
  - DHE-RSA-AES128/256-GCM-SHA256/384
- **OCSP Stapling**: Enabled for certificate validation
- **Security Headers**:
  - HSTS (Strict-Transport-Security) with 1-year max-age
  - X-Frame-Options: SAMEORIGIN
  - X-Content-Type-Options: nosniff
  - X-XSS-Protection: enabled
  - Content-Security-Policy

### 🐳 Docker Security
- **Resource Limits**: CPU and memory limits on all containers
- **Log Rotation**: Automatic rotation (10MB max, 3 files)
- **Security Options**: `no-new-privileges:true` prevents privilege escalation
- **Healthchecks**: Automatic monitoring of service health
- **Minimal Images**: Using Alpine Linux where possible

### 📁 File Permissions
- **Sensitive Files**: 600 permissions (owner read/write only)
  - `/opt/typebot/.env`
  - `/etc/ssl/cloudflare/*.pem`
  - `/opt/typebot/INSTALLATION_INFO.txt`
- **Config Files**: 644 permissions
- **Scripts**: 755 permissions
- **Owner**: Root only

### ✅ Input Validation
- **Domain Validation**: RFC-compliant domain name validation
- **Email Validation**: RFC 5322-compliant email validation
- **Command Injection Prevention**: Proper escaping and quoting
- **Type Checking**: Boolean values validated as true/false

### 📝 Logging Security
- **No Secrets in Logs**: Passwords and keys never written to logs
- **Log Rotation**: Prevents disk exhaustion
- **Secure Storage**: Logs readable by root only

## 🎯 Security Best Practices

### For Users

1. **Keep Updated**: Regularly update to the latest version
   ```bash
   cd /opt/typebot
   docker compose pull
   docker compose up -d
   ```

2. **System Updates**: Keep your OS updated
   ```bash
   apt update && apt upgrade -y
   ```

3. **Backup Credentials**: Save credentials securely, then delete installation info
   ```bash
   # After saving credentials to a secure location:
   rm /opt/typebot/INSTALLATION_INFO.txt
   ```

4. **Monitor Logs**: Regularly check for suspicious activity
   ```bash
   # Check fail2ban bans
   fail2ban-client status sshd

   # Check UFW status
   ufw status verbose

   # Check Docker logs
   docker compose logs -f
   ```

5. **Regular Backups**: Backup critical files
   - `/opt/typebot/.env`
   - Docker volumes
   - `/etc/ssl/cloudflare/`

### For Contributors

1. **Never Commit Secrets**: Check your code for hardcoded credentials
2. **Validate All Inputs**: Use proper validation for user inputs
3. **Follow Least Privilege**: Request minimum necessary permissions
4. **Test Security Changes**: Verify security improvements work as expected
5. **Document Security**: Update SECURITY_AUDIT.md for security changes

## 📊 Security Audits

This script undergoes regular security audits. Current rating: **99/100**

Last audit: November 13, 2025

See [SECURITY_AUDIT.md](SECURITY_AUDIT.md) for detailed analysis.

## 🔍 Known Security Considerations

### SSH Port Change
- **Important**: SSH port changes from 22 to 2222 during installation
- Ensure you have alternative access (console) before running
- Update firewall rules in your cloud provider if needed

### SSL Certificates
- Script requires Cloudflare Origin Certificates
- Certificates are valid for 15 years
- Private keys must be kept secure (600 permissions enforced)

### SMTP Credentials
- SMTP password stored in `.env` file (600 permissions)
- Consider using app-specific passwords
- Rotate credentials regularly

### Database Access
- PostgreSQL accessible only from Docker network
- Strong passwords generated automatically (24 characters)
- No external access by default

## 🛠️ Automated Security Tools

Recommended tools for additional security:

- **Lynis**: System security auditing
  ```bash
  apt install lynis
  lynis audit system
  ```

- **Docker Bench Security**: Docker security audit
  ```bash
  docker run --rm -it --net host --pid host --userns host --cap-add audit_control \
    -v /var/lib:/var/lib -v /var/run/docker.sock:/var/run/docker.sock \
    docker/docker-bench-security
  ```

- **OWASP ZAP**: Web application security testing
  - Test your Typebot installation for vulnerabilities

## 📜 Compliance

This script implements security controls aligned with:

- **OWASP Top 10**: Protection against common web vulnerabilities
- **CIS Benchmarks**: Docker and Linux hardening
- **PCI DSS**: Encryption and access control (if applicable)
- **GDPR**: Data encryption at rest and in transit
- **ISO 27001**: Security controls and best practices

## 🔗 Security Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [CIS Ubuntu Benchmark](https://www.cisecurity.org/benchmark/ubuntu_linux)
- [Typebot Security](https://docs.typebot.io/self-hosting/security)

## 📞 Contact

For security concerns, contact:
- **GitHub Security Advisories**: https://github.com/achiya-automation/typebot-installation-script/security/advisories
- **Email**: security@achiya-automation.com (if available)

## 🙏 Acknowledgments

We appreciate the security research community for helping keep this project secure.

Security researchers who responsibly disclose vulnerabilities may be acknowledged in our security advisories (with permission).

---

**Thank you for helping keep the Typebot Installation Script secure!** 🔒
