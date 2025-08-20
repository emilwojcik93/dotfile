# Complete Dotfile Setup Validation

Write-Host "=== COMPLETE DOTFILE SETUP VALIDATION ===" -ForegroundColor Green
Write-Host "Device: $env:COMPUTERNAME" -ForegroundColor Cyan
Write-Host "User: $env:USERNAME" -ForegroundColor Cyan  
Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host ""

# System Capabilities Check
Write-Host "=== SYSTEM CAPABILITIES ===" -ForegroundColor Yellow
$capabilities = @{
    VSCode = [bool](Get-Command code -ErrorAction SilentlyContinue)
    Python = [bool](Get-Command python -ErrorAction SilentlyContinue)
    Git = [bool](Get-Command git -ErrorAction SilentlyContinue)
    Docker = [bool](Get-Command docker -ErrorAction SilentlyContinue)
    PowerShell7 = [bool](Get-Command pwsh -ErrorAction SilentlyContinue)
    WindowsTerminal = [bool](Get-Command wt -ErrorAction SilentlyContinue)
    Winget = [bool](Get-Command winget -ErrorAction SilentlyContinue)
    WSL = (wsl --list 2>$null) -and ($LASTEXITCODE -eq 0)
}

$capabilities.GetEnumerator() | Sort-Object Name | ForEach-Object {
    $status = if($_.Value) { "✅ Available" } else { "❌ Not Found" }
    $color = if($_.Value) { "Green" } else { "Red" }
    Write-Host ("  {0}: {1}" -f $_.Key, $status) -ForegroundColor $color
}

Write-Host ""

# VS Code Extensions Check
Write-Host "=== VS CODE EXTENSIONS ===" -ForegroundColor Yellow
$installedExtensions = code --list-extensions 2>$null
if ($installedExtensions) {
    Write-Host "  Currently Installed:" -ForegroundColor Green
    $installedExtensions | ForEach-Object { Write-Host "    ✅ $_" -ForegroundColor Green }
} else {
    Write-Host "  ❌ No extensions currently installed" -ForegroundColor Red
}

Write-Host ""

# Git Configuration Check
Write-Host "=== GIT CONFIGURATION ===" -ForegroundColor Yellow
$gitUser = git config --global user.name 2>$null
$gitEmail = git config --global user.email 2>$null

if ($gitUser -and $gitEmail) {
    Write-Host "  ✅ User: $gitUser" -ForegroundColor Green
    Write-Host "  ✅ Email: $gitEmail" -ForegroundColor Green
} else {
    Write-Host "  ⚠️  Git user/email not configured (manual setup required)" -ForegroundColor Yellow
}

Write-Host ""

# PowerShell Profile Check
Write-Host "=== POWERSHELL PROFILE ===" -ForegroundColor Yellow
$profileExists = Test-Path $PROFILE
$profileContent = if ($profileExists) { Get-Content $PROFILE -Raw } else { "" }

Write-Host "  Profile Path: $PROFILE" -ForegroundColor Cyan
Write-Host ("  Profile Exists: {0}" -f $(if($profileExists) { "✅ Yes" } else { "❌ No" })) -ForegroundColor $(if($profileExists) { "Green" } else { "Red" })

if ($profileExists) {
    $hasBeastMode = $profileContent -match "beast"
    $hasGitFunctions = $profileContent -match "function.*git|gs.*=|gp.*="
    Write-Host ("  Beast Mode: {0}" -f $(if($hasBeastMode) { "✅ Configured" } else { "❌ Not found" })) -ForegroundColor $(if($hasBeastMode) { "Green" } else { "Red" })
    Write-Host ("  Git Functions: {0}" -f $(if($hasGitFunctions) { "✅ Configured" } else { "❌ Not found" })) -ForegroundColor $(if($hasGitFunctions) { "Green" } else { "Red" })
}

Write-Host ""

# Package Validation Check
Write-Host "=== PACKAGE VALIDATION ===" -ForegroundColor Yellow
if ($capabilities.Winget) {
    Write-Host "  ✅ Winget available for package management" -ForegroundColor Green
    
    # Test key packages
    $packages = @("Git.Git", "Microsoft.VisualStudioCode", "Python.Python.3.12")
    foreach ($pkg in $packages) {
        winget show $pkg 2>$null | Out-Null
        $available = $LASTEXITCODE -eq 0
        $status = if($available) { "✅ Available" } else { "❌ Not found" }
        $color = if($available) { "Green" } else { "Red" }
        Write-Host ("  {0}: {1}" -f $pkg, $status) -ForegroundColor $color
    }
} else {
    Write-Host "  ❌ Winget not available" -ForegroundColor Red
}

Write-Host ""

# Local History Check
Write-Host "=== LOCAL HISTORY SETUP ===" -ForegroundColor Yellow
$gitignoreExists = Test-Path ".gitignore"
$historyExcluded = if ($gitignoreExists) { (Get-Content ".gitignore" -Raw) -match "\.history" } else { $false }

Write-Host ("  .gitignore exists: {0}" -f $(if($gitignoreExists) { "✅ Yes" } else { "❌ No" })) -ForegroundColor $(if($gitignoreExists) { "Green" } else { "Red" })
Write-Host ("  .history excluded: {0}" -f $(if($historyExcluded) { "✅ Yes" } else { "❌ No" })) -ForegroundColor $(if($historyExcluded) { "Green" } else { "Red" })

Write-Host ""

# Installation Readiness
Write-Host "=== INSTALLATION READINESS ===" -ForegroundColor Yellow
$isReady = $capabilities.VSCode -and $capabilities.Git -and $capabilities.Winget
$adminPrivs = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

Write-Host ("  System Ready: {0}" -f $(if($isReady) { "✅ Yes" } else { "❌ Missing requirements" })) -ForegroundColor $(if($isReady) { "Green" } else { "Red" })
Write-Host ("  Admin Privileges: {0}" -f $(if($adminPrivs) { "✅ Yes" } else { "⚠️  Will auto-elevate" })) -ForegroundColor $(if($adminPrivs) { "Green" } else { "Yellow" })

Write-Host ""

# Recommendations
Write-Host "=== RECOMMENDATIONS ===" -ForegroundColor Yellow

if (-not $installedExtensions) {
    Write-Host "  🔧 Run: .\automation\Install-DevEnvironment.ps1" -ForegroundColor Cyan
    Write-Host "     This will install all VS Code extensions and configure the environment" -ForegroundColor Gray
}

if (-not $gitUser -or -not $gitEmail) {
    Write-Host "  🔧 Configure Git:" -ForegroundColor Cyan
    Write-Host "     git config --global user.name 'Your Name'" -ForegroundColor Gray
    Write-Host "     git config --global user.email 'your.email@example.com'" -ForegroundColor Gray
}

if ($capabilities.WSL -and -not (wsl --list --verbose 2>$null | Where-Object { $_ -match "Running" })) {
    Write-Host "  🔧 WSL installed but may need restart or initialization" -ForegroundColor Cyan
}

if (-not $capabilities.Docker) {
    Write-Host "  💡 Docker not found - Docker extensions will be skipped during installation" -ForegroundColor Blue
}

Write-Host ""
Write-Host "=== VALIDATION COMPLETE ===" -ForegroundColor Green
