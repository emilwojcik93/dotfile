<#
.SYNOPSIS
    Quick installer for Windows development environment
.DESCRIPTION
    Simple wrapper that launches the main installation script with appropriate settings.
    Auto-elevates to administrator if needed.
.EXAMPLE
    .\Install.ps1
    Run interactive installation
.NOTES
    Author: Emil Wójcik
    Version: 2.0.0
    Requires: PowerShell 5.1+, Windows 11
#>

Write-Host '=== Windows Development Environment - IaC Edition ===' -ForegroundColor Green
Write-Host 'Infrastructure as Code setup for Windows 11' -ForegroundColor Cyan
Write-Host ''

# Change to script directory
Set-Location $PSScriptRoot

# Run the main installation script
Write-Host 'Launching main installer...' -ForegroundColor Yellow
Write-Host ''

& '.\automation\Install-DevEnvironment.ps1'

Write-Host ''
Write-Host 'Installation completed!' -ForegroundColor Green
Write-Host ''
Write-Host 'Next steps:' -ForegroundColor Cyan
Write-Host '  1. Restart terminal or run: . $PROFILE' -ForegroundColor White
Write-Host '  2. Test profile: beast' -ForegroundColor White
Write-Host '  3. Open VS Code and verify extensions' -ForegroundColor White
Write-Host '  4. Optional: Install Cursor IDE with .\automation\Install-CursorIDE.ps1' -ForegroundColor White
Write-Host ''
Write-Host 'Documentation: .\README.md' -ForegroundColor Gray
Write-Host 'Commands: .\docs\COMMANDS.md' -ForegroundColor Gray
Write-Host 'Troubleshooting: .\docs\TROUBLESHOOTING.md' -ForegroundColor Gray
