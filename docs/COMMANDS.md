# Command Reference - Essential Commands

**Quick reference for frequently used commands in your development environment.**

---

## 📦 Package Management (Winget)

### Update All Packages
```powershell
winget upgrade --accept-package-agreements --accept-source-agreements --include-unknown --all
```

### Search & Install
```powershell
# Search for package
winget search <package-name>

# Show package details
winget show <PackageId>

# Install package
winget install --id <PackageId> --silent --accept-package-agreements --accept-source-agreements

# List installed packages
winget list
```

---

## 🔧 IDE Installation

### Visual Studio Code (Full Integration)
```powershell
winget install --force Microsoft.VisualStudioCode --override '/VERYSILENT /SP- /MERGETASKS="addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath"'
```

**Override Parameters:**
- `/VERYSILENT` - No UI during installation
- `/SP-` - Skip startup prompt
- `addcontextmenufiles` - Right-click files → "Open with Code"
- `addcontextmenufolders` - Right-click folders → "Open with Code"
- `associatewithfiles` - Associate file types with VS Code
- `addtopath` - Add `code` command to PATH

### Cursor IDE (Full Integration)
```powershell
# Using dedicated script (recommended)
.\automation\Install-CursorIDE.ps1 -Silent

# Direct winget command
winget install --force Cursor.Cursor --override '/VERYSILENT /SP- /MERGETASKS="addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath"'
```

---

## 🔄 Environment Maintenance

### Update Everything
```powershell
# Update environment (packages + extensions)
.\automation\Update-Environment.ps1 -Silent

# Update only packages
winget upgrade --all --silent --accept-package-agreements --accept-source-agreements

# Update VS Code extensions
code --list-extensions | ForEach-Object { code --install-extension $_ --force }
```

### PowerShell Profile
```powershell
# Reload profile
. $PROFILE

# Edit profile
code $PROFILE

# View profile location
$PROFILE
```

---

## 📝 Git Operations

### Shortcuts (from PowerShell profile)
```powershell
gs          # git status
ga .        # git add .
gc "msg"    # git commit -m "msg"
gp          # git push
gpl         # git pull
```

### Full Commands
```powershell
git status
git add .
git commit -m "feat(scope): description"
git push origin main
git pull --rebase
```

---

## 🐍 Python Development

### Virtual Environments
```powershell
# Create virtual environment
python -m venv venv

# Activate (Windows)
.\venv\Scripts\Activate.ps1

# Deactivate
deactivate

# Install requirements
pip install -r requirements.txt

# Update pip
python -m pip install --upgrade pip
```

---

## 🐳 Docker & WSL

### Docker Commands
```powershell
docker ps                    # List running containers
docker ps -a                 # List all containers
docker images                # List images
docker run --rm hello-world  # Test Docker
docker compose up -d         # Start services
docker compose down          # Stop services
docker system prune -a       # Clean up
```

### WSL Operations
```powershell
wsl                          # Enter WSL
wsl --list --verbose         # List distributions
wsl --shutdown               # Shutdown WSL
wsl --install                # Install WSL
wsl --install -d Ubuntu      # Install specific distro
wsl --update                 # Update WSL
```

---

## 🔍 System Information

### Custom Commands (from profile)
```powershell
sysinfo     # Comprehensive system info
ll          # List files (detailed)
la          # List all files (including hidden)
..          # Navigate up one directory
...         # Navigate up two directories
```

### System Details
```powershell
# Windows version
Get-ComputerInfo | Select-Object WindowsVersion, OsHardwareAbstractionLayer

# PowerShell version
$PSVersionTable

# Installed packages
winget list

# Environment variables
Get-ChildItem Env:

# PATH variable
$env:PATH -split ';'
```

---

## 📚 VS Code Extensions

### Manage Extensions
```powershell
# Install extension
code --install-extension <extension-id> --force

# List installed extensions
code --list-extensions

# Uninstall extension
code --uninstall-extension <extension-id>

# Update all extensions
code --list-extensions | ForEach-Object { code --install-extension $_ --force }
```

---

## 🚀 Quick Actions

### Daily Workflow
```powershell
# Start of day
cd ${env:USERPROFILE}\dotfile
gs                  # Check git status
gpl                 # Pull latest changes
winget upgrade --all --accept-package-agreements --accept-source-agreements

# Development
code .              # Open VS Code in current directory
py script.py        # Run Python script
docker compose up -d # Start Docker services

# End of day
ga .                # Stage all changes
gc "feat: description"  # Commit changes
gp                  # Push changes
```

### Troubleshooting
```powershell
# Check logs
Get-ChildItem $env:TEMP -Filter "*DevEnv*.log" | Sort-Object CreationTime -Desc | Select-Object -First 1 | Get-Content

# Reload environment
. $PROFILE
refreshenv  # If using Chocolatey

# Verify installations
winget list
code --version
python --version
docker --version
git --version
```

---

## 📖 Related Documentation

- [README](../README.md) - Main documentation
- [Troubleshooting](TROUBLESHOOTING.md) - Common issues
- [WSL & Docker](WSL_DOCKER.md) - Linux subsystem setup

---

**Tip**: Add these commands to your PowerShell profile for even quicker access!
