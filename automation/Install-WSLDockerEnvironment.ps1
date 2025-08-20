#Requires -Version 5.1
<#
.SYNOPSIS
    Comprehensive WSL Docker environment setup with clean installation and validation
.DESCRIPTION
    This script provides a complete WSL Docker setup solution including:
    - WSL availability and Ubuntu distribution detection/installation
    - Registry-based WSL network address retrieval
    - Sudoers NOPASSWD configuration for seamless operations
    - Python installation using official Ubuntu best practices
    - Docker and Docker Compose installation following official guidelines
    - Docker TCP socket configuration for Windows integration
    - Windows environment variables setup for DOCKER_HOST
    - Comprehensive validation and testing of all components
    Compatible with PowerShell 5.1+ (Windows 11 default) and PowerShell 7.x
.PARAMETER SkipValidation
    Skip comprehensive validation after installation
.PARAMETER Force
    Force reinstallation of existing components
.PARAMETER Silent
    Run in silent mode with minimal output (auto-continue prompts)
.PARAMETER CleanInstall
    Perform clean installation by removing existing WSL Ubuntu distribution
.EXAMPLE
    PS> .\Install-WSLDockerEnvironment.ps1
    Run with default settings and comprehensive validation
.EXAMPLE
    PS> .\Install-WSLDockerEnvironment.ps1 -CleanInstall -Force -Verbose
    Perform clean installation with force reinstall and verbose output
.EXAMPLE
    PS> .\Install-WSLDockerEnvironment.ps1 -Silent -SkipValidation
    Run silently without validation for automation scenarios
.INPUTS
    None
.OUTPUTS
    System.Object - Installation and validation results
.NOTES
    Author: Emil Wojcik
    Date: 2025-08-20
    Version: 2.0
    Requires: PowerShell 5.1+ (Windows 11 default), Administrator rights, Windows 11 WSL support
    Compatible: PowerShell 5.1, 7.x

    Prerequisites:
    - Windows 11 with WSL feature enabled
    - Administrator privileges for system-level configuration
    - Internet connectivity for package downloads

    Key Features:
    - Registry-based WSL network detection
    - Official Docker installation following best practices
    - Sudoers NOPASSWD configuration with validation
    - Windows DOCKER_HOST environment setup
    - TCP socket configuration for VS Code Docker extension
    - Comprehensive testing and validation suite

    Change Log:
    2.0 - Enhanced version with comprehensive WSL Docker setup
    1.0 - Initial version based on wsl-docker-setup repository

    Links:
    - https://docs.docker.com/engine/install/ubuntu/
    - https://docs.docker.com/engine/install/linux-postinstall/
    - https://github.com/emilwojcik93/wsl-docker-setup
.LINK
    https://github.com/emilwojcik93/dotfile
.COMPONENT
    WSL Docker Environment
.ROLE
    DevOps Engineer, Developer
.FUNCTIONALITY
    Complete WSL Docker environment setup and configuration
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(HelpMessage = "Skip comprehensive validation after installation")]
    [switch]$SkipValidation,

    [Parameter(HelpMessage = "Force reinstallation of existing components")]
    [switch]$Force,

    [Parameter(HelpMessage = "Run in silent mode with minimal output")]
    [switch]$Silent,

    [Parameter(HelpMessage = "Perform clean installation by removing existing WSL Ubuntu")]
    [switch]$CleanInstall
)

# ============================================================================
# SCRIPT INITIALIZATION AND GLOBAL VARIABLES
# ============================================================================

# Configure error handling and logging
$ErrorActionPreference = 'Stop'
$ProgressPreference = if ($Silent) { 'SilentlyContinue' } else { 'Continue' }

# Global variables for script execution
$Global:ScriptResults = @{
    StartTime = Get-Date
    WSLAvailable = $false
    UbuntuInstalled = $false
    UbuntuDistroId = $null
    WSLNetworkAddress = $null
    PythonInstalled = $false
    DockerInstalled = $false
    DockerComposeInstalled = $false
    DockerSocketConfigured = $false
    WindowsEnvConfigured = $false
    ValidationPassed = $false
    Warnings = @()
    Errors = @()
}

# Setup log file path
$Global:LogFilePath = Join-Path $env:TEMP "WSL-Docker-Setup-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# Logging function with timestamp and severity
function Write-LogMessage {
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [ValidateSet('INFO', 'WARN', 'ERROR', 'SUCCESS')]
        [string]$Level = 'INFO'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $colorMap = @{
        'INFO' = 'White'
        'WARN' = 'Yellow'
        'ERROR' = 'Red'
        'SUCCESS' = 'Green'
    }
    
    $logEntry = "[${timestamp}] [${Level}] ${Message}"
    
    # Always write to log file
    try {
        Add-Content -Path $Global:LogFilePath -Value $logEntry -Encoding UTF8 -ErrorAction SilentlyContinue
    }
    catch {
        # If we can't write to log file, continue silently
    }
    
    if (-not $Silent) {
        Write-Host $logEntry -ForegroundColor $colorMap[$Level]
    }
    
    # Store warnings and errors for final report
    switch ($Level) {
        'WARN' { $Global:ScriptResults.Warnings += $Message }
        'ERROR' { $Global:ScriptResults.Errors += $Message }
    }
}

# ============================================================================
# VALIDATION AND PREREQUISITE FUNCTIONS
# ============================================================================

function Test-AdminElevation {
    <#
    .SYNOPSIS
        Checks if script is running with administrator privileges and elevates if needed
    .DESCRIPTION
        Validates current user privileges and automatically re-launches the script
        with administrator rights if required. Preserves all original parameters.
    #>
    
    # Check if running as administrator
    $IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if (-not $IsAdmin) {
        Write-LogMessage "Script requires administrator privileges. Attempting to relaunch with elevation." -Level 'WARN'

        # Build argument list from bound parameters
        $argList = @()
        $PSBoundParameters.GetEnumerator() | ForEach-Object {
            $argList += if ($_.Value -is [switch] -and $_.Value) {
                "-$($_.Key)"
            } elseif ($_.Value -is [array]) {
                "-$($_.Key) $($_.Value -join ',')"
            } elseif ($_.Value) {
                "-$($_.Key) '$($_.Value)'"
            }
        }

        # Construct script execution command
        $script = "& { & `'$($PSCommandPath)`' $($argList -join ' ') }"

        # Determine PowerShell executable
        $powershellCmd = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell" }
        $processCmd = if (Get-Command wt.exe -ErrorAction SilentlyContinue) { "wt.exe" } else { "$powershellCmd" }

        # Launch elevated process
        try {
            if ($processCmd -eq "wt.exe") {
                Start-Process $processCmd -ArgumentList "$powershellCmd -ExecutionPolicy Bypass -NoProfile -Command `"$script`"" -Verb RunAs
            } else {
                Start-Process $processCmd -ArgumentList "-ExecutionPolicy Bypass -NoProfile -Command `"$script`"" -Verb RunAs
            }
            Write-LogMessage "Script relaunched with administrator privileges." -Level 'SUCCESS'
            exit 0
        }
        catch {
            Write-LogMessage "Failed to elevate privileges: $($_.Exception.Message)" -Level 'ERROR'
            exit 1
        }
    }

    return $IsAdmin
}

function Test-WSLAvailability {
    <#
    .SYNOPSIS
        Tests if WSL is available and enabled on the system
    .DESCRIPTION
        Checks for WSL executable availability and Windows feature enablement
    #>
    
    Write-LogMessage "Checking WSL availability..."
    
    try {
        # Check if wsl.exe is available
        if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) {
            Write-LogMessage "WSL executable (wsl.exe) not found. WSL may not be installed or enabled." -Level 'ERROR'
            return $false
        }
        
        # Test WSL status
        $wslStatus = & wsl.exe --status 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-LogMessage "WSL is not properly configured. Status check failed." -Level 'ERROR'
            return $false
        }
        
        Write-LogMessage "WSL is available and configured." -Level 'SUCCESS'
        $Global:ScriptResults.WSLAvailable = $true
        return $true
    }
    catch {
        Write-LogMessage "Error checking WSL availability: $($_.Exception.Message)" -Level 'ERROR'
        return $false
    }
}

function Test-UbuntuDistribution {
    <#
    .SYNOPSIS
        Checks if Ubuntu WSL distribution is installed and gets registry information
    .DESCRIPTION
        Uses registry entries to detect WSL distributions and identify Ubuntu instance
    #>
    
    Write-LogMessage "Checking Ubuntu WSL distribution..."
    
    try {
        # Check WSL distributions via registry
        $lxssPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss"
        
        if (-not (Test-Path $lxssPath)) {
            Write-LogMessage "WSL registry path not found. No WSL distributions detected." -Level 'WARN'
            return $false
        }
        
        # Get all WSL distribution entries
        $distroGuids = Get-ChildItem -Path $lxssPath -Name -ErrorAction SilentlyContinue
        
        foreach ($guid in $distroGuids) {
            $distroPath = Join-Path $lxssPath $guid
            try {
                $distroName = Get-ItemProperty -Path $distroPath -Name "DistributionName" -ErrorAction SilentlyContinue
                if ($distroName.DistributionName -eq "Ubuntu") {
                    Write-LogMessage "Found Ubuntu distribution with GUID: ${guid}" -Level 'SUCCESS'
                    $Global:ScriptResults.UbuntuInstalled = $true
                    $Global:ScriptResults.UbuntuDistroId = $guid
                    return $true
                }
            }
            catch {
                # Skip invalid registry entries
                continue
            }
        }
        
        Write-LogMessage "Ubuntu WSL distribution not found in registry." -Level 'WARN'
        return $false
    }
    catch {
        Write-LogMessage "Error checking Ubuntu distribution: $($_.Exception.Message)" -Level 'ERROR'
        return $false
    }
}

# ============================================================================
# WSL NETWORK AND CONFIGURATION FUNCTIONS
# ============================================================================

function Get-WSLNetworkAddress {
    <#
    .SYNOPSIS
        Retrieve WSL network address from registry entry
    .DESCRIPTION
        Gets the NAT IP address for WSL from Windows registry for Docker socket connectivity
    #>
    
    Write-LogMessage "Retrieving WSL network address from registry..."
    
    try {
        # First try to get from registry
        $wslIp = $null
        try {
            $wslIp = (Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Lxss" -Name "NatIpAddress" -ErrorAction SilentlyContinue).NatIpAddress
        }
        catch {
            Write-LogMessage "Could not retrieve IP from registry, trying alternative method..." -Level 'WARN'
        }

        if ([string]::IsNullOrEmpty($wslIp)) {
            # Try alternative method - get from active WSL instance
            Write-LogMessage "Getting WSL IP address from active instance..." -Level 'INFO'
            
            # Ensure WSL is running
            $wslStatus = & wsl.exe --list --verbose 2>$null
            if ($LASTEXITCODE -ne 0) {
                throw "WSL is not running or no distributions installed"
            }
            
            # Try to get IP from Ubuntu specifically
            $wslIpResult = & wsl.exe -d Ubuntu hostname -I 2>$null
            if ($LASTEXITCODE -eq 0 -and $wslIpResult -and $wslIpResult.Trim()) {
                $wslIp = $wslIpResult.Trim().Split(' ')[0]
            } else {
                # Try default WSL instance
                $wslIpResult = & wsl.exe hostname -I 2>$null
                if ($LASTEXITCODE -eq 0 -and $wslIpResult -and $wslIpResult.Trim()) {
                    $wslIp = $wslIpResult.Trim().Split(' ')[0]
                }
            }
        }

        if ([string]::IsNullOrEmpty($wslIp)) {
            # Last resort - try to get from network adapter
            Write-LogMessage "Trying to detect WSL IP from network adapters..." -Level 'INFO'
            
            $wslAdapter = Get-NetAdapter | Where-Object { $_.InterfaceDescription -like "*WSL*" -or $_.Name -like "*WSL*" } | Select-Object -First 1
            if ($wslAdapter) {
                $wslIpConfig = Get-NetIPAddress -InterfaceIndex $wslAdapter.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue | Select-Object -First 1
                if ($wslIpConfig) {
                    # WSL typically uses .1 as the host gateway
                    $wslNetworkBase = ($wslIpConfig.IPAddress -split '\.')[0..2] -join '.'
                    $wslIp = "${wslNetworkBase}.1"
                }
            }
        }

        if ([string]::IsNullOrEmpty($wslIp)) {
            throw "Could not retrieve WSL IP address from registry, WSL instance, or network adapters"
        }

        # Validate IP address format
        if ($wslIp -match '^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$') {
            # Additional validation - ensure it's a valid private IP
            $ipParts = $wslIp -split '\.'
            $firstOctet = [int]$ipParts[0]
            $secondOctet = [int]$ipParts[1]
            
            # Check if it's in private IP ranges (10.x.x.x, 172.16-31.x.x, 192.168.x.x)
            $isPrivateIP = ($firstOctet -eq 10) -or 
                          ($firstOctet -eq 172 -and $secondOctet -ge 16 -and $secondOctet -le 31) -or
                          ($firstOctet -eq 192 -and $secondOctet -eq 168)
            
            if (-not $isPrivateIP) {
                Write-LogMessage "Warning: WSL IP $wslIp is not in a typical private range" -Level 'WARN'
            }
            
            Write-LogMessage "WSL network address: ${wslIp}" -Level 'SUCCESS'
            $Global:ScriptResults.WSLNetworkAddress = $wslIp
            return $wslIp
        } else {
            throw "The retrieved value is not a valid IP address: ${wslIp}"
        }
    }
    catch {
        Write-LogMessage "Failed to get WSL network address: $($_.Exception.Message)" -Level 'ERROR'
        return $null
    }
}

function Test-WSLDockerSocket {
    <#
    .SYNOPSIS
        Test connection to WSL Docker socket
    .DESCRIPTION
        Validates connectivity to Docker daemon TCP socket on port 2375
    #>
    param (
        [Parameter(Mandatory)]
        [string]$WSLIp
    )
    
    Write-LogMessage "Testing connection to WSL Docker socket at ${WSLIp}:2375..."
    
    try {
        $originalProgressPreference = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue'
        
        $testResult = Test-NetConnection -ComputerName $WSLIp -Port 2375 -InformationLevel Quiet -WarningAction SilentlyContinue
        
        $ProgressPreference = $originalProgressPreference
        
        if ($testResult) {
            Write-LogMessage "Docker socket connection successful." -Level 'SUCCESS'
            return $true
        } else {
            Write-LogMessage "Docker socket connection failed. Port 2375 may not be open." -Level 'WARN'
            return $false
        }
    }
    catch {
        Write-LogMessage "Error testing Docker socket: $($_.Exception.Message)" -Level 'ERROR'
        return $false
    }
}

# ============================================================================
# WSL UBUNTU INSTALLATION AND CONFIGURATION
# ============================================================================

function Install-UbuntuWSL {
    <#
    .SYNOPSIS
        Install Ubuntu WSL distribution
    .DESCRIPTION
        Downloads and installs Ubuntu WSL distribution if not present
    #>
    
    Write-LogMessage "Installing Ubuntu WSL distribution..."
    
    try {
        # Check if WSL feature is enabled first
        $wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
        if ($wslFeature.State -ne "Enabled") {
            Write-LogMessage "WSL feature is not enabled. Please enable WSL first:" -Level 'ERROR'
            Write-LogMessage "Run: dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart" -Level 'ERROR'
            Write-LogMessage "Then: dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart" -Level 'ERROR'
            return $false
        }
        
        # Install Ubuntu WSL distribution with timeout handling
        Write-LogMessage "Starting Ubuntu installation (this may take several minutes)..." -Level 'INFO'
        
        # Start installation in background job with timeout
        $installJob = Start-Job -ScriptBlock {
            try {
                $result = & wsl.exe --install -d Ubuntu 2>&1
                return @{
                    Success = ($LASTEXITCODE -eq 0)
                    ExitCode = $LASTEXITCODE
                    Output = $result
                }
            }
            catch {
                return @{
                    Success = $false
                    ExitCode = -1
                    Output = $_.Exception.Message
                }
            }
        }
        
        # Wait for job with timeout (10 minutes)
        $timeoutSeconds = 600
        $jobResult = Wait-Job -Job $installJob -Timeout $timeoutSeconds
        
        if ($jobResult) {
            $installData = Receive-Job -Job $installJob
            Remove-Job -Job $installJob
            
            if ($installData.Success) {
                Write-LogMessage "Ubuntu installation command completed successfully." -Level 'SUCCESS'
            } else {
                Write-LogMessage "Ubuntu installation failed with exit code: $($installData.ExitCode)" -Level 'ERROR'
                Write-LogMessage "Output: $($installData.Output)" -Level 'ERROR'
                return $false
            }
        } else {
            Stop-Job -Job $installJob
            Remove-Job -Job $installJob
            Write-LogMessage "Ubuntu installation timed out after $timeoutSeconds seconds." -Level 'ERROR'
            return $false
        }
        
        # Wait for WSL distribution to appear in registry
        Write-LogMessage "Waiting for Ubuntu distribution to be registered..."
        $maxWaitTime = 120 # 2 minutes
        $waitInterval = 5
        $totalWaited = 0
        
        while ($totalWaited -lt $maxWaitTime) {
            Start-Sleep -Seconds $waitInterval
            $totalWaited += $waitInterval
            
            if (Test-UbuntuDistribution) {
                Write-LogMessage "Ubuntu distribution detected in registry!" -Level 'SUCCESS'
                break
            }
            
            Write-LogMessage "Still waiting for Ubuntu registration... ($totalWaited/$maxWaitTime seconds)" -Level 'INFO'
        }
        
        # Final verification
        if (Test-UbuntuDistribution) {
            # Try to initialize the distribution
            Write-LogMessage "Initializing Ubuntu distribution..." -Level 'INFO'
            $initResult = & wsl.exe -d Ubuntu echo "Ubuntu initialized" 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-LogMessage "Ubuntu WSL distribution installed and initialized successfully!" -Level 'SUCCESS'
                return $true
            } else {
                Write-LogMessage "Ubuntu installed but initialization failed: $initResult" -Level 'WARN'
                Write-LogMessage "You may need to complete the setup manually by running: wsl -d Ubuntu" -Level 'WARN'
                return $true # Still consider it a success as Ubuntu is installed
            }
        } else {
            throw "Ubuntu installation completed but distribution verification failed after $maxWaitTime seconds"
        }
    }
    catch {
        Write-LogMessage "Failed to install Ubuntu WSL: $($_.Exception.Message)" -Level 'ERROR'
        return $false
    }
}

function Remove-UbuntuWSL {
    <#
    .SYNOPSIS
        Remove existing Ubuntu WSL distribution for clean installation
    .DESCRIPTION
        Unregisters Ubuntu WSL distribution to enable clean reinstall
    #>
    
    Write-LogMessage "Removing existing Ubuntu WSL distribution for clean installation..."
    
    try {
        $unregisterResult = & wsl.exe --unregister Ubuntu 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-LogMessage "Ubuntu WSL distribution unregistered successfully." -Level 'SUCCESS'
            $Global:ScriptResults.UbuntuInstalled = $false
            $Global:ScriptResults.UbuntuDistroId = $null
            return $true
        } else {
            Write-LogMessage "Failed to unregister Ubuntu distribution: ${unregisterResult}" -Level 'WARN'
            return $false
        }
    }
    catch {
        Write-LogMessage "Error removing Ubuntu WSL: $($_.Exception.Message)" -Level 'ERROR'
        return $false
    }
}

function Set-WSLSudoersConfiguration {
    <#
    .SYNOPSIS
        Configure sudoers for NOPASSWD access using root commands
    .DESCRIPTION
        Adds user to sudoers with NOPASSWD for seamless operations using root commands
    #>
    
    Write-LogMessage "Configuring sudoers for NOPASSWD access..."
    
    try {
        # Ensure Ubuntu is running and accessible using root
        $ubuntuTest = & wsl.exe --user root bash -c 'echo test 2>/dev/null'
        if ($LASTEXITCODE -ne 0) {
            Write-LogMessage "Ubuntu WSL is not accessible as root, trying to start..." -Level 'WARN'
            
            # Try to initialize Ubuntu
            & wsl.exe -d Ubuntu --cd ~ 2>$null
            Start-Sleep -Seconds 3
            
            # Test again
            $ubuntuTest = & wsl.exe --user root bash -c 'echo test 2>/dev/null'
            if ($LASTEXITCODE -ne 0) {
                throw "Ubuntu WSL is not responding as root. Root access may need configuration."
            }
        }
        
        # Get WSL username using root to find default user
        $wslUser = & wsl.exe --user root bash -c 'getent passwd 1000 | cut -d: -f1 2>/dev/null'
        if ([string]::IsNullOrEmpty($wslUser) -or $LASTEXITCODE -ne 0) {
            throw "Could not determine WSL username for UID 1000. Ubuntu may need manual setup."
        }
        
        $wslUser = $wslUser.Trim()
        Write-LogMessage "WSL username: ${wslUser}"
        
        # Check if sudoers entry already exists using root
        $sudoersCheckCmd = "grep -q '^${wslUser} ALL=(ALL) NOPASSWD: ALL' /etc/sudoers 2>/dev/null"
        $sudoersCheck = & wsl.exe --user root bash -c $sudoersCheckCmd
        
        if ($LASTEXITCODE -eq 0) {
            Write-LogMessage "Sudoers NOPASSWD entry already exists for user: ${wslUser}" -Level 'SUCCESS'
            return $true
        }
        
        # Add sudoers entry using safer method (adding to sudoers.d instead of modifying main file)
        $sudoersEntry = "${wslUser} ALL=(ALL) NOPASSWD: ALL"
        $sudoersFile = "/etc/sudoers.d/99-${wslUser}-nopasswd"
        
        # Create sudoers.d entry using root
        $addSudoersCmd = "echo '${sudoersEntry}' > ${sudoersFile} 2>/dev/null"
        $addSudoersResult = & wsl.exe --user root bash -c $addSudoersCmd
        
        if ($LASTEXITCODE -eq 0) {
            # Set proper permissions on the sudoers file using root
            $chmodCmd = "chmod 440 ${sudoersFile} 2>/dev/null"
            & wsl.exe --user root bash -c $chmodCmd
            
            Write-LogMessage "Added NOPASSWD sudoers entry for user: ${wslUser}" -Level 'SUCCESS'
            
            # Verify the entry was added and is valid using root
            $verifyResult = & wsl.exe --user root bash -c 'visudo -c 2>/dev/null'
            if ($LASTEXITCODE -eq 0) {
                # Test sudo access as the user
                $sudoTestCmd = "sudo -n true 2>/dev/null"
                & wsl.exe -d Ubuntu -u $wslUser bash -c $sudoTestCmd
                if ($LASTEXITCODE -eq 0) {
                    Write-LogMessage "Sudoers configuration verified successfully." -Level 'SUCCESS'
                    return $true
                } else {
                    Write-LogMessage "Sudoers file is valid but NOPASSWD test failed. May need manual verification." -Level 'WARN'
                    return $true # Still consider success as the entry was added
                }
            } else {
                Write-LogMessage "Sudoers file validation failed. Removing invalid entry." -Level 'WARN'
                $removeCmd = "rm -f ${sudoersFile} 2>/dev/null"
                & wsl.exe --user root bash -c $removeCmd
                return $false
            }
        } else {
            throw "Failed to add sudoers entry: ${addSudoersResult}"
        }
    }
    catch {
        Write-LogMessage "Failed to configure sudoers: $($_.Exception.Message)" -Level 'ERROR'
        Write-LogMessage "You may need to manually configure NOPASSWD sudo access." -Level 'WARN'
        return $false
    }
}

# ============================================================================
# PYTHON INSTALLATION FUNCTIONS
# ============================================================================

function Install-PythonWSL {
    <#
    .SYNOPSIS
        Install Python in WSL Ubuntu using official best practices with root commands
    .DESCRIPTION
        Installs Python 3 and related packages following Ubuntu official guidelines using root commands to avoid password prompts
    #>
    
    Write-LogMessage "Installing Python in WSL Ubuntu..."
    
    try {
        # Check if Python is already installed
        $pythonCheck = & wsl.exe --user root bash -c 'python3 --version 2>/dev/null'
        
        if ($LASTEXITCODE -eq 0 -and -not $Force) {
            Write-LogMessage "Python is already installed: $($pythonCheck.Trim())" -Level 'SUCCESS'
            $Global:ScriptResults.PythonInstalled = $true
            return $true
        }
        
        # Update package list using root
        Write-LogMessage "Updating package list..."
        $updateResult = & wsl.exe --user root bash -c "export DEBIAN_FRONTEND=noninteractive && apt update -y > /dev/null 2>&1" 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to update package list: ${updateResult}"
        }
        
        # Install Python and related packages using root
        Write-LogMessage "Installing Python 3 and development tools..."
        $pythonPackages = "python3 python3-pip python3-venv python3-dev build-essential"
        
        $installResult = & wsl.exe --user root bash -c "export DEBIAN_FRONTEND=noninteractive && apt install -y ${pythonPackages} > /dev/null 2>&1" 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to install Python packages: ${installResult}"
        }
        
        # Verify installation
        $pythonVersion = & wsl.exe --user root bash -c 'python3 --version 2>/dev/null'
        $pipVersion = & wsl.exe --user root bash -c 'python3 -m pip --version 2>/dev/null'
        
        if ($LASTEXITCODE -eq 0) {
            Write-LogMessage "Python installed successfully: $($pythonVersion.Trim())" -Level 'SUCCESS'
            Write-LogMessage "Pip version: $($pipVersion.Trim())" -Level 'SUCCESS'
            $Global:ScriptResults.PythonInstalled = $true
            return $true
        } else {
            throw "Python installation verification failed"
        }
    }
    catch {
        Write-LogMessage "Failed to install Python: $($_.Exception.Message)" -Level 'ERROR'
        return $false
    }
}

# ============================================================================
# DOCKER INSTALLATION FUNCTIONS
# ============================================================================

function Install-DockerWSL {
    <#
    .SYNOPSIS
        Install Docker in WSL Ubuntu using official best practices with root commands
    .DESCRIPTION
        Installs Docker Engine following official Docker documentation guidelines using root commands to avoid password prompts
    #>
    
    Write-LogMessage "Installing Docker in WSL Ubuntu..."
    
    try {
        # Check if Docker is already installed
        $dockerCheck = & wsl.exe --user root bash -c 'docker --version 2>/dev/null'
        
        if ($LASTEXITCODE -eq 0 -and -not $Force) {
            Write-LogMessage "Docker is already installed: $($dockerCheck.Trim())" -Level 'SUCCESS'
            $Global:ScriptResults.DockerInstalled = $true
            return $true
        }
        
        # Remove old versions if they exist using root
        Write-LogMessage "Removing old Docker versions..."
        $oldPackages = "docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc"
        $removeResult = & wsl.exe --user root bash -c "export DEBIAN_FRONTEND=noninteractive && apt-get remove -y ${oldPackages} > /dev/null 2>&1" 2>$null
        
        # Update package list and install prerequisites using root
        Write-LogMessage "Installing prerequisites..."
        $prereqResult = & wsl.exe --user root bash -c "export DEBIAN_FRONTEND=noninteractive && apt-get update > /dev/null 2>&1" 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to update package list: ${prereqResult}"
        }
        
        $prereqPackages = "ca-certificates curl"
        $installPrereqResult = & wsl.exe --user root bash -c "export DEBIAN_FRONTEND=noninteractive && apt-get install -y ${prereqPackages} > /dev/null 2>&1" 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to install prerequisites: ${installPrereqResult}"
        }
        
        # Add Docker's official GPG key using root
        Write-LogMessage "Adding Docker's official GPG key..."
        & wsl.exe --user root bash -c 'install -m 0755 -d /etc/apt/keyrings 2>/dev/null'
        $gpgResult = & wsl.exe --user root bash -c 'curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc 2>/dev/null'
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to add Docker GPG key: ${gpgResult}"
        }
        
        & wsl.exe --user root bash -c 'chmod a+r /etc/apt/keyrings/docker.asc 2>/dev/null'
        
        # Add Docker repository using root
        Write-LogMessage "Adding Docker repository..."
        $repoCommand = 'echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null'
        $repoResult = & wsl.exe --user root bash -c $repoCommand 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to add Docker repository: ${repoResult}"
        }
        
        # Update package list again using root
        $updateResult2 = & wsl.exe --user root bash -c "export DEBIAN_FRONTEND=noninteractive && apt-get update > /dev/null 2>&1" 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to update package list after adding Docker repo: ${updateResult2}"
        }
        
        # Install Docker packages using root
        Write-LogMessage "Installing Docker packages..."
        $dockerPackages = "docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"
        
        $dockerInstallResult = & wsl.exe --user root bash -c "export DEBIAN_FRONTEND=noninteractive && apt-get install -y ${dockerPackages} > /dev/null 2>&1" 2>$null
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to install Docker packages: ${dockerInstallResult}"
        }
        
        # Verify Docker installation using root
        $dockerVersion = & wsl.exe --user root bash -c 'docker --version 2>/dev/null'
        if ($LASTEXITCODE -eq 0) {
            Write-LogMessage "Docker installed successfully: $($dockerVersion.Trim())" -Level 'SUCCESS'
            $Global:ScriptResults.DockerInstalled = $true
            return $true
        } else {
            throw "Docker installation verification failed"
        }
    }
    catch {
        Write-LogMessage "Failed to install Docker: $($_.Exception.Message)" -Level 'ERROR'
        return $false
    }
}

function Install-DockerComposeWSL {
    <#
    .SYNOPSIS
        Verify Docker Compose installation using root commands
    .DESCRIPTION
        Checks Docker Compose availability (should be installed with docker-compose-plugin) using root commands
    #>
    
    Write-LogMessage "Verifying Docker Compose installation..."
    
    try {
        # Check Docker Compose using new syntax with root commands
        $composeCheck = & wsl.exe --user root bash -c 'docker compose version 2>/dev/null'
        
        if ($LASTEXITCODE -eq 0) {
            Write-LogMessage "Docker Compose is available: $($composeCheck.Trim())" -Level 'SUCCESS'
            $Global:ScriptResults.DockerComposeInstalled = $true
            return $true
        } else {
            Write-LogMessage "Docker Compose verification failed." -Level 'ERROR'
            return $false
        }
    }
    catch {
        Write-LogMessage "Error verifying Docker Compose: $($_.Exception.Message)" -Level 'ERROR'
        return $false
    }
}

function Set-DockerPostInstall {
    <#
    .SYNOPSIS
        Configure Docker post-installation settings using root commands
    .DESCRIPTION
        Adds user to docker group and configures Docker daemon for TCP socket access using root commands to avoid password prompts
    #>
    
    Write-LogMessage "Configuring Docker post-installation settings..."
    
    try {
        # Get current user using root commands
        $getUserCmd = "getent passwd 1000 | cut -d: -f1 2>/dev/null"
        $wslUser = & wsl.exe --user root bash -c $getUserCmd
        if ([string]::IsNullOrEmpty($wslUser) -or $LASTEXITCODE -ne 0) {
            throw "Could not determine WSL username"
        }
        $wslUser = $wslUser.Trim()
        
        # Add user to docker group using root
        Write-LogMessage "Adding user ${wslUser} to docker group..."
        $usermodResult = & wsl.exe --user root bash -c "usermod -aG docker ${wslUser}" 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to add user to docker group: ${usermodResult}"
        }
        
        # Enable and start Docker services using root
        Write-LogMessage "Enabling and starting Docker services..."
        $enableResult = & wsl.exe --user root bash -c "systemctl enable docker.service containerd.service" 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-LogMessage "Warning: Failed to enable Docker services (may not be critical): ${enableResult}" -Level 'WARN'
        }
        
        # Configure Docker daemon for TCP socket using root
        Write-LogMessage "Configuring Docker daemon for TCP socket access..."
        
        # Create systemd override directory using root
        & wsl.exe --user root bash -c 'mkdir -p /etc/systemd/system/docker.service.d 2>/dev/null'
        
        # Get current ExecStart line using root
        $getExecStartCmd = "grep '^ExecStart=' /lib/systemd/system/docker.service 2>/dev/null"
        $currentExecStart = & wsl.exe --user root bash -c $getExecStartCmd
        if ($LASTEXITCODE -ne 0) {
            $currentExecStart = 'ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock'
        } else {
            $currentExecStart = $currentExecStart.Trim()
        }
        
        # Remove ExecStart= prefix
        $execStartCommand = $currentExecStart -replace '^ExecStart=', ''
        
        # Add TCP socket configuration if not present
        if ($execStartCommand -notmatch '-H\s+unix:///var/run/docker\.sock') {
            $execStartCommand = $execStartCommand -replace '--containerd=', '-H unix:///var/run/docker.sock --containerd='
        }
        
        if ($execStartCommand -notmatch '-H\s+tcp://0\.0\.0\.0:2375') {
            $execStartCommand = $execStartCommand -replace '--containerd=', '-H tcp://0.0.0.0:2375 --tls=false --containerd='
        }
        
        # Create override configuration using root
        $overrideConfig = "[Service]`nExecStart=`nExecStart=${execStartCommand}"
        
        $configCmd = "echo '${overrideConfig}' > /etc/systemd/system/docker.service.d/override.conf 2>/dev/null"
        $configResult = & wsl.exe --user root bash -c $configCmd
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to create Docker service override: ${configResult}"
        }
        
        # Create keepwsl.service to keep WSL running using root
        Write-LogMessage "Creating keepwsl.service to maintain WSL session..."
        $keepwslService = "[Unit]`nDescription=keepwsl.service`n`n[Service]`nExecStart=/mnt/c/Windows/System32/wsl.exe sleep infinity`n`n[Install]`nWantedBy=default.target"
        
        $keepwslCmd = "echo '${keepwslService}' > /etc/systemd/system/keepwsl.service 2>/dev/null"
        $keepwslResult = & wsl.exe --user root bash -c $keepwslCmd
        if ($LASTEXITCODE -ne 0) {
            Write-LogMessage "Warning: Failed to create keepwsl.service: ${keepwslResult}" -Level 'WARN'
        }
        
        # Reload systemd and restart Docker using root
        Write-LogMessage "Reloading systemd configuration and restarting Docker..."
        & wsl.exe --user root bash -c 'systemctl daemon-reload 2>/dev/null'
        $restartCmd = "systemctl restart docker.service docker.socket 2>/dev/null"
        $restartResult = & wsl.exe --user root bash -c $restartCmd
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to restart Docker service: ${restartResult}"
        }
        
        # Enable and start keepwsl.service using root
        $keepwslStartCmd = "systemctl enable --now keepwsl.service 2>/dev/null"
        $keepwslStartResult = & wsl.exe --user root bash -c $keepwslStartCmd
        if ($LASTEXITCODE -ne 0) {
            Write-LogMessage "Warning: Failed to start keepwsl.service: ${keepwslStartResult}" -Level 'WARN'
        }
        
        Write-LogMessage "Docker post-installation configuration completed." -Level 'SUCCESS'
        return $true
    }
    catch {
        Write-LogMessage "Failed to configure Docker post-install: $($_.Exception.Message)" -Level 'ERROR'
        return $false
    }
}

function Test-DockerInstallation {
    <#
    .SYNOPSIS
        Test Docker installation with hello-world container using root commands
    .DESCRIPTION
        Runs Docker hello-world container to verify installation using root commands
    #>
    
    Write-LogMessage "Testing Docker installation with hello-world container..."
    
    try {
        # Test Docker with hello-world using root commands
        $helloWorldResult = & wsl.exe --user root bash -c "docker run --rm hello-world" 2>&1
        
        if ($LASTEXITCODE -eq 0 -and $helloWorldResult -match 'Hello from Docker') {
            Write-LogMessage "Docker installation test successful!" -Level 'SUCCESS'
            return $true
        } else {
            throw "Docker hello-world test failed: ${helloWorldResult}"
        }
    }
    catch {
        Write-LogMessage "Docker installation test failed: $($_.Exception.Message)" -Level 'ERROR'
        return $false
    }
}

# ============================================================================
# WINDOWS ENVIRONMENT CONFIGURATION
# ============================================================================

function Set-DockerHostEnvironment {
    <#
    .SYNOPSIS
        Setup Windows user environment for DOCKER_HOST
    .DESCRIPTION
        Configures DOCKER_HOST environment variable for Windows to connect to WSL Docker socket
    #>
    param (
        [Parameter(Mandatory)]
        [string]$WSLIp
    )
    
    Write-LogMessage "Setting up Windows user environment for DOCKER_HOST..."
    
    try {
        $dockerHost = "tcp://${WSLIp}:2375"
        
        # Set for current process
        [System.Environment]::SetEnvironmentVariable('DOCKER_HOST', $dockerHost, [System.EnvironmentVariableTarget]::Process)
        
        # Set for user scope (persistent)
        [System.Environment]::SetEnvironmentVariable('DOCKER_HOST', $dockerHost, [System.EnvironmentVariableTarget]::User)
        
        # Verify the setting
        $currentDockerHost = [System.Environment]::GetEnvironmentVariable('DOCKER_HOST', [System.EnvironmentVariableTarget]::User)
        
        if ($currentDockerHost -eq $dockerHost) {
            Write-LogMessage "DOCKER_HOST environment variable set to: ${dockerHost}" -Level 'SUCCESS'
            $Global:ScriptResults.WindowsEnvConfigured = $true
            $Global:ScriptResults.DockerSocketConfigured = $true
            return $true
        } else {
            throw "Failed to verify DOCKER_HOST environment variable setting"
        }
    }
    catch {
        Write-LogMessage "Failed to set DOCKER_HOST environment: $($_.Exception.Message)" -Level 'ERROR'
        return $false
    }
}

# ============================================================================
# COMPREHENSIVE VALIDATION FUNCTIONS
# ============================================================================

function Test-ComprehensiveValidation {
    <#
    .SYNOPSIS
        Run comprehensive validation of all installed components using root commands
    .DESCRIPTION
        Tests all aspects of the WSL Docker environment setup using root commands where needed
    #>
    
    Write-LogMessage "Running comprehensive validation..." -Level 'INFO'
    
    $validationResults = @{
        WSLFunctional = $false
        UbuntuResponsive = $false
        PythonWorking = $false
        DockerRunning = $false
        DockerComposeWorking = $false
        DockerSocketAccessible = $false
        WindowsDockerHostSet = $false
        OverallSuccess = $false
    }
    
    try {
        # Test WSL functionality
        Write-LogMessage "Validating WSL functionality..."
        $wslTest = & wsl.exe echo "WSL is working" 2>$null
        if ($LASTEXITCODE -eq 0 -and $wslTest.Trim() -eq "WSL is working") {
            $validationResults.WSLFunctional = $true
            Write-LogMessage "[SUCCESS] WSL is functional" -Level 'SUCCESS'
        } else {
            Write-LogMessage "[ERROR] WSL functionality test failed" -Level 'ERROR'
        }
        
        # Test Ubuntu responsiveness
        Write-LogMessage "Validating Ubuntu distribution..."
        $ubuntuTest = & wsl.exe -d Ubuntu echo "Ubuntu is responsive" 2>$null
        if ($LASTEXITCODE -eq 0 -and $ubuntuTest.Trim() -eq "Ubuntu is responsive") {
            $validationResults.UbuntuResponsive = $true
            Write-LogMessage "[SUCCESS] Ubuntu distribution is responsive" -Level 'SUCCESS'
        } else {
            Write-LogMessage "[ERROR] Ubuntu distribution test failed" -Level 'ERROR'
        }
        
        # Test Python installation using root commands for consistency
        Write-LogMessage "Validating Python installation..."
        $pythonTestCmd = 'python3 -c "import sys; print(\"Python\", sys.version.split()[0])" 2>/dev/null'
        $pythonTest = & wsl.exe --user root bash -c $pythonTestCmd
        if ($LASTEXITCODE -eq 0 -and $pythonTest -match 'Python \d+\.\d+\.\d+') {
            $validationResults.PythonWorking = $true
            Write-LogMessage "[SUCCESS] Python is working: $($pythonTest.Trim())" -Level 'SUCCESS'
        } else {
            Write-LogMessage "[ERROR] Python validation failed" -Level 'ERROR'
        }
        
        # Test Docker installation using root commands
        Write-LogMessage "Validating Docker installation..."
        $dockerTest = & wsl.exe --user root bash -c 'docker --version 2>/dev/null'
        if ($LASTEXITCODE -eq 0 -and $dockerTest -match 'Docker version') {
            $validationResults.DockerRunning = $true
            Write-LogMessage "[SUCCESS] Docker is working: $($dockerTest.Trim())" -Level 'SUCCESS'
        } else {
            Write-LogMessage "[ERROR] Docker validation failed" -Level 'ERROR'
        }
        
        # Test Docker Compose using root commands
        Write-LogMessage "Validating Docker Compose..."
        $composeTest = & wsl.exe --user root bash -c 'docker compose version 2>/dev/null'
        if ($LASTEXITCODE -eq 0 -and $composeTest -match 'Docker Compose') {
            $validationResults.DockerComposeWorking = $true
            Write-LogMessage "[SUCCESS] Docker Compose is working: $($composeTest.Trim())" -Level 'SUCCESS'
        } else {
            Write-LogMessage "[ERROR] Docker Compose validation failed" -Level 'ERROR'
        }
        
        # Test Docker socket accessibility
        if ($Global:ScriptResults.WSLNetworkAddress) {
            Write-LogMessage "Validating Docker socket accessibility..."
            if (Test-WSLDockerSocket -WSLIp $Global:ScriptResults.WSLNetworkAddress) {
                $validationResults.DockerSocketAccessible = $true
                Write-LogMessage "[SUCCESS] Docker socket is accessible from Windows" -Level 'SUCCESS'
            } else {
                Write-LogMessage "[ERROR] Docker socket accessibility failed" -Level 'ERROR'
            }
        }
        
        # Test Windows DOCKER_HOST environment
        Write-LogMessage "Validating Windows DOCKER_HOST environment..."
        $dockerHostEnv = [System.Environment]::GetEnvironmentVariable('DOCKER_HOST', [System.EnvironmentVariableTarget]::User)
        if ($dockerHostEnv -and $dockerHostEnv.StartsWith('tcp://')) {
            $validationResults.WindowsDockerHostSet = $true
            Write-LogMessage "[SUCCESS] Windows DOCKER_HOST is set: ${dockerHostEnv}" -Level 'SUCCESS'
        } else {
            Write-LogMessage "[ERROR] Windows DOCKER_HOST validation failed" -Level 'ERROR'
        }
        
        # Calculate overall success
        $successCount = ($validationResults.Values | Where-Object { $_ -eq $true }).Count
        $totalTests = $validationResults.Keys.Count - 1 # Exclude OverallSuccess from count
        
        $validationResults.OverallSuccess = $successCount -eq $totalTests
        $Global:ScriptResults.ValidationPassed = $validationResults.OverallSuccess
        
        Write-LogMessage "Validation Summary: ${successCount}/${totalTests} tests passed" -Level $(if ($validationResults.OverallSuccess) { 'SUCCESS' } else { 'WARN' })
        
        return $validationResults
    }
    catch {
        Write-LogMessage "Error during comprehensive validation: $($_.Exception.Message)" -Level 'ERROR'
        return $validationResults
    }
}

# ============================================================================
# MAIN EXECUTION WORKFLOW
# ============================================================================

function Invoke-WSLDockerSetup {
    <#
    .SYNOPSIS
        Main execution function for WSL Docker environment setup
    .DESCRIPTION
        Orchestrates the complete setup process with error handling and progress tracking
    #>
    
    Write-LogMessage "=== WSL Docker Environment Setup Starting ===" -Level 'INFO'
    Write-LogMessage "PowerShell Version: $($PSVersionTable.PSVersion)" -Level 'INFO'
    Write-LogMessage "Execution Policy: $(Get-ExecutionPolicy)" -Level 'INFO'
    Write-LogMessage "Working Directory: $PWD" -Level 'INFO'
    Write-LogMessage "Script Path: $PSCommandPath" -Level 'INFO'
    
    try {
        # Step 1: Administrator elevation check
        Write-LogMessage "Step 1: Checking administrator privileges..." -Level 'INFO'
        if (-not (Test-AdminElevation)) {
            throw "Administrator elevation failed"
        }
        Write-LogMessage "Step 1: Administrator privileges confirmed" -Level 'SUCCESS'
        
        # Step 2: WSL availability check
        Write-LogMessage "Step 2: Checking WSL availability..." -Level 'INFO'
        if (-not (Test-WSLAvailability)) {
            throw "WSL is not available or not properly configured"
        }
        Write-LogMessage "Step 2: WSL availability confirmed" -Level 'SUCCESS'
        
        # Step 3: Clean installation if requested
        if ($CleanInstall) {
            Write-LogMessage "Step 3: Performing clean installation..." -Level 'INFO'
            Remove-UbuntuWSL | Out-Null
            Write-LogMessage "Step 3: Clean installation completed" -Level 'SUCCESS'
        } else {
            Write-LogMessage "Step 3: Skipping clean installation" -Level 'INFO'
        }
        
        # Step 4: Ubuntu distribution check/install
        Write-LogMessage "Step 4: Checking Ubuntu distribution..." -Level 'INFO'
        if (-not (Test-UbuntuDistribution)) {
            Write-LogMessage "Ubuntu distribution not found. Checking if Ubuntu is available for installation..." -Level 'INFO'
            
            # Check if Ubuntu is available in the store
            $availableDistros = & wsl.exe --list --online 2>/dev/null
            if ($LASTEXITCODE -ne 0 -or -not ($availableDistros -match "Ubuntu\s+Ubuntu")) {
                Write-LogMessage "Ubuntu WSL distribution is not available for installation. Skipping WSL Docker setup." -Level 'ERROR'
                Write-LogMessage "Please ensure WSL is properly configured and Ubuntu is available in the Microsoft Store." -Level 'ERROR'
                return $false
            }
            
            Write-LogMessage "Ubuntu is available. Proceeding with installation..." -Level 'INFO'
            if (-not (Install-UbuntuWSL)) {
                Write-LogMessage "Failed to install Ubuntu WSL distribution. Skipping WSL Docker setup." -Level 'ERROR'
                return $false
            }
        }
        Write-LogMessage "Step 4: Ubuntu distribution ready" -Level 'SUCCESS'
        
        # Step 5: Configure sudoers for NOPASSWD
        Write-LogMessage "Step 5: Configuring sudoers..." -Level 'INFO'
        if (-not (Set-WSLSudoersConfiguration)) {
            Write-LogMessage "Sudoers configuration failed but continuing..." -Level 'WARN'
        } else {
            Write-LogMessage "Step 5: Sudoers configuration completed" -Level 'SUCCESS'
        }
        
        # Step 6: Install Python
        Write-LogMessage "Step 6: Installing Python..." -Level 'INFO'
        if (-not (Install-PythonWSL)) {
            throw "Failed to install Python in WSL Ubuntu"
        }
        Write-LogMessage "Step 6: Python installation completed" -Level 'SUCCESS'
        
        # Step 7: Install Docker
        Write-LogMessage "Step 7: Installing Docker..." -Level 'INFO'
        if (-not (Install-DockerWSL)) {
            throw "Failed to install Docker in WSL Ubuntu"
        }
        Write-LogMessage "Step 7: Docker installation completed" -Level 'SUCCESS'
        
        # Step 8: Configure Docker post-installation
        Write-LogMessage "Step 8: Configuring Docker post-installation..." -Level 'INFO'
        if (-not (Set-DockerPostInstall)) {
            throw "Failed to configure Docker post-installation settings"
        }
        Write-LogMessage "Step 8: Docker post-installation completed" -Level 'SUCCESS'
        
        # Step 9: Verify Docker Compose
        Write-LogMessage "Step 9: Verifying Docker Compose..." -Level 'INFO'
        if (-not (Install-DockerComposeWSL)) {
            Write-LogMessage "Docker Compose verification failed but continuing..." -Level 'WARN'
        } else {
            Write-LogMessage "Step 9: Docker Compose verification completed" -Level 'SUCCESS'
        }
        
        # Step 10: Test Docker installation
        Write-LogMessage "Step 10: Testing Docker installation..." -Level 'INFO'
        if (-not (Test-DockerInstallation)) {
            Write-LogMessage "Docker installation test failed but continuing..." -Level 'WARN'
        } else {
            Write-LogMessage "Step 10: Docker installation test completed" -Level 'SUCCESS'
        }
        
        # Step 11: Get WSL network address
        Write-LogMessage "Step 11: Getting WSL network address..." -Level 'INFO'
        $wslIp = Get-WSLNetworkAddress
        if (-not $wslIp) {
            throw "Failed to retrieve WSL network address"
        }
        Write-LogMessage "Step 11: WSL network address retrieved: $wslIp" -Level 'SUCCESS'
        
        # Step 12: Configure Windows environment
        Write-LogMessage "Step 12: Configuring Windows environment..." -Level 'INFO'
        if (-not (Set-DockerHostEnvironment -WSLIp $wslIp)) {
            throw "Failed to configure Windows DOCKER_HOST environment"
        }
        Write-LogMessage "Step 12: Windows environment configuration completed" -Level 'SUCCESS'
        
        # Step 13: Comprehensive validation (if not skipped)
        if (-not $SkipValidation) {
            Write-LogMessage "Step 13: Running comprehensive validation..." -Level 'INFO'
            $validationResults = Test-ComprehensiveValidation
            if (-not $validationResults.OverallSuccess) {
                Write-LogMessage "Some validation tests failed. Check the results above." -Level 'WARN'
            } else {
                Write-LogMessage "Step 13: Comprehensive validation completed successfully" -Level 'SUCCESS'
            }
        } else {
            Write-LogMessage "Step 13: Skipping comprehensive validation" -Level 'INFO'
        }
        
        Write-LogMessage "=== WSL Docker Environment Setup Completed ===" -Level 'SUCCESS'
        return $true
    }
    catch {
        Write-LogMessage "=== WSL Docker Environment Setup Failed ===" -Level 'ERROR'
        Write-LogMessage "Error: $($_.Exception.Message)" -Level 'ERROR'
        return $false
    }
}

function Show-FinalReport {
    <#
    .SYNOPSIS
        Display comprehensive final report
    .DESCRIPTION
        Shows summary of installation results, warnings, and next steps
    #>
    
    $Global:ScriptResults.EndTime = Get-Date
    $duration = $Global:ScriptResults.EndTime - $Global:ScriptResults.StartTime
    
    Write-Host "`n" -NoNewline
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "                WSL DOCKER SETUP FINAL REPORT                  " -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan
    
    Write-Host "Execution Time: " -NoNewline
    Write-Host "$($duration.Minutes)m $($duration.Seconds)s" -ForegroundColor Yellow
    
    Write-Host "`nComponent Status:" -ForegroundColor White
    Write-Host "  WSL Available: " -NoNewline
    Write-Host $(if ($Global:ScriptResults.WSLAvailable) { "[SUCCESS]" } else { "[ERROR]" }) -ForegroundColor $(if ($Global:ScriptResults.WSLAvailable) { "Green" } else { "Red" })
    
    Write-Host "  Ubuntu Installed: " -NoNewline
    Write-Host $(if ($Global:ScriptResults.UbuntuInstalled) { "[SUCCESS]" } else { "[ERROR]" }) -ForegroundColor $(if ($Global:ScriptResults.UbuntuInstalled) { "Green" } else { "Red" })
    
    Write-Host "  Python Installed: " -NoNewline
    Write-Host $(if ($Global:ScriptResults.PythonInstalled) { "[SUCCESS]" } else { "[ERROR]" }) -ForegroundColor $(if ($Global:ScriptResults.PythonInstalled) { "Green" } else { "Red" })
    
    Write-Host "  Docker Installed: " -NoNewline
    Write-Host $(if ($Global:ScriptResults.DockerInstalled) { "[SUCCESS]" } else { "[ERROR]" }) -ForegroundColor $(if ($Global:ScriptResults.DockerInstalled) { "Green" } else { "Red" })
    
    Write-Host "  Docker Compose: " -NoNewline
    Write-Host $(if ($Global:ScriptResults.DockerComposeInstalled) { "[SUCCESS]" } else { "[ERROR]" }) -ForegroundColor $(if ($Global:ScriptResults.DockerComposeInstalled) { "Green" } else { "Red" })
    
    Write-Host "  Docker Socket: " -NoNewline
    Write-Host $(if ($Global:ScriptResults.DockerSocketConfigured) { "[SUCCESS]" } else { "[ERROR]" }) -ForegroundColor $(if ($Global:ScriptResults.DockerSocketConfigured) { "Green" } else { "Red" })
    
    Write-Host "  Windows ENV: " -NoNewline
    Write-Host $(if ($Global:ScriptResults.WindowsEnvConfigured) { "[SUCCESS]" } else { "[ERROR]" }) -ForegroundColor $(if ($Global:ScriptResults.WindowsEnvConfigured) { "Green" } else { "Red" })
    
    Write-Host "  Validation: " -NoNewline
    Write-Host $(if ($Global:ScriptResults.ValidationPassed) { "[SUCCESS]" } else { "[ERROR]" }) -ForegroundColor $(if ($Global:ScriptResults.ValidationPassed) { "Green" } else { "Red" })
    
    if ($Global:ScriptResults.WSLNetworkAddress) {
        Write-Host "`nNetwork Configuration:" -ForegroundColor White
        Write-Host "  WSL IP Address: " -NoNewline
        Write-Host $Global:ScriptResults.WSLNetworkAddress -ForegroundColor Yellow
        Write-Host "  DOCKER_HOST: " -NoNewline
        Write-Host "tcp://$($Global:ScriptResults.WSLNetworkAddress):2375" -ForegroundColor Yellow
    }
    
    if ($Global:ScriptResults.Warnings.Count -gt 0) {
        Write-Host "`nWarnings:" -ForegroundColor Yellow
        $Global:ScriptResults.Warnings | ForEach-Object {
            Write-Host "  * $_" -ForegroundColor Yellow
        }
    }
    
    if ($Global:ScriptResults.Errors.Count -gt 0) {
        Write-Host "`nErrors:" -ForegroundColor Red
        $Global:ScriptResults.Errors | ForEach-Object {
            Write-Host "  * $_" -ForegroundColor Red
        }
    }
    
    Write-Host "`nNext Steps:" -ForegroundColor White
    Write-Host "  1. Restart your terminal or VS Code to refresh environment variables" -ForegroundColor Cyan
    Write-Host "  2. Install Docker VS Code extension for enhanced development" -ForegroundColor Cyan
    Write-Host "  3. Test Docker integration: docker ps" -ForegroundColor Cyan
    Write-Host "  4. Test Docker Compose: docker compose --version" -ForegroundColor Cyan
    
    Write-Host "`n================================================================" -ForegroundColor Cyan
    
    # Always show log file location
    Write-Host "Log File: " -NoNewline -ForegroundColor White
    Write-Host $Global:LogFilePath -ForegroundColor Yellow
    
    # Auto-continue for Silent mode or add brief pause for visibility
    if ($Silent) {
        Write-LogMessage "Script completed in Silent mode. Exiting..." -Level 'INFO'
        Write-Host "Script completed in Silent mode. Check log file for details." -ForegroundColor Green
    } else {
        Write-Host "`nSetup completed. Check the results above." -ForegroundColor White
        Write-Host "Full execution details are saved in the log file." -ForegroundColor White
        Write-Host "You can now close this window." -ForegroundColor White
    }
    
    return $Global:ScriptResults
}

# ============================================================================
# SCRIPT ENTRY POINT
# ============================================================================

# Main execution block
try {
    # Initialize log file and show its location
    Write-LogMessage "Log file location: $Global:LogFilePath" -Level 'INFO'
    
    # Show parameter summary if not silent
    if (-not $Silent) {
        Write-LogMessage "Starting with parameters: CleanInstall=$CleanInstall, Force=$Force, Silent=$Silent, SkipValidation=$SkipValidation" -Level 'INFO'
        Write-Host "Full execution log will be saved to: $Global:LogFilePath" -ForegroundColor Cyan
    }
    
    # Execute main setup workflow
    $setupResult = Invoke-WSLDockerSetup
    
    # Show final report
    $finalResults = Show-FinalReport
    
    # Log the final log file location again
    Write-LogMessage "Complete execution log saved to: $Global:LogFilePath" -Level 'INFO'
    if (-not $Silent) {
        Write-Host "`nComplete execution log saved to: $Global:LogFilePath" -ForegroundColor Green
    }
    
    # Set exit code based on results
    if ($setupResult -and ($Global:ScriptResults.ValidationPassed -or $SkipValidation)) {
        exit 0
    } else {
        exit 1
    }
}
catch {
    # Log the critical error to file and console
    Write-LogMessage "Critical error during script execution: $($_.Exception.Message)" -Level 'ERROR'
    Write-LogMessage "Stack trace: $($_.ScriptStackTrace)" -Level 'ERROR'
    Write-LogMessage "Error occurred at line: $($_.InvocationInfo.ScriptLineNumber)" -Level 'ERROR'
    Write-LogMessage "Error in command: $($_.InvocationInfo.Line.Trim())" -Level 'ERROR'
    
    # Show critical error even in silent mode
    if ($Silent) {
        Write-Host "CRITICAL ERROR: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Check log file: $Global:LogFilePath" -ForegroundColor Yellow
    }
    
    # Show final report even on critical error
    Show-FinalReport | Out-Null
    
    exit 1
}
finally {
    # Reset progress preference
    $ProgressPreference = 'Continue'
    
    # Final log cleanup message
    if (Test-Path $Global:LogFilePath) {
        Write-LogMessage "Script execution completed. Log file preserved at: $Global:LogFilePath" -Level 'INFO'
    }
}
