# Beast Mode 3.1 Enhanced - Troubleshooting Guide

## 🚨 Common Issues and Solutions

### Beast Mode Not Showing in Agent Dropdown

**Symptoms:**
- Custom chat mode file created but not visible in VS Code
- Agent dropdown only shows default options

**Solutions:**
1. **Verify File Location**:
   ```
   %APPDATA%\Code\User\prompts\Beast Mode.chatmode.md
   ```
   On Windows: `C:\Users\{username}\AppData\Roaming\Code\User\prompts\`

2. **Check File Extension**:
   - Must be exactly `.chatmode.md`
   - Ensure Windows is not hiding file extensions

3. **Restart VS Code**:
   - Close VS Code completely
   - Reopen and check Chat sidebar

4. **Verify VS Code Version**:
   - Update to latest VS Code version
   - Custom chat modes require recent versions

### Beast Mode Stops Working Mid-Task

**Symptoms:**
- Agent stops responding before completing tasks
- "Request limit reached" errors
- Incomplete todo list execution

**Solutions:**
1. **Update VS Code Settings**:
   ```json
   {
       "chat.tools.autoApprove": true,
       "chat.agent.maxRequests": 100
   }
   ```

2. **Check Request Limits**:
   - Increase `maxRequests` if needed (default is often 20)
   - Monitor request usage in Chat sidebar

3. **Break Large Tasks**:
   - Split complex requests into smaller parts
   - Use explicit todo list formatting

### Tools Not Working (autoApprove Issues)

**Symptoms:**
- Constant permission prompts for tool usage
- "Permission required" dialogs blocking workflow
- Beast Mode can't execute file operations

**Solutions:**
1. **Enable Auto-Approval**:
   ```json
   {
       "chat.tools.autoApprove": true
   }
   ```

2. **Verify Setting Location**:
   - User Settings (not Workspace)
   - Settings UI: Search "chat tools auto"
   - Settings JSON: Add to user configuration

3. **Restart After Changes**:
   - Reload window: Ctrl+Shift+P → "Developer: Reload Window"
   - Full restart recommended

### Internet Research Failing

**Symptoms:**
- "Cannot fetch webpage" errors
- Search results not returning
- Beast Mode claiming no internet access

**Solutions:**
1. **Check Network Connectivity**:
   - Verify internet connection
   - Test with browser first

2. **Corporate Firewall Issues**:
   - May block search engine requests
   - Contact IT for allowlisting if needed
   - Beast Mode will fallback to cached knowledge

3. **Search Engine Rotation**:
   - Beast Mode tries Google → Bing → DuckDuckGo
   - Some engines may be blocked in certain regions

### GitHub Copilot Subscription Issues

**Symptoms:**
- "Copilot not available" errors
- Chat sidebar showing subscription prompts
- Beast Mode not responding at all

**Solutions:**
1. **Verify Subscription**:
   - Check GitHub Copilot subscription status
   - Ensure subscription is active and paid

2. **Re-authenticate**:
   - VS Code → Command Palette
   - "GitHub Copilot: Sign Out"
   - "GitHub Copilot: Sign In"

3. **Extension Updates**:
   - Update GitHub Copilot extension
   - Update GitHub Copilot Chat extension

### Memory System Not Working

**Symptoms:**
- Beast Mode not remembering previous conversations
- User preferences not persisting
- Repeated questions about project setup

**Solutions:**
1. **Check Memory File**:
   ```
   .github/instructions/memory.instruction.md
   ```
   Should exist in your workspace root

2. **Enable Git Integration**:
   - Ensure workspace is a Git repository
   - Beast Mode uses Git for memory persistence

3. **Workspace Context**:
   - Open correct workspace folder
   - Memory is workspace-specific

### PowerShell Compatibility Issues

**Symptoms:**
- Scripts failing with syntax errors
- "Command not found" errors
- PowerShell version conflicts

**Solutions:**
1. **Verify PowerShell Version**:
   ```powershell
   $PSVersionTable.PSVersion
   ```
   Should be 5.1+ for Windows compatibility

2. **Execution Policy**:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

3. **Profile Conflicts**:
   - Beast Mode uses `-NoProfile` for VS Code CLI operations
   - Custom profiles may interfere

### Performance Issues

**Symptoms:**
- Slow response times
- VS Code becoming unresponsive
- High memory usage

**Solutions:**
1. **Reduce Context Size**:
   - Limit file reading operations
   - Close unnecessary files in VS Code

2. **Memory Management**:
   - Restart VS Code periodically
   - Monitor system memory usage

3. **Request Throttling**:
   - Lower `maxRequests` if experiencing rate limits
   - Space out large requests

## 🔧 Diagnostic Commands

### VS Code Diagnostics
```
# Check VS Code version
code --version

# List installed extensions
code --list-extensions | findstr -i copilot

# Check settings
code --list-extensions --show-versions
```

### PowerShell Diagnostics
```powershell
# Check PowerShell version
$PSVersionTable

# Check execution policy
Get-ExecutionPolicy -List

# Test script execution
Test-Path $PROFILE
```

### File System Checks
```powershell
# Check chat mode file
Test-Path "$env:APPDATA\Code\User\prompts\Beast Mode.chatmode.md"

# List all chat modes
Get-ChildItem "$env:APPDATA\Code\User\prompts\" -Filter "*.chatmode.md"
```

## 📋 Environment Validation Checklist

Before reporting issues, verify:

- [ ] VS Code updated to latest version
- [ ] GitHub Copilot subscription active
- [ ] GitHub Copilot extensions installed and updated
- [ ] `chat.tools.autoApprove` set to `true`
- [ ] `chat.agent.maxRequests` set to `100` or higher
- [ ] Beast Mode chat mode file in correct location
- [ ] PowerShell 5.1+ available
- [ ] Internet connectivity working
- [ ] Workspace is a Git repository (for memory features)

## 🆘 Getting Help

If issues persist after trying these solutions:

1. **Repository Issues**: Create an issue in this repository with:
   - VS Code version
   - OS version (Windows build number)
   - PowerShell version
   - Error messages or screenshots
   - Steps to reproduce

2. **VS Code Community**: 
   - [GitHub Discussions](https://github.com/microsoft/vscode/discussions)
   - [VS Code Discord](https://discord.gg/vscode)

3. **GitHub Copilot Support**:
   - [GitHub Copilot Discussions](https://github.com/orgs/community/discussions/categories/copilot)
   - [GitHub Support](https://support.github.com/)

## 📝 Debug Log Collection

When reporting issues, include these diagnostic outputs:

### VS Code Information
```bash
code --version
code --list-extensions | findstr -i copilot
```

### Beast Mode Configuration
```powershell
# Check chat mode file exists and has content
Get-Content "$env:APPDATA\Code\User\prompts\Beast Mode.chatmode.md" | Select-Object -First 10

# VS Code settings related to chat
code --list-extensions | findstr chat
```

### System Environment
```powershell
# System information
Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, WindowsBuildLabEx

# PowerShell version
$PSVersionTable | Format-Table
```

---

*For additional support, see the [Complete Beast Mode Guide](beast-mode-guide.md) or open an issue in this repository.*
