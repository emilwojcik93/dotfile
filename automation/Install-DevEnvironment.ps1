# Install-DevEnvironment.ps1 - IaC Development Environment Setup
# Windows 11 PowerShell 5.x Compatible
# Infrastructure as Code approach with dynamic asset management

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [switch]${Silent} = $false,
    
    [Parameter(Mandatory=$false)]
    [string]${LogPath} = "${env:TEMP}\DevEnvInstall.log",
    
    [Parameter(Mandatory=$false)]
    [switch]${SkipVSCodeExtensions} = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]${SkipPowerShellProfile} = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]${SkipPython} = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]${SkipDocker} = $false
)

# Script metadata
${scriptVersion} = "1.0.0"
${scriptName} = "Install-DevEnvironment"

# Initialize logging
function Write-Log {
    param(
        [Parameter(Mandatory=$true)]
        [string]${Message},
        [Parameter(Mandatory=$false)]
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]${Level} = "INFO"
    )
    
    ${timestamp} = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    ${logEntry} = "[${timestamp}] [${Level}] ${Message}"
    
    # Write to console with color
    switch (${Level}) {
        "INFO" { Write-Host ${logEntry} -ForegroundColor White }
        "WARN" { Write-Host ${logEntry} -ForegroundColor Yellow }
        "ERROR" { Write-Host ${logEntry} -ForegroundColor Red }
        "SUCCESS" { Write-Host ${logEntry} -ForegroundColor Green }
    }
    
    # Write to log file
    Add-Content -Path ${LogPath} -Value ${logEntry} -ErrorAction SilentlyContinue
}

# Error handling
function Handle-Error {
    param([string]${ErrorMessage})
    Write-Log "ERROR: ${ErrorMessage}" -Level "ERROR"
    if (-not ${Silent}) {
        Read-Host "Press Enter to continue or Ctrl+C to exit"
    }
}

# System validation
function Test-AdminPrivileges {
    ${currentUser} = [Security.Principal.WindowsIdentity]::GetCurrent()
    ${principal} = New-Object Security.Principal.WindowsPrincipal(${currentUser})
    return ${principal}.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-InternetConnection {
    try {
        ${result} = Test-NetConnection -ComputerName "8.8.8.8" -Port 53 -InformationLevel Quiet
        return ${result}
    } catch {
        return $false
    }
}

function Get-SystemInfo {
    ${os} = Get-CimInstance -ClassName Win32_OperatingSystem
    ${cpu} = Get-CimInstance -ClassName Win32_Processor  
    ${memory} = Get-CimInstance -ClassName Win32_ComputerSystem
    
    return @{
        OSName = ${os}.Caption
        OSVersion = ${os}.Version
        CPUName = ${cpu}.Name
        TotalRAM = [Math]::Round(${memory}.TotalPhysicalMemory / 1GB, 2)
        PowerShellVersion = $PSVersionTable.PSVersion
    }
}

# Winget operations
function Install-WingetPackage {
    param(
        [Parameter(Mandatory=$true)]
        [string]${PackageId},
        [Parameter(Mandatory=$true)]
        [string]${PackageName}
    )
    
    Write-Log "Installing ${PackageName}..." -Level "INFO"
    
    try {
        ${result} = winget install --id ${PackageId} --silent --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -eq 0) {
            Write-Log "${PackageName} installed successfully" -Level "SUCCESS"
            return $true
        } else {
            Write-Log "Failed to install ${PackageName} (Exit code: $LASTEXITCODE)" -Level "WARN"
            return $false
        }
    } catch {
        Handle-Error "Exception installing ${PackageName}: ${_.Exception.Message}"
        return $false
    }
}

function Test-WingetPackageInstalled {
    param([string]${PackageId})
    
    try {
        ${result} = winget list --id ${PackageId} --exact 2>$null
        return $LASTEXITCODE -eq 0
    } catch {
        return $false
    }
}

# VS Code extension management
function Install-VSCodeExtension {
    param(
        [Parameter(Mandatory=$true)]
        [string]${ExtensionId},
        [Parameter(Mandatory=$true)]
        [string]${ExtensionName}
    )
    
    Write-Log "Installing VS Code extension: ${ExtensionName}..." -Level "INFO"
    
    try {
        ${codePath} = Get-Command code -ErrorAction SilentlyContinue
        if (-not ${codePath}) {
            Write-Log "VS Code CLI not found in PATH" -Level "WARN"
            return $false
        }
        
        ${result} = code --install-extension ${ExtensionId} --force
        if ($LASTEXITCODE -eq 0) {
            Write-Log "${ExtensionName} extension installed successfully" -Level "SUCCESS"
            return $true
        } else {
            Write-Log "Failed to install ${ExtensionName} extension" -Level "WARN"
            return $false
        }
    } catch {
        Handle-Error "Exception installing ${ExtensionName} extension: ${_.Exception.Message}"
        return $false
    }
}

# PowerShell profile installation
function Install-PowerShellProfile {
    Write-Log "Installing PowerShell profile..." -Level "INFO"
    
    try {
        ${profilePath} = $PROFILE
        ${profileDir} = Split-Path ${profilePath} -Parent
        
        # Create profile directory if it doesn't exist
        if (-not (Test-Path ${profileDir})) {
            New-Item -ItemType Directory -Path ${profileDir} -Force | Out-Null
        }
        
        # Copy profile from repository
        ${sourceProfile} = Join-Path $PSScriptRoot "src\powershell\profile.ps1"
        if (Test-Path ${sourceProfile}) {
            Copy-Item -Path ${sourceProfile} -Destination ${profilePath} -Force
            Write-Log "PowerShell profile installed successfully" -Level "SUCCESS"
            return $true
        } else {
            Write-Log "Source profile not found: ${sourceProfile}" -Level "WARN"
            return $false
        }
    } catch {
        Handle-Error "Exception installing PowerShell profile: ${_.Exception.Message}"
        return $false
    }
}

# VS Code settings installation
function Install-VSCodeSettings {
    Write-Log "Installing VS Code settings..." -Level "INFO"
    
    try {
        ${vscodeSettingsDir} = "${env:APPDATA}\Code\User"
        ${vscodePromptsDir} = "${vscodeSettingsDir}\prompts"
        
        # Create directories if they don't exist
        if (-not (Test-Path ${vscodeSettingsDir})) {
            New-Item -ItemType Directory -Path ${vscodeSettingsDir} -Force | Out-Null
        }
        
        if (-not (Test-Path ${vscodePromptsDir})) {
            New-Item -ItemType Directory -Path ${vscodePromptsDir} -Force | Out-Null
        }
        
        # Copy settings files
        ${sourceSettings} = Join-Path $PSScriptRoot "configs\vscode\settings.json"
        ${destSettings} = Join-Path ${vscodeSettingsDir} "settings.json"
        
        if (Test-Path ${sourceSettings}) {
            Copy-Item -Path ${sourceSettings} -Destination ${destSettings} -Force
            Write-Log "VS Code settings installed successfully" -Level "SUCCESS"
        }
        
        # Copy Beast Mode chatmode file
        ${sourceBeastMode} = Join-Path $PSScriptRoot "Beast Mode.chatmode.md"
        ${destBeastMode} = Join-Path ${vscodePromptsDir} "Beast Mode.chatmode.md"
        
        if (Test-Path ${sourceBeastMode}) {
            Copy-Item -Path ${sourceBeastMode} -Destination ${destBeastMode} -Force
            Write-Log "Beast Mode chatmode installed successfully" -Level "SUCCESS"
        }
        
        return $true
    } catch {
        Handle-Error "Exception installing VS Code settings: ${_.Exception.Message}"
        return $false
    }
}

# Main installation function
function Start-Installation {
    Write-Log "=== ${scriptName} v${scriptVersion} ===" -Level "INFO"
    Write-Log "Starting development environment installation..." -Level "INFO"
    
    # System validation
    Write-Log "Performing system validation..." -Level "INFO"
    
    if (-not (Test-AdminPrivileges)) {
        Handle-Error "Administrator privileges required. Please run as Administrator."
        exit 1
    }
    
    if (-not (Test-InternetConnection)) {
        Handle-Error "Internet connection required for installation."
        exit 1
    }
    
    ${sysInfo} = Get-SystemInfo
    Write-Log "System: ${sysInfo.OSName} ${sysInfo.OSVersion}" -Level "INFO"
    Write-Log "PowerShell: ${sysInfo.PowerShellVersion}" -Level "INFO"
    Write-Log "RAM: ${sysInfo.TotalRAM} GB" -Level "INFO"
    
    # Check winget availability
    try {
        winget --version | Out-Null
        Write-Log "Winget package manager available" -Level "SUCCESS"
    } catch {
        Handle-Error "Winget package manager not available. Please install App Installer from Microsoft Store."
        exit 1
    }
    
    # Core applications
    Write-Log "Installing core applications..." -Level "INFO"
    
    ${packages} = @(
        @{Id="Microsoft.VisualStudioCode"; Name="Visual Studio Code"},
        @{Id="Git.Git"; Name="Git"},
        @{Id="Microsoft.PowerShell"; Name="PowerShell 7+"}
    )
    
    if (-not ${SkipPython}) {
        ${packages} += @{Id="Python.Python.3.12"; Name="Python 3.12"}
    }
    
    if (-not ${SkipDocker}) {
        ${packages} += @{Id="Docker.DockerDesktop"; Name="Docker Desktop"}
    }
    
    foreach (${package} in ${packages}) {
        if (-not (Test-WingetPackageInstalled ${package}.Id)) {
            Install-WingetPackage ${package}.Id ${package}.Name
        } else {
            Write-Log "${package.Name} already installed" -Level "INFO"
        }
    }
    
    # VS Code extensions
    if (-not ${SkipVSCodeExtensions}) {
        Write-Log "Installing VS Code extensions..." -Level "INFO"
        
        ${extensions} = @(
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
        
        foreach (${extension} in ${extensions}) {
            Install-VSCodeExtension ${extension}.Id ${extension}.Name
        }
    }
    
    # PowerShell profile
    if (-not ${SkipPowerShellProfile}) {
        Install-PowerShellProfile
    }
    
    # VS Code settings
    Install-VSCodeSettings
    
    # WSL setup recommendation
    Write-Log "Checking WSL status..." -Level "INFO"
    try {
        wsl --version 2>$null | Out-Null
        Write-Log "WSL already installed" -Level "SUCCESS"
    } catch {
        Write-Log "WSL not installed. Run 'wsl --install' to install Ubuntu WSL" -Level "WARN"
    }
    
    # Installation complete
    Write-Log "=== Installation Complete ===" -Level "SUCCESS"
    Write-Log "Development environment setup finished!" -Level "SUCCESS"
    Write-Log "" -Level "INFO"
    Write-Log "Next steps:" -Level "INFO"
    Write-Log "1. Restart your terminal or run: . $PROFILE" -Level "INFO"
    Write-Log "2. Open VS Code and check extensions are loaded" -Level "INFO"
    Write-Log "3. Type 'beast' in PowerShell to see Beast Mode information" -Level "INFO"
    Write-Log "4. Install WSL if not already installed: wsl --install" -Level "INFO"
    Write-Log "" -Level "INFO"
    Write-Log "Log file: ${LogPath}" -Level "INFO"
    
    if (-not ${Silent}) {
        Read-Host "Press Enter to exit"
    }
}

# Script execution
try {
    Start-Installation
} catch {
    Handle-Error "Unexpected error during installation: ${_.Exception.Message}"
    exit 1
}
