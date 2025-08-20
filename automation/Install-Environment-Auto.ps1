#Requires -Version 5.1
<#
.SYNOPSIS
    Comprehensive Auto-Detection and Installation for Development Environment
.DESCRIPTION
    Advanced environment detection and dependency installation script that supports:
    - PowerShell 5.x (REQUIRED - Windows 11 default, primary automation environment)
    - PowerShell 7.x (OPTIONAL - supplementary with enhanced profiles)
    - Python on Windows (python.exe) - OPTIONAL
    - WSL with Ubuntu (OPTIONAL with registry-based detection and nopasswd sudo)
    - Python on Ubuntu WSL (OPTIONAL with intelligent fallback)
    - Docker Engine on Ubuntu WSL (OPTIONAL - NO Docker Desktop support)
    - Docker Compose on Ubuntu WSL (OPTIONAL - integrated with Docker Engine)
    
    Script prioritizes PowerShell 5.x for maximum Windows 11 compatibility and provides
    intelligent fallback mechanisms with comprehensive WSL integration.
.PARAMETER Silent
    Run in silent mode with minimal user interaction and automatic defaults
.PARAMETER SkipWSL
    Skip WSL installation and configuration entirely
.PARAMETER SkipDocker
    Skip Docker installation in WSL Ubuntu
.PARAMETER SkipPython
    Skip Python installation checks on both Windows and WSL
.PARAMETER ForceWSLInstall
    Force WSL installation even if already present and configured
.EXAMPLE
    PS> .\Install-Environment-Auto.ps1
    Run with interactive prompts and comprehensive environment detection
.EXAMPLE
    PS> .\Install-Environment-Auto.ps1 -Silent
    Run in silent mode with automatic decisions and logging
.EXAMPLE
    PS> .\Install-Environment-Auto.ps1 -SkipDocker -Silent
    Install everything except Docker Engine in WSL Ubuntu
.NOTES
    Author: Emil Wójcik
    Date: 2025-08-20
    Version: 2.0
    Requires: PowerShell 5.1+ (Windows 11 default), Administrator rights
    Compatible: PowerShell 5.1, 7.x with enhanced profile support
    
    Environment Priority:
    1. Windows 11 + PowerShell 5.x (REQUIRED - Primary automation environment)
    2. PowerShell 7.x with custom profiles (OPTIONAL - Interactive use only)
    3. Python on Windows via python.exe (OPTIONAL - Native Windows development)
    4. WSL Ubuntu with registry-based detection + nopasswd sudo (OPTIONAL)
    5. Python in WSL via wsl python3 (OPTIONAL - Cross-platform fallback)
    6. Docker Engine in WSL Ubuntu only (OPTIONAL - NO Docker Desktop)
    
    WSL Integration Commands:
    - Root operations: wsl --user root bash -c "command"
    - User operations: wsl bash -c "command"
    - Python fallback: wsl python3 -c "script" (when Windows python.exe unavailable)
    - Docker operations: wsl docker <command> (NEVER Docker Desktop)
    
    PowerShell Profile Strategy:
    - PowerShell 5.x: Comprehensive profile with WSL shortcuts and environment functions
    - PowerShell 7.x: Optional enhanced profile with PSReadLine integration
    
    Fixed Issues:
    - WSL sudo command escaping corrected
    - Docker installation for Ubuntu 24.04.3 LTS compatibility
    - PowerShell 7.x version detection formatting cleaned up
    - Registry-based WSL detection implementation
    - Comprehensive profile implementation with working shortcuts
    
    Change Log:
    2.0 - Complete rewrite with fixed command escaping, Docker compatibility, enhanced profiles
    1.0 - Initial comprehensive environment auto-detection system
.LINK
    https://github.com/emilwojcik93/dotfile
.COMPONENT
    Environment Detection and Dependency Management
.ROLE
    DevOps Infrastructure Setup
.FUNCTIONALITY
    Multi-environment dependency installation with intelligent detection and fallback mechanisms
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(HelpMessage = "Run in silent mode with minimal user interaction")]
    [switch]$Silent,
    
    [Parameter(HelpMessage = "Skip WSL installation and configuration")]
    [switch]$SkipWSL,
    
    [Parameter(HelpMessage = "Skip Docker installation in WSL")]
    [switch]$SkipDocker,
    
    [Parameter(HelpMessage = "Skip Python installation checks")]
    [switch]$SkipPython,
    
    [Parameter(HelpMessage = "Force WSL installation even if already present")]
    [switch]$ForceWSLInstall
)

# ==========================================
# INITIALIZATION AND VALIDATION
# ==========================================

# Script variables
${ScriptName} = "Install-Environment-Auto-Enhanced"
${ScriptVersion} = "2.0.0"
${LogPath} = "${env:TEMP}\${ScriptName}.log"
${StartTime} = Get-Date

# Environment detection results
${EnvResults} = @{
    RequiredComponents = @{
        Windows11 = $false
        PowerShell5 = $false
    }
    OptionalComponents = @{
        PowerShell7 = $false
        PythonWindows = $false
        WSL = $false
        WSLUbuntu = $false
        PythonWSL = $false
        DockerWSL = $false
        DockerComposeWSL = $false
    }
    DetectedPaths = @{
        PowerShell5 = ""
        PowerShell7 = ""
        PythonWindows = ""
        WSLExecutable = ""
    }
    Profiles = @{
        PowerShell5Profile = ""
        PowerShell7Profile = ""
    }
    WSLInfo = @{
        DefaultVersion = 0
        Distributions = @()
        UbuntuUser = ""
    }
}

# ==========================================
# LOGGING AND OUTPUT FUNCTIONS
# ==========================================

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR', 'SUCCESS')]
        [string]$Level = 'INFO'
    )
    
    ${Timestamp} = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    ${LogEntry} = "[${Timestamp}] [${Level}] ${Message}"
    
    # Console output with colors
    switch ($Level) {
        'INFO'    { Write-Host ${LogEntry} -ForegroundColor White }
        'WARN'    { Write-Host ${LogEntry} -ForegroundColor Yellow }
        'ERROR'   { Write-Host ${LogEntry} -ForegroundColor Red }
        'SUCCESS' { Write-Host ${LogEntry} -ForegroundColor Green }
    }
    
    # Log to file
    try {
        Add-Content -Path ${LogPath} -Value ${LogEntry} -Encoding UTF8 -ErrorAction SilentlyContinue
    }
    catch {
        # Ignore logging errors to avoid breaking the script
    }
}

function Get-UserPrompt {
    param(
        [string]$Prompt,
        [int]$TimeoutSeconds = 10,
        [string]$DefaultResponse = "n"
    )
    
    if ($Silent) {
        Write-Log "Silent mode: Using default response '${DefaultResponse}' for: ${Prompt}" -Level 'INFO'
        return ${DefaultResponse}
    }
    
    # Enhanced console input detection - handle piped input gracefully
    try {
        # Try multiple methods to detect console input redirection
        $IsInputRedirected = $false
        
        # Method 1: Console.IsInputRedirected (may not work in all PowerShell versions)
        try {
            $IsInputRedirected = [Console]::IsInputRedirected
        }
        catch {
            # Fallback to checking if stdin is available
            $IsInputRedirected = $true
        }
        
        # Method 2: Check if we can access Console.KeyAvailable without exception
        if (-not $IsInputRedirected) {
            try {
                $null = [Console]::KeyAvailable
                $ConsoleInputAvailable = $true
            }
            catch {
                $ConsoleInputAvailable = $false
                $IsInputRedirected = $true
            }
        }
        
        if ($IsInputRedirected) {
            Write-Log "Console input redirected - using default response '${DefaultResponse}' for: ${Prompt}" -Level 'INFO'
            return ${DefaultResponse}
        }
    }
    catch {
        Write-Log "Console detection failed - using default response '${DefaultResponse}': $($_.Exception.Message)" -Level 'WARN'
        return ${DefaultResponse}
    }
    
    Write-Host "${Prompt} (auto-continues in ${TimeoutSeconds}s): " -NoNewline -ForegroundColor Cyan
    
    # Robust timeout approach with proper error handling
    try {
        for ($i = 0; $i -lt ${TimeoutSeconds}; $i++) {
            try {
                if ([Console]::KeyAvailable) {
                    $Response = Read-Host
                    return $Response
                }
            }
            catch {
                # If we can't check KeyAvailable, fall back to default
                Write-Log "Input detection failed - using default response '${DefaultResponse}'" -Level 'WARN'
                Write-Host ""
                return ${DefaultResponse}
            }
            Start-Sleep -Seconds 1
        }
    }
    catch {
        Write-Log "Input timeout error - using default response '${DefaultResponse}': $($_.Exception.Message)" -Level 'WARN'
        Write-Host ""
        return ${DefaultResponse}
    }
    
    Write-Host ""
    Write-Log "No input detected within ${TimeoutSeconds}s, using default: ${DefaultResponse}" -Level 'INFO'
    return ${DefaultResponse}
}

# ==========================================
# ENVIRONMENT DETECTION FUNCTIONS
# ==========================================

function Test-Windows11 {
    Write-Log "Detecting Windows 11..." -Level 'INFO'
    
    try {
        $OSInfo = Get-CimInstance -ClassName Win32_OperatingSystem
        $OSVersion = [System.Environment]::OSVersion.Version
        
        Write-Log "OS Detection - Major: $($OSVersion.Major), Build: $($OSVersion.Build)" -Level 'INFO'
        Write-Log "OS Caption: $($OSInfo.Caption)" -Level 'INFO'
        
        # Windows 11 is version 10.0.22000 or higher
        if ($OSVersion.Major -eq 10 -and $OSVersion.Build -ge 22000) {
            Write-Log "Windows 11 detected: $($OSInfo.Caption) (Build $($OSVersion.Build))" -Level 'SUCCESS'
            ${EnvResults}.RequiredComponents.Windows11 = $true
            ${EnvResults}.DetectedPaths.WindowsVersion = "$($OSInfo.Caption) ($OSVersion)"
            return $true
        }
        elseif ($OSVersion.Major -eq 10 -and $OSVersion.Build -ge 19041) {
            # Windows 10 version 2004 or higher - acceptable fallback
            Write-Log "Windows 10 detected (compatible): $($OSInfo.Caption) (Build $($OSVersion.Build))" -Level 'SUCCESS'
            ${EnvResults}.RequiredComponents.Windows11 = $true
            ${EnvResults}.DetectedPaths.WindowsVersion = "$($OSInfo.Caption) ($OSVersion)"
            return $true
        }
        else {
            Write-Log "Windows 11/10 (2004+) REQUIRED but not detected. Found: $($OSInfo.Caption) (Build $($OSVersion.Build))" -Level 'ERROR'
            ${EnvResults}.RequiredComponents.Windows11 = $false
            return $false
        }
    }
    catch {
        Write-Log "Failed to detect Windows version: $($_.Exception.Message)" -Level 'ERROR'
        ${EnvResults}.RequiredComponents.Windows11 = $false
        return $false
    }
}

function Test-PowerShell5 {
    Write-Log "Detecting PowerShell 5.x..." -Level 'INFO'
    
    try {
        ${PSPath} = where.exe powershell 2>$null | Select-Object -First 1
        if (${PSPath}) {
            ${EnvResults}.DetectedPaths.PowerShell5 = ${PSPath}
            
            # Get version
            ${PSVersion} = powershell.exe -NoProfile -Command '$PSVersionTable.PSVersion.Major'
            if (${PSVersion} -eq 5) {
                Write-Log "PowerShell 5.x detected: ${PSPath} (Version ${PSVersion})" -Level 'SUCCESS'
                ${EnvResults}.RequiredComponents.PowerShell5 = $true
                
                # Detect profile path
                ${ProfilePath} = powershell.exe -NoProfile -Command 'Split-Path $PROFILE -Parent'
                if (${ProfilePath} -and (Test-Path ${ProfilePath})) {
                    ${EnvResults}.Profiles.PowerShell5Profile = Join-Path ${ProfilePath} "Microsoft.PowerShell_profile.ps1"
                    Write-Log "PowerShell 5.x profile location: $(${EnvResults}.Profiles.PowerShell5Profile)" -Level 'INFO'
                }
                
                return $true
            }
        }
        
        Write-Log "PowerShell 5.x REQUIRED but not found in PATH" -Level 'ERROR'
        ${EnvResults}.RequiredComponents.PowerShell5 = $false
        return $false
    }
    catch {
        Write-Log "Failed to detect PowerShell 5.x: ${_}" -Level 'ERROR'
        ${EnvResults}.RequiredComponents.PowerShell5 = $false
        return $false
    }
}

function Test-PowerShell7 {
    Write-Log "Detecting PowerShell 7.x (optional)..." -Level 'INFO'
    
    try {
        ${PSPath} = where.exe pwsh 2>$null | Select-Object -First 1
        if (${PSPath}) {
            ${EnvResults}.DetectedPaths.PowerShell7 = ${PSPath}
            
            # Get clean version string
            ${PSVersionString} = pwsh.exe -NoProfile -Command '$PSVersionTable.PSVersion.ToString()'
            Write-Log "PowerShell 7.x detected: ${PSPath} (Version ${PSVersionString})" -Level 'SUCCESS'
            ${EnvResults}.OptionalComponents.PowerShell7 = $true
            
            # Detect profile path
            ${ProfilePath} = pwsh.exe -NoProfile -Command 'Split-Path $PROFILE -Parent'
            if (${ProfilePath} -and (Test-Path ${ProfilePath})) {
                ${EnvResults}.Profiles.PowerShell7Profile = Join-Path ${ProfilePath} "Microsoft.PowerShell_profile.ps1"
                Write-Log "PowerShell 7.x profile location: $(${EnvResults}.Profiles.PowerShell7Profile)" -Level 'INFO'
            }
            
            return $true
        }
        else {
            Write-Log "PowerShell 7.x not found (optional component)" -Level 'WARN'
            return $false
        }
    }
    catch {
        Write-Log "Failed to detect PowerShell 7.x: ${_}" -Level 'WARN'
        return $false
    }
}

function Test-PythonWindows {
    if ($SkipPython) {
        Write-Log "Skipping Python detection (user requested)" -Level 'INFO'
        return $false
    }
    
    Write-Log "Detecting Python on Windows (optional)..." -Level 'INFO'
    
    try {
        ${PythonPath} = where.exe python 2>$null | Select-Object -First 1
        if (${PythonPath}) {
            ${EnvResults}.DetectedPaths.PythonWindows = ${PythonPath}
            
            # Get version
            ${PythonVersion} = python.exe --version 2>&1
            Write-Log "Python on Windows detected: ${PythonPath} (${PythonVersion})" -Level 'SUCCESS'
            ${EnvResults}.OptionalComponents.PythonWindows = $true
            return $true
        }
        else {
            Write-Log "Python not found on Windows (optional - can use WSL Python)" -Level 'WARN'
            return $false
        }
    }
    catch {
        Write-Log "Failed to detect Python on Windows: ${_}" -Level 'WARN'
        return $false
    }
}

function Test-WSL {
    if ($SkipWSL) {
        Write-Log "Skipping WSL detection (user requested)" -Level 'INFO'
        return $false
    }
    
    Write-Log "Detecting WSL (optional)..." -Level 'INFO'
    
    try {
        ${WSLPath} = where.exe wsl 2>$null | Select-Object -First 1
        if (${WSLPath}) {
            ${EnvResults}.DetectedPaths.WSLExecutable = ${WSLPath}
            
            # Check WSL status
            ${WSLStatus} = wsl.exe --status 2>&1
            Write-Log "WSL executable detected: ${WSLPath}" -Level 'SUCCESS'
            Write-Log "WSL Status: ${WSLStatus}" -Level 'INFO'
            ${EnvResults}.OptionalComponents.WSL = $true
            
            # Enhanced registry-based WSL detection
            try {
                $WSLRegistryPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss"
                $WSLRegistry = Get-ItemProperty -Path $WSLRegistryPath -ErrorAction SilentlyContinue
                
                if ($WSLRegistry) {
                    Write-Log "WSL registry configuration found" -Level 'SUCCESS'
                    
                    # Get default WSL version from registry
                    $DefaultVersion = $WSLRegistry.DefaultVersion
                    if ($DefaultVersion) {
                        ${EnvResults}.WSLInfo.DefaultVersion = $DefaultVersion
                        Write-Log "WSL Default Version: $DefaultVersion" -Level 'INFO'
                    }
                    
                    # Get distribution information from registry
                    $DistroKeys = Get-ChildItem -Path $WSLRegistryPath -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '\{.*\}' }
                    foreach ($distroKey in $DistroKeys) {
                        $distroInfo = Get-ItemProperty -Path $distroKey.PSPath -ErrorAction SilentlyContinue
                        if ($distroInfo -and $distroInfo.DistributionName) {
                            ${EnvResults}.WSLInfo.Distributions += $distroInfo.DistributionName
                            Write-Log "Found WSL distribution in registry: $($distroInfo.DistributionName)" -Level 'INFO'
                            
                            if ($distroInfo.DistributionName -match "Ubuntu") {
                                ${EnvResults}.OptionalComponents.WSLUbuntu = $true
                                Write-Log "Ubuntu distribution confirmed via registry" -Level 'SUCCESS'
                                
                                # Get Ubuntu user from registry if available
                                if ($distroInfo.DefaultUid) {
                                    Write-Log "Ubuntu default UID from registry: $($distroInfo.DefaultUid)" -Level 'INFO'
                                }
                            }
                        }
                    }
                }
                else {
                    Write-Log "WSL registry entries not found - fallback to command detection" -Level 'WARN'
                }
            }
            catch {
                Write-Log "Could not read WSL registry entries: $_" -Level 'WARN'
            }
            
            # Fallback: Check for Ubuntu distribution via command line (handle Unicode properly)
            if (-not ${EnvResults.OptionalComponents.WSLUbuntu}) {
                try {
                    # Use PowerShell native approach to handle Unicode issues
                    $WSLListOutput = & wsl.exe --list --quiet 2>&1
                    $WSLDistros = @()
                    
                    foreach ($line in $WSLListOutput) {
                        $cleanLine = $line -replace "`0", "" -replace "\s+", " "
                        $cleanLine = $cleanLine.Trim()
                        if ($cleanLine -and $cleanLine -ne "") {
                            $WSLDistros += $cleanLine
                            Write-Log "Found WSL distribution: '$cleanLine'" -Level 'INFO'
                        }
                    }
                    
                    foreach ($distro in $WSLDistros) {
                        if ($distro -match "Ubuntu") {
                            Write-Log "Ubuntu distribution found via command: $distro" -Level 'SUCCESS'
                            ${EnvResults}.OptionalComponents.WSLUbuntu = $true
                            
                            # Test WSL Ubuntu accessibility and get user info
                            try {
                                ${UbuntuVersion} = wsl.exe bash -c "lsb_release -d" 2>&1
                                if ($LASTEXITCODE -eq 0) {
                                    Write-Log "Ubuntu in WSL: ${UbuntuVersion}" -Level 'SUCCESS'
                                    
                                    # Get WSL user for later sudo configuration
                                    ${WSLUser} = wsl.exe bash -c "whoami" 2>&1
                                    if ($LASTEXITCODE -eq 0 -and ${WSLUser}) {
                                        ${EnvResults}.WSLInfo.UbuntuUser = ${WSLUser}.Trim()
                                        Write-Log "WSL Ubuntu user detected: ${WSLUser}" -Level 'INFO'
                                    }
                                }
                                else {
                                    Write-Log "Ubuntu detected but not fully accessible" -Level 'WARN'
                                }
                            }
                            catch {
                                Write-Log "Ubuntu detected but not accessible: $_" -Level 'WARN'
                            }
                            break
                        }
                    }
                    
                    if (-not ${EnvResults}.OptionalComponents.WSLUbuntu) {
                        Write-Log "Ubuntu distribution not found in WSL" -Level 'WARN'
                        Write-Log "Available distributions: $($WSLDistros -join ', ')" -Level 'INFO'
                    }
                }
                catch {
                    Write-Log "Failed to check WSL distributions: $_" -Level 'WARN'
                }
            }
            
            return $true
        }
        else {
            Write-Log "WSL not found (optional component)" -Level 'WARN'
            return $false
        }
    }
    catch {
        Write-Log "Failed to detect WSL: $_" -Level 'WARN'
        return $false
    }
}

function Test-PythonWSL {
    if ($SkipPython -or -not ${EnvResults}.OptionalComponents.WSLUbuntu) {
        return $false
    }
    
    Write-Log "Detecting Python in WSL Ubuntu (optional)..." -Level 'INFO'
    
    try {
        ${PythonVersion} = wsl.exe bash -c "python3 --version" 2>&1
        if (${LASTEXITCODE} -eq 0) {
            Write-Log "Python in WSL detected: ${PythonVersion}" -Level 'SUCCESS'
            ${EnvResults}.OptionalComponents.PythonWSL = $true
            return $true
        }
        else {
            Write-Log "Python not found in WSL Ubuntu" -Level 'WARN'
            return $false
        }
    }
    catch {
        Write-Log "Failed to detect Python in WSL: ${_}" -Level 'WARN'
        return $false
    }
}

function Test-DockerWSL {
    if ($SkipDocker -or -not ${EnvResults}.OptionalComponents.WSLUbuntu) {
        return $false
    }
    
    Write-Log "Detecting Docker in WSL Ubuntu (optional)..." -Level 'INFO'
    
    try {
        ${DockerVersion} = wsl.exe bash -c "docker --version" 2>&1
        if (${LASTEXITCODE} -eq 0) {
            Write-Log "Docker in WSL detected: ${DockerVersion}" -Level 'SUCCESS'
            ${EnvResults}.OptionalComponents.DockerWSL = $true
            
            # Check Docker Compose
            ${ComposeVersion} = wsl.exe bash -c "docker compose version" 2>&1
            if (${LASTEXITCODE} -eq 0) {
                Write-Log "Docker Compose in WSL detected: ${ComposeVersion}" -Level 'SUCCESS'
                ${EnvResults}.OptionalComponents.DockerComposeWSL = $true
            }
            
            return $true
        }
        else {
            Write-Log "Docker not found in WSL Ubuntu" -Level 'WARN'
            return $false
        }
    }
    catch {
        Write-Log "Failed to detect Docker in WSL: ${_}" -Level 'WARN'
        return $false
    }
}

# ==========================================
# INSTALLATION FUNCTIONS
# ==========================================

function Install-WSLUbuntu {
    Write-Log "Installing WSL with Ubuntu..." -Level 'INFO'
    
    if (-not $ForceWSLInstall -and ${EnvResults.OptionalComponents.WSLUbuntu}) {
        Write-Log "WSL Ubuntu already available" -Level 'INFO'
        return $true
    }
    
    try {
        ${Response} = Get-UserPrompt "Install WSL with Ubuntu? (y/N)" 10 "n"
        if (${Response} -notmatch '^y(es)?$') {
            Write-Log "WSL installation skipped by user" -Level 'WARN'
            return $false
        }
        
        Write-Log "Installing WSL Ubuntu (this may take several minutes)..." -Level 'INFO'
        
        # Enable WSL features
        Write-Log "Enabling Windows features for WSL..." -Level 'INFO'
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -All -NoRestart
        Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -All -NoRestart
        
        # Install Ubuntu
        wsl.exe --install Ubuntu --no-launch
        
        if (${LASTEXITCODE} -eq 0) {
            Write-Log "WSL Ubuntu installation completed successfully" -Level 'SUCCESS'
            Write-Log "NOTE: A system restart may be required to complete WSL setup" -Level 'WARN'
            ${EnvResults}.OptionalComponents.WSL = $true
            ${EnvResults}.OptionalComponents.WSLUbuntu = $true
            return $true
        }
        else {
            Write-Log "WSL Ubuntu installation failed with exit code ${LASTEXITCODE}" -Level 'ERROR'
            return $false
        }
    }
    catch {
        Write-Log "Failed to install WSL Ubuntu: ${_}" -Level 'ERROR'
        return $false
    }
}

function Set-WSLSudoNoPassword {
    if (-not ${EnvResults.OptionalComponents.WSLUbuntu}) {
        return $false
    }
    
    Write-Log "Configuring WSL Ubuntu sudo nopasswd..." -Level 'INFO'
    
    try {
        # Check current sudo configuration first
        ${SudoCheck} = wsl.exe --user root bash -c "sudo -l" 2>&1
        if (${SudoCheck} -match "NOPASSWD") {
            Write-Log "WSL sudo nopasswd already configured" -Level 'INFO'
            return $true
        }
        
        ${Response} = Get-UserPrompt "Configure WSL Ubuntu for passwordless sudo? (Y/n)" 10 "y"
        if (${Response} -notmatch '^y(es)?$|^$') {
            Write-Log "WSL sudo configuration skipped by user" -Level 'WARN'
            return $false
        }
        
        Write-Log "Adding nopasswd entry to WSL Ubuntu sudoers..." -Level 'INFO'
        
        # Get WSL username - use cached value or detect
        ${WSLUser} = ${EnvResults}.WSLInfo.UbuntuUser
        if (-not ${WSLUser}) {
            ${WSLUser} = wsl.exe bash -c "whoami" 2>&1
            if ($LASTEXITCODE -eq 0) {
                ${WSLUser} = ${WSLUser}.Trim()
                ${EnvResults}.WSLInfo.UbuntuUser = ${WSLUser}
            }
            else {
                Write-Log "Failed to get WSL username" -Level 'ERROR'
                return $false
            }
        }
        
        Write-Log "Creating sudoers entry for user: ${WSLUser}" -Level 'INFO'
        
        # FIXED: Proper command escaping for WSL sudo configuration
        # Split the command to avoid escaping issues with parentheses and special characters
        $SudoersEntry = "${WSLUser} ALL=(ALL) NOPASSWD: ALL"
        $TempFile = "/tmp/sudoers_entry"
        
        # Step 1: Create the entry in a temp file to avoid command line escaping issues
        wsl.exe --user root bash -c "echo '${SudoersEntry}' > ${TempFile}"
        
        if ($LASTEXITCODE -eq 0) {
            # Step 2: Append the temp file to sudoers
            wsl.exe --user root bash -c "echo >> /etc/sudoers && cat ${TempFile} >> /etc/sudoers"
            
            if ($LASTEXITCODE -eq 0) {
                # Step 3: Clean up temp file
                wsl.exe --user root bash -c "rm -f ${TempFile}"
                
                # Verify the configuration
                ${VerifyResult} = wsl.exe --user root bash -c "sudo -l" 2>&1
                Write-Log "WSL sudo nopasswd configured successfully" -Level 'SUCCESS'
                Write-Log "Verification result: ${VerifyResult}" -Level 'INFO'
                
                # Test that regular user can use sudo without password
                $TestSudo = wsl.exe bash -c "sudo -n whoami" 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Log "Sudo nopasswd configuration verified for user ${WSLUser}" -Level 'SUCCESS'
                }
                else {
                    Write-Log "Warning: Sudo configuration may require WSL restart" -Level 'WARN'
                }
                
                return $true
            }
            else {
                Write-Log "Failed to append sudoers entry" -Level 'ERROR'
                wsl.exe --user root bash -c "rm -f ${TempFile}" # Cleanup on failure
                return $false
            }
        }
        else {
            Write-Log "Failed to create temporary sudoers entry" -Level 'ERROR'
            return $false
        }
    }
    catch {
        Write-Log "Failed to configure WSL sudo: ${_}" -Level 'ERROR'
        return $false
    }
}

function Install-PythonWSL {
    if ($SkipPython -or -not ${EnvResults.OptionalComponents.WSLUbuntu}) {
        return $false
    }
    
    if (${EnvResults.OptionalComponents.PythonWSL}) {
        Write-Log "Python already available in WSL" -Level 'INFO'
        return $true
    }
    
    Write-Log "Installing Python in WSL Ubuntu..." -Level 'INFO'
    
    try {
        ${Response} = Get-UserPrompt "Install Python in WSL Ubuntu? (y/N)" 10 "y"
        if (${Response} -notmatch '^y(es)?$') {
            Write-Log "Python WSL installation skipped by user" -Level 'WARN'
            return $false
        }
        
        Write-Log "Updating WSL Ubuntu package list..." -Level 'INFO'
        wsl.exe bash -c "sudo apt update"
        
        Write-Log "Installing Python and essential packages in WSL..." -Level 'INFO'
        wsl.exe bash -c "sudo apt install -y python3 python3-pip python3-venv python3-dev"
        
        if (${LASTEXITCODE} -eq 0) {
            ${PythonVersion} = wsl.exe bash -c "python3 --version" 2>&1
            Write-Log "Python installed successfully in WSL: ${PythonVersion}" -Level 'SUCCESS'
            ${EnvResults.OptionalComponents.PythonWSL} = $true
            return $true
        }
        else {
            Write-Log "Failed to install Python in WSL" -Level 'ERROR'
            return $false
        }
    }
    catch {
        Write-Log "Failed to install Python in WSL: ${_}" -Level 'ERROR'
        return $false
    }
}

function Install-DockerWSL {
    if ($SkipDocker -or -not ${EnvResults.OptionalComponents.WSLUbuntu}) {
        return $false
    }
    
    if (${EnvResults.OptionalComponents.DockerWSL}) {
        Write-Log "Docker already available in WSL" -Level 'INFO'
        return $true
    }
    
    Write-Log "Installing Docker Engine in WSL Ubuntu (NO Docker Desktop)..." -Level 'INFO'
    
    try {
        ${Response} = Get-UserPrompt "Install Docker Engine in WSL Ubuntu? (Y/n)" 10 "y"
        if (${Response} -notmatch '^y(es)?$|^$') {
            Write-Log "Docker WSL installation skipped by user" -Level 'WARN'
            return $false
        }
        
        Write-Log "IMPORTANT: Installing Docker ENGINE in WSL - NOT Docker Desktop" -Level 'WARN'
        Write-Log "All Docker operations will be via: wsl docker command" -Level 'INFO'
        
        # FIXED: Remove old Docker packages safely with proper error handling
        Write-Log "Checking for conflicting Docker packages..." -Level 'INFO'
        $OldPackages = @("docker.io", "docker-doc", "docker-compose", "docker-compose-v2", "podman-docker", "containerd", "runc")
        
        # Check which packages are actually installed before trying to remove them
        foreach ($pkg in $OldPackages) {
            $PackageExists = wsl.exe bash -c "dpkg -l | grep -w $pkg | wc -l" 2>&1
            if ($LASTEXITCODE -eq 0 -and [int]$PackageExists -gt 0) {
                Write-Log "Removing conflicting package: $pkg" -Level 'INFO'
                wsl.exe bash -c "sudo apt-get remove $pkg -y" 2>&1 | Out-Null
            }
        }
        
        # Update package database
        Write-Log "Updating package database..." -Level 'INFO'
        wsl.exe bash -c "sudo apt-get update"
        
        # Install prerequisites
        Write-Log "Installing Docker prerequisites..." -Level 'INFO'
        wsl.exe bash -c "sudo apt-get install -y ca-certificates curl"
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Failed to install prerequisites" -Level 'ERROR'
            return $false
        }
        
        # Add Docker GPG key
        Write-Log "Adding Docker GPG key..." -Level 'INFO'
        wsl.exe bash -c "sudo install -m 0755 -d /etc/apt/keyrings"
        wsl.exe bash -c "sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc"
        wsl.exe bash -c "sudo chmod a+r /etc/apt/keyrings/docker.asc"
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Failed to add Docker GPG key" -Level 'ERROR'
            return $false
        }
        
        # FIXED: Add Docker repository with proper Ubuntu 24.04.3 LTS support
        Write-Log "Adding Docker repository..." -Level 'INFO'
        $RepoCommand = 'echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "${VERSION_CODENAME}") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null'
        wsl.exe bash -c $RepoCommand
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Failed to add Docker repository" -Level 'ERROR'
            return $false
        }
        
        # Update package database with Docker repository
        Write-Log "Updating package database with Docker repository..." -Level 'INFO'
        wsl.exe bash -c "sudo apt-get update"
        
        # TROUBLESHOOTING: Check if packages are available before installation
        Write-Log "Checking Docker package availability..." -Level 'INFO'
        $DockerAvailable = wsl.exe bash -c "apt-cache policy docker-ce | grep -c 'Candidate:'" 2>&1
        
        if ([int]$DockerAvailable -eq 0) {
            Write-Log "Docker CE packages not available - trying alternative approach" -Level 'WARN'
            
            # Try using convenience script as fallback for Ubuntu 24.04.3
            Write-Log "Using Docker convenience installation script..." -Level 'INFO'
            wsl.exe bash -c "curl -fsSL https://get.docker.com -o get-docker.sh"
            wsl.exe bash -c "sudo sh get-docker.sh"
            
            if ($LASTEXITCODE -ne 0) {
                Write-Log "Docker convenience script installation failed" -Level 'ERROR'
                return $false
            }
        }
        else {
            # Install Docker using apt packages
            Write-Log "Installing Docker Engine, CLI, and Docker Compose..." -Level 'INFO'
            wsl.exe bash -c "sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"
            
            if ($LASTEXITCODE -ne 0) {
                Write-Log "Failed to install Docker packages via apt" -Level 'ERROR'
                return $false
            }
        }
        
        # Start Docker service
        Write-Log "Starting Docker service..." -Level 'INFO'
        wsl.exe bash -c "sudo service docker start"
        
        # Create docker group and add user
        Write-Log "Configuring Docker user permissions..." -Level 'INFO'
        ${WSLUser} = ${EnvResults}.WSLInfo.UbuntuUser
        if (-not ${WSLUser}) {
            ${WSLUser} = wsl.exe bash -c "whoami" 2>&1
        }
        
        wsl.exe bash -c "sudo groupadd docker" 2>&1 | Out-Null  # May already exist
        wsl.exe bash -c "sudo usermod -aG docker ${WSLUser}"
        
        # Test Docker installation
        Write-Log "Testing Docker installation..." -Level 'INFO'
        ${DockerVersion} = wsl.exe bash -c "docker --version" 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Docker installed successfully: ${DockerVersion}" -Level 'SUCCESS'
            ${EnvResults.OptionalComponents.DockerWSL} = $true
            
            # Check Docker Compose
            ${ComposeVersion} = wsl.exe bash -c "docker compose version" 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Docker Compose available: ${ComposeVersion}" -Level 'SUCCESS'
                ${EnvResults.OptionalComponents.DockerComposeWSL} = $true
            }
            
            Write-Log "IMPORTANT: Use Docker via WSL commands only:" -Level 'WARN'
            Write-Log "  wsl docker <command>" -Level 'INFO'
            Write-Log "  wsl docker compose <command>" -Level 'INFO'
            Write-Log "NEVER use Docker Desktop - all operations via WSL!" -Level 'ERROR'
            
            # Test with hello-world (optional)
            Write-Log "Running Docker hello-world test..." -Level 'INFO'
            $HelloTest = wsl.exe bash -c "sudo docker run --rm hello-world" 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Docker hello-world test successful" -Level 'SUCCESS'
            }
            else {
                Write-Log "Docker hello-world test failed - but Docker is installed" -Level 'WARN'
            }
            
            return $true
        }
        else {
            Write-Log "Docker installation completed but version check failed" -Level 'ERROR'
            return $false
        }
    }
    catch {
        Write-Log "Failed to install Docker in WSL: ${_}" -Level 'ERROR'
        return $false
    }
}

function Install-PowerShellProfiles {
    Write-Log "Setting up comprehensive PowerShell profiles..." -Level 'INFO'
    
    # PowerShell 5.x Profile (PRIMARY - RECOMMENDED)
    if (${EnvResults}.RequiredComponents.PowerShell5 -and ${EnvResults}.Profiles.PowerShell5Profile) {
        Write-Log "Configuring PowerShell 5.x profile (PRIMARY)..." -Level 'INFO'
        
        if (-not (Test-Path ${EnvResults}.Profiles.PowerShell5Profile)) {
            ${Response} = Get-UserPrompt "Create PowerShell 5.x profile? (Y/n)" 10 "y"
            if (${Response} -match '^y(es)?$|^$') {
                ${ProfileDir} = Split-Path ${EnvResults}.Profiles.PowerShell5Profile -Parent
                New-Item -Path ${ProfileDir} -ItemType Directory -Force | Out-Null
                
                ${ProfileContent} = @"
# PowerShell 5.x Profile - IaC Edition Enhanced
# Optimized for Windows 11 automation and WSL integration
# Author: Emil Wójcik - Auto-generated by Install-Environment-Auto-Enhanced

# ==========================================
# ENCODING AND COMPATIBILITY
# ==========================================
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

# ==========================================
# ENHANCED PROMPT WITH GIT INTEGRATION
# ==========================================
function prompt {
    `${CurrentPath} = `${pwd}.Path
    if (`${CurrentPath}.Length -gt 50) {
        `${CurrentPath} = "..." + `${CurrentPath}.Substring(`${CurrentPath}.Length - 47)
    }
    
    Write-Host "PS " -NoNewline -ForegroundColor Green
    Write-Host `${CurrentPath} -NoNewline -ForegroundColor Cyan
    
    # Git branch info if available
    if (Get-Command git -ErrorAction SilentlyContinue) {
        `${GitBranch} = git branch --show-current 2>`$null
        if (`${GitBranch}) {
            Write-Host " [" -NoNewline -ForegroundColor DarkGray
            Write-Host `${GitBranch} -NoNewline -ForegroundColor Yellow
            Write-Host "]" -NoNewline -ForegroundColor DarkGray
        }
    }
    
    return "> "
}

# ==========================================
# SYSTEM INFORMATION FUNCTION
# ==========================================
function sysinfo {
    Write-Host "=== SYSTEM INFORMATION ===" -ForegroundColor Green
    Write-Host "OS: " -NoNewline
    Write-Host (Get-CimInstance Win32_OperatingSystem).Caption -ForegroundColor Cyan
    Write-Host "Build: " -NoNewline
    Write-Host ([System.Environment]::OSVersion.Version) -ForegroundColor Cyan
    Write-Host "PowerShell: " -NoNewline  
    Write-Host `${PSVersionTable}.PSVersion -ForegroundColor Cyan
    Write-Host "Execution Policy: " -NoNewline
    Write-Host (Get-ExecutionPolicy) -ForegroundColor Cyan
    
    if (Get-Command python -ErrorAction SilentlyContinue) {
        Write-Host "Python (Windows): " -NoNewline
        Write-Host (python --version 2>&1) -ForegroundColor Green
    }
    
    if (Get-Command wsl -ErrorAction SilentlyContinue) {
        Write-Host "WSL: " -NoNewline
        Write-Host "Available" -ForegroundColor Green
        try {
            `${WSLVersion} = wsl bash -c "lsb_release -d" 2>&1
            if (`$LASTEXITCODE -eq 0) {
                Write-Host "WSL Ubuntu: " -NoNewline
                Write-Host `${WSLVersion} -ForegroundColor Green
            }
            `${WSLPython} = wsl python3 --version 2>&1
            if (`$LASTEXITCODE -eq 0) {
                Write-Host "Python (WSL): " -NoNewline
                Write-Host `${WSLPython} -ForegroundColor Green
            }
        } catch {
            Write-Host "WSL: Available but not accessible" -ForegroundColor Yellow
        }
    }
    
    if (Get-Command wsl -ErrorAction SilentlyContinue) {
        try {
            `${DockerVersion} = wsl docker --version 2>&1
            if (`$LASTEXITCODE -eq 0) {
                Write-Host "Docker (WSL): " -NoNewline
                Write-Host `${DockerVersion} -ForegroundColor Green
            }
        } catch {
            Write-Host "Docker: Not available" -ForegroundColor Yellow
        }
    }
    Write-Host "===========================" -ForegroundColor Green
}

# ==========================================
# DEVELOPMENT ENVIRONMENT VALIDATION
# ==========================================
function Test-DevEnvironment {
    Write-Host "=== DEVELOPMENT ENVIRONMENT VALIDATION ===" -ForegroundColor Magenta
    
    `${Issues} = @()
    
    # Test PowerShell
    Write-Host "PowerShell 5.x: " -NoNewline
    if (`$PSVersionTable.PSVersion.Major -eq 5) {
        Write-Host "OK" -ForegroundColor Green
    } else {
        Write-Host "ISSUE - Not PowerShell 5.x" -ForegroundColor Red
        `${Issues} += "PowerShell version"
    }
    
    # Test Python Windows
    Write-Host "Python (Windows): " -NoNewline
    if (Get-Command python -ErrorAction SilentlyContinue) {
        Write-Host "OK" -ForegroundColor Green
    } else {
        Write-Host "Optional - Not found" -ForegroundColor Yellow
    }
    
    # Test WSL
    Write-Host "WSL: " -NoNewline
    if (Get-Command wsl -ErrorAction SilentlyContinue) {
        Write-Host "OK" -ForegroundColor Green
        
        # Test WSL Ubuntu
        Write-Host "WSL Ubuntu: " -NoNewline
        try {
            wsl bash -c "echo 'test'" 2>&1 | Out-Null
            if (`$LASTEXITCODE -eq 0) {
                Write-Host "OK" -ForegroundColor Green
            } else {
                Write-Host "ISSUE - Not accessible" -ForegroundColor Red
                `${Issues} += "WSL Ubuntu accessibility"
            }
        } catch {
            Write-Host "ISSUE - Not accessible" -ForegroundColor Red
            `${Issues} += "WSL Ubuntu"
        }
        
        # Test WSL Python
        Write-Host "Python (WSL): " -NoNewline
        try {
            wsl python3 --version 2>&1 | Out-Null
            if (`$LASTEXITCODE -eq 0) {
                Write-Host "OK" -ForegroundColor Green
            } else {
                Write-Host "Optional - Not found" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "Optional - Not found" -ForegroundColor Yellow
        }
        
        # Test Docker in WSL
        Write-Host "Docker (WSL): " -NoNewline
        try {
            wsl docker --version 2>&1 | Out-Null
            if (`$LASTEXITCODE -eq 0) {
                Write-Host "OK" -ForegroundColor Green
            } else {
                Write-Host "Optional - Not found" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "Optional - Not found" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Optional - Not found" -ForegroundColor Yellow
    }
    
    # Test Git
    Write-Host "Git: " -NoNewline
    if (Get-Command git -ErrorAction SilentlyContinue) {
        Write-Host "OK" -ForegroundColor Green
    } else {
        Write-Host "Recommended - Not found" -ForegroundColor Yellow
    }
    
    Write-Host "=========================================" -ForegroundColor Magenta
    
    if (`${Issues}.Count -eq 0) {
        Write-Host "Environment validation: " -NoNewline
        Write-Host "PASSED" -ForegroundColor Green
    } else {
        Write-Host "Environment validation: " -NoNewline
        Write-Host "ISSUES FOUND" -ForegroundColor Red
        Write-Host "Issues: " -NoNewline
        Write-Host (`${Issues} -join ", ") -ForegroundColor Red
    }
}

# ==========================================
# WSL INTEGRATION SHORTCUTS
# ==========================================
if (Get-Command wsl -ErrorAction SilentlyContinue) {
    # Python shortcuts
    function wpy { wsl python3 `$args }
    function wpip { wsl python3 -m pip `$args }
    
    # Docker shortcuts (if available)
    function wdocker { wsl docker `$args }
    function wcompose { wsl docker compose `$args }
    
    # General WSL shortcuts
    function wbash { wsl bash `$args }
    function wsh { wsl bash -c `$args }
}

# ==========================================
# DIRECTORY NAVIGATION SHORTCUTS
# ==========================================
function ll { Get-ChildItem -Force `$args | Format-Table -AutoSize }
function la { Get-ChildItem -Force -Hidden `$args | Format-Table -AutoSize }
function .. { Set-Location .. }
function ... { Set-Location ..\.. }
function .... { Set-Location ..\..\.. }

# ==========================================
# GIT SHORTCUTS
# ==========================================
if (Get-Command git -ErrorAction SilentlyContinue) {
    function gs { git status }
    function ga { git add `$args }
    function gc { git commit -m `$args }
    function gp { git push }
    function gl { git log --oneline -10 }
    function gb { git branch }
    function gco { git checkout `$args }
}

# ==========================================
# UTILITY FUNCTIONS
# ==========================================
function which(`$name) {
    Get-Command `$name -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Definition
}

function grep(`$regex, `$dir) {
    if (`$dir) {
        Get-ChildItem `$dir | select-string `$regex
    } else {
        `$input | select-string `$regex
    }
}

# ==========================================
# STARTUP MESSAGE
# ==========================================
Write-Host ""
Write-Host "PowerShell 5.x Profile Loaded - IaC Edition Enhanced" -ForegroundColor Green
Write-Host "Available commands:" -ForegroundColor Yellow
Write-Host "  sysinfo          - Show detailed system information" -ForegroundColor Cyan
Write-Host "  Test-DevEnvironment - Validate development environment" -ForegroundColor Cyan
Write-Host "  ll, la           - Enhanced directory listing" -ForegroundColor Cyan
Write-Host "  .., ..., ....    - Quick directory navigation" -ForegroundColor Cyan
Write-Host "  gs, ga, gc, gp, gl - Git shortcuts" -ForegroundColor Cyan
if (Get-Command wsl -ErrorAction SilentlyContinue) {
    Write-Host "  wpy, wpip        - WSL Python shortcuts" -ForegroundColor Cyan
    Write-Host "  wdocker, wcompose - WSL Docker shortcuts" -ForegroundColor Cyan
    Write-Host "  wbash, wsh       - WSL shell shortcuts" -ForegroundColor Cyan
}
Write-Host ""

"@
                
                Set-Content -Path ${EnvResults}.Profiles.PowerShell5Profile -Value ${ProfileContent} -Encoding UTF8
                Write-Log "PowerShell 5.x profile created: $(${EnvResults}.Profiles.PowerShell5Profile)" -Level 'SUCCESS'
            }
        }
        else {
            Write-Log "PowerShell 5.x profile already exists: $(${EnvResults}.Profiles.PowerShell5Profile)" -Level 'INFO'
        }
    }
    
    # PowerShell 7.x Profile (OPTIONAL - SUPPLEMENTARY)
    if (${EnvResults}.OptionalComponents.PowerShell7 -and ${EnvResults}.Profiles.PowerShell7Profile) {
        Write-Log "Configuring PowerShell 7.x profile (supplementary)..." -Level 'INFO'
        
        if (-not (Test-Path ${EnvResults}.Profiles.PowerShell7Profile)) {
            ${Response} = Get-UserPrompt "Create PowerShell 7.x profile? (y/N)" 10 "n"
            if (${Response} -match '^y(es)?$') {
                ${ProfileDir} = Split-Path ${EnvResults}.Profiles.PowerShell7Profile -Parent
                New-Item -Path ${ProfileDir} -ItemType Directory -Force | Out-Null
                
                ${ProfileContent} = @"
# PowerShell 7.x Profile - IaC Edition Enhanced
# Supplementary profile - Use PowerShell 5.x as primary for automation
# Author: Emil Wójcik - Auto-generated by Install-Environment-Auto-Enhanced

# ==========================================
# WARNING AND COMPATIBILITY NOTICE
# ==========================================
Write-Host "PowerShell 7.x Profile Loaded - IaC Edition Enhanced" -ForegroundColor Green
Write-Host "WARNING: Use PowerShell 5.x for automation scripts" -ForegroundColor Yellow
Write-Host "Note: This profile may interfere with VS Code CLI commands" -ForegroundColor Yellow

# ==========================================
# ENHANCED FEATURES FOR INTERACTIVE USE
# ==========================================
if (Get-Module -ListAvailable PSReadLine) {
    Set-PSReadLineOption -EditMode Emacs
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineKeyHandler -Key Tab -Function Complete
}

# ==========================================
# LOAD POWERSHELL 5.x COMPATIBLE FUNCTIONS
# ==========================================
`${PS5Profile} = "$(${EnvResults}.Profiles.PowerShell5Profile)"
if (Test-Path `${PS5Profile}) {
    Write-Host "Loading PowerShell 5.x compatible functions..." -ForegroundColor Cyan
    . `${PS5Profile}
}

# ==========================================
# POWERSHELL 7.x SPECIFIC ENHANCEMENTS
# ==========================================
# Additional features that work better in PowerShell 7.x
if (`$PSVersionTable.PSVersion.Major -ge 7) {
    # Enhanced error handling
    `$ErrorActionPreference = 'Stop'
    
    # Additional aliases for PowerShell 7.x
    Set-Alias -Name 'touch' -Value 'New-Item'
    Set-Alias -Name 'curl' -Value 'Invoke-WebRequest'
}

Write-Host "Available in PowerShell 7.x: All PowerShell 5.x functions plus enhanced features" -ForegroundColor Cyan
Write-Host ""

"@
                
                Set-Content -Path ${EnvResults}.Profiles.PowerShell7Profile -Value ${ProfileContent} -Encoding UTF8
                Write-Log "PowerShell 7.x profile created: $(${EnvResults}.Profiles.PowerShell7Profile)" -Level 'SUCCESS'
                Write-Log "NOTE: PowerShell 7.x profiles may interfere with VS Code CLI" -Level 'WARN'
            }
        }
        else {
            Write-Log "PowerShell 7.x profile already exists" -Level 'INFO'
        }
    }
}

# ==========================================
# MAIN EXECUTION FLOW
# ==========================================

function Show-EnvironmentSummary {
    Write-Log "Environment Detection Summary" -Level 'INFO'
    Write-Log "============================" -Level 'INFO'
    
    Write-Log "REQUIRED COMPONENTS:" -Level 'INFO'
    if (${EnvResults}.RequiredComponents.Windows11) {
        Write-Log "  Windows 11: DETECTED" -Level 'SUCCESS'
    } else {
        Write-Log "  Windows 11: MISSING" -Level 'ERROR'
    }
    
    if (${EnvResults}.RequiredComponents.PowerShell5) {
        Write-Log "  PowerShell 5.x: DETECTED" -Level 'SUCCESS'
    } else {
        Write-Log "  PowerShell 5.x: MISSING" -Level 'ERROR'
    }
    
    Write-Log "OPTIONAL COMPONENTS:" -Level 'INFO'
    if (${EnvResults}.OptionalComponents.PowerShell7) {
        Write-Log "  PowerShell 7.x: AVAILABLE" -Level 'SUCCESS'
    } else {
        Write-Log "  PowerShell 7.x: NOT FOUND" -Level 'WARN'
    }
    
    if (${EnvResults}.OptionalComponents.PythonWindows) {
        Write-Log "  Python (Windows): AVAILABLE" -Level 'SUCCESS'
    } else {
        Write-Log "  Python (Windows): NOT FOUND" -Level 'WARN'
    }
    
    if (${EnvResults}.OptionalComponents.WSL) {
        Write-Log "  WSL: AVAILABLE" -Level 'SUCCESS'
    } else {
        Write-Log "  WSL: NOT FOUND" -Level 'WARN'
    }
    
    if (${EnvResults}.OptionalComponents.WSLUbuntu) {
        Write-Log "  WSL Ubuntu: AVAILABLE" -Level 'SUCCESS'
    } else {
        Write-Log "  WSL Ubuntu: NOT FOUND" -Level 'WARN'
    }
    
    if (${EnvResults}.OptionalComponents.PythonWSL) {
        Write-Log "  Python (WSL): AVAILABLE" -Level 'SUCCESS'
    } else {
        Write-Log "  Python (WSL): NOT FOUND" -Level 'WARN'
    }
    
    if (${EnvResults}.OptionalComponents.DockerWSL) {
        Write-Log "  Docker (WSL): AVAILABLE" -Level 'SUCCESS'
    } else {
        Write-Log "  Docker (WSL): NOT FOUND" -Level 'WARN'
    }
    
    if (${EnvResults}.OptionalComponents.DockerComposeWSL) {
        Write-Log "  Docker Compose (WSL): AVAILABLE" -Level 'SUCCESS'
    } else {
        Write-Log "  Docker Compose (WSL): NOT FOUND" -Level 'WARN'
    }
}

function Show-UsageInstructions {
    Write-Log "Environment Usage Instructions" -Level 'INFO'
    Write-Log "=============================" -Level 'INFO'
    
    Write-Log "RECOMMENDED PRIMARY ENVIRONMENT:" -Level 'INFO'
    Write-Log "  PowerShell 5.x: Use for all automation scripts and VS Code integration" -Level 'SUCCESS'
    Write-Log "  Path: $(${EnvResults}.DetectedPaths.PowerShell5)" -Level 'INFO'
    
    if (${EnvResults}.OptionalComponents.PowerShell7) {
        Write-Log "SUPPLEMENTARY ENVIRONMENT:" -Level 'INFO'
        Write-Log "  PowerShell 7.x: Available for interactive use (avoid for automation)" -Level 'WARN'
        Write-Log "  Path: $(${EnvResults}.DetectedPaths.PowerShell7)" -Level 'INFO'
    }
    
    if (${EnvResults}.OptionalComponents.PythonWindows) {
        Write-Log "PYTHON (Windows):" -Level 'INFO'
        Write-Log "  Command: python.exe" -Level 'SUCCESS'
        Write-Log "  Path: $(${EnvResults}.DetectedPaths.PythonWindows)" -Level 'INFO'
    }
    
    if (${EnvResults}.OptionalComponents.WSLUbuntu) {
        Write-Log "WSL UBUNTU COMMANDS:" -Level 'INFO'
        Write-Log "  General: wsl bash -c 'command'" -Level 'SUCCESS'
        Write-Log "  Root operations: wsl --user root bash -c 'command'" -Level 'SUCCESS'
        
        if (${EnvResults}.OptionalComponents.PythonWSL) {
            Write-Log "  Python in WSL: wsl python3 -c 'script'" -Level 'SUCCESS'
            if (-not ${EnvResults}.OptionalComponents.PythonWindows) {
                Write-Log "  Use WSL Python as fallback when Windows python.exe unavailable" -Level 'WARN'
            }
        }
        
        if (${EnvResults}.OptionalComponents.DockerWSL) {
            Write-Log "DOCKER IN WSL (NO Docker Desktop):" -Level 'INFO'
            Write-Log "  Docker: wsl docker <command>" -Level 'SUCCESS'
            Write-Log "  Compose: wsl docker compose <command>" -Level 'SUCCESS'
            Write-Log "  IMPORTANT: ALWAYS use Docker via WSL - NEVER Docker Desktop" -Level 'ERROR'
        }
    }
}

# Main execution
function main {
    try {
        Write-Log "Starting Environment Auto-Detection and Installation" -Level 'INFO'
        Write-Log "Script: ${ScriptName} v${ScriptVersion}" -Level 'INFO'
        Write-Log "Log file: ${LogPath}" -Level 'INFO'
        Write-Log "Started at: ${StartTime}" -Level 'INFO'
        
        # Required components detection
        Write-Log "Detecting required components..." -Level 'INFO'
        Test-Windows11
        Test-PowerShell5
        
        # Debug output for troubleshooting
        Write-Log "Windows11 Status: $(${EnvResults}.RequiredComponents.Windows11)" -Level 'INFO'
        Write-Log "PowerShell5 Status: $(${EnvResults}.RequiredComponents.PowerShell5)" -Level 'INFO'
        
        # Check if required components are available
        if (-not ${EnvResults}.RequiredComponents.Windows11 -or -not ${EnvResults}.RequiredComponents.PowerShell5) {
            Write-Log "CRITICAL: Required components missing - cannot continue" -Level 'ERROR'
            Write-Log "This script requires Windows 11 and PowerShell 5.x" -Level 'ERROR'
            return 1
        }
        
        Write-Log "Required components verified - continuing with optional components..." -Level 'SUCCESS'
        
        # Optional components detection
        Write-Log "Detecting optional components..." -Level 'INFO'
        Test-PowerShell7
        Test-PythonWindows
        Test-WSL
        Test-PythonWSL
        Test-DockerWSL
        
        # Show current environment status
        Show-EnvironmentSummary
        
        # Installation phase
        Write-Log "Starting installation phase..." -Level 'INFO'
        
        # Install WSL if requested and not available
        if (-not ${EnvResults.OptionalComponents.WSLUbuntu} -and -not $SkipWSL) {
            Install-WSLUbuntu
        }
        
        # Configure WSL sudo if available
        if (${EnvResults}.OptionalComponents.WSLUbuntu) {
            Set-WSLSudoNoPassword
        }
        
        # Install Python in WSL if needed (WSL available but Python not detected)
        if (${EnvResults}.OptionalComponents.WSLUbuntu -and -not ${EnvResults}.OptionalComponents.PythonWSL -and -not $SkipPython) {
            Install-PythonWSL
        }
        
        # Install Docker in WSL if needed (WSL available but Docker not detected)
        if (${EnvResults}.OptionalComponents.WSLUbuntu -and -not ${EnvResults}.OptionalComponents.DockerWSL -and -not $SkipDocker) {
            Install-DockerWSL
        }
        
        # Set up PowerShell profiles
        Install-PowerShellProfiles
        
        # Final environment check
        Write-Log "Performing final environment validation..." -Level 'INFO'
        Test-PowerShell7  # Re-check in case anything changed
        Test-PythonWindows
        Test-WSL
        Test-PythonWSL
        Test-DockerWSL
        
        # Show final summary and usage instructions
        Write-Log "Installation completed!" -Level 'SUCCESS'
        Show-EnvironmentSummary
        Show-UsageInstructions
        
        Write-Log "Environment setup completed successfully" -Level 'SUCCESS'
        return 0
        
    }
    catch {
        Write-Log "Critical error during environment setup: ${_}" -Level 'ERROR'
        return 1
    }
    finally {
        ${EndTime} = Get-Date
        ${Duration} = ${EndTime} - ${StartTime}
        Write-Log "Script completed in $([math]::Round(${Duration}.TotalMinutes, 2)) minutes" -Level 'INFO'
        Write-Log "Log file saved: ${LogPath}" -Level 'INFO'
    }
}

# Execute main function
if ($PSCmdlet.ShouldProcess("System Environment", "Auto-detect and install dependencies")) {
    exit (main)
}
else {
    Write-Log "Script execution cancelled by WhatIf parameter" -Level 'WARN'
    exit 0
}
