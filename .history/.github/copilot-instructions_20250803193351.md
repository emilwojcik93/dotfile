<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

# Coding Instructions for AI Assistants

## General Rules

### Character Encoding
- **Scripts**: Use only UTF-8/ASCII characters (no Unicode symbols)
- **Markdown**: Full Unicode support allowed
- **Comments**: Keep ASCII-only for scripts, Unicode OK for documentation

### Platform Environment
- **OS**: Windows 11 with WSL Ubuntu
- **Shells**: PowerShell 7+ and Bash (WSL)
- **Python**: Python 3.11+ (prefer latest stable)
- **Tools**: VS Code, Git, Windows Terminal

## Script Development

### PowerShell Scripts (.ps1)
```powershell
# Template header for PowerShell scripts
#Requires -Version 7.0
<#
.SYNOPSIS
    Brief description of what the script does
.DESCRIPTION
    Detailed description of the script's functionality, purpose, and behavior.
    Include any important prerequisites or dependencies.
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
    
    Prerequisites:
    - PowerShell 7.0 or later
    - Administrator rights (if applicable)
    - Required modules: ModuleName
    
    Change Log:
    1.0 - Initial version
    
    Links:
    - https://docs.microsoft.com/powershell/
.LINK
    https://github.com/your-repo/script-name
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
