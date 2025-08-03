#Requires -Version 5.1
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
    Version: 2.1
    Requires: Windows 11, PowerShell 5.1+ (default Windows PowerShell)
    Compatible: PowerShell 5.1, 7.x
    Run as Administrator for full functionality
.LINK
    https://github.com/emilwojcik93/dotfile
.COMPONENT
    DotfilesSetup
.ROLE
    DeveloperTools
.FUNCTIONALITY
    Environment setup and configuration for cross-platform development
#>

[CmdletBinding()]
param(
    [switch]$SkipPowerShellProfile,
    [switch]$SkipPythonSetup,
    [switch]$SkipWSLSetup,
    [switch]$SkipWingetInstall,
    [switch]$SkipValidation
)

Write-Host "Setup script minimal test" -ForegroundColor Green
