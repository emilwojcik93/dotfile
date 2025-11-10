# Troubleshooting Guide

**Common issues and solutions for the development environment setup.**

---

## 🔧 Installation Issues

### Script Won't Run

**Problem**: PowerShell blocks script execution

**Solution**:
```powershell
# Set execution policy for current user
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Verify policy
Get-ExecutionPolicy -List
```

**Note**: Scripts auto-elevate to admin - no manual elevation needed.

---

### Winget Not Found

**Problem**: `winget` command not recognized

**Solution**:
1. Install "App Installer" from Microsoft Store
2. Restart PowerShell
3. Verify: `winget --version`

**Alternative**:
```powershell
# Check if winget is installed but not in PATH
Get-Command winget -ErrorAction SilentlyContinue
```

---

### Installation Hangs or Fails

**Problem**: Installation stops responding or exits with errors

**Solution**:
```powershell
# 1. Check logs
Get-ChildItem $env:TEMP -Filter "*DevEnv*.log" | Sort-Object CreationTime -Desc | Select-Object -First 1 | Get-Content

# 2. Run with Force to continue despite errors
.\automation\Install-DevEnvironment.ps1 -Force

# 3. Run in Silent mode to avoid prompts
.\automation\Install-DevEnvironment.ps1 -Silent
```

---

### VS Code CLI Not Found

**Problem**: `code` command not recognized after installation

**Solution**:
```powershell
# 1. Restart PowerShell to reload PATH
exit
# Open new PowerShell window

# 2. Manually add to PATH (if still not working)
$env:PATH += ";${env:LOCALAPPDATA}\Programs\Microsoft VS Code\bin"

# 3. Verify
code --version

# 4. Reinstall with full integration
winget install --force Microsoft.VisualStudioCode --override '/VERYSILENT /SP- /MERGETASKS="addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath"'
```

---

## 🐍 Python Issues

### Python Not Found

**Problem**: `python` command not recognized

**Solution**:
```powershell
# 1. Check if Python is installed
winget list --id Python.Python.3.12

# 2. Install Python
winget install --id Python.Python.3.12 --silent --accept-package-agreements --accept-source-agreements

# 3. Restart PowerShell

# 4. Verify
python --version
pip --version
```

---

### Virtual Environment Activation Fails

**Problem**: Cannot activate Python virtual environment

**Solution**:
```powershell
# 1. Enable script execution (if not already done)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 2. Create virtual environment
python -m venv venv

# 3. Activate
.\venv\Scripts\Activate.ps1

# 4. If still fails, use full path
& "${PWD}\venv\Scripts\Activate.ps1"
```

---

## 🐳 Docker & WSL Issues

### WSL Not Available

**Problem**: `wsl` command not found or WSL not installed

**Solution**:
```powershell
# 1. Check if WSL is enabled
wsl --status

# 2. Install WSL
wsl --install

# 3. Restart computer (required)

# 4. Verify
wsl --list --verbose
```

---

### Docker Not Starting

**Problem**: Docker Desktop won't start or containers fail

**Solution**:
```powershell
# 1. Check Docker status
docker ps

# 2. Restart Docker Desktop
# - Right-click Docker icon in system tray
# - Select "Restart"

# 3. Check WSL integration (Docker Desktop)
# - Docker Desktop → Settings → Resources → WSL Integration
# - Enable integration with your distro

# 4. Alternative: Use Docker in WSL (no Docker Desktop)
# See docs/WSL_DOCKER.md for native Docker Engine setup
```

---

## 🔄 Update Issues

### Update Fails for Some Packages

**Problem**: `winget upgrade` fails for certain packages

**Solution**:
```powershell
# 1. Update packages individually
winget upgrade --id <PackageId> --silent --accept-package-agreements --accept-source-agreements

# 2. Skip failing packages
winget upgrade --all --accept-package-agreements --accept-source-agreements --include-unknown

# 3. Check specific package
winget show <PackageId>

# 4. Reinstall problematic package
winget install --id <PackageId> --force --silent --accept-package-agreements --accept-source-agreements
```

---

### VS Code Extensions Won't Update

**Problem**: Extensions fail to update or install

**Solution**:
```powershell
# 1. Update extensions manually
code --list-extensions | ForEach-Object { code --install-extension $_ --force }

# 2. Check VS Code version
code --version

# 3. Update VS Code
winget upgrade --id Microsoft.VisualStudioCode

# 4. Reinstall specific extension
code --uninstall-extension <extension-id>
code --install-extension <extension-id> --force
```

---

## 📝 PowerShell Profile Issues

### Profile Not Loading

**Problem**: Custom commands and shortcuts not available

**Solution**:
```powershell
# 1. Check if profile exists
Test-Path $PROFILE

# 2. View profile location
$PROFILE

# 3. Reload profile
. $PROFILE

# 4. Check for errors in profile
Test-Path $PROFILE
Get-Content $PROFILE

# 5. Reinstall profile
.\automation\Install-DevEnvironment.ps1 -SkipVSCodeExtensions
```

---

### Profile Commands Not Working

**Problem**: `gs`, `ll`, `sysinfo` commands not found

**Solution**:
```powershell
# 1. Verify profile is loaded
Test-Path Function:\gs

# 2. Reload profile
. $PROFILE

# 3. Check for profile errors
$Error[0]

# 4. Manually source profile
. "${env:USERPROFILE}\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
# or
. "${env:USERPROFILE}\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
```

---

## 🎨 Cursor IDE Issues

### Cursor CLI Not Found

**Problem**: `cursor` command not recognized

**Solution**:
```powershell
# 1. Reinstall with full integration
.\automation\Install-CursorIDE.ps1 -Force

# 2. Restart PowerShell

# 3. Check PATH
$env:PATH -split ';' | Select-String -Pattern "Cursor"

# 4. Manually add to PATH (if needed)
$env:PATH += ";${env:LOCALAPPDATA}\Programs\cursor\resources\app\bin"
```

---

### Beast Mode Not Available

**Problem**: Beast Mode chat mode not showing in Cursor

**Solution**:
1. Open Cursor
2. Go to Chat → "..." → "Configure Modes"
3. Select "Create new custom chat mode file"
4. Choose "User Data Folder"
5. Copy contents from `Beast Mode.chatmode.md`
6. Save as "Beast Mode 3.1 Enhanced"
7. Restart Cursor
8. Select "Beast Mode 3.1 Enhanced" from agent dropdown

---

## 🔍 General Troubleshooting Steps

### 1. Check Logs
```powershell
# View latest installation log
Get-ChildItem $env:TEMP -Filter "*DevEnv*.log" | Sort-Object CreationTime -Desc | Select-Object -First 1 | Get-Content

# View latest update log
Get-ChildItem $env:TEMP -Filter "*Update*.log" | Sort-Object CreationTime -Desc | Select-Object -First 1 | Get-Content

# View Cursor installation log
Get-ChildItem $env:TEMP -Filter "*Cursor*.log" | Sort-Object CreationTime -Desc | Select-Object -First 1 | Get-Content
```

### 2. Verify Installations
```powershell
# Check all installed packages
winget list

# Check specific tools
code --version
python --version
git --version
docker --version
wsl --version
```

### 3. Restart Services
```powershell
# Restart PowerShell (reload environment)
exit
# Open new PowerShell window

# Restart VS Code
# Close all VS Code windows and reopen

# Restart Docker
# Right-click Docker icon → Restart

# Restart WSL
wsl --shutdown
wsl
```

### 4. Clean Reinstall
```powershell
# Uninstall package
winget uninstall --id <PackageId>

# Reinstall
winget install --id <PackageId> --silent --accept-package-agreements --accept-source-agreements

# Or use automation scripts
.\automation\Install-DevEnvironment.ps1 -Force
```

---

## 📞 Getting Help

### Check Documentation
- [README](../README.md) - Main documentation
- [Command Reference](COMMANDS.md) - Common commands
- [WSL & Docker Guide](WSL_DOCKER.md) - Linux subsystem setup

### Review Logs
All operations are logged with timestamps:
- Installation: `%TEMP%\DevEnvInstall*.log`
- Updates: `%TEMP%\DevEnvUpdate*.log`
- Cursor: `%TEMP%\CursorIDE-Install*.log`

### System Information
```powershell
# Get comprehensive system info
sysinfo

# Check PowerShell version
$PSVersionTable

# Check Windows version
Get-ComputerInfo | Select-Object WindowsVersion, OsBuildNumber
```

---

## 🚨 Known Issues

### Issue: Wait-Job Timeout
**Symptom**: Installation shows "No input detected, continuing automatically..."
**Impact**: None - this is expected behavior for unattended operation
**Solution**: No action needed - installation continues normally

### Issue: Docker Desktop License
**Symptom**: Docker Desktop requires license for commercial use
**Impact**: May affect enterprise users
**Solution**: Use Docker Engine in WSL (see `docs/WSL_DOCKER.md`)

### Issue: VS Code Extension Conflicts
**Symptom**: Some extensions conflict with each other
**Impact**: May cause VS Code to behave unexpectedly
**Solution**: Disable conflicting extensions or use workspace-specific settings

---

**Still having issues? Check logs in `%TEMP%` or review the [.cursorrules](.cursorrules) for coding standards.**
