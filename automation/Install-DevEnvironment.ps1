<#
.SYNOPSIS
    Sets up the development environment for Windows 11 using Infrastructure as Code principles.
.DESCRIPTION
    Installs and configures development tools, VS Code extensions, PowerShell profile, and settings.
    Uses Infrastructure as Code approach with dynamic asset management and conditional installation.
    Compatible with PowerShell 5.1+ (default Windows PowerShell) and PowerShell 7.x

    PROMPT NOTICE:
    Any prompt requiring user input will automatically continue/exit after 10 seconds if no input is provided. This ensures automation and prevents blocking.
.PARAMETER Silent
    Run in silent mode without user interaction
.PARAMETER LogPath
    Path for log file output
.PARAMETER SkipVSCodeExtensions
    Skip VS Code extension installation
.PARAMETER SkipPowerShellProfile
    Skip PowerShell profile installation
.PARAMETER SkipPython
    Skip Python-related installations
.PARAMETER SkipDocker
    Skip Docker Desktop installation
.PARAMETER Force
    Continue despite errors
.EXAMPLE
    .\Install-DevEnvironment.ps1
    Run with default settings
.EXAMPLE
    .\Install-DevEnvironment.ps1 -Silent -SkipPython
    Run silently without Python components
.NOTES
    Author: Emil Wójcik
    Version: 1.2.0
    Requires: PowerShell 5.1+, Administrator privileges
#>

[CmdletBinding()]
param(
    [switch]$Silent = $false,
    [string]$LogPath = "$env:TEMP\DevEnvInstall.log",
    [switch]$SkipVSCodeExtensions = $false,
    [switch]$SkipPowerShellProfile = $false,
    [switch]$SkipPython = $false,
    [switch]$SkipDocker = $false,
    [switch]$Force = $false
)

# WinUtil-style Admin Self-Elevation
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host 'Install-DevEnvironment needs to be run as Administrator. Attempting to relaunch...' -ForegroundColor Yellow
    $argList = @()

    $PSBoundParameters.GetEnumerator() | ForEach-Object {
        $argList += if ($_.Value -is [switch] -and $_.Value) {
            "-$($_.Key)"
        } elseif ($_.Value -is [array]) {
            "-$($_.Key) $($_.Value -join ',')"
        } elseif ($_.Value) {
            "-$($_.Key) '$($_.Value)'"
        }
    }

    $script = "& { & '$PSCommandPath' $($argList -join ' ') }"
    $powershellCmd = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell" }
    $processCmd = if (Get-Command wt.exe -ErrorAction SilentlyContinue) { "wt.exe" } else { "$powershellCmd" }

    try {
        if ($processCmd -eq "wt.exe") {
            Start-Process $processCmd -ArgumentList "$powershellCmd -ExecutionPolicy Bypass -NoProfile -Command `"$script`"" -Verb RunAs -Wait
        } else {
            Start-Process $processCmd -ArgumentList "-ExecutionPolicy Bypass -NoProfile -Command `"$script`"" -Verb RunAs -Wait
        }
        Write-Host 'Script relaunched with administrator privileges.' -ForegroundColor Green
        exit 0
    } catch {
        $errorMsg = $_.Exception.Message
        Write-Error "Failed to elevate privileges: $errorMsg"
        exit 1
    }
    exit 0
}

# Script metadata
$scriptVersion = "1.2.0"
$scriptName = "Install-DevEnvironment"

# Initialize logging
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARN" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
    }
    
    try {
        Add-Content -Path $LogPath -Value $logEntry -ErrorAction SilentlyContinue
    } catch {
        # Ignore logging errors
    }
}

function Write-Error {
    param([string]$ErrorMessage)
    Write-Log "ERROR: $ErrorMessage" -Level "ERROR"
    if (-not $Silent -and -not $Force) {
        Write-Log "Use -Force to continue despite errors" -Level "WARN"
        exit 1
    }
}

# =============================================================================
# VALIDATION FUNCTIONS - PowerShell Best Practices for Script Validation
# =============================================================================

function Test-InternetConnection {
    <#
    .SYNOPSIS
        Tests internet connectivity by resolving DNS and attempting connection
    .DESCRIPTION
        Uses multiple validation methods to ensure reliable internet connectivity
    #>
    try {
        # Test DNS resolution
        [System.Net.Dns]::GetHostAddresses("github.com") | Out-Null
        
        # Test HTTP connectivity with timeout
        $webRequest = [System.Net.WebRequest]::Create("https://github.com")
        $webRequest.Timeout = 5000
        $response = $webRequest.GetResponse()
        $response.Close()
        
        return $true
    } catch {
        Write-Log "Internet connectivity test failed: $($_.Exception.Message)" -Level "WARN"
        return $false
    }
}

function Test-AdminPrivileges {
    <#
    .SYNOPSIS
        Validates if current session has administrator privileges
    .DESCRIPTION
        Uses Windows Principal to check for admin rights
    #>
    return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-PowerShellVersion {
    <#
    .SYNOPSIS
        Validates PowerShell version meets minimum requirements
    .DESCRIPTION
        Ensures PowerShell 5.1+ compatibility
    #>
    $minVersion = [version]"5.1.0.0"
    $currentVersion = $PSVersionTable.PSVersion
    
    if ($currentVersion -ge $minVersion) {
        Write-Log "PowerShell version check passed: $currentVersion" -Level "INFO"
        return $true
    } else {
        Write-Log "PowerShell version $currentVersion is below minimum required $minVersion" -Level "ERROR"
        return $false
    }
}

function Test-ToolAvailability {
    <#
    .SYNOPSIS
        Tests if a command/tool is available in the system
    .DESCRIPTION
        Uses Get-Command with comprehensive error handling
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ToolName,
        
        [Parameter(Mandatory=$false)]
        [string[]]$AlternativeNames = @()
    )
    
    # Test primary tool name
    if (Get-Command $ToolName -ErrorAction SilentlyContinue) {
        return $true
    }
    
    # Test alternative names
    foreach ($altName in $AlternativeNames) {
        if (Get-Command $altName -ErrorAction SilentlyContinue) {
            return $true
        }
    }
    
    return $false
}

function Test-PathValid {
    <#
    .SYNOPSIS
        Advanced path validation using Test-Path with enhanced checking
    .DESCRIPTION
        Validates paths with type checking, permissions, and accessibility
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("Any", "Container", "Leaf")]
        [string]$PathType = "Any",
        
        [Parameter(Mandatory=$false)]
        [switch]$CheckWriteAccess
    )
    
    # Basic path existence check
    if (-not (Test-Path $Path)) {
        return $false
    }
    
    # Type-specific validation
    if ($PathType -eq "Container" -and -not (Test-Path $Path -PathType Container)) {
        return $false
    } elseif ($PathType -eq "Leaf" -and -not (Test-Path $Path -PathType Leaf)) {
        return $false
    }
    
    # Write access check if requested
    if ($CheckWriteAccess) {
        try {
            $testFile = Join-Path $Path "test_write_$(Get-Random).tmp"
            New-Item -Path $testFile -ItemType File -Force | Out-Null
            Remove-Item $testFile -Force
            return $true
        } catch {
            Write-Log "Path $Path exists but is not writable" -Level "WARN"
            return $false
        }
    }
    
    return $true
}

function Get-SystemCapabilities {
    <#
    .SYNOPSIS
        Detects system capabilities and available tools
    .DESCRIPTION
        Returns a hashtable of system capabilities for conditional installations
    #>
    $capabilities = @{
        PowerShell = Test-ToolAvailability "powershell" @("pwsh")
        Python = Test-ToolAvailability "python" @("python3", "py")
        Node = Test-ToolAvailability "node" @("nodejs")
        Git = Test-ToolAvailability "git"
        Docker = Test-ToolAvailability "docker"
        WSL = $false
        VSCode = Test-ToolAvailability "code"
        WindowsTerminal = Test-ToolAvailability "wt"
    }
    
    # Special WSL detection
    try {
        $wslOutput = wsl --list --quiet 2>$null
        $capabilities.WSL = ($LASTEXITCODE -eq 0) -and $wslOutput
    } catch {
        $capabilities.WSL = $false
    }
    
    Write-Log "System capabilities detected: $(($capabilities.GetEnumerator() | Where-Object {$_.Value} | ForEach-Object {$_.Key}) -join ', ')" -Level "INFO"
    return $capabilities
}

# =============================================================================
# INSTALLATION FUNCTIONS
# =============================================================================

function Get-SystemInfo {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $cpu = Get-CimInstance -ClassName Win32_Processor
    $memory = Get-CimInstance -ClassName Win32_ComputerSystem
    
    return @{
        OSName = $os.Caption
        OSVersion = $os.Version
        CPUName = $cpu.Name
        TotalRAM = [Math]::Round($memory.TotalPhysicalMemory / 1GB, 2)
        PowerShellVersion = $PSVersionTable.PSVersion
    }
}

function Install-WingetPackage {
    param(
        [string]$PackageId,
        [string]$PackageName
    )
    
    Write-Log "Installing $PackageName..." -Level "INFO"
    
    try {
        winget install --id $PackageId --silent --accept-package-agreements --accept-source-agreements --disable-interactivity | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Log "$PackageName installed successfully" -Level "SUCCESS"
            return $true
        } else {
            Write-Log "Failed to install $PackageName (Exit code: $LASTEXITCODE)" -Level "WARN"
            return $Force
        }
    } catch {
        $errorMsg = $_.Exception.Message
        Write-Error "Exception installing $PackageName - $errorMsg"
        return $Force
    }
}

function Test-WingetPackageInstalled {
    param([string]$PackageId)
    
    try {
        winget list --id $PackageId --exact 2>$null | Out-Null
        return $LASTEXITCODE -eq 0
    } catch {
        return $false
    }
}

function Install-VSCodeExtension {
    param(
        [string]$ExtensionId,
        [string]$ExtensionName
    )
    
    Write-Log "Installing VS Code extension: $ExtensionName..." -Level "INFO"
    
    try {
        $codePath = Get-Command code -ErrorAction SilentlyContinue
        if (-not $codePath) {
            Write-Log "VS Code CLI not found in PATH, skipping extension installation" -Level "WARN"
            return $Force
        }
        
        code --install-extension $ExtensionId --force 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Log "$ExtensionName extension installed successfully" -Level "SUCCESS"
            return $true
        } else {
            Write-Log "Failed to install $ExtensionName extension" -Level "WARN"
            return $Force
        }
    } catch {
        $errorMsg = $_.Exception.Message
        Write-Error "Exception installing $ExtensionName extension - $errorMsg"
        return $Force
    }
}

function Install-PowerShellProfile {
    Write-Log "Installing PowerShell profile..." -Level "INFO"
    
    try {
        $profilePath = $PROFILE
        $sourceProfile = Join-Path $PSScriptRoot "..\src\powershell\profile.ps1"
        
        if (Test-Path $sourceProfile) {
            $profileDir = Split-Path $profilePath -Parent
            if (-not (Test-Path $profileDir)) {
                New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
            }
            
            Copy-Item -Path $sourceProfile -Destination $profilePath -Force
            Write-Log "PowerShell profile installed successfully" -Level "SUCCESS"
            return $true
        } else {
            Write-Log "Source PowerShell profile not found: $sourceProfile" -Level "WARN"
            return $Force
        }
    } catch {
        $errorMsg = $_.Exception.Message
        Write-Error "Exception installing PowerShell profile - $errorMsg"
        return $Force
    }
}

function Install-VSCodeSettings {
    Write-Log "Installing VS Code settings..." -Level "INFO"
    
    try {
        $vscodeSettingsDir = "$env:APPDATA\Code\User"
        $vscodePromptsDir = "$vscodeSettingsDir\prompts"
        
        if (-not (Test-Path $vscodeSettingsDir)) {
            New-Item -ItemType Directory -Path $vscodeSettingsDir -Force | Out-Null
        }
        
        if (-not (Test-Path $vscodePromptsDir)) {
            New-Item -ItemType Directory -Path $vscodePromptsDir -Force | Out-Null
        }
        
        # Install settings.json
        $sourceSettings = Join-Path $PSScriptRoot "..\configs\settings.json"
        $destSettings = Join-Path $vscodeSettingsDir "settings.json"
        
        if (Test-Path $sourceSettings) {
            Copy-Item -Path $sourceSettings -Destination $destSettings -Force
            Write-Log "VS Code settings installed" -Level "SUCCESS"
        } else {
            Write-Log "Source settings.json not found: $sourceSettings" -Level "WARN"
        }
        
        # Install Beast Mode chatmode
        $sourceBeastMode = Join-Path $PSScriptRoot "..\Beast Mode.chatmode.md"
        $destBeastMode = Join-Path $vscodePromptsDir "Beast Mode.chatmode.md"
        
        if (Test-Path $sourceBeastMode) {
            Copy-Item -Path $sourceBeastMode -Destination $destBeastMode -Force
            Write-Log "Beast Mode chatmode installed" -Level "SUCCESS"
        } else {
            Write-Log "Source Beast Mode file not found: $sourceBeastMode" -Level "WARN"
        }
        
        return $true
    } catch {
        $errorMsg = $_.Exception.Message
        Write-Error "Exception installing VS Code settings - $errorMsg"
        return $Force
    }
}

function Start-Installation {
    Write-Log "=== $scriptName v$scriptVersion ===" -Level "INFO"
    Write-Log "Starting development environment installation..." -Level "INFO"
    
    # =============================================================================
    # COMPREHENSIVE SYSTEM VALIDATION
    # =============================================================================
    Write-Log "Performing comprehensive system validation..." -Level "INFO"
    
    # Validate PowerShell version
    if (-not (Test-PowerShellVersion)) {
        Write-Error "PowerShell version validation failed"
        if (-not $Force) { exit 1 }
    }
    
    # Validate administrator privileges
    if (-not (Test-AdminPrivileges)) {
        Write-Error "Administrator privileges validation failed"
        if (-not $Force) { exit 1 }
    } else {
        Write-Log "Administrator privileges validated" -Level "SUCCESS"
    }
    
    # Test internet connectivity with enhanced validation
    if (-not (Test-InternetConnection)) {
        Write-Log "Internet connection test failed, some installations may fail" -Level "WARN"
        if (-not $Force -and -not $Silent) {
            $promptJob = Start-Job { Read-Host "Continue without internet connectivity? (y/N)" }
            $jobResult = Wait-Job $promptJob -Timeout 10
            if ($null -eq $jobResult) {
                Write-Host "No input detected, continuing automatically..." -ForegroundColor Yellow
                Stop-Job $promptJob | Out-Null
            } else {
                $response = Receive-Job $promptJob
                if ($response -ne "y" -and $response -ne "Y") {
                    Remove-Job $promptJob | Out-Null
                    exit 1
                }
            }
            Remove-Job $promptJob | Out-Null
        }
    } else {
        Write-Log "Internet connectivity validated" -Level "SUCCESS"
    }
    
    # Validate required paths and permissions
    $tempPath = $env:TEMP
    if (-not (Test-PathValid $tempPath -PathType "Container" -CheckWriteAccess)) {
        Write-Error "Temporary directory validation failed: $tempPath"
        if (-not $Force) { exit 1 }
    } else {
        Write-Log "Temporary directory validated: $tempPath" -Level "SUCCESS"
    }
    
    # Get detailed system information
    $sysInfo = Get-SystemInfo
    Write-Log "System Information:" -Level "INFO"
    Write-Log "  OS: $($sysInfo.OSName) $($sysInfo.OSVersion)" -Level "INFO"
    Write-Log "  PowerShell: $($sysInfo.PowerShellVersion)" -Level "INFO"
    Write-Log "  RAM: $($sysInfo.TotalRAM) GB" -Level "INFO"
    Write-Log "  CPU: $($sysInfo.CPUName)" -Level "INFO"
    
    # Validate package manager availability
    try {
        $wingetVersion = winget --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Winget package manager validated: $wingetVersion" -Level "SUCCESS"
        } else {
            throw "Winget validation failed"
        }
    } catch {
        Write-Error "Winget package manager not available. Please install App Installer from Microsoft Store."
        if (-not $Force) { exit 1 }
    }
    
    # =============================================================================
    # PACKAGE INSTALLATION
    # =============================================================================
    Write-Log "Installing core applications..." -Level "INFO"

    $packages = @(
        @{Id="Microsoft.VisualStudioCode"; Name="Visual Studio Code"},
        @{Id="Git.Git"; Name="Git"},
        @{Id="Microsoft.PowerShell"; Name="PowerShell 7+"}
    )

    if (-not $SkipPython) {
        $packages += @{Id="Python.Python.3.12"; Name="Python 3.12"}
    }

    if (-not $SkipDocker) {
        $packages += @{Id="Docker.DockerDesktop"; Name="Docker Desktop"}
    }

    foreach ($package in $packages) {
        if (-not (Test-WingetPackageInstalled $package.Id)) {
            Install-WingetPackage $package.Id $package.Name | Out-Null
        } else {
            Write-Log "$($package.Name) already installed" -Level "INFO"
        }
    }
    
    # =============================================================================
    # CONDITIONAL VS CODE EXTENSION INSTALLATION
    # =============================================================================
    if (-not $SkipVSCodeExtensions) {
        Write-Log "Installing VS Code extensions..." -Level "INFO"
        Start-Sleep -Seconds 3
        
        # Get system capabilities for conditional extension installation
        $systemCaps = Get-SystemCapabilities
        
        # Core extensions - always install
        $extensions = @(
            @{Id="GitHub.copilot"; Name="GitHub Copilot"; Required=$true; Condition=$true},
            @{Id="GitHub.copilot-chat"; Name="GitHub Copilot Chat"; Required=$true; Condition=$true},
            @{Id="esbenp.prettier-vscode"; Name="Prettier - Code formatter"; Required=$true; Condition=$true},
            @{Id="zainchen.json"; Name="JSON"; Required=$true; Condition=$true},
            @{Id="xyz.local-history"; Name="Local History"; Required=$true; Condition=$true}
        )
        
        # Conditional extensions based on detected capabilities
        if ($systemCaps.PowerShell) {
            $extensions += @{Id="ms-vscode.powershell"; Name="PowerShell"; Required=$false; Condition=$true}
            Write-Log "PowerShell detected - adding PowerShell extension" -Level "INFO"
        }
        
        if ($systemCaps.Python -and -not $SkipPython) {
            $extensions += @{Id="ms-python.python"; Name="Python"; Required=$false; Condition=$true}
            Write-Log "Python detected - adding Python extensions" -Level "INFO"
        }
        
        if ($systemCaps.WSL) {
            $extensions += @{Id="ms-vscode-remote.remote-wsl"; Name="WSL"; Required=$false; Condition=$true}
            Write-Log "WSL detected - adding WSL extension" -Level "INFO"
        }
        
        if ($systemCaps.Docker -and -not $SkipDocker) {
            $extensions += @{Id="ms-vscode-remote.remote-containers"; Name="Dev Containers"; Required=$false; Condition=$true}
            $extensions += @{Id="ms-azuretools.vscode-docker"; Name="Docker"; Required=$false; Condition=$true}
            Write-Log "Docker detected - adding Docker extensions" -Level "INFO"
        }
        
        if ($systemCaps.Git) {
            $extensions += @{Id="eamodio.gitlens"; Name="GitLens"; Required=$false; Condition=$true}
            Write-Log "Git detected - adding GitLens extension" -Level "INFO"
        }
        
        if ($systemCaps.Node) {
            $extensions += @{Id="bradlc.vscode-tailwindcss"; Name="Tailwind CSS IntelliSense"; Required=$false; Condition=$true}
            Write-Log "Node.js detected - adding web development extensions" -Level "INFO"
        }
        
        # Install extensions
        foreach ($extension in $extensions) {
            if ($extension.Condition) {
                $result = Install-VSCodeExtension $extension.Id $extension.Name
                if (-not $result -and $extension.Required) {
                    Write-Log "Required extension $($extension.Name) failed to install" -Level "ERROR"
                    if (-not $Force) {
                        Write-Error "Required VS Code extension installation failed"
                    }
                }
            }
        }
    }

    if (-not $SkipPowerShellProfile) {
        Install-PowerShellProfile | Out-Null
    }

    Install-VSCodeSettings | Out-Null

    Write-Log "Checking WSL status..." -Level "INFO"
    $wslCapability = Get-SystemCapabilities
    if ($wslCapability.WSL) {
        Write-Log "WSL already installed and configured" -Level "SUCCESS"
    } else {
        Write-Log "WSL not detected. Install with: wsl --install" -Level "INFO"
    }

    Write-Log "=== Installation Complete ===" -Level "SUCCESS"
    Write-Log "Development environment setup finished!" -Level "SUCCESS"
    Write-Log "" -Level "INFO"
    Write-Log "Next steps:" -Level "INFO"
    Write-Log "1. Restart your terminal or run: . `$PROFILE" -Level "INFO"
    Write-Log "2. Open VS Code and check extensions are loaded" -Level "INFO"
    Write-Log "3. Type 'beast' in PowerShell to see Beast Mode information" -Level "INFO"
    Write-Log "4. Install WSL if not already installed: wsl --install" -Level "INFO"
    Write-Log "" -Level "INFO"
    Write-Log "Log file: $LogPath" -Level "INFO"
    
    if (-not $Silent) {
        Write-Host "`nInstallation completed successfully! Press Enter to exit (auto-continues in 10 seconds)..." -ForegroundColor Green
        $promptJob = Start-Job { Read-Host }
        $jobResult = Wait-Job $promptJob -Timeout 10
        if ($null -eq $jobResult) {
            Write-Host "No input detected, continuing automatically..." -ForegroundColor Yellow
            Stop-Job $promptJob | Out-Null
        } else {
            Receive-Job $promptJob | Out-Null
        }
        Remove-Job $promptJob | Out-Null
    }
}

try {
    Start-Installation
} catch {
    $errorMsg = $_.Exception.Message
    Write-Log "Unexpected error during installation: $errorMsg" -Level "ERROR"
    if (-not $Force) {
        Write-Log "Use -Force parameter to continue despite errors" -Level "WARN"
        exit 1
    }
}
