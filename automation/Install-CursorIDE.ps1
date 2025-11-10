<#
.SYNOPSIS
    Installs Cursor IDE with full context menu integration and file associations.
.DESCRIPTION
    Installs Cursor IDE using winget with custom override parameters for complete integration.
    Includes context menu entries, file associations, and PATH configuration.
    Uses Infrastructure as Code principles with PowerShell 5.x compatibility.
.PARAMETER Silent
    Run in silent mode without user interaction
.PARAMETER Force
    Force reinstallation even if Cursor is already installed
.PARAMETER LogPath
    Path for log file output
.EXAMPLE
    .\Install-CursorIDE.ps1
    Install Cursor IDE with default settings
.EXAMPLE
    .\Install-CursorIDE.ps1 -Silent
    Install silently without user interaction
.EXAMPLE
    .\Install-CursorIDE.ps1 -Force
    Force reinstallation with full integration
.NOTES
    Author: Emil Wójcik
    Version: 1.0.0
    Requires: PowerShell 5.1+, Administrator privileges
    Package ID: Cursor.Cursor
#>

[CmdletBinding()]
param(
    [switch]$Silent = $false,
    [switch]$Force = $false,
    [string]$LogPath = "${env:TEMP}\CursorIDE-Install_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').log"
)

# WinUtil-style Admin Self-Elevation
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host 'Install-CursorIDE needs to be run as Administrator. Attempting to relaunch...' -ForegroundColor Yellow
    ${argList} = @()

    $PSBoundParameters.GetEnumerator() | ForEach-Object {
        ${argList} += if ($_.Value -is [switch] -and $_.Value) {
            "-$($_.Key)"
        } elseif ($_.Value -is [array]) {
            "-$($_.Key) $($_.Value -join ',')"
        } elseif ($_.Value) {
            "-$($_.Key) '$($_.Value)'"
        }
    }

    ${script} = "& { & '${PSCommandPath}' $(${argList} -join ' ') }"
    ${powershellCmd} = 'powershell'
    ${processCmd} = if (Get-Command wt.exe -ErrorAction SilentlyContinue) { 'wt.exe' } else { "${powershellCmd}" }

    try {
        if (${processCmd} -eq 'wt.exe') {
            Start-Process ${processCmd} -ArgumentList "${powershellCmd} -ExecutionPolicy Bypass -NoProfile -Command `"${script}`"" -Verb RunAs -Wait
        } else {
            Start-Process ${processCmd} -ArgumentList "-ExecutionPolicy Bypass -NoProfile -Command `"${script}`"" -Verb RunAs -Wait
        }
        Write-Host 'Script relaunched with administrator privileges.' -ForegroundColor Green
        exit 0
    } catch {
        ${errorMsg} = $_.Exception.Message
        Write-Error "Failed to elevate privileges: ${errorMsg}"
        exit 1
    }
    exit 0
}

# Script metadata
${scriptVersion} = '1.0.0'
${scriptName} = 'Install-CursorIDE'
${packageId} = 'Cursor.Cursor'
${packageName} = 'Cursor IDE'

# Initialize logging
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR', 'SUCCESS')]
        [string]$Level = 'INFO'
    )

    ${timestamp} = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    ${logEntry} = "[${timestamp}] [${Level}] ${Message}"

    if (-not ${Silent}) {
        switch (${Level}) {
            'INFO' { Write-Host ${logEntry} -ForegroundColor White }
            'WARN' { Write-Host ${logEntry} -ForegroundColor Yellow }
            'ERROR' { Write-Host ${logEntry} -ForegroundColor Red }
            'SUCCESS' { Write-Host ${logEntry} -ForegroundColor Green }
        }
    }

    try {
        Add-Content -Path ${LogPath} -Value ${logEntry} -ErrorAction SilentlyContinue
    } catch {
        # Ignore logging errors
    }
}

function Test-WingetAvailable {
    try {
        ${wingetVersion} = winget --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Winget package manager validated: ${wingetVersion}" -Level 'SUCCESS'
            return $true
        } else {
            Write-Log 'Winget validation failed' -Level 'ERROR'
            return $false
        }
    } catch {
        Write-Log 'Winget package manager not available' -Level 'ERROR'
        return $false
    }
}

function Test-CursorInstalled {
    try {
        winget list --id ${packageId} --exact 2>$null | Out-Null
        return $LASTEXITCODE -eq 0
    } catch {
        return $false
    }
}

function Install-Cursor {
    Write-Log "Installing ${packageName} with full integration..." -Level 'INFO'

    # Override parameters for InnoSetup installer (same as VS Code)
    ${overrideParams} = '/VERYSILENT /SP- /MERGETASKS="addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath"'

    Write-Log "Override parameters: ${overrideParams}" -Level 'INFO'
    Write-Log '  - /VERYSILENT: Silent installation without UI' -Level 'INFO'
    Write-Log '  - /SP-: Skip startup prompt' -Level 'INFO'
    Write-Log "  - addcontextmenufiles: Add 'Open with Cursor' to file context menu" -Level 'INFO'
    Write-Log "  - addcontextmenufolders: Add 'Open with Cursor' to folder context menu" -Level 'INFO'
    Write-Log '  - associatewithfiles: Associate supported file types with Cursor' -Level 'INFO'
    Write-Log '  - addtopath: Add Cursor CLI to system PATH' -Level 'INFO'

    try {
        if (${Force}) {
            Write-Log "Force mode enabled - reinstalling ${packageName}..." -Level 'WARN'
            winget install --force ${packageId} --override ${overrideParams} --accept-package-agreements --accept-source-agreements
        } else {
            winget install --id ${packageId} --override ${overrideParams} --accept-package-agreements --accept-source-agreements
        }

        if ($LASTEXITCODE -eq 0) {
            Write-Log "${packageName} installed successfully" -Level 'SUCCESS'
            return $true
        } else {
            Write-Log "Installation completed with exit code: ${LASTEXITCODE}" -Level 'WARN'
            return $false
        }
    } catch {
        ${errorMsg} = $_.Exception.Message
        Write-Log "Exception during installation: ${errorMsg}" -Level 'ERROR'
        return $false
    }
}

function Test-CursorCLI {
    Write-Log 'Testing Cursor CLI availability...' -Level 'INFO'

    # Refresh environment variables
    ${env:Path} = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path', 'User')

    try {
        ${cursorPath} = Get-Command cursor -ErrorAction SilentlyContinue
        if (${cursorPath}) {
            Write-Log "Cursor CLI found at: $(${cursorPath}.Source)" -Level 'SUCCESS'
            return $true
        } else {
            Write-Log 'Cursor CLI not found in PATH' -Level 'WARN'
            Write-Log 'You may need to restart your terminal or run: refreshenv' -Level 'INFO'
            return $false
        }
    } catch {
        Write-Log "Error testing Cursor CLI: ${_}" -Level 'WARN'
        return $false
    }
}

function Show-PostInstallInfo {
    Write-Log '' -Level 'INFO'
    Write-Log "=== ${packageName} Installation Complete ===" -Level 'SUCCESS'
    Write-Log '' -Level 'INFO'
    Write-Log 'Features Installed:' -Level 'INFO'
    Write-Log '  [SUCCESS] Context menu integration (right-click files/folders)' -Level 'SUCCESS'
    Write-Log '  [SUCCESS] File type associations for supported formats' -Level 'SUCCESS'
    Write-Log '  [SUCCESS] Cursor CLI added to system PATH' -Level 'SUCCESS'
    Write-Log '' -Level 'INFO'
    Write-Log 'Next Steps:' -Level 'INFO'
    Write-Log "  1. Restart your terminal to use 'cursor' command" -Level 'INFO'
    Write-Log "  2. Right-click any file or folder to see 'Open with Cursor'" -Level 'INFO'
    Write-Log '  3. Launch Cursor from Start Menu or run: cursor' -Level 'INFO'
    Write-Log '  4. Configure Beast Mode 3.1 Enhanced (see docs/setup/beast-mode-guide.md)' -Level 'INFO'
    Write-Log '' -Level 'INFO'
    Write-Log 'Useful Commands:' -Level 'INFO'
    Write-Log '  cursor .                    # Open current directory in Cursor' -Level 'INFO'
    Write-Log '  cursor file.txt             # Open specific file in Cursor' -Level 'INFO'
    Write-Log '  cursor --help               # Show Cursor CLI help' -Level 'INFO'
    Write-Log '' -Level 'INFO'
    Write-Log "Log file: ${LogPath}" -Level 'INFO'
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

try {
    Write-Log "=== ${scriptName} v${scriptVersion} ===" -Level 'INFO'
    Write-Log "Starting ${packageName} installation..." -Level 'INFO'
    Write-Log '' -Level 'INFO'

    # Validate winget availability
    if (-not (Test-WingetAvailable)) {
        Write-Log 'Winget package manager not available. Please install App Installer from Microsoft Store.' -Level 'ERROR'
        exit 1
    }

    # Check if Cursor is already installed
    ${isInstalled} = Test-CursorInstalled
    if (${isInstalled} -and -not ${Force}) {
        Write-Log "${packageName} is already installed" -Level 'INFO'
        Write-Log 'Use -Force parameter to reinstall with full integration' -Level 'INFO'

        if (-not ${Silent}) {
            ${response} = Read-Host 'Would you like to reinstall with full integration? (y/N)'
            if (${response} -eq 'y' -or ${response} -eq 'Y') {
                ${Force} = $true
            } else {
                Write-Log 'Installation cancelled by user' -Level 'INFO'
                exit 0
            }
        } else {
            Write-Log 'Silent mode - skipping reinstallation' -Level 'INFO'
            exit 0
        }
    }

    # Install Cursor IDE
    ${installResult} = Install-Cursor
    if (-not ${installResult}) {
        Write-Log 'Installation may have encountered issues' -Level 'WARN'
        Write-Log "Check log file for details: ${LogPath}" -Level 'INFO'
    }

    # Test CLI availability
    Start-Sleep -Seconds 2
    Test-CursorCLI | Out-Null

    # Show post-install information
    Show-PostInstallInfo

    if (-not ${Silent}) {
        Write-Host "`nPress Enter to exit..." -ForegroundColor Green
        Read-Host
    }

    exit 0

} catch {
    ${errorMsg} = $_.Exception.Message
    Write-Log "Unexpected error during installation: ${errorMsg}" -Level 'ERROR'
    Write-Log "Stack trace: ${_}" -Level 'ERROR'
    exit 1
}
