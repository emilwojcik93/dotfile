#Requires -Version 5.1
<#
.SYNOPSIS
    Test script for comment-based help functionality
.DESCRIPTION
    This is a simple test script to verify that Get-Help works with comment-based help
    in PowerShell 5.1 without requiring internet access.
.PARAMETER TestParam
    A test parameter for demonstration
.EXAMPLE
    .\test-help.ps1 -TestParam "Hello"
    Runs the test script with a parameter
.NOTES
    Author: Test Script
    Version: 1.0
    This script tests offline help functionality
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Test parameter")]
    [string]$TestParam = "Default"
)

Write-Host "Test script executed with parameter: $TestParam" -ForegroundColor Green
Write-Host "Help should work offline without internet lookup" -ForegroundColor Cyan
