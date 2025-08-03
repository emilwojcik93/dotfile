#Requires -Version 5.1
<#
.SYNOPSIS
    PowerShell profile configuration for development environment
.DESCRIPTION
    Sets up PowerShell environment with custom functions, aliases, and modules
    for development work with proper UTF-8 encoding and validation tools.
    Compatible with PowerShell 5.1+ (default Windows PowerShell) and PowerShell 7.x
.NOTES
    Author: Personal Development Environment
    Version: 2.1
    Requires: PowerShell 5.1+ (Windows 11 default)
    Compatible: PowerShell 5.1, 7.x
    Place this file in: $PROFILE.CurrentUserAllHosts
.LINK
    https://github.com/emilwojcik93/dotfile
.COMPONENT
    DotfilesProfile
.ROLE
    DeveloperTools
.FUNCTIONALITY
    PowerShell environment configuration for cross-platform development
#>

# Set console encoding to UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Set PSReadLine options
if (Get-Module -ListAvailable -Name PSReadLine) {
    Set-PSReadLineOption -EditMode Emacs
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineKeyHandler -Key Tab -Function Complete
}

# Import useful modules if available
$ModulesToImport = @(
    'PSScriptAnalyzer',
    'Pester',
    'PowerShellGet'
)

foreach ($Module in $ModulesToImport) {
    if (Get-Module -ListAvailable -Name $Module) {
        Import-Module $Module -Force -Scope Global
    }
}

# Custom functions
function Test-ScriptSyntax {
    <#
    .SYNOPSIS
        Validates PowerShell script syntax
    .PARAMETER Path
        Path to the PowerShell script file
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Path
    )

    try {
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $Path -Raw), [ref]$null)
        Write-Host "✓ Syntax is valid: $Path" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "✗ Syntax error in: $Path" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        return $false
    }
}

function Format-AllScripts {
    <#
    .SYNOPSIS
        Formats all PowerShell scripts in current directory
    #>
    Get-ChildItem -Path . -Filter '*.ps1' -Recurse | ForEach-Object {
        Write-Host "Formatting: $($_.Name)" -ForegroundColor Yellow
        $Content = Get-Content $_.FullName -Raw
        $Formatted = Invoke-Formatter -ScriptDefinition $Content
        Set-Content -Path $_.FullName -Value $Formatted -Encoding UTF8
    }
}

function Validate-AllFiles {
    <#
    .SYNOPSIS
        Validates syntax of all script files in current directory
    #>
    Write-Host 'Validating PowerShell files...' -ForegroundColor Cyan
    Get-ChildItem -Path . -Filter '*.ps1' -Recurse | ForEach-Object {
        Test-ScriptSyntax -Path $_.FullName
    }

    Write-Host 'Validating Python files...' -ForegroundColor Cyan
    Get-ChildItem -Path . -Filter '*.py' -Recurse | ForEach-Object {
        python -m py_compile $_.FullName
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ Python syntax valid: $($_.Name)" -ForegroundColor Green
        } else {
            Write-Host "✗ Python syntax error: $($_.Name)" -ForegroundColor Red
        }
    }

    Write-Host 'Validating JSON files...' -ForegroundColor Cyan
    Get-ChildItem -Path . -Filter '*.json' -Recurse | ForEach-Object {
        try {
            Get-Content $_.FullName | ConvertFrom-Json | Out-Null
            Write-Host "✓ JSON syntax valid: $($_.Name)" -ForegroundColor Green
        } catch {
            Write-Host "✗ JSON syntax error: $($_.Name)" -ForegroundColor Red
        }
    }
}

function Set-UTF8Encoding {
    <#
    .SYNOPSIS
        Ensures files are saved with UTF-8 encoding
    .PARAMETER Path
        Path to the file to convert
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Path
    )

    $Content = Get-Content -Path $Path -Raw
    Set-Content -Path $Path -Value $Content -Encoding UTF8 -NoNewline
    Write-Host "✓ Converted to UTF-8: $Path" -ForegroundColor Green
}

# Useful aliases
Set-Alias -Name validate -Value Validate-AllFiles
Set-Alias -Name format -Value Format-AllScripts
Set-Alias -Name utf8 -Value Set-UTF8Encoding

# Environment variables
$env:PYTHONIOENCODING = 'utf-8'

# Custom prompt with Git branch if available
function prompt {
    $Location = Get-Location
    $GitBranch = ''

    if (Get-Command git -ErrorAction SilentlyContinue) {
        try {
            $GitStatus = git status --porcelain=v1 2>$null
            if ($LASTEXITCODE -eq 0) {
                $Branch = git branch --show-current 2>$null
                if ($Branch) {
                    $GitBranch = " ($Branch)"
                }
            }
        } catch {
            # Ignore git errors
        }
    }

    Write-Host 'PS ' -NoNewline -ForegroundColor Yellow
    Write-Host $Location -NoNewline -ForegroundColor Blue
    Write-Host $GitBranch -NoNewline -ForegroundColor Green
    Write-Host '> ' -NoNewline
    return ' '
}

# Welcome message
Write-Host 'PowerShell Development Profile Loaded' -ForegroundColor Green
Write-Host 'Available commands: validate, format, utf8' -ForegroundColor Yellow
Write-Host 'Encoding set to UTF-8' -ForegroundColor Cyan
