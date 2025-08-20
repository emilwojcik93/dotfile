# Install-DevEnvironment.ps1 - IaC Development Environment Setup
# Windows 11 PowerShell 5.x Compatible with WinUtil-style Admin Self-Elevation
# Infrastructure as Code approach with dynamic asset management

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
    Write-Host "Install-DevEnvironment needs to be run as Administrator. Attempting to relaunch..." -ForegroundColor Yellow
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
    } catch {
        $errorMsg = $_.Exception.Message
        Write-Error "Failed to elevate privileges: $errorMsg"
        exit 1
    }
    exit 0
}

# Script metadata
$scriptVersion = "1.1.0"
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

function Handle-Error {
    param([string]$ErrorMessage)
    Write-Log "ERROR: $ErrorMessage" -Level "ERROR"
    if (-not $Silent -and -not $Force) {
        Write-Log "Use -Force to continue despite errors" -Level "WARN"
        exit 1
    }
}

function Test-InternetConnection {
    try {
        [System.Net.Dns]::GetHostAddresses("github.com") | Out-Null
        return $true
    } catch {
        return $false
    }
}

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
        $result = winget install --id $PackageId --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
        if ($LASTEXITCODE -eq 0) {
            Write-Log "$PackageName installed successfully" -Level "SUCCESS"
            return $true
        } elseif ($LASTEXITCODE -eq -1978335189) {
            Write-Log "$PackageName already installed" -Level "INFO"
            return $true
        } else {
            Write-Log "Failed to install $PackageName (Exit code: $LASTEXITCODE)" -Level "WARN"
            return $Force
        }
    } catch {
        $errorMsg = $_.Exception.Message
        Handle-Error "Exception installing $PackageName - $errorMsg"
        return $Force
    }
}

function Test-WingetPackageInstalled {
    param([string]$PackageId)
    
    try {
        $result = winget list --id $PackageId --exact 2>$null
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
        
        $result = code --install-extension $ExtensionId --force 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Log "$ExtensionName extension installed successfully" -Level "SUCCESS"
            return $true
        } else {
            Write-Log "Failed to install $ExtensionName extension" -Level "WARN"
            return $Force
        }
    } catch {
        $errorMsg = $_.Exception.Message
        Handle-Error "Exception installing $ExtensionName extension - $errorMsg"
        return $Force
    }
}

function Install-PowerShellProfile {
    Write-Log "Installing PowerShell profile..." -Level "INFO"
    
    try {
        $profilePath = $PROFILE
        $profileDir = Split-Path $profilePath -Parent
        
        if (-not (Test-Path $profileDir)) {
            New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
        }
        
        $sourceProfile = Join-Path $PSScriptRoot "..\src\powershell\profile.ps1"
        if (Test-Path $sourceProfile) {
            Copy-Item -Path $sourceProfile -Destination $profilePath -Force
            Write-Log "PowerShell profile installed successfully" -Level "SUCCESS"
            return $true
        } else {
            Write-Log "Source profile not found: $sourceProfile" -Level "WARN"
            return $Force
        }
    } catch {
        $errorMsg = $_.Exception.Message
        Handle-Error "Exception installing PowerShell profile - $errorMsg"
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
        
        $sourceSettings = Join-Path $PSScriptRoot "..\configs\settings.json"
        $destSettings = Join-Path $vscodeSettingsDir "settings.json"
        
        if (Test-Path $sourceSettings) {
            Copy-Item -Path $sourceSettings -Destination $destSettings -Force
            Write-Log "VS Code settings installed successfully" -Level "SUCCESS"
        }
        
        $sourceBeastMode = Join-Path $PSScriptRoot "..\Beast Mode.chatmode.md"
        $destBeastMode = Join-Path $vscodePromptsDir "Beast Mode.chatmode.md"
        
        if (Test-Path $sourceBeastMode) {
            Copy-Item -Path $sourceBeastMode -Destination $destBeastMode -Force
            Write-Log "Beast Mode chatmode installed successfully" -Level "SUCCESS"
        }
        
        return $true
    } catch {
        $errorMsg = $_.Exception.Message
        Handle-Error "Exception installing VS Code settings - $errorMsg"
        return $Force
    }
}

function Start-Installation {
    Write-Log "=== $scriptName v$scriptVersion ===" -Level "INFO"
    Write-Log "Starting development environment installation..." -Level "INFO"
    
    Write-Log "Performing system validation..." -Level "INFO"
    
    if (-not (Test-InternetConnection)) {
        Write-Log "Internet connection test failed, continuing anyway..." -Level "WARN"
    } else {
        Write-Log "Internet connection verified" -Level "SUCCESS"
    }
    
    $sysInfo = Get-SystemInfo
    Write-Log "System: $($sysInfo.OSName) $($sysInfo.OSVersion)" -Level "INFO"
    Write-Log "PowerShell: $($sysInfo.PowerShellVersion)" -Level "INFO"
    Write-Log "RAM: $($sysInfo.TotalRAM) GB" -Level "INFO"
    
    try {
        winget --version | Out-Null
        Write-Log "Winget package manager available" -Level "SUCCESS"
    } catch {
        Handle-Error "Winget package manager not available. Please install App Installer from Microsoft Store."
        if (-not $Force) { exit 1 }
    }
    
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
    
    if (-not $SkipVSCodeExtensions) {
        Write-Log "Installing VS Code extensions..." -Level "INFO"
        Start-Sleep -Seconds 3
        
        $extensions = @(
            @{Id="ms-vscode.powershell"; Name="PowerShell"},
            @{Id="ms-python.python"; Name="Python"},
            @{Id="ms-vscode-remote.remote-wsl"; Name="WSL"},
            @{Id="ms-vscode-remote.remote-containers"; Name="Dev Containers"},
            @{Id="GitHub.copilot"; Name="GitHub Copilot"},
            @{Id="GitHub.copilot-chat"; Name="GitHub Copilot Chat"},
            @{Id="bradlc.vscode-tailwindcss"; Name="Tailwind CSS IntelliSense"},
            @{Id="esbenp.prettier-vscode"; Name="Prettier"},
            @{Id="ms-vscode.vscode-json"; Name="JSON"}
        )
        
        foreach ($extension in $extensions) {
            Install-VSCodeExtension $extension.Id $extension.Name | Out-Null
        }
    }
    
    if (-not $SkipPowerShellProfile) {
        Install-PowerShellProfile | Out-Null
    }
    
    Install-VSCodeSettings | Out-Null
    
    Write-Log "Checking WSL status..." -Level "INFO"
    try {
        wsl --version 2>$null | Out-Null
        Write-Log "WSL already installed" -Level "SUCCESS"
    } catch {
        Write-Log "WSL not installed. Run 'wsl --install' to install Ubuntu WSL" -Level "WARN"
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
        Write-Host "`nInstallation completed successfully! Press Enter to exit..." -ForegroundColor Green
        Read-Host
    }
}

try {
    Start-Installation
} catch {
    $errorMsg = $_.Exception.Message
    Write-Log "Unexpected error during installation: $errorMsg" -Level "ERROR"
    if (-not $Force) {
        exit 1
    }
}

exit 0
