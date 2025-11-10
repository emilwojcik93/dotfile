# Windows Development Environment - IaC Edition

**Modern Infrastructure as Code setup for Windows 11 development with PowerShell, WSL, Python, and Docker.**

---

## 🚀 Quick Start

```powershell
# Clone repository
git clone <your-repo-url> ${env:USERPROFILE}\dotfile
cd ${env:USERPROFILE}\dotfile

# Install everything (auto-elevates to admin)
.\Install.ps1

# Or install with options
.\automation\Install-DevEnvironment.ps1 -Silent -SkipDocker
```

**That's it!** The script handles everything: package installation, VS Code extensions, PowerShell profile, and configuration.

---

## 📦 What Gets Installed

### Core Tools (via winget)
- **Visual Studio Code** - Primary IDE with context menu integration
- **Cursor IDE** - AI-powered editor (optional)
- **Git** - Version control
- **PowerShell 7+** - Modern PowerShell (alongside Windows PowerShell 5.x)
- **Python 3.12** - Latest Python (optional)
- **Docker Desktop** - Containers (optional)

### VS Code Extensions (auto-detected based on installed tools)
- GitHub Copilot & Chat
- PowerShell, Python, Docker extensions
- GitLens, Prettier, Local History
- WSL & Dev Containers (if available)

### Configuration
- Enhanced PowerShell profile with shortcuts
- VS Code settings optimized for development
- Beast Mode 3.1 Enhanced chat mode (Cursor AI)
- Git configuration templates

---

## 📁 Repository Structure

```
dotfile/
├── automation/              # Installation & update scripts
│   ├── Install-DevEnvironment.ps1      # Main installer (recommended)
│   ├── Install-CursorIDE.ps1          # Cursor IDE with full integration
│   └── Update-Environment.ps1          # Update all packages & extensions
├── configs/                 # VS Code & tool configurations
│   ├── settings.json       # VS Code settings
│   ├── extensions.json     # Recommended extensions
│   └── tasks.json          # VS Code tasks
├── src/                    # Source files & templates
│   ├── powershell/
│   │   └── profile.ps1     # Enhanced PowerShell profile
│   └── python/
│       └── requirements.txt # Python dependencies
├── docs/                   # Documentation (topic-specific)
│   ├── COMMANDS.md         # Frequently used commands
│   ├── TROUBLESHOOTING.md  # Common issues & solutions
│   └── WSL_DOCKER.md       # WSL & Docker setup guide
├── Beast Mode.chatmode.md  # Cursor AI chat mode configuration
├── .cursorrules            # AI coding standards & instructions
├── Install.ps1             # Quick installer wrapper
└── README.md               # This file
```

---

## 🔧 Installation Options

### Standard Installation
```powershell
.\Install.ps1
```
Runs interactive installation with progress output.

### Silent Installation (Recommended for automation)
```powershell
.\automation\Install-DevEnvironment.ps1 -Silent
```
Fully unattended installation - perfect for scripts or scheduled tasks.

### Custom Installation
```powershell
# Skip optional components
.\automation\Install-DevEnvironment.ps1 -SkipPython -SkipDocker

# Force continue despite errors
.\automation\Install-DevEnvironment.ps1 -Force

# Custom log location
.\automation\Install-DevEnvironment.ps1 -LogPath "C:\Logs\install.log"
```

### Cursor IDE Installation
```powershell
# Install Cursor with full context menu integration
.\automation\Install-CursorIDE.ps1 -Silent
```

---

## 🔄 Maintenance & Updates

### Update Everything
```powershell
# Update all packages and extensions
.\automation\Update-Environment.ps1 -Silent
```

### Manual Updates
```powershell
# Update all winget packages
winget upgrade --accept-package-agreements --accept-source-agreements --include-unknown --all

# Update VS Code extensions
code --list-extensions | ForEach-Object { code --install-extension $_ --force }

# Reload PowerShell profile
. $PROFILE
```

---

## 📚 Documentation

### Quick References
- **[Command Reference](docs/COMMANDS.md)** - Frequently used commands and examples
- **[Troubleshooting Guide](docs/TROUBLESHOOTING.md)** - Common issues and solutions
- **[WSL & Docker Setup](docs/WSL_DOCKER.md)** - Linux subsystem and container setup

### Configuration Files
- **[.cursorrules](.cursorrules)** - AI coding standards and repository guidelines
- **[Beast Mode](Beast%20Mode.chatmode.md)** - Cursor AI chat mode configuration
- **[VS Code Settings](configs/settings.json)** - Editor configuration

---

## 💡 Key Features

### 1. Infrastructure as Code
- No static assets - everything downloaded from official sources
- Dynamic package management via winget
- Idempotent installations - safe to run multiple times
- Version-controlled configurations

### 2. Self-Elevating Scripts
- Automatic admin privilege handling (WinUtil-style)
- No manual "Run as Administrator" needed
- Preserves all command-line parameters
- Works with Windows Terminal

### 3. Conditional Installation
- Auto-detects installed tools
- Installs only relevant VS Code extensions
- Skips unnecessary components
- Validates system capabilities

### 4. PowerShell 5.x Compatible
- Works on default Windows 11 PowerShell
- Proper bracketed variable syntax: `${var}`
- UTF-8/ASCII only (no Unicode characters)
- Tested on PowerShell 5.1 and 7.x

### 5. Enhanced PowerShell Profile
```powershell
# Navigation shortcuts
ll, la          # List files
.., ...         # Navigate up directories

# Git shortcuts
gs              # git status
ga .            # git add .
gc "msg"        # git commit -m "msg"
gp, gpl         # git push/pull

# Development
py              # python
code .          # Open VS Code
sysinfo         # System information
beast           # Beast Mode info
```

---

## 🎯 Common Tasks

### Install Cursor IDE with Full Integration
```powershell
.\automation\Install-CursorIDE.ps1 -Silent
```
Adds context menu, file associations, and PATH configuration.

### Install VS Code with Full Integration
```powershell
winget install --force Microsoft.VisualStudioCode --override '/VERYSILENT /SP- /MERGETASKS="addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath"'
```

### Update All Packages
```powershell
winget upgrade --accept-package-agreements --accept-source-agreements --include-unknown --all
```

### Setup WSL with Docker (No Docker Desktop)
```powershell
# Install WSL
wsl --install

# Install Docker in WSL (native Docker Engine)
# See docs/WSL_DOCKER.md for detailed guide
```

---

## 🔍 System Requirements

- **OS**: Windows 11 (Windows 10 may work but untested)
- **PowerShell**: 5.1+ (included in Windows 11)
- **Winget**: App Installer from Microsoft Store
- **Internet**: Required for package downloads
- **Disk Space**: ~5GB for full installation

---

## 🚨 Troubleshooting

### Script Won't Run
```powershell
# Set execution policy (if needed)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Scripts auto-elevate to admin - no manual elevation needed
```

### Winget Not Found
```powershell
# Install App Installer from Microsoft Store
# Then restart PowerShell
```

### Installation Fails
```powershell
# Check logs
Get-ChildItem $env:TEMP -Filter "*DevEnv*.log" | Sort-Object CreationTime -Desc | Select-Object -First 1 | Get-Content

# Run with Force to continue despite errors
.\automation\Install-DevEnvironment.ps1 -Force
```

**For more issues, see [Troubleshooting Guide](docs/TROUBLESHOOTING.md)**

---

## 🎨 Beast Mode 3.1 Enhanced

**AI-powered development assistant for Cursor IDE**

### Setup
1. Install Cursor IDE: `.\automation\Install-CursorIDE.ps1`
2. Open Cursor → Chat → "..." → "Configure Modes"
3. Create new custom chat mode
4. Paste contents from `Beast Mode.chatmode.md`
5. Save as "Beast Mode 3.1 Enhanced"

### Features
- Persona-based workflow (Product Manager, Architect, Implementer, etc.)
- Enhanced internet research with live documentation
- Infrastructure as Code principles
- PowerShell 5.x compatibility enforcement
- shadcn/ui integration

---

## 🤝 Contributing

1. Follow IaC principles - no static assets
2. Use PowerShell 5.x compatible syntax: `${var}`
3. Test on clean Windows 11 systems
4. Update documentation for changes
5. Use conventional commit messages

---

## 📄 License

MIT License - Adapt freely for your needs.

---

## 🎯 Next Steps After Installation

1. ✅ **Restart Terminal** - Reload environment variables
2. ✅ **Test Profile** - Run `beast` command
3. ✅ **Open VS Code** - Verify extensions loaded
4. ✅ **Configure Git** - Set user name and email
5. ⭐ **Optional**: Install WSL with `wsl --install`
6. ⭐ **Optional**: Setup Beast Mode in Cursor

---

**Questions? Check [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) or review logs in `%TEMP%`**

---

*Infrastructure as Code Edition - Modern Windows Development Environment*
