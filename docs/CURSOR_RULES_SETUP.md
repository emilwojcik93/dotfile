# Cursor Rules Setup Guide

This guide explains how to set up and maintain PowerShell coding standards across all projects using Cursor's Rules feature.

## Overview

The setup consists of two levels of rules enforcement:
1. **Global Rules** - Apply to ALL projects and workspaces
2. **Project-Specific Rules** - Apply to individual repositories via `.cursorrules` files

## Global Rules Configuration

### What Was Configured

Global rules have been added to your Cursor settings at:
`${env:APPDATA}\Cursor\User\settings.json`

The rules enforce:
- UTF-8/ASCII only characters (no emojis/Unicode)
- Proper PowerShell 5.x variable syntax with brackets: `${var}:` instead of `$var:`
- Prohibition of read-only/system variables as script variables
- Infrastructure as Code (IaC) principles
- Production-ready code standards

### How It Works

These global rules are automatically applied by Cursor AI across ALL your projects, ensuring consistent adherence to PowerShell coding standards regardless of which repository you're working in.

## Project-Specific Rules

### Dotfile Repository

A comprehensive `.cursorrules` file has been created in your dotfile repository:
`${env:USERPROFILE}\GitHub\dotfile\.cursorrules`

This file contains detailed PowerShell-specific standards including:
- Character encoding requirements
- Variable naming conventions
- PowerShell 5.x compatibility rules
- Error prevention guidelines
- Self-elevation patterns
- Security best practices

### Existing Repositories with Rules

The following repositories already have `.cursorrules` files that should be reviewed:

1. `GitHub\project-pipeline-library\.cursorrules`
2. `GitHub\project-articles\archive\development-docs\.cursorrules`
3. `OneDrive\Development\docs\.cursorrules`
4. `OneDrive\Development\Access_Requests\.cursorrules`
5. `OneDrive\Work\Projects\Videos\trainings\.cursorrules`
6. `GitHub\wiki-rag\docs\reference\.cursorrules`

## PowerShell Coding Standards Summary

### Character Encoding
```powershell
# ❌ BAD - Unicode characters
Write-Host "✅ Installation complete! 🎉"

# ✅ GOOD - ASCII only
Write-Host "[SUCCESS] Installation complete!"
```

### Variable Syntax
```powershell
# ❌ BAD - Using system variables as script variables
$Error = @()
$host = "myserver"
$user = "testuser"

# ❌ BAD - Incorrect special character syntax
$path:backup = "C:\Backup"
Write-Host "Path: $env:PATH\bin"

# ✅ GOOD - Custom variable names and proper syntax
${CustomErrors} = @()
${TargetHost} = "myserver"
${ScriptUser} = "testuser"
${path}:backup = "C:\Backup"
Write-Host "Path: ${env:PATH}\bin"
```

### Error Prevention
```powershell
# ❌ BAD - No error handling
Copy-Item $source $destination

# ✅ GOOD - Proper error handling
try {
    Copy-Item $source $destination -ErrorAction Stop
    Write-Host "[INFO] File copied successfully"
} catch {
    Write-Error "Failed to copy file: ${_}"
    throw
}
```

## Verification

### Testing Global Rules
1. Open any PowerShell file in Cursor
2. Try writing code that violates the rules (e.g., using emojis)
3. Cursor AI should automatically suggest corrections based on the rules

### Testing Project Rules
1. Navigate to `${env:USERPROFILE}\GitHub\dotfile\`
2. Open any PowerShell script
3. Cursor should apply both global AND project-specific rules

## Maintenance

### Updating Global Rules

To modify global rules:
1. Open Cursor Settings
2. Navigate to the settings.json file
3. Modify the `cursor.general.globalRules` section
4. Restart Cursor for changes to take effect

### Updating Project Rules

To modify project-specific rules:
1. Edit the `.cursorrules` file in the repository
2. Changes take effect immediately (no restart required)
3. Commit the updated rules file to version control

### Adding Rules to New Projects

For new repositories, copy the `.cursorrules` template:
```powershell
Copy-Item "${env:USERPROFILE}\GitHub\dotfile\.cursorrules" .\
```

Or create project-specific rules based on the template.

## Rule Priorities

Rules are applied in this order:
1. **Global Rules** (always applied)
2. **Project Rules** (can extend or override globals)
3. **File-specific patterns** (if defined in project rules)

## Troubleshooting

### Rules Not Being Applied

1. **Check Cursor Version**: Ensure you're using a recent version of Cursor
2. **Restart Cursor**: Global rules require a restart after changes
3. **Check Syntax**: Ensure the rules are properly formatted
4. **Verify File Paths**: Check that `.cursorrules` files are in the correct location

### Conflicting Rules

If you have conflicting rules between global and project levels:
- Project rules take precedence over global rules
- More specific rules override general ones
- Consider aligning project rules with global standards

### Performance Issues

If Cursor becomes slow with complex rules:
- Simplify rule descriptions
- Focus on the most critical standards
- Use bullet points instead of long paragraphs

## Best Practices

### Rule Writing
- Keep rules concise and actionable
- Include both positive and negative examples
- Focus on the most common issues
- Update rules based on code review feedback

### Team Adoption
- Share this documentation with team members
- Include rules setup in onboarding processes
- Regular review and updates of rules
- Consistent enforcement across all projects

### Version Control
- Always commit `.cursorrules` files to version control
- Document rule changes in commit messages
- Consider semantic versioning for major rule changes
- Backup your global settings periodically

## Advanced Configuration

### Conditional Rules

You can create rules that apply only to specific file types:
```markdown
# In .cursorrules file
This applies only to PowerShell files (*.ps1, *.psm1, *.psd1):
- Use proper error handling
- Implement parameter validation
```

### Team Rules

For team-wide consistency, ensure all team members:
1. Use the same global rules in their Cursor settings
2. Include standardized `.cursorrules` files in shared repositories
3. Follow the same rule update processes

## Support and Resources

- **Cursor Documentation**: https://cursor.com/docs/context/rules
- **PowerShell Best Practices**: Microsoft PowerShell documentation
- **IaC Principles**: Infrastructure as Code guidelines
- **Team Support**: Contact via established communication channels

---

**Last Updated**: $(Get-Date -Format "yyyy-MM-dd")
**Version**: 1.0
**Maintainer**: Development Team
