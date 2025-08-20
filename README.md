# Modern Development Environment - IaC Edition

A professional Infrastructure as Code (IaC) setup for Windows 11, PowerShell, WSL, Python, and Docker development environments with Beast Mode 3.1 Enhanced integration.

## 🚀 Quick Start

**Prerequisites:**
- Windows 11 with Administrator access
- Internet connection for package downloads
- App Installer (winget) - Available from Microsoft Store

**One-Command Installation:**
```powershell
# Run as Administrator
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\automation\Install-DevEnvironment.ps1
```

## 🏗️ Infrastructure as Code Architecture

This repository follows modern IaC principles:

### 📁 Repository Structure
```
dotfile/
├── src/                    # Source code and scripts
│   ├── powershell/        # PowerShell modules and profiles
│   └── python/            # Python utilities and helpers
├── configs/               # Configuration files
│   ├── vscode/           # VS Code settings and extensions
│   ├── git/              # Git configuration
│   └── ssh/              # SSH keys and config
├── automation/           # Installation and deployment scripts
│   ├── Install-DevEnvironment.ps1
│   └── Update-Environment.ps1
├── docs/                 # Documentation and guides
│   ├── setup/            # Setup instructions
│   └── troubleshooting/  # Common issues and solutions
└── .github/              # GitHub-specific files
    └── workflows/        # GitHub Actions (future)
```

### 🎯 Core Principles

1. **No Static Assets**: All dependencies downloaded from official sources
2. **Dynamic Downloads**: Packages fetched via winget and official repositories
3. **Version Control**: Only source code, scripts, and configurations stored
4. **Cross-Platform**: Windows 11, WSL, Docker, and Python support
5. **Professional Quality**: Enterprise-grade automation and error handling

## 🛠️ Features

### Beast Mode 3.1 Enhanced
- **Persona-Based Workflow**: Product Manager, Architect, Implementer, Problem Solver, Reviewer personas
- **Enhanced Internet Research**: Multi-engine search with Bing/DuckDuckGo fallbacks
- **Live Documentation Fetching**: Always uses latest official documentation
- **shadcn/ui Integration**: Automatic component documentation lookup
- **IaC Guidelines**: Proper PowerShell 5.x syntax with `${var}` notation

### Development Tools
- **VS Code**: Latest version with essential extensions
- **PowerShell 7+**: Modern PowerShell with backwards compatibility
- **Python 3.12**: Latest stable Python with pip management
- **Docker Desktop**: Container development support
- **Git**: Version control with enhanced configuration
- **WSL Integration**: Ubuntu subsystem support

### Enhanced PowerShell Profile
- **Modern Prompt**: Git branch display and colored output
- **Navigation Shortcuts**: `ll`, `la`, `..`, `...` aliases
- **Git Shortcuts**: `gs`, `gp`, `gpl`, `gc`, `ga` commands
- **Development Helpers**: `py`, `pip`, `code` shortcuts
- **System Information**: `sysinfo` command for system details
- **Beast Mode Helper**: `beast` command for configuration info

## 🔧 Installation Options

### Full Installation (Recommended)
```powershell
.\automation\Install-DevEnvironment.ps1
```

### Silent Installation
```powershell
.\automation\Install-DevEnvironment.ps1 -Silent
```

### Custom Installation
```powershell
# Skip specific components
.\automation\Install-DevEnvironment.ps1 -SkipPython -SkipDocker

# Custom log location
.\automation\Install-DevEnvironment.ps1 -LogPath "C:\Logs\DevInstall.log"
```

## 📋 What Gets Installed

### Core Applications (via winget)
- Visual Studio Code
- Git for Windows
- PowerShell 7+
- Python 3.12 (optional)
- Docker Desktop (optional)

### VS Code Extensions
- PowerShell extension
- Python extension  
- WSL extension
- Dev Containers extension
- GitHub Copilot & Chat
- Tailwind CSS IntelliSense
- Prettier code formatter

### Configuration Files
- Enhanced PowerShell profile with shortcuts
- VS Code settings with Beast Mode integration
- Beast Mode 3.1 Enhanced chatmode file
- Git configuration templates

## 🐍 Python Development

The environment includes Python 3.12 with virtual environment helpers:

```powershell
# Create virtual environment
venv-create myproject

# Activate virtual environment  
venv-activate myproject

# Use pip shortcut
pip install requests
```

## 🐳 Docker Integration

Docker Desktop integration with PowerShell shortcuts:

```powershell
# Docker shortcuts
dps                    # docker ps
dimg                   # docker images  
drun ubuntu:latest     # docker run
dexec -it container    # docker exec
```

## 🔧 Beast Mode 3.1 Enhanced

Beast Mode is integrated into VS Code as a chat mode:

1. **Location**: `%APPDATA%\Code\User\prompts\Beast Mode.chatmode.md`
2. **Access**: VS Code → Chat sidebar → Agent dropdown → "Beast Mode"
3. **Features**:
   - Persona-based development workflow
   - Enhanced internet research with live fetching
   - Infrastructure as Code principles
   - PowerShell 5.x compatibility
   - shadcn/ui documentation integration

### Beast Mode Personas
- **Product Manager**: Requirements gathering and PRDs
- **Software Architect**: Technical design and implementation guides  
- **Implementer**: Clean code following IaC principles
- **Problem Solver**: Debugging and root cause analysis
- **Reviewer**: Code review and validation

## 🖥️ PowerShell 5.x Compatibility

All scripts use proper Windows 11 PowerShell 5.x syntax:

- **Variable Syntax**: `${var}:` instead of `$var:`
- **Special Characters**: `${var}%` instead of `$var%`
- **Path Handling**: `"${var}.exe"` instead of `"$var.exe"`
- **UTF-8/ASCII Only**: No Unicode characters in source files

## 🔍 System Information

Get comprehensive system details:

```powershell
sysinfo
```

Shows OS version, CPU, RAM, PowerShell version, WSL status, and Docker availability.

## 📱 WSL Integration

The environment supports Ubuntu WSL:

```powershell
# Install WSL if not present
wsl --install

# Access Ubuntu
wsl
```

VS Code includes WSL extension for seamless development across Windows and Linux.

## 🚨 Troubleshooting

### Common Issues

**Execution Policy Error:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Winget Not Found:**
- Install "App Installer" from Microsoft Store
- Restart PowerShell

**Administrator Required:**
- Right-click PowerShell → "Run as Administrator"

**VS Code Extensions Not Installing:**
- Ensure VS Code is installed first
- Check internet connection
- Run: `code --version`

### Log Files

Installation logs are saved to `%TEMP%\DevEnvInstall.log` by default.

## 🔄 Updates

Update the environment:

```powershell
# Future: Update script
.\automation\Update-Environment.ps1
```

## 📝 Contributing

1. Follow IaC principles - no static assets
2. Use PowerShell 5.x compatible syntax
3. Test on clean Windows 11 systems
4. Update documentation for changes
5. Maintain UTF-8/ASCII character compliance

## 📄 License

MIT License - Feel free to adapt for your development needs.

## 🎯 Next Steps After Installation

1. **Restart Terminal**: Launch new PowerShell window
2. **Test Profile**: Type `beast` to see Beast Mode info
3. **Open VS Code**: Launch and check extensions loaded
4. **Configure Git**: Set up your Git user details
5. **Install WSL**: Run `wsl --install` if needed
6. **Test Python**: Create and activate virtual environment
7. **Test Docker**: Verify Docker Desktop is running

---

**Beast Mode 3.1 Enhanced - IaC Edition**: Modern development environment with autonomous AI assistance, professional tooling, and Infrastructure as Code principles.
