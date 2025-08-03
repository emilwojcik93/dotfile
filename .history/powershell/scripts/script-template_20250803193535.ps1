#Requires -Version 7.0
<#
.SYNOPSIS
    Template for PowerShell scripts with proper UTF-8 encoding and validation
.DESCRIPTION
    This template provides a starting point for PowerShell scripts following
    enterprise development standards with proper error handling, documentation,
    self-elevation, and comprehensive help system
.PARAMETER InputPath
    Path to input file or directory
.PARAMETER OutputPath
    Path where output will be saved
.PARAMETER Force
    Overwrite existing files without prompting
.PARAMETER RequireAdmin
    Force script to run with administrator privileges
.EXAMPLE
    .\script-template.ps1 -InputPath "C:\Data" -OutputPath "C:\Results"
    Process data from C:\Data and save results to C:\Results
.EXAMPLE
    .\script-template.ps1 -InputPath "file.txt" -OutputPath "processed.txt" -Force
    Process single file and overwrite existing output without prompting
.EXAMPLE
    .\script-template.ps1 -InputPath "C:\Data" -OutputPath "C:\Results" -RequireAdmin -Verbose
    Run with administrator privileges and detailed verbose output
.INPUTS
    System.String
    You can pipe file paths to this script
.OUTPUTS
    System.Management.Automation.PSCustomObject
    Returns processing results with status and details
.NOTES
    Author: Your Name
    Date: 2025-08-03
    Version: 1.0
    
    Prerequisites:
    - PowerShell 7.0 or later
    - UTF-8 encoding support
    - Administrator rights (if RequireAdmin specified)
    
    Change Log:
    1.0 - Initial version with self-elevation and comprehensive help
    
    Links:
    - https://docs.microsoft.com/powershell/
    - https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_comment_based_help
.LINK
    https://github.com/your-repo/script-template
.COMPONENT
    DevelopmentTools
.ROLE
    Developer
.FUNCTIONALITY
    Template script demonstrating enterprise PowerShell development standards
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory, 
               ValueFromPipeline,
               ValueFromPipelineByPropertyName,
               HelpMessage = "Specify the input path for processing")]
    [ValidateScript({ Test-Path $_ })]
    [string]$InputPath,
    
    [Parameter(Mandatory, 
               HelpMessage = "Specify the output path where results will be saved")]
    [ValidateNotNullOrEmpty()]
    [string]$OutputPath,
    
    [Parameter(HelpMessage = "Overwrite existing files without prompting")]
    [switch]$Force,
    
    [Parameter(HelpMessage = "Require administrator privileges for this operation")]
    [switch]$RequireAdmin
)

# Set strict mode and error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Configure encoding for UTF-8 support
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Self-elevation function based on ChrisTitusTech/winutil pattern
function Test-AdminElevation {
    <#
    .SYNOPSIS
        Checks if script is running with administrator privileges and elevates if needed
    .DESCRIPTION
        Validates current user privileges and automatically re-launches the script
        with administrator rights if required. Preserves all original parameters.
    .PARAMETER RequireAdmin
        Force elevation check even if not explicitly required
    .EXAMPLE
        Test-AdminElevation -RequireAdmin
    .NOTES
        Based on ChrisTitusTech/winutil self-elevation pattern
        Modified to exclude external URL execution for security
    #>
    [CmdletBinding()]
    param(
        [switch]$RequireAdmin
    )
    
    # Check if running as administrator
    $IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $IsAdmin -and $RequireAdmin) {
        Write-Warning "Script requires administrator privileges. Attempting to relaunch with elevation."
        
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
        
        # Construct script execution command (no external URL for security)
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
            Write-Host "Script relaunched with administrator privileges." -ForegroundColor Green
            exit 0
        }
        catch {
            Write-Error "Failed to elevate privileges: $($_.Exception.Message)"
            exit 1
        }
    }
    
    return $IsAdmin
}

# Check for administrative privileges if required
if ($RequireAdmin) {
    $IsAdmin = Test-AdminElevation -RequireAdmin
    Write-Verbose "Running with administrator privileges: $IsAdmin"
}

# Script-level variables
$script:StartTime = Get-Date
$script:LogPath = Join-Path $env:TEMP "script-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# Logging function with grade-level comments
function Write-Log {
    <#
    .SYNOPSIS
        Provides structured logging with multiple output levels
    .DESCRIPTION
        This function implements enterprise-grade logging with console and file output.
        It supports multiple log levels and UTF-8 encoding for international characters.
    .PARAMETER Message
        The message to log
    .PARAMETER Level
        The severity level of the message
    .EXAMPLE
        Write-Log "Processing started" -Level Info
    .NOTES
        Uses UTF-8 encoding to ensure proper character display across different systems
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [ValidateSet('Info', 'Warning', 'Error', 'Debug')]
        [string]$Level = 'Info'
    )
    
    $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $LogEntry = "[$Timestamp] [$Level] $Message"
    
    # Write to console with appropriate colors for better user experience
    switch ($Level) {
        'Info'    { Write-Host $LogEntry -ForegroundColor White }
        'Warning' { Write-Warning $LogEntry }
        'Error'   { Write-Error $LogEntry }
        'Debug'   { Write-Debug $LogEntry }
    }
    
    # Write to log file with UTF-8 encoding to support international characters
    try {
        Add-Content -Path $script:LogPath -Value $LogEntry -Encoding UTF8
    }
    catch {
        Write-Warning "Failed to write to log file: $($_.Exception.Message)"
    }
}

# Input validation function with comprehensive error checking
function Test-InputParameters {
    <#
    .SYNOPSIS
        Validates all input parameters before processing begins
    .DESCRIPTION
        Performs comprehensive validation of input parameters including path existence,
        directory creation, and file overwrite protection. This prevents runtime errors
        and provides clear feedback to users about parameter issues.
    .NOTES
        This function implements defensive programming practices by validating all
        assumptions before proceeding with main processing logic.
    #>
    [CmdletBinding()]
    param()
    
    Write-Log "Validating input parameters..." -Level Debug
    
    # Validate input path exists - critical for preventing downstream errors
    if (-not (Test-Path $InputPath)) {
        throw "Input path does not exist: $InputPath"
    }
    
    # Ensure output directory structure exists - create if missing
    $OutputDir = Split-Path $OutputPath -Parent
    if ($OutputDir -and -not (Test-Path $OutputDir)) {
        Write-Log "Creating output directory: $OutputDir"
        # Use Force to create entire directory tree if needed
        New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
    }
    
    # Implement file overwrite protection unless Force is explicitly specified
    if ((Test-Path $OutputPath) -and -not $Force) {
        throw "Output file exists and -Force not specified: $OutputPath"
    }
    
    Write-Log "Input validation completed successfully"
}

# Main processing function
function Invoke-MainProcessing {
    [CmdletBinding()]
    param()
    
    try {
        Write-Log "Starting main processing..."
        
        # TODO: Implement your main logic here
        # Example: Process files, transform data, etc.
        
        # Get input item
        $InputItem = Get-Item $InputPath
        Write-Log "Processing: $($InputItem.Name)"
        
        # Example processing (replace with actual logic)
        if ($InputItem.PSIsContainer) {
            Write-Log "Processing directory with $((Get-ChildItem $InputPath).Count) items"
            # Directory processing logic
        }
        else {
            Write-Log "Processing file of size $($InputItem.Length) bytes"
            # File processing logic
        }
        
        # Create output (example)
        $OutputContent = @{
            ProcessedAt = Get-Date
            InputPath = $InputPath
            OutputPath = $OutputPath
            Status = "Success"
        }
        
        # Save output with UTF-8 encoding
        $OutputContent | ConvertTo-Json -Depth 10 | 
            Set-Content -Path $OutputPath -Encoding UTF8
        
        Write-Log "Output saved to: $OutputPath"
        Write-Log "Main processing completed successfully"
        
        return $true
    }
    catch {
        Write-Log "Error in main processing: $($_.Exception.Message)" -Level Error
        throw
    }
}

# Cleanup function
function Invoke-Cleanup {
    [CmdletBinding()]
    param()
    
    Write-Log "Performing cleanup operations..."
    
    # TODO: Add cleanup logic here
    # Example: Close connections, remove temporary files, etc.
    
    $EndTime = Get-Date
    $Duration = $EndTime - $script:StartTime
    Write-Log "Script completed in $($Duration.TotalSeconds) seconds"
    Write-Log "Log file saved to: $script:LogPath"
}

# Main execution block
try {
    Write-Log "=== Script Started ==="
    Write-Log "Input Path: $InputPath"
    Write-Log "Output Path: $OutputPath"
    Write-Log "Force: $Force"
    
    # Validate parameters
    Test-InputParameters
    
    # Confirm action if WhatIf is not specified
    if ($PSCmdlet.ShouldProcess($InputPath, "Process and save to $OutputPath")) {
        # Execute main processing
        $Result = Invoke-MainProcessing
        
        if ($Result) {
            Write-Log "=== Script Completed Successfully ==="
            exit 0
        }
        else {
            Write-Log "=== Script Completed with Issues ===" -Level Warning
            exit 1
        }
    }
    else {
        Write-Log "Operation cancelled by user"
        exit 0
    }
}
catch {
    Write-Log "=== Script Failed ===" -Level Error
    Write-Log "Error: $($_.Exception.Message)" -Level Error
    Write-Log "Line: $($_.InvocationInfo.ScriptLineNumber)" -Level Error
    exit 1
}
finally {
    Invoke-Cleanup
}
