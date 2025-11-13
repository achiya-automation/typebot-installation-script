# Contributing to Typebot Installation Script

First off, thank you for considering contributing to the Typebot Installation Script! 🎉

It's people like you that make this project better for everyone in the Typebot community.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Getting Started](#getting-started)
- [Development Process](#development-process)
- [Testing Guidelines](#testing-guidelines)
- [Security Guidelines](#security-guidelines)
- [Pull Request Process](#pull-request-process)
- [Style Guidelines](#style-guidelines)

## 🤝 Code of Conduct

This project and everyone participating in it is governed by our commitment to:

- Be respectful and inclusive
- Welcome newcomers and help them learn
- Focus on what is best for the community
- Show empathy towards other community members

## 💡 How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates.

When creating a bug report, include:

- **Clear title** - Descriptive and specific
- **Description** - What happened vs. what you expected
- **Environment**:
  - OS version (Ubuntu 22.04, 24.04, etc.)
  - Server specifications (CPU, RAM)
  - Cloud provider (if applicable)
- **Steps to reproduce** - Exact commands run
- **Logs** - Relevant error messages or logs
- **Screenshots** - If applicable

Example:
```markdown
**Title**: Installation fails at Nginx configuration step

**Description**:
The script exits with error when configuring Nginx with SSL certificates.

**Environment**:
- Ubuntu 22.04 LTS
- 2 vCPU, 4GB RAM
- DigitalOcean Droplet

**Steps to Reproduce**:
1. Run `sudo ./install-typebot.sh`
2. Enter domain: typebot.example.com
3. Paste SSL certificate
4. Error occurs at Nginx configuration

**Error Message**:
```
nginx: [emerg] cannot load certificate "/etc/ssl/cloudflare/cert.pem"
```
```

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- **Clear title** - What feature you're suggesting
- **Detailed description** - Explain the feature and why it's needed
- **Use cases** - Real-world scenarios where this would help
- **Possible implementation** - If you have ideas on how to implement
- **Alternatives** - Other solutions you've considered

### Contributing Code

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/amazing-feature`)
3. **Make your changes**
4. **Test thoroughly** (see Testing Guidelines)
5. **Commit with descriptive messages**
6. **Push to your fork** (`git push origin feature/amazing-feature`)
7. **Open a Pull Request**

## 🚀 Getting Started

### Prerequisites

- Basic knowledge of Bash scripting
- Understanding of Linux system administration
- Familiarity with Docker and Docker Compose
- Ubuntu 22.04+ test environment

### Development Environment Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/typebot-installation-script.git
cd typebot-installation-script

# Add upstream remote
git remote add upstream https://github.com/achiya-automation/typebot-installation-script.git

# Create a branch for your changes
git checkout -b feature/your-feature-name
```

### Testing Environment

**⚠️ IMPORTANT**: NEVER test on a production server!

Options for testing:
1. **Local VM** (VirtualBox, VMware)
2. **Cloud instance** (DigitalOcean, AWS, Hetzner)
3. **Docker container** (for basic syntax testing only)

Recommended: Fresh Ubuntu 22.04 LTS server with at least 2GB RAM.

## 🔄 Development Process

### 1. Keep Your Fork Updated

```bash
# Fetch upstream changes
git fetch upstream

# Merge upstream changes into your main branch
git checkout main
git merge upstream/main

# Push updates to your fork
git push origin main
```

### 2. Make Your Changes

- Write clean, readable code
- Follow existing code style
- Add comments for complex logic
- Update documentation if needed

### 3. Commit Messages

Follow this format:

```
<type>: <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code formatting (no functional changes)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `security`: Security improvements
- `perf`: Performance improvements

**Example:**
```
feat: Add support for Ubuntu 24.04 LTS

- Updated package installation for Ubuntu 24.04
- Added OS version detection
- Updated documentation

Closes #42
```

## 🧪 Testing Guidelines

### Pre-Testing Checklist

- [ ] Syntax check: `bash -n install-typebot.sh`
- [ ] ShellCheck: `shellcheck install-typebot.sh`
- [ ] Test on fresh Ubuntu 22.04 server
- [ ] Test on fresh Ubuntu 24.04 server (if applicable)
- [ ] Test with different configuration options
- [ ] Verify all services start correctly
- [ ] Check all logs for errors
- [ ] Test accessing the application

### Testing Procedure

1. **Provision fresh Ubuntu server**
   ```bash
   # DigitalOcean, Hetzner, AWS, etc.
   # Minimum: 2 vCPU, 4GB RAM, 20GB disk
   ```

2. **Upload your modified script**
   ```bash
   scp install-typebot.sh root@YOUR_SERVER_IP:~/
   ```

3. **Run the script**
   ```bash
   ssh root@YOUR_SERVER_IP
   chmod +x install-typebot.sh
   ./install-typebot.sh
   ```

4. **Verify installation**
   ```bash
   # Check all containers are running
   docker compose ps

   # Check logs for errors
   docker compose logs

   # Access the application
   curl -I https://your-domain.com
   ```

5. **Test functionality**
   - Access Builder domain
   - Create a test bot
   - Publish the bot
   - Access Viewer domain
   - Test file uploads (MinIO)
   - Test email magic link

### Automated Testing

We're working on automated tests. Contributions welcome!

## 🔒 Security Guidelines

### Security-First Development

- **Never hardcode secrets** - All credentials must be generated at runtime
- **Validate all inputs** - Prevent injection attacks
- **Use secure defaults** - Opt for maximum security by default
- **Keep dependencies updated** - Regular updates to Docker images, packages
- **Follow least privilege** - Minimum necessary permissions
- **Secure file permissions** - 600 for sensitive files, 644 for configs

### Security Testing

Before submitting, verify:

- [ ] No secrets in code or commits
- [ ] Input validation works correctly
- [ ] File permissions are correct (600 for .env, SSL keys)
- [ ] Firewall rules are properly configured
- [ ] SSH hardening is effective
- [ ] SSL/TLS configuration is strong
- [ ] Docker containers have resource limits
- [ ] Logs don't contain sensitive information

### Reporting Security Vulnerabilities

**DO NOT** open public issues for security vulnerabilities.

Instead:
1. Email: security@achiya-automation.com (if available)
2. Or open a private security advisory on GitHub
3. Include detailed description and reproduction steps
4. We'll respond within 48 hours

## 📝 Pull Request Process

### Before Submitting

1. **Test thoroughly** - Follow testing guidelines above
2. **Update documentation** - README, guides, comments
3. **Update CHANGELOG.md** - Document your changes
4. **Check for conflicts** - Rebase on latest main if needed
5. **Run linters** - ShellCheck, markdown lint

### PR Description Template

```markdown
## Description
Brief description of what this PR does.

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update
- [ ] Security improvement

## How Has This Been Tested?
- [ ] Tested on Ubuntu 22.04
- [ ] Tested on Ubuntu 24.04
- [ ] Tested with different configuration options
- [ ] All services start correctly
- [ ] Application is accessible and functional

## Checklist
- [ ] My code follows the project's style guidelines
- [ ] I have performed a self-review of my code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have tested my changes on a fresh server
- [ ] Any dependent changes have been merged and published

## Screenshots (if applicable)
Add screenshots to help explain your changes.

## Additional Notes
Any additional information that reviewers should know.
```

### Review Process

1. **Automated checks** - Must pass before review
2. **Code review** - At least one maintainer approval
3. **Testing verification** - Evidence of testing required
4. **Documentation check** - Docs must be updated
5. **Security review** - For security-related changes
6. **Merge** - Squash and merge to main

## 📏 Style Guidelines

### Bash Script Style

- **Indentation**: 4 spaces (no tabs)
- **Line length**: Maximum 120 characters
- **Function names**: lowercase_with_underscores
- **Variable names**: UPPERCASE_FOR_GLOBALS, lowercase_for_locals
- **Comments**: Explain WHY, not WHAT

Example:
```bash
# Good
function generate_password() {
    local length="${1:-24}"  # Default to 24 characters
    openssl rand -base64 "$length" | tr -d "=+/" | cut -c1-"$length"
}

PASSWORD=$(generate_password)

# Bad
function GeneratePassword() {
local LEN=$1
openssl rand -base64 $LEN | tr -d "=+/" | cut -c1-$LEN
}
```

### Error Handling

Always check for errors:
```bash
# Good
if ! command_that_might_fail; then
    print_error "Command failed"
    exit 1
fi

# Or
command_that_might_fail || {
    print_error "Command failed"
    exit 1
}
```

### User-Facing Messages

- **Clear and concise** - Easy to understand
- **Actionable** - Tell user what to do
- **Consistent** - Use same terminology throughout
- **Colors** - Use colors to highlight important info
  - 🟢 Green for success
  - 🔴 Red for errors
  - 🟡 Yellow for warnings
  - 🔵 Blue for info

## 🏷️ Issue Labels

- `bug` - Something isn't working
- `enhancement` - New feature or request
- `documentation` - Documentation improvements
- `security` - Security-related issues
- `good first issue` - Good for newcomers
- `help wanted` - Extra attention needed
- `question` - Further information requested
- `wontfix` - This will not be worked on
- `duplicate` - Issue already exists

## 🎯 Areas for Contribution

### High Priority
- Automated testing framework
- Support for more Linux distributions (Debian, CentOS)
- Backup and restore functionality
- Monitoring integration (Prometheus/Grafana)
- Multi-server deployment support

### Medium Priority
- IPv6 support
- Let's Encrypt certificate integration
- Database migration tools
- Configuration management (Ansible, Terraform)
- Rollback functionality

### Documentation
- Video tutorials
- Translations (Spanish, French, German, etc.)
- Troubleshooting guides
- Best practices documentation
- Architecture diagrams

## 📞 Getting Help

- **GitHub Discussions** - For questions and discussions
- **GitHub Issues** - For bugs and feature requests
- **Email** - For private security concerns

## 📜 License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing! 🎉

Your efforts help make Typebot more accessible and secure for everyone.
