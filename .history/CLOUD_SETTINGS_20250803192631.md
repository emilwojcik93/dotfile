# Cloud Settings Configuration

This document explains how to configure cloud settings for VS Code to load the coding instructions from this remote repository.

## GitHub Copilot Configuration

### Method 1: Workspace-specific Instructions (Recommended)

The `.github/copilot-instructions.md` file in this repository will be automatically loaded by GitHub Copilot when you open this workspace. This file contains comprehensive coding standards and instructions.

### Method 2: Global User Settings

To apply these instructions globally across all projects, you can reference this repository in your VS Code user settings:

1. Open VS Code Settings (Ctrl+,)
2. Search for "copilot instructions"
3. Add the following to your `settings.json`:

```json
{
    "github.copilot.chat.welcome.quickActions": [
        {
            "label": "Load Coding Standards",
            "command": "Follow the coding standards from: https://github.com/your-username/dotfiles/.github/copilot-instructions.md"
        }
    ]
}
```

## Settings Sync Configuration

### Enable Settings Sync

1. Open VS Code
2. Press `Ctrl+Shift+P` and type "Settings Sync: Turn On"
3. Choose what to sync:
   - ✅ Settings
   - ✅ Extensions
   - ✅ Keyboard Shortcuts
   - ✅ Snippets
   - ✅ Tasks

### Manual Sync Setup

If you prefer manual synchronization, you can:

1. Copy the contents of `.vscode/settings.json` to your user settings
2. Install the recommended extensions from `.vscode/extensions.json`
3. Import the tasks from `.vscode/tasks.json`

## Repository URL for Cloud Access

Use this repository URL for cloud access:
```
https://github.com/your-username/dotfiles
```

## Environment Variables for Cloud IDEs

For cloud-based development environments (GitHub Codespaces, GitPod, etc.), set these environment variables:

```bash
export PYTHONIOENCODING=utf-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
```

## Cline/Cursor Configuration

For Cline and Cursor AI assistants, you can reference the instructions file directly:

### Cline Configuration
Add to your Cline settings:
```json
{
    "cline.instructionsFile": ".github/copilot-instructions.md"
}
```

### Cursor Configuration
In Cursor, you can add a workspace rule:
```json
{
    "cursor.cpp.includePath": [".github/copilot-instructions.md"]
}
```

## Quick Setup Commands

### Clone and Setup (PowerShell)
```powershell
# Clone the repository
git clone https://github.com/your-username/dotfiles.git
cd dotfiles

# Run setup (as Administrator)
.\setup.ps1

# Validate installation
.\validate-all.ps1
```

### Clone and Setup (Bash/WSL)
```bash
# Clone the repository
git clone https://github.com/your-username/dotfiles.git
cd dotfiles

# Copy WSL configuration
cp wsl/.bashrc ~/.bashrc
source ~/.bashrc

# Install Python dependencies
pip3 install -r python/requirements.txt
```

## AI Assistant Instructions Summary

This repository provides:

- **UTF-8/ASCII enforcement** for scripts
- **Automatic syntax validation** for PowerShell, Python, JSON, YAML
- **Consistent formatting** rules across all file types
- **Cross-platform compatibility** (Windows/WSL)
- **Enterprise development standards**
- **Security best practices**
- **Performance guidelines**

## Integration with Cloud Services

### GitHub Codespaces
The repository includes a `.devcontainer` configuration (if needed) and will automatically:
- Install required extensions
- Apply coding standards
- Set up the development environment

### GitPod
For GitPod integration, the repository settings will:
- Configure the workspace
- Install dependencies
- Apply formatting rules

### VS Code Online
When using VS Code in the browser:
- Settings sync will apply configurations
- Extensions will be automatically suggested
- Coding instructions will be loaded

## Updating Instructions

To update the coding instructions:

1. Edit `.github/copilot-instructions.md`
2. Commit and push changes
3. AI assistants will automatically use the updated instructions

## Troubleshooting

### Instructions Not Loading
- Verify the file path: `.github/copilot-instructions.md`
- Check file encoding (must be UTF-8)
- Restart VS Code/AI assistant

### Settings Not Syncing
- Enable Settings Sync in VS Code
- Check internet connectivity
- Verify GitHub authentication

### Validation Errors
- Run the validation task: `Ctrl+Shift+P` → "Tasks: Run Task" → "Validate All Files"
- Check file encoding and syntax
- Review error messages for specific issues
