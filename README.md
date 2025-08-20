# Modern Development Environment - IaC Edition

A professional Infrastructure as Code (IaC) setup for Windows 11, PowerShell, WSL, Python, and Docker development environments with Beast Mode 3.1 Enhanced integration.

## 🚀 Quick Start

**Prerequisites:**
- Windows 11 (PowerShell 5.x included)
- Internet connection for package downloads
- App Installer (winget) - Available from Microsoft Store
- VS Code (for Beast Mode 3.1 Enhanced)

### 🎯 Beast Mode 3.1 Enhanced Setup

**Step 1: Configure VS Code Settings**
```json
{
    "chat.tools.autoApprove": true,
    "chat.agent.maxRequests": 100
}
```

**Step 2: Install Beast Mode Custom Chat Mode**
1. Open VS Code
2. Go to Chat > "..." > "Configure Modes"
3. Select "Create new custom chat mode file"  
4. Choose "User Data Folder" (makes it global)
5. Paste contents from `Beast Mode.chatmode.md`
6. Save as "Beast Mode 3.1 Enhanced"

**Step 3: Activate Beast Mode**
- Select "Beast Mode 3.1 Enhanced" from agent dropdown in VS Code Chat
- Beast Mode is now ready with enhanced IaC workflows!

### 🏃‍♂️ Environment Auto-Detection & Setup

**Comprehensive Environment Setup:**
```powershell
# Auto-detects and installs all components
.\automation\Install-Environment-Auto.ps1 -Silent
```

**Components Auto-Detected:**
- ✅ Windows 11 (mandatory) - Build validation and OS version check
- ✅ PowerShell 5.x (mandatory) - Primary automation environment  
- ✅ PowerShell 7.x (optional) - Supplementary with enhanced features
- ✅ Python Windows (optional) - Native Windows development
- ✅ WSL Ubuntu (optional) - Registry-based detection with user mapping
- ✅ Python in WSL (optional) - Cross-platform Python development
- ✅ Docker in WSL (optional) - Container development (NO Docker Desktop)
- ✅ Docker Compose (optional) - Multi-container orchestration

**Registry-Based WSL Detection:**
- Checks `HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss`
- Validates distribution names and user IDs
- Automatic fallback to command-based detection
- Ubuntu 24.04.3 LTS compatibility verified

**Winget Package Validation:**
Use these commands to verify package availability before installation:
```powershell
# Search for packages
winget search git

# Validate package exists
winget show Git.Git

# Check available versions
winget search Git.Git --versions
```

**Package Verification Sources:**
- GitHub Manifests: https://github.com/microsoft/winget-pkgs/tree/master/manifests
- Winget.run: https://winget.run/pkg/Git/Git
- Winstall.app: https://winstall.app/apps/Git.Git

**One-Command Installation (Self-Elevating):**
```powershell
# No need to run as Administrator - script will self-elevate automatically
.\automation\Install-DevEnvironment.ps1
```

**Silent Installation (Recommended for automation):**
```powershell
# Completely unattended installation with automatic elevation
.\automation\Install-DevEnvironment.ps1 -Silent
```

## 🛡️ WinUtil-Style Self-Elevation

Our installation script uses the same proven self-elevation pattern as [ChrisTitusTech's WinUtil](https://github.com/ChrisTitusTech/winutil):

- **Automatic Admin Detection**: Checks for Administrator privileges
- **Smart Parameter Preservation**: Maintains all command-line arguments during elevation
- **Windows Terminal Integration**: Uses Windows Terminal when available
- **Unattended Mode**: Automatically adds `-Silent` flag for elevated sessions
- **Error Handling**: Graceful fallback and error reporting

**How it works:**
1. Script detects if running as Administrator
2. If not, builds argument list preserving all parameters
3. Launches new elevated session with Windows Terminal (if available) or PowerShell
4. Continues installation with same parameters in elevated context
5. No user interaction required for elevation process

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
│   ├── Install-DevEnvironment.ps1  # Self-elevating installer
│   └── Update-Environment.ps1      # Self-elevating updater
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
6. **Unattended Operation**: No interactive prompts in silent mode

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

### Standard Installation (Self-Elevating)
```powershell
.\automation\Install-DevEnvironment.ps1
```

### Silent Installation (Unattended)
```powershell
.\automation\Install-DevEnvironment.ps1 -Silent
```

### Custom Installation Options
```powershell
# Skip specific components
.\automation\Install-DevEnvironment.ps1 -SkipPython -SkipDocker

# Custom log location
.\automation\Install-DevEnvironment.ps1 -LogPath "C:\Logs\DevInstall.log"

# Force installation even with validation errors
.\automation\Install-DevEnvironment.ps1 -Force

# Silent mode with custom options
.\automation\Install-DevEnvironment.ps1 -Silent -SkipVSCodeExtensions
```

## 📋 What Gets Installed

### Core Applications (via winget - unattended mode)
- Visual Studio Code (with CLI integration)
- Git for Windows
- PowerShell 7+
- Python 3.12 (optional)
- Docker Desktop (optional)

### VS Code Extensions (silent installation)
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

## 🔄 Environment Maintenance

Update your environment with the same self-elevating pattern:

### Standard Update
```powershell
.\automation\Update-Environment.ps1
```

### Silent Update (Recommended for scheduled tasks)
```powershell
.\automation\Update-Environment.ps1 -Silent
```

### Selective Updates
```powershell
# Update only packages
.\automation\Update-Environment.ps1 -UpdateExtensions:$false -UpdateConfigs:$false

# Update only configurations
.\automation\Update-Environment.ps1 -UpdatePackages:$false -UpdateExtensions:$false
```

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

📖 **[Complete Beast Mode Setup Guide](docs/setup/beast-mode-guide.md)** - Comprehensive installation, configuration, and usage documentation.

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
- **Self-Elevation**: WinUtil-style admin privilege handling

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

**Script Won't Run:**
- Script automatically handles execution policy and elevation
- If still having issues: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

**Winget Not Found:**
- Install "App Installer" from Microsoft Store
- Restart PowerShell

**Installation Stuck on Interactive Prompt:**
- Use `-Silent` parameter for unattended installation
- Script automatically prevents interactive prompts in elevated mode

### Unattended Installation Advantages

- **No User Interaction**: Silent mode prevents all interactive prompts
- **Automatic Elevation**: No need to manually run as Administrator
- **Comprehensive Logging**: Timestamped logs for troubleshooting
- **Error Resilience**: Continues installation even if some components fail
- **Scheduled Execution**: Perfect for automated deployment

### Log Files

Installation logs with timestamps:
- Installation: `%TEMP%\DevEnvInstall_YYYY-MM-DD_HH-mm-ss.log`
- Updates: `%TEMP%\DevEnvUpdate_YYYY-MM-DD_HH-mm-ss.log`

## 🔄 Updates

Update the environment with the same self-elevating pattern:

```powershell
# Standard update (self-elevating)
.\automation\Update-Environment.ps1

# Silent update (unattended)
.\automation\Update-Environment.ps1 -Silent
```

## � Documentation

### Setup & Configuration
- **[Installation Guide](docs/setup/installation-guide.md)** - Complete setup instructions and requirements
- **[Beast Mode Complete Guide](docs/setup/beast-mode-guide.md)** - Comprehensive Beast Mode 3.1 setup and usage
- **[Validation Report](docs/setup/validation-report.md)** - Environment validation and testing procedures

### Troubleshooting
- **[Common Issues](docs/troubleshooting/common-issues.md)** - General troubleshooting and solutions
- **[Beast Mode Issues](docs/troubleshooting/beast-mode-issues.md)** - Specific Beast Mode troubleshooting
- **[Installation Fixes](docs/troubleshooting/installation-fixes.md)** - Environment setup issue resolution

### Advanced Topics
- **[PowerShell Functions](src/powershell/functions/)** - Custom PowerShell modules and utilities
- **[Script Templates](src/powershell/scripts/)** - Reusable script templates with IaC principles
- **[Python Modules](src/python/modules/)** - Python utilities and validation functions

## �📝 Contributing

1. Follow IaC principles - no static assets
2. Use PowerShell 5.x compatible syntax with `${var}` brackets
3. Implement WinUtil-style self-elevation for admin scripts
4. Test on clean Windows 11 systems in both interactive and silent modes
5. Update documentation for changes
6. Maintain UTF-8/ASCII character compliance

## 📄 License

MIT License - Feel free to adapt for your development needs.

## 🎯 Next Steps After Installation

1. **No Terminal Restart Needed**: Script installs in current session
2. **Test Profile**: Type `beast` to see Beast Mode info
3. **Open VS Code**: Launch and check extensions loaded automatically
4. **Configure Git**: Set up your Git user details
5. **Install WSL**: Run `wsl --install` if needed (optional)
6. **Test Python**: Create and activate virtual environment
7. **Test Docker**: Verify Docker Desktop is running

---

**Beast Mode 3.1 Enhanced - IaC Edition**: Modern development environment with autonomous AI assistance, professional tooling, WinUtil-style automation, and Infrastructure as Code principles for completely unattended installation and maintenance.
