# Setup Guide - Development Environment

## Prerequisites

Before running the installation script, ensure you have:

### System Requirements
- **Windows 11** (Build 22000 or later)
- **Administrator access** for installation
- **8GB RAM minimum** (16GB recommended)
- **20GB free disk space** for all tools
- **Active internet connection** for downloads

### Required Software
- **App Installer (winget)**: Available from Microsoft Store
- **PowerShell 5.x**: Pre-installed on Windows 11

## Pre-Installation Steps

### 1. Enable Script Execution
```powershell
# Run as Administrator
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 2. Verify Winget Installation
```powershell
# Test winget availability
winget --version
```

If winget is not available, install "App Installer" from Microsoft Store.

### 3. Check System Resources
```powershell
# Check available disk space
Get-WmiObject -Class Win32_LogicalDisk | Select-Object DeviceID, @{Name="Size(GB)";Expression={[math]::Round(${_.Size}/1GB,2)}}, @{Name="FreeSpace(GB)";Expression={[math]::Round(${_.FreeSpace}/1GB,2)}}
```

## Installation Methods

### Method 1: Quick Install (Recommended)
```powershell
# Clone repository
git clone https://your-repo-url.git
cd dotfile

# Run installation as Administrator
.\automation\Install-DevEnvironment.ps1
```

### Method 2: Silent Install
```powershell
# For automated deployment
.\automation\Install-DevEnvironment.ps1 -Silent
```

### Method 3: Custom Install
```powershell
# Skip specific components
.\automation\Install-DevEnvironment.ps1 -SkipPython -SkipDocker

# Custom log location
.\automation\Install-DevEnvironment.ps1 -LogPath "C:\CustomLogs\install.log"
```

## Post-Installation Setup

### 1. Restart Terminal
After installation, restart your PowerShell terminal to load the new profile.

### 2. Test Installation
```powershell
# Test PowerShell profile
beast

# Test system information
sysinfo

# Test Git configuration
git --version

# Test Python (if installed)
python --version

# Test Docker (if installed)
docker --version
```

### 3. Configure Git
```powershell
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### 4. Install WSL (Optional)
```powershell
# Install Ubuntu WSL
wsl --install

# After restart, set up Ubuntu
wsl
```

### 5. Verify VS Code Integration
1. Open VS Code
2. Check that extensions are installed
3. Open Chat sidebar
4. Verify "Beast Mode" appears in agent dropdown

## Beast Mode Setup

Beast Mode 3.1 Enhanced is automatically configured:

### Location
- **File**: `%APPDATA%\Code\User\prompts\Beast Mode.chatmode.md`
- **Access**: VS Code → Chat sidebar → Agent dropdown

### Features Available
- Persona-based development workflow
- Enhanced internet research
- Infrastructure as Code principles
- Live documentation fetching
- shadcn/ui integration

### Test Beast Mode
1. Open VS Code
2. Open Chat sidebar (Ctrl+Shift+I)
3. Select "Beast Mode" from agent dropdown
4. Test with: "Help me create a React component"

## Environment Verification

### PowerShell Profile Features
```powershell
# Navigation shortcuts
ll        # Detailed file listing
la        # All files including hidden
..        # Go up one directory
...       # Go up two directories

# Git shortcuts
gs        # git status
gp        # git push  
gpl       # git pull
gc "msg"  # git commit -m "msg"
ga file   # git add file

# Development helpers
py        # python
pip       # python -m pip
code      # VS Code
```

### System Information
```powershell
# Comprehensive system details
sysinfo
```

### Docker Integration
```powershell
# Docker shortcuts
dps       # docker ps
dimg      # docker images
drun      # docker run
dexec     # docker exec
```

### Python Virtual Environments
```powershell
# Create and activate virtual environment
venv-create myproject
venv-activate myproject
```

## Next Steps

1. **Explore Documentation**: Check `docs/` folder for guides
2. **Customize Settings**: Modify VS Code settings as needed  
3. **Install Additional Tools**: Add project-specific dependencies
4. **Setup SSH Keys**: Configure Git SSH authentication
5. **Test Development Workflow**: Create a sample project

## Backup and Restore

### Backup Current Settings
```powershell
# Copy current configurations
xcopy "${env:APPDATA}\Code\User" "backup\vscode\" /E /I
copy $PROFILE "backup\profile.ps1"
```

### Restore from Backup
```powershell
# Restore configurations
xcopy "backup\vscode\" "${env:APPDATA}\Code\User\" /E /Y
copy "backup\profile.ps1" $PROFILE
```

---

**Need Help?** Check the [troubleshooting guide](../troubleshooting/common-issues.md) for common issues and solutions.
