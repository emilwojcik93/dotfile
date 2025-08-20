# Windows 11 PowerShell 5.x Profile - IaC Edition
# Compatible with default Windows 11 PowerShell

# Set proper encoding for compatibility
[Console]::OutputEncoding = [Text.Encoding]::UTF8

# Enhanced prompt with Git status
function prompt {
    ${path} = ${pwd}.Path
    ${gitBranch} = ""
    
    if (Test-Path .git) {
        try {
            ${branch} = git rev-parse --abbrev-ref HEAD 2>$null
            if (${branch}) {
                ${gitBranch} = " [${branch}]"
            }
        } catch {
            # Silently ignore git errors
        }
    }
    
    Write-Host "PS " -NoNewline -ForegroundColor Green
    Write-Host ${path} -NoNewline -ForegroundColor Blue  
    Write-Host ${gitBranch} -NoNewline -ForegroundColor Yellow
    Write-Host ">" -NoNewline -ForegroundColor Green
    " "
}

# Navigation aliases with proper syntax
Set-Alias -Name ll -Value Get-ChildItemDetailed
Set-Alias -Name la -Value Get-ChildItemAll
Set-Alias -Name .. -Value Set-LocationUp
Set-Alias -Name ... -Value Set-LocationUpTwo

function Get-ChildItemDetailed { Get-ChildItem -Force | Format-Table -AutoSize }
function Get-ChildItemAll { Get-ChildItem -Force -Hidden | Format-Table -AutoSize }
function Set-LocationUp { Set-Location .. }
function Set-LocationUpTwo { Set-Location ..\.. }

# Git shortcuts
Set-Alias -Name g -Value git
function gs { git status }
function gp { git push }
function gpl { git pull }
function gc { param([string]${msg}) git commit -m ${msg} }
function ga { param([string]${file}) git add ${file} }

# Development helpers  
Set-Alias -Name py -Value python
function pip { python -m pip @args }
function code { 
    param([string]${path} = ".")
    & "${env:LOCALAPPDATA}\Programs\Microsoft VS Code\Code.exe" ${path}
}

# Quick directory navigation
function cddev { Set-Location "${env:USERPROFILE}\Dev" }
function cddoc { Set-Location "${env:USERPROFILE}\Documents" }
function cddown { Set-Location "${env:USERPROFILE}\Downloads" }

# Beast Mode helper
function beast {
    Write-Host "Beast Mode 3.1 Enhanced - IaC Edition" -ForegroundColor Green
    Write-Host "======================================" -ForegroundColor Green
    Write-Host "Chat Mode Location: ${env:APPDATA}\Code\User\prompts\Beast Mode.chatmode.md" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "VS Code: Chat sidebar -> Agent dropdown -> Beast Mode" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Key Features:" -ForegroundColor White
    Write-Host "- Persona-based development workflow" -ForegroundColor Gray
    Write-Host "- Enhanced internet research with multi-engine search" -ForegroundColor Gray  
    Write-Host "- Infrastructure as Code principles" -ForegroundColor Gray
    Write-Host "- PowerShell 5.x compatibility with proper variable syntax" -ForegroundColor Gray
    Write-Host "- shadcn/ui integration with live documentation fetching" -ForegroundColor Gray
}

# System information
function sysinfo {
    ${os} = Get-CimInstance -ClassName Win32_OperatingSystem
    ${cpu} = Get-CimInstance -ClassName Win32_Processor
    ${memory} = Get-CimInstance -ClassName Win32_ComputerSystem
    
    Write-Host "System Information" -ForegroundColor Green
    Write-Host "==================" -ForegroundColor Green
    Write-Host "OS: ${os.Caption} ${os.Version}" -ForegroundColor White
    Write-Host "CPU: ${cpu.Name}" -ForegroundColor White  
    Write-Host "RAM: $([Math]::Round(${memory}.TotalPhysicalMemory / 1GB, 2)) GB" -ForegroundColor White
    Write-Host "PowerShell: $($PSVersionTable.PSVersion)" -ForegroundColor White
    
    # Check for WSL
    try {
        ${wslVersion} = wsl --version 2>$null
        if (${wslVersion}) {
            Write-Host "WSL: Available" -ForegroundColor Green
        }
    } catch {
        Write-Host "WSL: Not installed" -ForegroundColor Yellow
    }
    
    # Check for Docker
    try {
        docker --version 2>$null | Out-Null
        Write-Host "Docker: Available" -ForegroundColor Green
    } catch {
        Write-Host "Docker: Not installed" -ForegroundColor Yellow
    }
}

# Docker shortcuts
function dps { docker ps @args }
function dimg { docker images @args }
function drun { docker run @args }
function dexec { docker exec @args }

# Python virtual environment helpers  
function venv-create {
    param([string]${name} = "venv")
    python -m venv ${name}
    Write-Host "Virtual environment '${name}' created" -ForegroundColor Green
}

function venv-activate {
    param([string]${name} = "venv")
    ${activateScript} = "${name}\Scripts\Activate.ps1"
    if (Test-Path ${activateScript}) {
        & ${activateScript}
        Write-Host "Virtual environment '${name}' activated" -ForegroundColor Green
    } else {
        Write-Host "Virtual environment '${name}' not found" -ForegroundColor Red
    }
}

# Load additional modules if available
${modulePath} = Join-Path $PSScriptRoot "modules"
if (Test-Path ${modulePath}) {
    Get-ChildItem -Path ${modulePath} -Filter "*.psm1" | ForEach-Object {
        try {
            Import-Module ${_.FullName} -Force
        } catch {
            Write-Warning "Failed to load module: ${_.Name}"
        }
    }
}

# Welcome message
Write-Host ""
Write-Host "PowerShell Profile Loaded - IaC Edition" -ForegroundColor Green
Write-Host "Type 'beast' for Beast Mode information" -ForegroundColor Cyan
Write-Host "Type 'sysinfo' for system information" -ForegroundColor Cyan
Write-Host ""
