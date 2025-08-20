# WSL Docker Environment Setup Guide

A comprehensive guide for setting up Docker Engine in WSL Ubuntu without Docker Desktop, designed for developers who prefer a native Linux container environment with Windows integration.

## 🚀 Quick Start

```powershell
# Standard setup with validation (recommended)
.\automation\Install-WSLDockerEnvironment.ps1

# Silent installation for automation
.\automation\Install-WSLDockerEnvironment.ps1 -Silent

# Clean installation (removes existing Ubuntu WSL)
.\automation\Install-WSLDockerEnvironment.ps1 -CleanInstall -Force
```

## 🎯 Key Features

### Password-Free Automation
- Uses `wsl --user root bash -c '<COMMAND>'` pattern to avoid sudo prompts
- No interactive password requests during installation
- Fully automated from start to finish

### Official Docker Installation
- Follows Docker CE installation guidelines from docs.docker.com
- Uses official Docker GPG keys and repositories
- Installs latest stable Docker Engine and Docker Compose plugin

### Windows Integration
- Configures TCP socket on port 2375 for Windows connectivity
- Sets DOCKER_HOST environment variable automatically
- Works seamlessly with VS Code Docker extension
- No Docker Desktop required

### Comprehensive Logging
- All operations logged to timestamped files in `$env:TEMP`
- Detailed step-by-step progress tracking
- Error messages with stack traces for troubleshooting
- Log file location displayed during and after execution

## 📋 What Gets Installed

### Step-by-Step Process

1. **WSL Availability Check**
   - Verifies WSL is enabled and configured
   - Tests WSL executable availability

2. **Ubuntu Distribution Setup**
   - Registry-based Ubuntu WSL detection
   - Installs Ubuntu if not present
   - Initializes distribution for first use

3. **Sudoers Configuration**
   - Configures NOPASSWD access for seamless operations
   - Creates `/etc/sudoers.d/99-<username>-nopasswd` file
   - Validates sudoers file syntax

4. **Python Installation**
   - Installs Python 3 and development tools
   - Includes pip, venv, and build-essential packages
   - Uses Ubuntu's official package repositories

5. **Docker Engine Installation**
   - Removes old Docker versions (docker.io, docker-compose-v2)
   - Adds Docker's official GPG key and repository
   - Installs docker-ce, docker-ce-cli, containerd.io
   - Installs docker-buildx-plugin and docker-compose-plugin

6. **Docker Post-Installation**
   - Adds user to docker group
   - Configures Docker daemon for TCP socket access
   - Creates systemd service overrides
   - Sets up keepwsl.service to maintain WSL session
   - Restarts Docker services with new configuration

7. **Windows Environment Setup**
   - Retrieves WSL network address from registry
   - Sets DOCKER_HOST environment variable
   - Configures Windows user environment for persistence

8. **Comprehensive Validation**
   - Tests WSL functionality
   - Validates Ubuntu distribution responsiveness
   - Verifies Python installation
   - Tests Docker and Docker Compose functionality
   - Checks Docker socket accessibility from Windows
   - Validates DOCKER_HOST environment variable

## 🔧 Command Options

### Basic Usage
```powershell
# Standard installation with all validation
.\automation\Install-WSLDockerEnvironment.ps1

# View help and parameters
Get-Help .\automation\Install-WSLDockerEnvironment.ps1 -Full
```

### Advanced Options
```powershell
# Skip comprehensive validation (faster)
.\automation\Install-WSLDockerEnvironment.ps1 -SkipValidation

# Force reinstallation of existing components
.\automation\Install-WSLDockerEnvironment.ps1 -Force

# Clean installation - removes existing Ubuntu WSL
.\automation\Install-WSLDockerEnvironment.ps1 -CleanInstall

# Silent mode for automation (no interactive prompts)
.\automation\Install-WSLDockerEnvironment.ps1 -Silent

# Combine options
.\automation\Install-WSLDockerEnvironment.ps1 -Silent -Force -SkipValidation
```

### Parameter Details

| Parameter | Type | Description |
|-----------|------|-------------|
| `-SkipValidation` | Switch | Skip comprehensive validation after installation |
| `-Force` | Switch | Force reinstallation of existing components |
| `-Silent` | Switch | Run in silent mode with minimal output (auto-continue prompts) |
| `-CleanInstall` | Switch | Perform clean installation by removing existing WSL Ubuntu distribution |

## 📊 Validation Results

The script performs 7 comprehensive validation tests:

1. **WSL Functional** - Basic WSL echo test
2. **Ubuntu Responsive** - Ubuntu distribution communication test
3. **Python Working** - Python 3 installation and version test
4. **Docker Running** - Docker daemon functionality test
5. **Docker Compose Working** - Docker Compose plugin test
6. **Docker Socket Accessible** - TCP port 2375 connectivity test from Windows
7. **Windows DOCKER_HOST Set** - Environment variable configuration test

**Success Criteria**: All 7 tests must pass for complete validation success.

## 📝 Log Files

### Log File Format
```
[TIMESTAMP] [LEVEL] MESSAGE
[2025-08-21 00:38:00] [INFO] WSL Docker Environment Setup Starting
[2025-08-21 00:38:00] [SUCCESS] Step 1: Administrator privileges confirmed
[2025-08-21 00:38:01] [ERROR] Failed to install Docker: Could not find path
```

### Log Levels
- **INFO**: General information and progress updates
- **SUCCESS**: Successful completion of operations
- **WARN**: Warning messages (non-critical issues)
- **ERROR**: Error messages (critical issues)

### Finding Log Files
```powershell
# Find the most recent log file
$logFile = Get-ChildItem $env:TEMP -Filter "*WSL-Docker-Setup*" | Sort-Object CreationTime -Descending | Select-Object -First 1

# Display log file path
Write-Host "Latest log file: $($logFile.FullName)"

# View last 20 log entries
Get-Content $logFile.FullName | Select-Object -Last 20

# View all log entries
Get-Content $logFile.FullName
```

## 🚀 After Installation

### Test Docker Functionality
```powershell
# Test Docker connectivity from Windows
docker ps
docker --version
docker compose --version

# Run hello-world container
docker run --rm hello-world

# Test Docker Compose
docker compose --help
```

### VS Code Integration
The Docker extension in VS Code will automatically detect the Docker socket:

1. Install Docker VS Code extension
2. Open VS Code
3. The Docker extension should show containers, images, and volumes
4. Use the Docker explorer in the sidebar

### Environment Variables
The installation sets the following environment variables:

```powershell
# View current DOCKER_HOST setting
[System.Environment]::GetEnvironmentVariable('DOCKER_HOST', [System.EnvironmentVariableTarget]::User)

# Should display something like: tcp://172.18.249.113:2375
```

### Network Configuration
- **WSL IP Address**: Automatically detected from registry or WSL instance
- **TCP Port**: 2375 (standard Docker daemon port)
- **Protocol**: TCP (no TLS for local development)

## 🔍 Troubleshooting

### Common Issues

**Issue**: "Could not find a part of the path 'C:\dev\null'"
- **Cause**: PowerShell interpreting `/dev/null` as Windows path
- **Solution**: Fixed in current version using proper command escaping

**Issue**: WSL Docker socket not accessible
- **Cause**: Docker daemon not configured for TCP socket
- **Solution**: Check Docker service status: `wsl --user root systemctl status docker`

**Issue**: Ubuntu WSL not responding
- **Cause**: WSL distribution not properly initialized
- **Solution**: Run `wsl -d Ubuntu` manually to complete setup

### Debugging Commands
```powershell
# Check WSL distributions
wsl --list --verbose

# Test WSL Ubuntu access
wsl -d Ubuntu echo "Ubuntu is working"

# Check Docker service in WSL
wsl --user root systemctl status docker

# Test Docker socket
Test-NetConnection -ComputerName (Get-Content $env:TEMP\wsl-ip.txt -ErrorAction SilentlyContinue) -Port 2375
```

### Re-running Installation
```powershell
# Clean installation (removes existing Ubuntu)
.\automation\Install-WSLDockerEnvironment.ps1 -CleanInstall -Force

# Force reinstall existing components
.\automation\Install-WSLDockerEnvironment.ps1 -Force

# Skip validation to speed up debugging
.\automation\Install-WSLDockerEnvironment.ps1 -Force -SkipValidation
```

## 🏆 Best Practices

### Development Workflow
1. Use this setup for container-based development without Docker Desktop
2. Leverage VS Code Docker extension for container management
3. Use Docker Compose for multi-container applications
4. Keep WSL distribution updated: `wsl -d Ubuntu -c "sudo apt update && sudo apt upgrade"`

### Security Considerations
- TCP socket on 2375 is for local development only
- No TLS encryption (suitable for localhost communication)
- Firewall should block external access to port 2375
- Consider using Unix socket for production environments

### Performance Tips
- WSL 2 provides better performance than WSL 1
- Store project files in WSL filesystem for better I/O performance
- Use Docker BuildKit for faster builds: `export DOCKER_BUILDKIT=1`

### Maintenance
```powershell
# Update Docker in WSL
wsl --user root apt update
wsl --user root apt upgrade docker-ce docker-ce-cli containerd.io

# Clean up Docker resources
docker system prune
docker volume prune
```

This setup provides a professional, automated Docker development environment that integrates seamlessly with Windows while maintaining the benefits of native Linux containers.
