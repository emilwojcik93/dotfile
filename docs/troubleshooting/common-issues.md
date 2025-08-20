# Troubleshooting Guide

Common issues and solutions for the development environment setup.

## 📚 Specialized Troubleshooting Guides

- **[Beast Mode Issues](beast-mode-issues.md)** - Complete Beast Mode 3.1 Enhanced troubleshooting
- **[Installation Fixes](installation-fixes.md)** - Environment setup and automation issues

## Installation Issues

### PowerShell Execution Policy Error

**Error:**
```
execution of scripts is disabled on this system
```

**Solution:**
```powershell
# Run as Administrator
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Winget Not Found

**Error:**
```
winget : The term 'winget' is not recognized
```

**Solutions:**
1. Install "App Installer" from Microsoft Store
2. Restart PowerShell terminal
3. Verify: `winget --version`

Alternative: Manual download from [Microsoft GitHub releases](https://github.com/microsoft/winget-cli/releases)

### Administrator Privileges Required

**Error:**
```
Administrator privileges required
```

**Solution:**
1. Right-click PowerShell icon
2. Select "Run as Administrator"
3. Re-run installation script

### Internet Connection Issues

**Error:**
```
Internet connection required for installation
```

**Solutions:**
1. Check network connectivity: `Test-NetConnection 8.8.8.8`
2. Verify DNS resolution: `nslookup github.com`
3. Check firewall/proxy settings
4. Retry installation

## VS Code Issues

### Extensions Not Installing

**Error:**
```
VS Code CLI not found in PATH
```

**Solutions:**
1. Verify VS Code installation: `code --version`
2. Restart terminal after VS Code installation
3. Add VS Code to PATH manually:
   ```powershell
   ${env:PATH} += ";${env:LOCALAPPDATA}\Programs\Microsoft VS Code\bin"
   ```
4. Re-run extension installation

### Beast Mode Not Available

**Issue:** Beast Mode doesn't appear in VS Code chat sidebar

**Solutions:**
1. Check file exists: `${env:APPDATA}\Code\User\prompts\Beast Mode.chatmode.md`
2. Restart VS Code completely
3. Verify GitHub Copilot Chat extension is installed and enabled
4. Check VS Code settings for system prompt configuration

### Settings Not Applied

**Issue:** VS Code settings from repository not loading

**Solutions:**
1. Check settings file location: `${env:APPDATA}\Code\User\settings.json`
2. Validate JSON syntax in settings file
3. Restart VS Code
4. Manually copy settings from `configs\vscode\settings.json`

## PowerShell Profile Issues

### Profile Not Loading

**Issue:** PowerShell shortcuts not available

**Solutions:**
1. Check profile path: `$PROFILE`
2. Verify file exists: `Test-Path $PROFILE`
3. Test loading manually: `. $PROFILE`
4. Check execution policy: `Get-ExecutionPolicy`

### Git Shortcuts Not Working

**Issue:** `gs`, `gp`, `gpl` commands not recognized

**Solutions:**
1. Verify Git installation: `git --version`
2. Check PATH includes Git: `${env:PATH}`
3. Restart terminal to load new profile
4. Manual Git PATH fix:
   ```powershell
   ${env:PATH} += ";C:\Program Files\Git\cmd"
   ```

## Package Installation Issues

### Python Installation Failed

**Error:**
```
Failed to install Python 3.12
```

**Solutions:**
1. Check if Python already installed: `python --version`
2. Manual installation from [python.org](https://python.org)
3. Skip Python in installation: `-SkipPython`
4. Check Windows version compatibility

### Docker Installation Issues

**Error:**
```
Docker Desktop installation failed
```

**Solutions:**
1. Enable Hyper-V and WSL2:
   ```powershell
   Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
   ```
2. Install WSL2 kernel update
3. Manual Docker Desktop installation
4. Skip Docker in installation: `-SkipDocker`

### Package Update Failures

**Error:**
```
Some packages may have failed to update
```

**Solutions:**
1. Run updates individually:
   ```powershell
   winget upgrade Microsoft.VisualStudioCode
   winget upgrade Git.Git
   ```
2. Clear winget cache:
   ```powershell
   winget source reset
   ```
3. Check available updates: `winget upgrade`

## WSL Issues

### WSL Installation Failed

**Error:**
```
WSL installation failed
```

**Solutions:**
1. Enable Windows Subsystem for Linux feature:
   ```powershell
   dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
   ```
2. Enable Virtual Machine Platform:
   ```powershell
   dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
   ```
3. Restart computer
4. Download WSL2 kernel update manually
5. Re-run: `wsl --install`

### Ubuntu Not Starting

**Issue:** `wsl` command shows no distributions

**Solutions:**
1. Install Ubuntu specifically: `wsl --install -d Ubuntu`
2. Check available distributions: `wsl --list --online`
3. Set WSL version: `wsl --set-default-version 2`

## System Performance Issues

### High Memory Usage During Installation

**Issue:** System becomes slow during installation

**Solutions:**
1. Close unnecessary applications
2. Run installation during off-hours
3. Install components separately with delays
4. Monitor system resources: `Get-Process | Sort-Object CPU -Descending`

### Disk Space Issues

**Error:**
```
Insufficient disk space
```

**Solutions:**
1. Check available space: `Get-WmiObject -Class Win32_LogicalDisk`
2. Clean temporary files: `cleanmgr`
3. Uninstall unused programs
4. Move files to external storage

## Configuration Issues

### PATH Environment Variable

**Issue:** Commands not found after installation

**Solutions:**
1. Check current PATH: `${env:PATH}`
2. Restart terminal/computer
3. Add paths manually:
   ```powershell
   ${env:PATH} += ";C:\Program Files\Git\cmd"
   ${env:PATH} += ";${env:LOCALAPPDATA}\Programs\Microsoft VS Code\bin"
   ```
4. Make permanent via System Properties → Environment Variables

### File Association Issues

**Issue:** Files don't open with correct applications

**Solutions:**
1. Set default applications in Windows Settings
2. Associate file types manually:
   ```powershell
   # Associate .ps1 files with VS Code
   cmd /c assoc .ps1=VSCode.ps1
   cmd /c ftype VSCode.ps1="\"${env:LOCALAPPDATA}\Programs\Microsoft VS Code\Code.exe\" \"%1\""
   ```

## Network and Firewall Issues

### Corporate Firewall/Proxy

**Issue:** Downloads fail due to corporate network restrictions

**Solutions:**
1. Configure proxy for winget:
   ```powershell
   winget settings --proxy http://proxy.company.com:8080
   ```
2. Set PowerShell proxy:
   ```powershell
   ${env:HTTPS_PROXY} = "http://proxy.company.com:8080"
   ```
3. Contact IT for application whitelisting
4. Use manual installers from corporate software catalog

### SSL Certificate Issues

**Error:**
```
SSL/TLS certificate verification failed
```

**Solutions:**
1. Update certificates: `certmgr.msc`
2. Bypass SSL (not recommended):
   ```powershell
   [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
   ```
3. Contact network administrator

## Logging and Diagnostics

### Enable Detailed Logging

Add verbose logging to troubleshoot issues:

```powershell
# Run with detailed logging
.\automation\Install-DevEnvironment.ps1 -LogPath "C:\Logs\detailed-install.log" -Verbose
```

### Check System Event Logs

```powershell
# Check application event log
Get-EventLog -LogName Application -Newest 50 | Where-Object {${_.EntryType} -eq "Error"}

# Check system event log  
Get-EventLog -LogName System -Newest 50 | Where-Object {${_.EntryType} -eq "Error"}
```

### Collect System Information

```powershell
# Generate system report
msinfo32 /report "C:\Temp\systeminfo.txt"

# PowerShell system info
Get-ComputerInfo | Out-File "C:\Temp\psinfo.txt"
```

## Recovery Options

### Reset Installation

If installation is completely broken:

1. **Uninstall Applications:**
   ```powershell
   winget uninstall Microsoft.VisualStudioCode
   winget uninstall Git.Git
   winget uninstall Python.Python.3.12
   ```

2. **Remove Configuration Files:**
   ```powershell
   Remove-Item "${env:APPDATA}\Code" -Recurse -Force
   Remove-Item $PROFILE -Force
   ```

3. **Clean Registry (Advanced):**
   Use Registry Editor to remove application entries (caution required)

4. **Fresh Installation:**
   ```powershell
   .\automation\Install-DevEnvironment.ps1 -Silent
   ```

## Getting Help

### Log File Locations
- Installation: `%TEMP%\DevEnvInstall.log`
- Updates: `%TEMP%\DevEnvUpdate.log`
- VS Code: `%APPDATA%\Code\logs`

### System Information Commands
```powershell
# PowerShell version
$PSVersionTable

# Installed packages
winget list

# VS Code extensions
code --list-extensions

# System info
sysinfo
```

### Support Resources
- **GitHub Issues**: Create issue with log files
- **VS Code Documentation**: https://code.visualstudio.com/docs
- **PowerShell Documentation**: https://docs.microsoft.com/powershell
- **Winget Documentation**: https://docs.microsoft.com/windows/package-manager

---

**Still having issues?** Include your log files and system information when seeking help.
