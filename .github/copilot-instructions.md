<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

# Coding Instructions for AI Assistants

## General Rules

### Character Encoding

- **Scripts**: Use only UTF-8/ASCII characters (no Unicode symbols)
- **Markdown**: Full Unicode support allowed
- **Comments**: Keep ASCII-only for scripts, Unicode OK for documentation

### Platform Environment

- **OS**: Windows 11 with WSL Ubuntu
- **Primary Shell**: **PowerShell 5.1** (Default Windows PowerShell) - **REQUIRED**
- **Secondary Shell**: Bash (WSL) for Linux compatibility
- **Python**: Python 3.11+ (prefer latest stable)
- **Tools**: VS Code, Git, Windows Terminal

**⚠️ PowerShell Version Requirements:**
- **Always use PowerShell 5.1** (`powershell.exe`) as the primary scripting environment
- **PowerShell 7.x compatibility issues**: Custom profiles interfere with VS Code CLI (`code --list-extensions` opens GUI instead of listing)
- **Windows 11 default**: PowerShell 5.1 is the default Windows PowerShell installation
- **Script compatibility**: All automation scripts must work with PowerShell 5.1 syntax
- **Optional PowerShell 7.x**: Can be installed as supplementary but not required for core functionality

### Package Management & Dependencies

- **Primary Package Manager**: Always prefer **winget** for Windows software installation
- **Validate Package Availability**: Use `winget search <package>` to verify packages exist
- **Package Sources**: Reference official winget sources for validation:
  - GitHub Manifests: https://github.com/microsoft/winget-pkgs/tree/master/manifests
  - Winget.run: https://winget.run/pkg/<Publisher>/<Package>
  - Winstall.app: https://winstall.app/apps/<Publisher>.<Package>
- **Installation Commands**: Use `winget install <PackageId>` format consistently
- **Version Management**: Specify versions when stability is critical: `winget install Git.Git --version 2.50.1`

### Development History & Backup

- **Local History Extension**: Always install `xyz.local-history` VS Code extension for automatic file versioning
- **History Directory**: Utilize `.history/` directory in git repositories for:
  - **Script Recovery**: Restore corrupted or accidentally deleted scripts
  - **Version Comparison**: Compare current files with historical versions
  - **Backup Strategy**: Automatic local backup before major changes
- **Git Integration**: Always add `.history/` to `.gitignore` to exclude from commits:
  ```gitignore
  # === History files ===
  .history/
  *.history
  ```
- **Recovery Process**: Access file history via VS Code Command Palette > "Local History: Show"

### Log Analysis and Validation

- **Always Check Logs**: After any script execution, review log files for warnings and errors
- **Log File Locations**: Check standard locations like `$env:TEMP\*.log` or script-specific paths
- **Warning Analysis**: Even successful runs may contain important warnings to address
- **Validation Steps**: Use `Get-Content -Tail 50` to review recent log entries
- **Error Patterns**: Look for ERROR, WARN, FAIL patterns in log output
- **Success Verification**: Confirm that "SUCCESS" or completion messages appear in logs
- **Post-Installation**: Always validate installation results even when scripts report success

## Script Development

### Code Quality Standards

- **Comment Grade**: Add in-code comments explaining complexity, business logic, and technical decisions
- **Documentation Level**: Include comprehensive help documentation for all functions and scripts
- **Readability**: Write self-documenting code with clear variable names and logical structure
- **Maintainability**: Structure code for future modifications and debugging

### MANDATORY VALIDATION REQUIREMENTS

- **Always Validate**: Every script MUST include comprehensive validation functions
- **Test-Path Usage**: Use Test-Path cmdlet extensively for file/directory validation
- **Command Validation**: Use Get-Command to check for required tools before use
- **Network Validation**: Test connectivity before attempting downloads or API calls
- **Parameter Validation**: Use ValidateScript, ValidateSet, and ValidateRange attributes
- **Error Handling**: Implement try/catch blocks with proper cleanup
- **Logging**: Include timestamped logging with severity levels (INFO, WARN, ERROR, SUCCESS)
- **Auto-Continue Prompts**: All user prompts must auto-continue/exit after 10 seconds maximum
- **System Requirements**: Validate OS, PowerShell version, disk space, and permissions

### Administrative Operations

- **Use gsudo**: For administrative commands when available: `gsudo Install-Module ModuleName`
- **Self-Elevation**: Include elevation functions for scripts requiring admin rights
- **Privilege Validation**: Always check and handle privilege requirements explicitly

### PowerShell Scripts (.ps1)

```powershell
# Template header for PowerShell scripts
#Requires -Version 5.1
<#
.SYNOPSIS
    Brief description of what the script does
.DESCRIPTION
    Detailed description of the script's functionality, purpose, and behavior.
    Include any important prerequisites or dependencies.
    Compatible with PowerShell 5.1+ (default Windows PowerShell) and PowerShell 7.x
.PARAMETER ParameterName
    Description of the parameter, including valid values and examples
.EXAMPLE
    PS> .\script-name.ps1 -ParameterName "Value"
    Description of what this example does
.EXAMPLE
    PS> .\script-name.ps1 -ParameterName "Value" -Verbose
    Example with verbose output
.INPUTS
    System.String
    You can pipe strings to this script
.OUTPUTS
    System.Object
    Returns objects of this type
.NOTES
    Author: Your Name
    Date: YYYY-MM-DD
    Version: 1.0
    Requires: PowerShell 5.1+ (Windows 11 default)
    Compatible: PowerShell 5.1, 7.x

    Prerequisites:
    - PowerShell 5.1 or later (default Windows PowerShell)
    - Administrator rights (if applicable)
    - Required modules: ModuleName

    Change Log:
    1.0 - Initial version

    Links:
    - https://docs.microsoft.com/powershell/
.LINK
    https://github.com/emilwojcik93/dotfile
.COMPONENT
    ComponentName (if part of a larger system)
.ROLE
    RoleName (target audience/role)
.FUNCTIONALITY
    Brief description of core functionality
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
param(
    [Parameter(Mandatory,
               ValueFromPipeline,
               ValueFromPipelineByPropertyName,
               HelpMessage = "Specify the parameter value")]
    [ValidateNotNullOrEmpty()]
    [string]$ParameterName,

    [Parameter(HelpMessage = "Enable administrative operations")]
    [switch]$RequireAdmin
)
```

**PowerShell Development Standards:**

- Always use **#Requires -Version 5.1** for Windows 11 compatibility (default PowerShell)
- Support both **PowerShell 5.1** (Windows PowerShell) and **PowerShell 7.x** (PowerShell Core)
- Always include complete **Comment-Based Help** following Microsoft conventions
- Use **approved verbs** (Get-Verb for reference)
- Include **parameter validation** and help messages
- Add **error handling** with try/catch blocks
- Use **Write-Verbose**, **Write-Warning**, **Write-Error** for proper output
- Include **NOTES section** with prerequisites, change log, and links
- Add **INPUTS/OUTPUTS** documentation for pipeline compatibility
- Test on both **Windows PowerShell 5.1** and **PowerShell 7+**
- Use **gsudo** for administrative commands when available
- Include **self-elevation function** for admin-required scripts

**PowerShell 5.1 Compatibility Requirements:**
- Avoid PowerShell 7+ specific features (null-conditional operators, ternary operators)
- Use compatible parameter syntax and validation attributes
- Test `Get-Help` functionality locally (avoid internet lookups)
- Use `Where-Object` instead of `?` shorthand for clarity
- Use `ForEach-Object` instead of `%` shorthand for readability
- Ensure all cmdlets and modules work in both versions
- Use explicit pipeline variable references `$_` for clarity
- **VS Code CLI**: Always use `powershell.exe -NoProfile -Command` to avoid profile interference

### Python Scripts (.py)

```python
#!/usr/bin/env python3
"""
Module docstring with description.

Author: Your Name
Date: YYYY-MM-DD
Version: 1.0
"""
import logging
import sys
from pathlib import Path

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)
```

- Use type hints for all function parameters and returns
- Include comprehensive docstrings
- Handle exceptions gracefully
- Use pathlib for file operations
- Include logging for debugging
- Validate input parameters
- Follow PEP 8 style guidelines

### Shell Scripts (.sh)

```bash
#!/bin/bash
set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Script description
# Author: Your Name
# Date: YYYY-MM-DD
# Version: 1.0

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "$0")"
```

- Always include shebang and set options
- Use readonly for constants
- Quote variables to prevent word splitting
- Include error handling
- Use functions for reusable code

## File Formatting and Validation

### Always Validate Syntax

- **PowerShell**: Use `Test-ScriptFileInfo` and PSScriptAnalyzer
- **Python**: Use `python -m py_compile` and linting tools
- **JSON**: Validate with `Test-Json` or `jq`
- **YAML**: Use `yamllint` or online validators
- **CSV**: Check for proper escaping and encoding

### Formatting Standards

- **Indentation**: 4 spaces (no tabs)
- **Line endings**: CRLF for Windows files, LF for Unix files
- **Encoding**: UTF-8 with BOM for PowerShell, UTF-8 without BOM for others
- **Max line length**: 120 characters (prefer 80 when possible)

## Configuration Files

### JSON Files

- Use 2-space indentation
- Include schema references when available
- Validate syntax before committing
- Use meaningful property names

### YAML Files

- Use 2-space indentation
- Quote strings with special characters
- Validate with yamllint
- Include version and metadata

### CSV Files

- Include headers
- Use proper escaping for commas and quotes
- Validate encoding (UTF-8)
- Test with Excel and other tools

## Development Workflow

### Before Creating/Editing Files

1. Determine file type and apply appropriate standards
2. Check for existing templates or examples
3. Plan error handling and validation
4. Consider cross-platform compatibility

### After Creating/Editing Files

1. Validate syntax using appropriate tools
2. Format according to style guidelines
3. Test functionality
4. Update documentation if needed
5. Check encoding and line endings

## Error Handling

### Self-Elevation Function for PowerShell

```powershell
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
```

### PowerShell

```powershell
try {
    # Main logic here
}
catch {
    Write-Error "Error occurred: $($_.Exception.Message)"
    throw
}
finally {
    # Cleanup code
}
```

### Python

```python
try:
    # Main logic here
    pass
except SpecificException as e:
    logger.error(f"Specific error: {e}")
    raise
except Exception as e:
    logger.error(f"Unexpected error: {e}")
    sys.exit(1)
finally:
    # Cleanup code
    pass
```

## Documentation Standards

### Code Comments

- Explain WHY, not WHAT
- Use clear, concise language
- Update comments when code changes
- Avoid obvious comments

### Function Documentation

- Include purpose, parameters, return values
- Provide usage examples
- Document exceptions that may be raised
- Specify required permissions or dependencies

## Testing and Quality

### Before Committing

- [ ] Syntax validation passed
- [ ] Code formatted according to standards
- [ ] Error handling implemented
- [ ] Documentation updated
- [ ] Cross-platform compatibility checked
- [ ] Security considerations reviewed

### Tools to Use

- **PowerShell**: PSScriptAnalyzer, Pester
- **Python**: pylint, black, mypy, pytest
- **General**: EditorConfig, Prettier (for JSON/YAML)

## Security Considerations

- Never hardcode secrets or credentials
- Use secure string handling for sensitive data
- Validate all user inputs
- Use least-privilege principles
- Consider injection attacks for dynamic code
- Use official packages and verify checksums

## Performance Guidelines

- Prefer built-in functions over custom implementations
- Use appropriate data structures
- Minimize file I/O operations
- Consider memory usage for large datasets
- Profile code when performance matters
- Use parallel processing when beneficial

## AI Assistant Specific Instructions

When generating code:

1. Always include proper error handling
2. Follow the encoding and formatting rules above
3. Include comprehensive documentation
4. Consider Windows/WSL compatibility
5. Validate syntax and provide testing suggestions
6. Suggest appropriate tools for validation
7. Include relevant security considerations
8. Provide examples of usage when helpful

Remember: The goal is maintainable, secure, and cross-platform compatible code that follows enterprise development standards.
