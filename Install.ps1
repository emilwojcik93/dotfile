# Install.ps1 - Simple wrapper for development environment installation
# Windows 11 PowerShell 5.x Compatible

Write-Host "Beast Mode 3.1 Enhanced - IaC Development Environment Installer" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""

# Change to script directory
Set-Location $PSScriptRoot

# Run the main installation script with Force flag for unattended operation
& ".\automation\Install-DevEnvironment.ps1" -Force -Silent:$false

Write-Host ""
Write-Host "Installation wrapper completed!" -ForegroundColor Green
