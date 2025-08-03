#Requires -Version 7.0
<#
.SYNOPSIS
    Template for PowerShell scripts with proper UTF-8 encoding and validation
.DESCRIPTION
    This template provides a starting point for PowerShell scripts following
    enterprise development standards with proper error handling and documentation
.PARAMETER InputPath
    Path to input file or directory
.PARAMETER OutputPath
    Path where output will be saved
.PARAMETER Force
    Overwrite existing files without prompting
.EXAMPLE
    .\script-template.ps1 -InputPath "C:\Data" -OutputPath "C:\Results"
.EXAMPLE
    .\script-template.ps1 -InputPath "file.txt" -OutputPath "processed.txt" -Force
.NOTES
    Author: Your Name
    Date: 2025-08-03
    Version: 1.0
    
    Requirements:
    - PowerShell 7.0 or later
    - UTF-8 encoding support
    
    Change Log:
    1.0 - Initial version
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory, HelpMessage = "Specify the input path")]
    [ValidateScript({ Test-Path $_ })]
    [string]$InputPath,
    
    [Parameter(Mandatory, HelpMessage = "Specify the output path")]
    [string]$OutputPath,
    
    [Parameter(HelpMessage = "Overwrite existing files")]
    [switch]$Force
)

# Set strict mode and error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Configure encoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Script-level variables
$script:StartTime = Get-Date
$script:LogPath = Join-Path $env:TEMP "script-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

# Logging function
function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [ValidateSet('Info', 'Warning', 'Error', 'Debug')]
        [string]$Level = 'Info'
    )
    
    $Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $LogEntry = "[$Timestamp] [$Level] $Message"
    
    # Write to console with colors
    switch ($Level) {
        'Info'    { Write-Host $LogEntry -ForegroundColor White }
        'Warning' { Write-Warning $LogEntry }
        'Error'   { Write-Error $LogEntry }
        'Debug'   { Write-Debug $LogEntry }
    }
    
    # Write to log file
    try {
        Add-Content -Path $script:LogPath -Value $LogEntry -Encoding UTF8
    }
    catch {
        Write-Warning "Failed to write to log file: $($_.Exception.Message)"
    }
}

# Input validation function
function Test-InputParameters {
    [CmdletBinding()]
    param()
    
    Write-Log "Validating input parameters..." -Level Debug
    
    # Check if input path exists
    if (-not (Test-Path $InputPath)) {
        throw "Input path does not exist: $InputPath"
    }
    
    # Check if output directory exists, create if needed
    $OutputDir = Split-Path $OutputPath -Parent
    if ($OutputDir -and -not (Test-Path $OutputDir)) {
        Write-Log "Creating output directory: $OutputDir"
        New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
    }
    
    # Check if output file exists and Force is not specified
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
