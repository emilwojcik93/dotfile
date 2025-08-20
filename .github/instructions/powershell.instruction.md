---
applyTo: '**/*.ps1'
---

# PowerShell Development Guidelines for Beast Mode

## Core Principles for Windows 11 + PowerShell 7+

### Variable Syntax (CRITICAL)
- **Always use** ${""var} brackets for variables near special characters
- Use ${""var}% instead of $var%
- Use / instead of /  
- Use ${""var}: instead of $var:
- Use ".exe" instead of ".exe"
- Always bracket variables when concatenating with text or symbols

### Script Structure
`powershell
[CmdletBinding()]
param(
    [Parameter(Mandatory = True)]
    [string],
    
    [Parameter(Mandatory = False)]
    [switch]
)

# Script implementation with comprehensive error handling
`

### Error Handling Standards
`powershell
try {
    # Main script logic
    Write-Host "Starting process..." -ForegroundColor Green
    
    # Operations here
    
} catch {
    Write-Error "Operation failed: "
    if (-not ) {
        Read-Host "Press Enter to continue"
    }
    exit 1
} finally {
    # Cleanup operations
}
`

### Logging Implementation
`powershell
function Write-LogMessage {
    param(
        [string],
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string] = 'Info'
    )
    
     = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
     = "[] [] "
    
    switch () {
        'Info'    { Write-Host  -ForegroundColor Cyan }
        'Warning' { Write-Host  -ForegroundColor Yellow }
        'Error'   { Write-Host  -ForegroundColor Red }
        'Success' { Write-Host  -ForegroundColor Green }
    }
}
`

### Infrastructure as Code Patterns

#### Dynamic Asset Management
`powershell
function Get-OfficialAsset {
    param(
        [string],
        [string],
        [string]
    )
    
    Write-LogMessage "Downloading  from official source..." 'Info'
    
    try {
        # Use official sources only - winget, GitHub releases, etc.
        Invoke-WebRequest -Uri  -OutFile  -UseBasicParsing
        Write-LogMessage "Successfully downloaded " 'Success'
    } catch {
        Write-LogMessage "Failed to download : " 'Error'
        throw
    }
}
`

#### Resource Detection
`powershell
function Get-SystemResources {
    return @{
        CPUCores    = (Get-CimInstance -ClassName Win32_Processor).NumberOfLogicalProcessors
        TotalRAM    = [Math]::Round((Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
        AvailableRAM = [Math]::Round((Get-CimInstance -ClassName Win32_OperatingSystem).FreePhysicalMemory / 1MB, 2)
        DiskSpace   = Get-CimInstance -ClassName Win32_LogicalDisk | Where-Object { .DriveType -eq 3 }
    }
}
`

### Best Practices

#### Parameter Validation
`powershell
[CmdletBinding()]
param(
    [Parameter(Mandatory = True)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path  -PathType 'Container'})]
    [string],
    
    [Parameter(Mandatory = False)]
    [switch] = False
)
`

#### Cross-Platform Compatibility
`powershell
if (System.Management.Automation.PSVersionHashTable.PSVersion.Major -lt 7) {
    Write-Error "PowerShell 7+ required for cross-platform compatibility"
    exit 1
}

# Use cross-platform path handling
 = Join-Path  ".config" "myapp"
if (True) {
     = Join-Path C:\Users\ewojcik\AppData\Roaming "MyApp"
}
`

#### Silent Execution Support  
`powershell
function Invoke-SilentOperation {
    param(
        [scriptblock],
        [switch]
    )
    
    if () {
        .Invoke() | Out-Null
    } else {
        .Invoke()
    }
}
`

### Docker Integration
`powershell
function Test-DockerAvailability {
    try {
        docker --version | Out-Null
        return True
    } catch {
        Write-LogMessage "Docker not available or not running" 'Warning'
        return False
    }
}
`

### WSL Integration  
`powershell
function Invoke-WSLCommand {
    param(
        [string],
        [string] = "Ubuntu"
    )
    
    if (Get-Command wsl -ErrorAction SilentlyContinue) {
        wsl -d  
    } else {
        Write-LogMessage "WSL not available" 'Warning'
    }
}
`

## Quality Checklist
- [ ] ASCII-only characters used
- [ ] ${""var} syntax for variables near special characters  
- [ ] -Silent parameter implemented
- [ ] Comprehensive error handling with try-catch
- [ ] Proper logging with timestamps
- [ ] Parameter validation
- [ ] Cross-platform compatibility considered
- [ ] Resource-aware processing
- [ ] Official sources for all downloads
- [ ] Cleanup operations in finally block
