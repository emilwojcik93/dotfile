#Requires -Version 7.0
<#
.SYNOPSIS
    Comprehensive setup script for development environment
.DESCRIPTION
    Automatically installs/upgrades winget, installs all dependencies,
    configures Windows development environment with proper encoding,
    and validates the complete setup
.PARAMETER SkipPowerShellProfile
    Skip PowerShell profile setup
.PARAMETER SkipPythonSetup
    Skip Python environment setup
.PARAMETER SkipWSLSetup
    Skip WSL environment setup
.PARAMETER SkipWingetInstall
    Skip winget installation/upgrade
.PARAMETER SkipValidation
    Skip environment validation
.EXAMPLE
    .\setup.ps1
    Run complete setup with all options
.EXAMPLE
    .\setup.ps1 -SkipWSLSetup -SkipValidation
    Run setup without WSL and validation
.NOTES
    Author: Personal Development Environment
    Version: 2.0
    Requires: Windows 11, PowerShell 7+
    Run as Administrator for full functionality
#>

[CmdletBinding()]
param(
    [switch]$SkipPowerShellProfile,
    [switch]$SkipPythonSetup,
    [switch]$SkipWSLSetup,
    [switch]$SkipWingetInstall,
    [switch]$SkipValidation
)

# Set encoding and error handling
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = 'Stop'

Write-Host "=== Personal Development Environment Setup ===" -ForegroundColor Green
Write-Host "Starting comprehensive environment configuration..." -ForegroundColor Cyan

# Function to test administrator privileges
function Test-AdminPrivileges {
    $IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $IsAdmin) {
        Write-Warning "Administrator privileges recommended for full setup"
        Write-Host "Some features may not be available without admin rights" -ForegroundColor Yellow
        return $false
    }
    Write-Host "✓ Running with Administrator privileges" -ForegroundColor Green
    return $true
}

# Function to install/upgrade winget
function Install-Winget {
    if ($SkipWingetInstall) {
        Write-Host "Skipping winget installation" -ForegroundColor Yellow
        return
    }

    Write-Host "Installing/upgrading Windows Package Manager (winget)..." -ForegroundColor Yellow

    try {
        # Check if winget is already available
        $wingetVersion = winget --version 2>$null
        if ($wingetVersion) {
            Write-Host "✓ Winget already installed: $wingetVersion" -ForegroundColor Green
            
            # Try to upgrade winget
            Write-Host "Attempting to upgrade winget..." -ForegroundColor Cyan
            try {
                winget upgrade Microsoft.DesktopAppInstaller --silent --accept-package-agreements --accept-source-agreements
                Write-Host "✓ Winget upgraded successfully" -ForegroundColor Green
            }
            catch {
                Write-Host "! Winget upgrade not needed or failed: $($_.Exception.Message)" -ForegroundColor Yellow
            }
            return
        }
    }
    catch {
        Write-Host "Winget not found, installing..." -ForegroundColor Cyan
    }

    # Install winget via App Installer package
    try {
        Write-Host "Downloading and installing Microsoft App Installer..." -ForegroundColor Cyan
        $tempPath = Join-Path $env:TEMP "Microsoft.DesktopAppInstaller.msixbundle"
        
        # Download the latest version
        $downloadUrl = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
        Invoke-WebRequest -Uri $downloadUrl -OutFile $tempPath -UseBasicParsing
        
        # Install the package
        Add-AppxPackage -Path $tempPath -ForceApplicationShutdown
        Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
        
        # Verify installation
        Start-Sleep -Seconds 5
        $wingetVersion = winget --version 2>$null
        if ($wingetVersion) {
            Write-Host "✓ Winget installed successfully: $wingetVersion" -ForegroundColor Green
        }
        else {
            throw "Winget installation verification failed"
        }
    }
    catch {
        Write-Error "Failed to install winget: $($_.Exception.Message)"
        Write-Host "Please install App Installer from Microsoft Store manually" -ForegroundColor Red
        return
    }
}

# Function to install packages using winget
function Install-WingetPackages {
    Write-Host "Installing development packages with winget..." -ForegroundColor Yellow
    
    # Check if winget is available
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Warning "Winget not available. Skipping package installation."
        return
    }
    
    $Packages = @(
        @{ Id = "Microsoft.Git"; Name = "Git" },
        @{ Id = "Microsoft.VisualStudioCode"; Name = "Visual Studio Code" },
        @{ Id = "Microsoft.PowerShell"; Name = "PowerShell 7+" },
        @{ Id = "Python.Python.3.12"; Name = "Python 3.12" },
        @{ Id = "JetBrains.JetBrainsMono"; Name = "JetBrains Mono Font" },
        @{ Id = "Microsoft.WindowsTerminal"; Name = "Windows Terminal" },
        @{ Id = "gsudo.gsudo"; Name = "GSudo (Admin Helper)" },
        @{ Id = "Microsoft.WindowsSubsystemForLinux"; Name = "WSL" },
        @{ Id = "Canonical.Ubuntu.2404"; Name = "Ubuntu 24.04 LTS" }
    )
    
    foreach ($Package in $Packages) {
        Write-Host "Installing $($Package.Name)..." -ForegroundColor Cyan
        try {
            $result = winget install --id $Package.Id --silent --accept-package-agreements --accept-source-agreements 2>&1
            if ($LASTEXITCODE -eq 0 -or $result -match "already installed") {
                Write-Host "✓ $($Package.Name) installed/updated successfully" -ForegroundColor Green
            }
            else {
                Write-Warning "Issue installing $($Package.Name): $result"
            }
        }
        catch {
            Write-Warning "Failed to install $($Package.Name): $($_.Exception.Message)"
        }
    }
}# Function to setup PowerShell profile
function Set-PowerShellProfile {
    if ($SkipPowerShellProfile) {
        Write-Host "Skipping PowerShell profile setup" -ForegroundColor Yellow
        return
    }

    Write-Host "Setting up PowerShell profile..." -ForegroundColor Yellow

    $ProfilePath = $PROFILE.CurrentUserAllHosts
    $ProfileDir = Split-Path $ProfilePath -Parent
    $SourceProfile = Join-Path $PSScriptRoot "powershell\profile.ps1"

    # Create profile directory if it doesn't exist
    if (-not (Test-Path $ProfileDir)) {
        New-Item -Path $ProfileDir -ItemType Directory -Force | Out-Null
        Write-Host "✓ Created PowerShell profile directory" -ForegroundColor Green
    }

    # Copy profile
    if (Test-Path $SourceProfile) {
        Copy-Item $SourceProfile $ProfilePath -Force
        Write-Host "✓ PowerShell profile installed to: $ProfilePath" -ForegroundColor Green
    }
    else {
        Write-Warning "Source profile not found: $SourceProfile"
    }

    # Install required modules
    Write-Host "Installing PowerShell modules..." -ForegroundColor Cyan
    $Modules = @('PSScriptAnalyzer', 'Pester', 'PSReadLine')
    foreach ($Module in $Modules) {
        try {
            Write-Host "Installing module: $Module" -ForegroundColor Cyan
            Install-Module $Module -Force -Scope CurrentUser -AllowClobber -SkipPublisherCheck
            Write-Host "✓ $Module installed successfully" -ForegroundColor Green
        }
        catch {
            Write-Warning "Failed to install module ${Module}: $($_.Exception.Message)"
        }
    }
}

# Function to setup Python environment
function Set-PythonEnvironment {
    if ($SkipPythonSetup) {
        Write-Host "Skipping Python setup" -ForegroundColor Yellow
        return
    }

    Write-Host "Setting up Python environment..." -ForegroundColor Yellow

    # Check if Python is available
    if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
        Write-Warning "Python not found in PATH. Install Python first."
        return
    }

    try {
        # Upgrade pip first
        Write-Host "Upgrading pip..." -ForegroundColor Cyan
        python -m pip install --upgrade pip
        Write-Host "✓ Pip upgraded successfully" -ForegroundColor Green

        # Install Python packages from requirements
        $RequirementsFile = Join-Path $PSScriptRoot "python\requirements.txt"
        if (Test-Path $RequirementsFile) {
            Write-Host "Installing Python packages from requirements.txt..." -ForegroundColor Cyan
            python -m pip install -r $RequirementsFile
            Write-Host "✓ Python packages installed successfully" -ForegroundColor Green
        }
        else {
            # Install essential packages manually
            Write-Host "Installing essential Python packages..." -ForegroundColor Cyan
            $PythonPackages = @('black', 'pylint', 'mypy', 'flake8', 'autopep8', 'bandit', 'pytest')
            foreach ($package in $PythonPackages) {
                python -m pip install $package
            }
            Write-Host "✓ Essential Python packages installed" -ForegroundColor Green
        }

        # Set environment variables
        [Environment]::SetEnvironmentVariable("PYTHONIOENCODING", "utf-8", "User")
        [Environment]::SetEnvironmentVariable("PYTHONUTF8", "1", "User")
        Write-Host "✓ Python UTF-8 encoding configured" -ForegroundColor Green
    }
    catch {
        Write-Warning "Python setup failed: $($_.Exception.Message)"
    }
}

# Function to setup WSL environment
function Set-WSLEnvironment {
    if ($SkipWSLSetup) {
        Write-Host "Skipping WSL setup" -ForegroundColor Yellow
        return
    }

    Write-Host "Setting up WSL environment..." -ForegroundColor Yellow

    # Check if WSL is available
    if (-not (Get-Command wsl -ErrorAction SilentlyContinue)) {
        Write-Warning "WSL not found. Install WSL first: wsl --install"
        return
    }

    try {
        # Check WSL status
        $wslStatus = wsl --status 2>&1
        Write-Host "WSL Status: $wslStatus" -ForegroundColor Cyan

        # Install/copy bashrc
        $BashrcSource = Join-Path $PSScriptRoot "wsl\.bashrc"
        if (Test-Path $BashrcSource) {
            Write-Host "Installing WSL bashrc..." -ForegroundColor Cyan
            $dotfilePath = $PSScriptRoot.Replace('\', '/').Replace('C:', '/mnt/c')
            wsl cp "$dotfilePath/wsl/.bashrc" ~/.bashrc
            Write-Host "✓ WSL bashrc installed" -ForegroundColor Green
        }

        # Update packages and install development tools
        Write-Host "Updating WSL packages..." -ForegroundColor Cyan
        wsl sudo apt update
        wsl sudo apt upgrade -y
        
        Write-Host "Installing WSL development packages..." -ForegroundColor Cyan
        wsl sudo apt install -y python3-pip yamllint git curl build-essential
        
        Write-Host "Installing WSL Python packages..." -ForegroundColor Cyan
        wsl pip3 install black pylint mypy flake8 autopep8
        
        Write-Host "✓ WSL environment configured successfully" -ForegroundColor Green
    }
    catch {
        Write-Warning "WSL setup failed: $($_.Exception.Message)"
    }
}

# Function to setup VS Code settings
function Set-VSCodeSettings {
    Write-Host "Setting up VS Code settings..." -ForegroundColor Yellow

    $VSCodeSettingsDir = Join-Path $env:APPDATA "Code\User"
    $SourceSettingsDir = Join-Path $PSScriptRoot ".vscode"

    if (-not (Test-Path $VSCodeSettingsDir)) {
        New-Item -Path $VSCodeSettingsDir -ItemType Directory -Force | Out-Null
        Write-Host "✓ Created VS Code settings directory" -ForegroundColor Green
    }

    # Copy settings.json
    $SourceSettings = Join-Path $SourceSettingsDir "settings.json"
    $TargetSettings = Join-Path $VSCodeSettingsDir "settings.json"
    if (Test-Path $SourceSettings) {
        Copy-Item $SourceSettings $TargetSettings -Force
        Write-Host "✓ VS Code settings.json installed" -ForegroundColor Green
    }

    # Install recommended extensions
    $ExtensionsFile = Join-Path $SourceSettingsDir "extensions.json"
    if (Test-Path $ExtensionsFile) {
        Write-Host "Installing recommended VS Code extensions..." -ForegroundColor Cyan
        try {
            $extensions = Get-Content $ExtensionsFile | ConvertFrom-Json
            foreach ($extension in $extensions.recommendations) {
                code --install-extension $extension --force
            }
            Write-Host "✓ VS Code extensions installed" -ForegroundColor Green
        }
        catch {
            Write-Warning "Failed to install some extensions: $($_.Exception.Message)"
        }
    }
}

# Function to create comprehensive validation script
function New-ValidationScript {
    Write-Host "Creating comprehensive validation script..." -ForegroundColor Yellow

    $ValidationScript = @'
#Requires -Version 7.0
<#
.SYNOPSIS
    Comprehensive validation of development environment
.DESCRIPTION
    Validates all script files, environment configuration, and tool availability
#>

[CmdletBinding()]
param(
    [switch]$Verbose
)

Write-Host "=== Development Environment Validation ===" -ForegroundColor Green
$ErrorCount = 0

# Function to test command availability
function Test-Command {
    param([string]$Command)
    if (Get-Command $Command -ErrorAction SilentlyContinue) {
        Write-Host "✓ $Command is available" -ForegroundColor Green
        return $true
    } else {
        Write-Host "✗ $Command not found" -ForegroundColor Red
        return $false
    }
}

# Validate required tools
Write-Host "`n=== Tool Availability ===" -ForegroundColor Cyan
$Tools = @('git', 'code', 'python', 'winget', 'wsl')
foreach ($tool in $Tools) {
    if (-not (Test-Command $tool)) { $ErrorCount++ }
}

# Validate PowerShell files
Write-Host "`n=== PowerShell File Validation ===" -ForegroundColor Cyan
Get-ChildItem -Path . -Filter "*.ps1" -Recurse | ForEach-Object {
    try {
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $_.FullName -Raw), [ref]$null)
        Write-Host "✓ $($_.Name)" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ $($_.Name): $($_.Exception.Message)" -ForegroundColor Red
        $ErrorCount++
    }
}

# Validate Python files
Write-Host "`n=== Python File Validation ===" -ForegroundColor Cyan
if (Get-Command python -ErrorAction SilentlyContinue) {
    Get-ChildItem -Path . -Filter "*.py" -Recurse | ForEach-Object {
        $Result = python -m py_compile $_.FullName 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ $($_.Name)" -ForegroundColor Green
        } else {
            Write-Host "✗ $($_.Name): $Result" -ForegroundColor Red
            $ErrorCount++
        }
    }
} else {
    Write-Host "! Python not available for validation" -ForegroundColor Yellow
}

# Validate JSON files
Write-Host "`n=== JSON File Validation ===" -ForegroundColor Cyan
Get-ChildItem -Path . -Filter "*.json" -Recurse | ForEach-Object {
    try {
        Get-Content $_.FullName | ConvertFrom-Json | Out-Null
        Write-Host "✓ $($_.Name)" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ $($_.Name): $($_.Exception.Message)" -ForegroundColor Red
        $ErrorCount++
    }
}

# Validate environment variables
Write-Host "`n=== Environment Validation ===" -ForegroundColor Cyan
$EnvVars = @('PYTHONIOENCODING', 'PYTHONUTF8')
foreach ($var in $EnvVars) {
    $value = [Environment]::GetEnvironmentVariable($var, "User")
    if ($value) {
        Write-Host "✓ $var = $value" -ForegroundColor Green
    } else {
        Write-Host "! $var not set" -ForegroundColor Yellow
    }
}

# Validate PowerShell modules
Write-Host "`n=== PowerShell Module Validation ===" -ForegroundColor Cyan
$RequiredModules = @('PSScriptAnalyzer', 'Pester', 'PSReadLine')
foreach ($module in $RequiredModules) {
    if (Get-Module -ListAvailable -Name $module) {
        Write-Host "✓ $module is installed" -ForegroundColor Green
    } else {
        Write-Host "✗ $module not installed" -ForegroundColor Red
        $ErrorCount++
    }
}

# Final summary
Write-Host "`n=== Validation Summary ===" -ForegroundColor Green
if ($ErrorCount -eq 0) {
    Write-Host "✓ All validations passed successfully!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "✗ $ErrorCount validation(s) failed" -ForegroundColor Red
    exit 1
}
'@

    $ValidationPath = Join-Path $PSScriptRoot "validate-all.ps1"
    Set-Content -Path $ValidationPath -Value $ValidationScript -Encoding UTF8
    Write-Host "✓ Comprehensive validation script created: $ValidationPath" -ForegroundColor Green
}

# Function to validate environment
function Test-Environment {
    if ($SkipValidation) {
        Write-Host "Skipping environment validation" -ForegroundColor Yellow
        return
    }

    Write-Host "Validating environment setup..." -ForegroundColor Yellow
    
    try {
        # Run the validation script
        $ValidationPath = Join-Path $PSScriptRoot "validate-all.ps1"
        if (Test-Path $ValidationPath) {
            & $ValidationPath
        } else {
            Write-Warning "Validation script not found. Creating and running..."
            New-ValidationScript
            & $ValidationPath
        }
    }
    catch {
        Write-Warning "Environment validation failed: $($_.Exception.Message)"
    }
}

# Function to setup Python environment
function Set-PythonEnvironment {
    if ($SkipPythonSetup) {
        Write-Host "Skipping Python setup" -ForegroundColor Yellow
        return
    }

    Write-Host "Setting up Python environment..." -ForegroundColor Yellow

    # Install Python packages
    $RequirementsFile = Join-Path $PSScriptRoot "python\requirements.txt"
    if (Test-Path $RequirementsFile) {
        Write-Host "Installing Python packages from requirements.txt..." -ForegroundColor Cyan
        python -m pip install --upgrade pip
        python -m pip install -r $RequirementsFile
        Write-Host "✓ Python packages installed" -ForegroundColor Green
    }
    else {
        Write-Warning "Requirements file not found: $RequirementsFile"
    }

    # Set environment variable
    [Environment]::SetEnvironmentVariable("PYTHONIOENCODING", "utf-8", "User")
    Write-Host "✓ Python UTF-8 encoding configured" -ForegroundColor Green
}

# Function to setup WSL
function Set-WSLEnvironment {
    if ($SkipWSLSetup) {
        Write-Host "Skipping WSL setup" -ForegroundColor Yellow
        return
    }

    Write-Host "Setting up WSL environment..." -ForegroundColor Yellow

    # Check if WSL is installed
    if (Get-Command wsl -ErrorAction SilentlyContinue) {
        $BashrcSource = Join-Path $PSScriptRoot "wsl\.bashrc"

        if (Test-Path $BashrcSource) {
            # Copy bashrc to WSL home directory
            Write-Host "Installing WSL bashrc..." -ForegroundColor Cyan
            wsl cp /mnt/c/Users/$env:USERNAME/GitHub/dotfile/wsl/.bashrc ~/.bashrc
            Write-Host "✓ WSL bashrc installed" -ForegroundColor Green
        }

        # Install common packages in WSL
        Write-Host "Installing WSL packages..." -ForegroundColor Cyan
        wsl sudo apt update
        wsl sudo apt install -y python3-pip yamllint git curl
        wsl pip3 install black pylint mypy
        Write-Host "✓ WSL packages installed" -ForegroundColor Green
    }
    else {
        Write-Warning "WSL not found. Install WSL first: wsl --install"
    }
}

# Function to setup VS Code settings
function Set-VSCodeSettings {
    Write-Host "Setting up VS Code settings..." -ForegroundColor Yellow

    $VSCodeSettingsDir = Join-Path $env:APPDATA "Code\User"
    $SourceSettings = Join-Path $PSScriptRoot ".vscode\settings.json"
    $TargetSettings = Join-Path $VSCodeSettingsDir "settings.json"

    if (-not (Test-Path $VSCodeSettingsDir)) {
        New-Item -Path $VSCodeSettingsDir -ItemType Directory -Force | Out-Null
    }

    if (Test-Path $SourceSettings) {
        Copy-Item $SourceSettings $TargetSettings -Force
        Write-Host "✓ VS Code settings installed" -ForegroundColor Green
    }
    else {
        Write-Warning "Source settings not found: $SourceSettings"
    }
}

# Function to create validation script
function New-ValidationScript {
    Write-Host "Creating validation script..." -ForegroundColor Yellow

    $ValidationScript = @'
#Requires -Version 7.0
<#
.SYNOPSIS
    Validates all script files in the current directory
#>

Write-Host "=== File Validation ===" -ForegroundColor Green

# Validate PowerShell files
Write-Host "Validating PowerShell files..." -ForegroundColor Cyan
Get-ChildItem -Path . -Filter "*.ps1" -Recurse | ForEach-Object {
    try {
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $_.FullName -Raw), [ref]$null)
        Write-Host "✓ $($_.Name)" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ $($_.Name): $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Validate Python files
Write-Host "Validating Python files..." -ForegroundColor Cyan
Get-ChildItem -Path . -Filter "*.py" -Recurse | ForEach-Object {
    $Result = python -m py_compile $_.FullName 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ $($_.Name)" -ForegroundColor Green
    } else {
        Write-Host "✗ $($_.Name): $Result" -ForegroundColor Red
    }
}

# Validate JSON files
Write-Host "Validating JSON files..." -ForegroundColor Cyan
Get-ChildItem -Path . -Filter "*.json" -Recurse | ForEach-Object {
    try {
        Get-Content $_.FullName | ConvertFrom-Json | Out-Null
        Write-Host "✓ $($_.Name)" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ $($_.Name): $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "=== Validation Complete ===" -ForegroundColor Green
'@

    $ValidationPath = Join-Path $PSScriptRoot "validate-all.ps1"
    Set-Content -Path $ValidationPath -Value $ValidationScript -Encoding UTF8
    Write-Host "✓ Validation script created: $ValidationPath" -ForegroundColor Green
}

# Main execution block
try {
    Write-Host "Starting comprehensive environment setup..." -ForegroundColor Cyan
    
    # Test administrator privileges
    $HasAdmin = Test-AdminPrivileges
    
    # Install/upgrade winget first
    Install-Winget
    
    # Install development packages
    Install-WingetPackages
    
    # Setup PowerShell environment
    Set-PowerShellProfile
    
    # Setup Python environment
    Set-PythonEnvironment
    
    # Setup WSL environment (if not skipped)
    Set-WSLEnvironment
    
    # Setup VS Code settings and extensions
    Set-VSCodeSettings
    
    # Create validation script
    New-ValidationScript
    
    # Validate environment
    Test-Environment
    
    Write-Host "`n=== Setup Complete! ===" -ForegroundColor Green
    Write-Host "Your development environment is now configured." -ForegroundColor Cyan
    
    Write-Host "`nNext steps:" -ForegroundColor Yellow
    Write-Host "1. Restart PowerShell to load new profile" -ForegroundColor White
    Write-Host "2. Restart VS Code to apply all settings" -ForegroundColor White
    Write-Host "3. Run .\validate-all.ps1 to verify everything" -ForegroundColor White
    if (-not $HasAdmin) {
        Write-Host "4. Consider running as Administrator for full functionality" -ForegroundColor White
    }
    Write-Host "5. Configure Git with your personal details:" -ForegroundColor White
    Write-Host "   git config --global user.name 'Your Name'" -ForegroundColor Gray
    Write-Host "   git config --global user.email 'your.email@example.com'" -ForegroundColor Gray
    Write-Host "6. Restart your terminal to use new fonts and settings" -ForegroundColor White
    
    Write-Host "`nEnvironment ready for development with AI assistants!" -ForegroundColor Green
}
catch {
    Write-Error "Setup failed: $($_.Exception.Message)"
    Write-Host "Check the error above and try running specific sections manually" -ForegroundColor Red
    exit 1
}
