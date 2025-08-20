<#
.SYNOPSIS
    Maintains and updates the development environment for Windows 11 using Infrastructure as Code principles.
.DESCRIPTION
    Updates winget packages, VS Code extensions, and configuration files.
    Uses Infrastructure as Code approach for environment maintenance.
    Compatible with PowerShell 5.1+ (default Windows PowerShell) and PowerShell 7.x

    PROMPT NOTICE:
    Any prompt requiring user input will automatically continue/exit after 10 seconds if no input is provided. This ensures automation and prevents blocking.
.PARAMETER Silent
    Run in silent mode without user interaction
.PARAMETER LogPath
    Path for log file output
.PARAMETER UpdatePackages
    Update winget packages (default: true)
.PARAMETER UpdateExtensions
    Update VS Code extensions (default: true)
.PARAMETER UpdateConfigs
    Update configuration files (default: true)
.EXAMPLE
    .\Update-Environment.ps1
    Run with default settings
.EXAMPLE
    .\Update-Environment.ps1 -Silent -UpdatePackages:$false
    Update only extensions and configs, skip packages
.NOTES
    Author: Emil Wójcik
    Version: 1.2.0
    Requires: PowerShell 5.1+, Administrator privileges
#>

# Update-Environment.ps1 - Development Environment Maintenance
# Windows 11 PowerShell 5.x Compatible with WinUtil-style self-elevation
# Infrastructure as Code approach for environment updates

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]${Silent} = $false,

    [Parameter(Mandatory = $false)]
    [string]${LogPath} = "${env:TEMP}\DevEnvUpdate.log",

    [Parameter(Mandatory = $false)]
    [switch]${UpdatePackages} = $true,

    [Parameter(Mandatory = $false)]
    [switch]${UpdateExtensions} = $true,

    [Parameter(Mandatory = $false)]
    [switch]${UpdateConfigs} = $true
)

# Admin Self-Elevation (WinUtil style)
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host 'Update-Environment needs to be run as Administrator. Attempting to relaunch...' -ForegroundColor Yellow

    ${argList} = @()
    $PSBoundParameters.GetEnumerator() | ForEach-Object {
        ${argList} += if (${_.Value} -is [switch] -and ${_.Value}) {
            "-${_.Key}"
        } elseif (${_.Value} -is [array]) {
            "-${_.Key} $(${_.Value} -join ',')"
        } elseif (${_.Value}) {
            "-${_.Key} '${_.Value}'"
        }
    }

    # Always add -Silent for elevated execution to avoid interactive prompts
    if (-not $PSBoundParameters.ContainsKey('Silent')) {
        ${argList} += '-Silent'
    }

    ${script} = if ($PSCommandPath) {
        "& { & `'$($PSCommandPath)`' $(${argList} -join ' ') }"
    } else {
        Write-Error 'Script path not available for elevation'
        exit 1
    }

    ${powershellCmd} = if (Get-Command pwsh -ErrorAction SilentlyContinue) { 'pwsh' } else { 'powershell' }
    ${processCmd} = if (Get-Command wt.exe -ErrorAction SilentlyContinue) { 'wt.exe' } else { "${powershellCmd}" }

    try {
        if (${processCmd} -eq 'wt.exe') {
            Start-Process ${processCmd} -ArgumentList "${powershellCmd} -ExecutionPolicy Bypass -NoProfile -Command `"${script}`"" -Verb RunAs -Wait
        } else {
            Start-Process ${processCmd} -ArgumentList "-ExecutionPolicy Bypass -NoProfile -Command `"${script}`"" -Verb RunAs -Wait
        }

        Write-Host 'Update completed in elevated session.' -ForegroundColor Green
        if (-not ${Silent}) {
            Write-Host 'Press Enter to exit (auto-continues in 10 seconds)...' -ForegroundColor Green
            $promptJob = Start-Job { Read-Host }
            $jobResult = Wait-Job $promptJob -Timeout 10
            if ($jobResult -eq $null) {
                Write-Host 'No input detected, continuing automatically...' -ForegroundColor Yellow
                Stop-Job $promptJob | Out-Null
            } else {
                Receive-Job $promptJob | Out-Null
            }
            Remove-Job $promptJob | Out-Null
        }
        exit 0
    } catch {
        Write-Error "Failed to start elevated process: ${_.Exception.Message}"
        exit 1
    }
}

# Script metadata
${scriptVersion} = '1.1.0'
${scriptName} = 'Update-Environment'
${dateTime} = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'

# Set PowerShell window title for admin session
$Host.UI.RawUI.WindowTitle = "Update-Environment (Admin) - ${scriptVersion}"

# Initialize logging with timestamped log file
if (-not ${LogPath}.Contains(${dateTime})) {
    ${logDir} = Split-Path ${LogPath} -Parent
    ${logName} = [System.IO.Path]::GetFileNameWithoutExtension(${LogPath})
    ${logExt} = [System.IO.Path]::GetExtension(${LogPath})
    ${LogPath} = Join-Path ${logDir} "${logName}_${dateTime}${logExt}"
}

# Logging function
function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]${Message},
        [Parameter(Mandatory = $false)]
        [ValidateSet('INFO', 'WARN', 'ERROR', 'SUCCESS')]
        [string]${Level} = 'INFO'
    )

    ${timestamp} = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    ${logEntry} = "[${timestamp}] [${Level}] ${Message}"

    # Write to console with color (only if not silent)
    if (-not ${Silent}) {
        switch (${Level}) {
            'INFO' { Write-Host ${logEntry} -ForegroundColor White }
            'WARN' { Write-Host ${logEntry} -ForegroundColor Yellow }
            'ERROR' { Write-Host ${logEntry} -ForegroundColor Red }
            'SUCCESS' { Write-Host ${logEntry} -ForegroundColor Green }
        }
    }

    # Always write to log file
    Add-Content -Path ${LogPath} -Value ${logEntry} -ErrorAction SilentlyContinue
}

# Update winget packages with unattended mode
function Update-WingetPackages {
    Write-Log 'Updating winget packages...' -Level 'INFO'

    try {
        ${result} = winget upgrade --all --silent --accept-package-agreements --accept-source-agreements --disable-interactivity 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Log 'Winget packages updated successfully' -Level 'SUCCESS'
        } else {
            Write-Log "Some packages may have failed to update (Exit code: $LASTEXITCODE)" -Level 'WARN'
        }
    } catch {
        Write-Log "Error updating winget packages: ${_.Exception.Message}" -Level 'ERROR'
    }
}

# Update VS Code extensions
function Update-VSCodeExtensions {
    Write-Log 'Updating VS Code extensions...' -Level 'INFO'

    try {
        ${codePath} = Get-Command code -ErrorAction SilentlyContinue
        if (-not ${codePath}) {
            Write-Log 'VS Code CLI not found in PATH' -Level 'WARN'
            return
        }

        ${extensions} = code --list-extensions
        ${updateCount} = 0

        foreach (${extension} in ${extensions}) {
            try {
                code --install-extension ${extension} --force 2>$null
                if ($LASTEXITCODE -eq 0) {
                    ${updateCount}++
                }
            } catch {
                Write-Log "Failed to update extension: ${extension}" -Level 'WARN'
            }
        }

        Write-Log "Updated ${updateCount} VS Code extensions" -Level 'SUCCESS'
    } catch {
        Write-Log "Error updating VS Code extensions: ${_.Exception.Message}" -Level 'ERROR'
    }
}

# Update configuration files
function Update-ConfigFiles {
    Write-Log 'Updating configuration files...' -Level 'INFO'

    try {
        ${updateCount} = 0

        # Update PowerShell profile
        ${profilePath} = $PROFILE
        ${sourceProfile} = Join-Path $PSScriptRoot '..\src\powershell\profile.ps1'

        if ((Test-Path ${sourceProfile}) -and (Test-Path ${profilePath})) {
            ${sourceHash} = Get-FileHash ${sourceProfile} -Algorithm MD5
            ${destHash} = Get-FileHash ${profilePath} -Algorithm MD5

            if (${sourceHash}.Hash -ne ${destHash}.Hash) {
                Copy-Item -Path ${sourceProfile} -Destination ${profilePath} -Force
                Write-Log 'PowerShell profile updated' -Level 'SUCCESS'
                ${updateCount}++
            } else {
                Write-Log 'PowerShell profile is up to date' -Level 'INFO'
            }
        }

        # Update VS Code settings
        ${vscodeSettingsDir} = "${env:APPDATA}\Code\User"
        ${sourceSettings} = Join-Path $PSScriptRoot '..\configs\settings.json'
        ${destSettings} = Join-Path ${vscodeSettingsDir} 'settings.json'

        if ((Test-Path ${sourceSettings}) -and (Test-Path ${destSettings})) {
            ${sourceHash} = Get-FileHash ${sourceSettings} -Algorithm MD5
            ${destHash} = Get-FileHash ${destSettings} -Algorithm MD5

            if (${sourceHash}.Hash -ne ${destHash}.Hash) {
                Copy-Item -Path ${sourceSettings} -Destination ${destSettings} -Force
                Write-Log 'VS Code settings updated' -Level 'SUCCESS'
                ${updateCount}++
            } else {
                Write-Log 'VS Code settings are up to date' -Level 'INFO'
            }
        }

        # Update Beast Mode chatmode
        ${vscodePromptsDir} = "${env:APPDATA}\Code\User\prompts"
        ${sourceBeastMode} = Join-Path $PSScriptRoot '..\Beast Mode.chatmode.md'
        ${destBeastMode} = Join-Path ${vscodePromptsDir} 'Beast Mode.chatmode.md'

        if ((Test-Path ${sourceBeastMode}) -and (Test-Path ${destBeastMode})) {
            ${sourceHash} = Get-FileHash ${sourceBeastMode} -Algorithm MD5
            ${destHash} = Get-FileHash ${destBeastMode} -Algorithm MD5

            if (${sourceHash}.Hash -ne ${destHash}.Hash) {
                Copy-Item -Path ${sourceBeastMode} -Destination ${destBeastMode} -Force
                Write-Log 'Beast Mode chatmode updated' -Level 'SUCCESS'
                ${updateCount}++
            } else {
                Write-Log 'Beast Mode chatmode is up to date' -Level 'INFO'
            }
        }

        Write-Log "Updated ${updateCount} configuration files" -Level 'SUCCESS'

    } catch {
        Write-Log "Error updating configuration files: ${_.Exception.Message}" -Level 'ERROR'
    }
}

# Main update function
function Start-Update {
    Write-Log "=== ${scriptName} v${scriptVersion} ===" -Level 'INFO'
    Write-Log 'Starting development environment update...' -Level 'INFO'

    # Update packages
    if (${UpdatePackages}) {
        Update-WingetPackages
    }

    # Update VS Code extensions
    if (${UpdateExtensions}) {
        Update-VSCodeExtensions
    }

    # Update configuration files
    if (${UpdateConfigs}) {
        Update-ConfigFiles
    }

    Write-Log '=== Update Complete ===' -Level 'SUCCESS'
    Write-Log 'Development environment updated successfully!' -Level 'SUCCESS'
    Write-Log "Log file: ${LogPath}" -Level 'INFO'

    if (-not ${Silent}) {
        Write-Host 'Press Enter to exit (auto-continues in 10 seconds)...' -ForegroundColor Green
        $promptJob = Start-Job { Read-Host }
        $jobResult = Wait-Job $promptJob -Timeout 10
        if ($jobResult -eq $null) {
            Write-Host 'No input detected, continuing automatically...' -ForegroundColor Yellow
            Stop-Job $promptJob | Out-Null
        } else {
            Receive-Job $promptJob | Out-Null
        }
        Remove-Job $promptJob | Out-Null
    }
}

# Execute update with error handling
try {
    Start-Update
    exit 0
} catch {
    Write-Log "Unexpected error during update: ${_.Exception.Message}" -Level 'ERROR'
    Write-Log "Stack trace: ${_.ScriptStackTrace}" -Level 'ERROR'
    exit 1
}
