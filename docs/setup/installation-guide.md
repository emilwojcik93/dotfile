# Setup Guide - Development Environment

## Prerequisites

### System Requirements
- **Windows 11** (Build 22000 or later)
- **PowerShell 5.x** (Pre-installed on Windows 11) 
- **8GB RAM minimum** (16GB recommended)
- **20GB free disk space** for all tools
- **Active internet connection** for downloads

### Required Software
- **App Installer (winget)**: Available from Microsoft Store
- **No Administrator privileges required**: Script will auto-elevate

## Pre-Installation Steps

### 1. Install App Installer (if needed)
If winget is not available, install "App Installer" from Microsoft Store:
```powershell
# Test winget availability
winget --version
```

### 2. Check System Resources
```powershell
# Check available disk space
Get-WmiObject -Class Win32_LogicalDisk | Select-Object DeviceID, @{Name="Size(GB)";Expression={[math]::Round(${_.Size}/1GB,2)}}, @{Name="FreeSpace(GB)";Expression={[math]::Round(${_.FreeSpace}/1GB,2)}}
```

## Installation Methods

### Method 1: Self-Elevating Installation (Recommended)
```powershell
# Clone repository
git clone https://github.com/emilwojcik93/dotfile.git
cd dotfile

# Run installation (will auto-elevate to Administrator)
.\automation\Install-DevEnvironment.ps1
```

**What happens:**
1. Script detects if running as Administrator
2. If not, automatically requests elevation with UAC prompt
3. Preserves all command-line parameters during elevation
4. Uses Windows Terminal if available, falls back to PowerShell
5. Continues installation in elevated context

### Method 2: Silent Installation (Unattended)
```powershell
# For automated deployment without any user interaction
.\automation\Install-DevEnvironment.ps1 -Silent
```

**Perfect for:**
- Automated deployment scripts
- Scheduled tasks
- Enterprise environments
- CI/CD pipelines

### Method 3: Custom Installation
```powershell
# Skip specific components
.\automation\Install-DevEnvironment.ps1 -SkipPython -SkipDocker

# Custom log location
.\automation\Install-DevEnvironment.ps1 -LogPath "C:\CustomLogs\install.log"

# Force installation even with validation errors
.\automation\Install-DevEnvironment.ps1 -Force

# Silent mode with custom options
.\automation\Install-DevEnvironment.ps1 -Silent -SkipVSCodeExtensions
```

## WinUtil-Style Self-Elevation

Our scripts use the same proven pattern as [ChrisTitusTech's WinUtil](https://github.com/ChrisTitusTech/winutil):

### Benefits
- **No Manual "Run as Administrator"**: Script handles elevation automatically
- **Parameter Preservation**: All command-line arguments maintained during elevation
- **Smart Terminal Detection**: Uses Windows Terminal when available
- **Unattended Mode**: Automatically adds `-Silent` for elevated sessions
- **Error Handling**: Graceful fallback if elevation fails

### How It Works
```powershell
# Detection
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    
    # Build argument list preserving parameters
    ${argList} = @()
    $PSBoundParameters.GetEnumerator() | ForEach-Object { ... }
    
    # Always add -Silent for elevated execution
    if (-not $PSBoundParameters.ContainsKey('Silent')) {
        ${argList} += "-Silent"
    }
    
    # Launch elevated session
    Start-Process ... -Verb RunAs -Wait
}
```

## Post-Installation Setup

### 1. Automatic Profile Loading
The installation automatically configures your PowerShell profile. Test it:

```powershell
# Test Beast Mode info
beast

# Test system information
sysinfo

# Test Git shortcuts
gs    # git status
```

### 2. Verify VS Code Integration
1. Open VS Code (automatically installed)
2. Check that extensions are installed
3. Open Chat sidebar (Ctrl+Shift+I)
4. Verify "Beast Mode" appears in agent dropdown

### 3. Configure Git (Manual Step)
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

## Beast Mode Setup (Automatic)

Beast Mode 3.1 Enhanced is automatically configured during installation:

### Automatic Configuration
- **File**: Installed to `%APPDATA%\Code\User\prompts\Beast Mode.chatmode.md`
- **VS Code Integration**: Available in Chat sidebar agent dropdown
- **Features**: All personas and enhanced research capabilities

### Test Beast Mode
1. Open VS Code
2. Open Chat sidebar (Ctrl+Shift+I)
3. Select "Beast Mode" from agent dropdown
4. Test with: "Help me create a React component with TypeScript"

## Environment Verification

### PowerShell Profile Features (Automatic)
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
beast     # Beast Mode information
sysinfo   # System information
```

### Docker Integration
```powershell
# Docker shortcuts (if Docker installed)
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

## Unattended Installation Advantages

### For Enterprise Environments
- **No Interactive Prompts**: Perfect for automated deployment
- **Comprehensive Logging**: Timestamped logs for auditing
- **Error Resilience**: Continues even if some components fail
- **Scheduled Execution**: Works with Windows Task Scheduler
- **Group Policy Compatible**: Can be deployed via GPO

### For Developers
- **One-Command Setup**: `.\automation\Install-DevEnvironment.ps1 -Silent`
- **Repeatable**: Same result every time
- **Fast**: No waiting for user input
- **Logged**: Full trace of what was installed

## Troubleshooting Installation

### Script Won't Start
**Issue**: PowerShell execution policy prevents script execution

**Solution**: Script automatically handles execution policy, but if needed:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### UAC Prompt Appears
**Expected Behavior**: This is normal - the script needs Administrator privileges

**What Happens**:
1. UAC prompt appears for elevation
2. Click "Yes" to allow elevation
3. Script continues automatically in elevated session
4. No further user interaction needed

### Installation Fails with Winget
**Issue**: App Installer not available

**Solutions**:
1. Install "App Installer" from Microsoft Store
2. Restart PowerShell
3. Verify: `winget --version`

### Installation Stalls
**Issue**: Interactive prompt in silent mode

**Solution**: This shouldn't happen with v1.1.0, but if it does:
- Use `-Force` parameter to bypass validation errors
- Check log file for specific error location

## Log Files and Debugging

### Automatic Logging
All installations create timestamped logs:
- **Location**: `%TEMP%\DevEnvInstall_YYYY-MM-DD_HH-mm-ss.log`
- **Content**: Full trace of installation steps
- **Format**: `[timestamp] [LEVEL] message`

### Reading Logs
```powershell
# View recent installation log
Get-Content "${env:TEMP}\DevEnvInstall_*.log" | Select-Object -Last 50

# Search for errors
Get-Content "${env:TEMP}\DevEnvInstall_*.log" | Select-String "ERROR"
```

## Maintenance and Updates

### Environment Updates (Self-Elevating)
```powershell
# Standard update with auto-elevation
.\automation\Update-Environment.ps1

# Silent update (unattended)
.\automation\Update-Environment.ps1 -Silent

# Selective updates
.\automation\Update-Environment.ps1 -Silent -UpdatePackages:$false
```

### Scheduled Updates
Create a Windows Task Scheduler task:
```powershell
# Task runs daily at 2 AM, silent mode
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File C:\path\to\dotfile\automation\Update-Environment.ps1 -Silent"
$trigger = New-ScheduledTaskTrigger -Daily -At "2:00 AM"
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount
Register-ScheduledTask -TaskName "DevEnvUpdate" -Action $action -Trigger $trigger -Principal $principal
```

## Next Steps

1. **Test All Features**: Run through all PowerShell shortcuts and VS Code integration
2. **Customize Settings**: Modify VS Code settings and PowerShell profile as needed
3. **Setup Projects**: Create development projects using the new environment
4. **Configure SSH**: Set up SSH keys for Git authentication
5. **Install Additional Tools**: Add project-specific dependencies

---

**Need Help?** Check the [troubleshooting guide](../troubleshooting/common-issues.md) for comprehensive solutions to common issues.
