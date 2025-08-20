# Update-Environment.ps1 - Development Environment Maintenance
# Windows 11 PowerShell 5.x Compatible
# Infrastructure as Code approach for environment updates

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [switch]${Silent} = $false,
    
    [Parameter(Mandatory=$false)]
    [string]${LogPath} = "${env:TEMP}\DevEnvUpdate.log",
    
    [Parameter(Mandatory=$false)]
    [switch]${UpdatePackages} = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]${UpdateExtensions} = $true,
    
    [Parameter(Mandatory=$false)]
    [switch]${UpdateConfigs} = $true
)

# Script metadata
${scriptVersion} = "1.0.0"
${scriptName} = "Update-Environment"

# Logging function
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
    
    switch (${Level}) {
        "INFO" { Write-Host ${logEntry} -ForegroundColor White }
        "WARN" { Write-Host ${logEntry} -ForegroundColor Yellow }
        "ERROR" { Write-Host ${logEntry} -ForegroundColor Red }
        "SUCCESS" { Write-Host ${logEntry} -ForegroundColor Green }
    }
    
    Add-Content -Path ${LogPath} -Value ${logEntry} -ErrorAction SilentlyContinue
}

# Update winget packages
function Update-WingetPackages {
    Write-Log "Updating winget packages..." -Level "INFO"
    
    try {
        ${result} = winget upgrade --all --silent --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Winget packages updated successfully" -Level "SUCCESS"
        } else {
            Write-Log "Some packages may have failed to update" -Level "WARN"
        }
    } catch {
        Write-Log "Error updating winget packages: ${_.Exception.Message}" -Level "ERROR"
    }
}

# Update VS Code extensions
function Update-VSCodeExtensions {
    Write-Log "Updating VS Code extensions..." -Level "INFO"
    
    try {
        ${codePath} = Get-Command code -ErrorAction SilentlyContinue
        if (-not ${codePath}) {
            Write-Log "VS Code CLI not found in PATH" -Level "WARN"
            return
        }
        
        ${result} = code --list-extensions | ForEach-Object {
            code --install-extension ${_} --force
        }
        
        Write-Log "VS Code extensions updated" -Level "SUCCESS"
    } catch {
        Write-Log "Error updating VS Code extensions: ${_.Exception.Message}" -Level "ERROR"
    }
}

# Update configuration files
function Update-ConfigFiles {
    Write-Log "Updating configuration files..." -Level "INFO"
    
    try {
        # Update PowerShell profile
        ${profilePath} = $PROFILE
        ${sourceProfile} = Join-Path $PSScriptRoot "..\src\powershell\profile.ps1"
        
        if ((Test-Path ${sourceProfile}) -and (Test-Path ${profilePath})) {
            ${sourceHash} = Get-FileHash ${sourceProfile} -Algorithm MD5
            ${destHash} = Get-FileHash ${profilePath} -Algorithm MD5
            
            if (${sourceHash}.Hash -ne ${destHash}.Hash) {
                Copy-Item -Path ${sourceProfile} -Destination ${profilePath} -Force
                Write-Log "PowerShell profile updated" -Level "SUCCESS"
            } else {
                Write-Log "PowerShell profile is up to date" -Level "INFO"
            }
        }
        
        # Update VS Code settings
        ${vscodeSettingsDir} = "${env:APPDATA}\Code\User"
        ${sourceSettings} = Join-Path $PSScriptRoot "..\configs\vscode\settings.json"
        ${destSettings} = Join-Path ${vscodeSettingsDir} "settings.json"
        
        if ((Test-Path ${sourceSettings}) -and (Test-Path ${destSettings})) {
            ${sourceHash} = Get-FileHash ${sourceSettings} -Algorithm MD5
            ${destHash} = Get-FileHash ${destSettings} -Algorithm MD5
            
            if (${sourceHash}.Hash -ne ${destHash}.Hash) {
                Copy-Item -Path ${sourceSettings} -Destination ${destSettings} -Force
                Write-Log "VS Code settings updated" -Level "SUCCESS"
            } else {
                Write-Log "VS Code settings are up to date" -Level "INFO"
            }
        }
        
        # Update Beast Mode chatmode
        ${vscodePromptsDir} = "${env:APPDATA}\Code\User\prompts"
        ${sourceBeastMode} = Join-Path $PSScriptRoot "..\Beast Mode.chatmode.md"
        ${destBeastMode} = Join-Path ${vscodePromptsDir} "Beast Mode.chatmode.md"
        
        if ((Test-Path ${sourceBeastMode}) -and (Test-Path ${destBeastMode})) {
            ${sourceHash} = Get-FileHash ${sourceBeastMode} -Algorithm MD5
            ${destHash} = Get-FileHash ${destBeastMode} -Algorithm MD5
            
            if (${sourceHash}.Hash -ne ${destHash}.Hash) {
                Copy-Item -Path ${sourceBeastMode} -Destination ${destBeastMode} -Force
                Write-Log "Beast Mode chatmode updated" -Level "SUCCESS"
            } else {
                Write-Log "Beast Mode chatmode is up to date" -Level "INFO"
            }
        }
        
    } catch {
        Write-Log "Error updating configuration files: ${_.Exception.Message}" -Level "ERROR"
    }
}

# Main update function
function Start-Update {
    Write-Log "=== ${scriptName} v${scriptVersion} ===" -Level "INFO"
    Write-Log "Starting development environment update..." -Level "INFO"
    
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
    
    Write-Log "=== Update Complete ===" -Level "SUCCESS"
    Write-Log "Development environment updated successfully!" -Level "SUCCESS"
    Write-Log "Log file: ${LogPath}" -Level "INFO"
    
    if (-not ${Silent}) {
        Read-Host "Press Enter to exit"
    }
}

# Execute update
try {
    Start-Update
} catch {
    Write-Log "Unexpected error during update: ${_.Exception.Message}" -Level "ERROR"
    exit 1
}
