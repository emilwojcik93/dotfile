#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Initial setup script for development environment
.DESCRIPTION
    Configures Windows development environment with proper encoding,
    installs required tools, and sets up profiles and configurations
.NOTES
    Author: Development Team
    Version: 1.0
    Run as Administrator
#>

[CmdletBinding()]
param(
    [switch]$SkipPowerShellProfile,
    [switch]$SkipPythonSetup,
    [switch]$SkipWSLSetup
)

# Set encoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "=== Development Environment Setup ===" -ForegroundColor Green

# Check if running as administrator
$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $IsAdmin) {
    Write-Error "This script must be run as Administrator"
    exit 1
}

# Function to install packages using winget
function Install-WingetPackages {
    Write-Host "Installing packages with winget..." -ForegroundColor Yellow
    
    # Check if winget is available
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Warning "Winget not found. Please install App Installer from Microsoft Store."
        return
    }
    
    $Packages = @(
        @{ Id = "Microsoft.Git"; Name = "Git" },
        @{ Id = "Microsoft.VisualStudioCode"; Name = "Visual Studio Code" },
        @{ Id = "Microsoft.PowerShell"; Name = "PowerShell" },
        @{ Id = "Python.Python.3.12"; Name = "Python 3.12" },
        @{ Id = "JetBrains.JetBrainsMono"; Name = "JetBrains Mono Font" },
        @{ Id = "Microsoft.WindowsTerminal"; Name = "Windows Terminal" },
        @{ Id = "gsudo.gsudo"; Name = "GSudo" }
    )
    
    foreach ($Package in $Packages) {
        Write-Host "Installing $($Package.Name)..." -ForegroundColor Cyan
        try {
            winget install --id $Package.Id --silent --accept-package-agreements --accept-source-agreements
            Write-Host "✓ $($Package.Name) installed successfully" -ForegroundColor Green
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
    $Modules = @('PSScriptAnalyzer', 'Pester', 'PSReadLine')
    foreach ($Module in $Modules) {
        Write-Host "Installing module: $Module" -ForegroundColor Cyan
        Install-Module $Module -Force -Scope CurrentUser -AllowClobber
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

try {
    # Main setup process
    Write-Host "Starting environment setup..." -ForegroundColor Cyan

    # Install Chocolatey packages
    Install-ChocoPackages

    # Setup PowerShell profile
    Set-PowerShellProfile

    # Setup Python environment
    Set-PythonEnvironment

    # Setup WSL environment
    Set-WSLEnvironment

    # Setup VS Code settings
    Set-VSCodeSettings

    # Create validation script
    New-ValidationScript

    Write-Host "=== Setup Complete ===" -ForegroundColor Green
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Restart PowerShell to load new profile" -ForegroundColor White
    Write-Host "2. Restart VS Code to apply settings" -ForegroundColor White
    Write-Host "3. Run .\validate-all.ps1 to test everything" -ForegroundColor White
    Write-Host "4. Configure Git: git config --global user.name 'Your Name'" -ForegroundColor White
    Write-Host "5. Configure Git: git config --global user.email 'your.email@company.com'" -ForegroundColor White
}
catch {
    Write-Error "Setup failed: $($_.Exception.Message)"
    exit 1
}
