# Personal Dotfiles Repository

This repository contains my personal development environment configuration and instructions for AI assistants (GitHub Copilot, Cline, Cursor).

## Environment
- **OS**: Windows 11 with WSL Ubuntu
- **Shells**: PowerShell 7+, Bash (WSL)
- **Languages**: Python 3.12+, PowerShell
- **Editors**: VS Code with AI assistants

## Features

### Development Environment
- **Windows 11 Optimized**: Native Windows development with WSL integration
- **Font Configuration**: JetBrainsMono Nerd Font with ligatures and icon support
- **Cross-Platform**: Seamless Windows/WSL development workflow
- **Performance Tuned**: Optimized settings for large repositories and remote development

### Coding Standards
- **UTF-8/ASCII Enforcement**: Scripts use only UTF-8/ASCII characters (no Unicode symbols)
- **Automatic Validation**: Syntax checking for PowerShell, Python, JSON, YAML files
- **Consistent Formatting**: Standardized code formatting across all languages
- **Smart Suggestions**: Intelligent autocomplete and code suggestions

### AI Assistant Integration
- **GitHub Copilot**: Advanced code completion and chat features
- **Cline/Cursor**: Alternative AI assistants with custom instructions
- **Workspace Instructions**: Automatic instruction loading from `.github/copilot-instructions.md`
- **Context Awareness**: AI assistants understand project structure and coding standards

### Extension Ecosystem
- **PowerShell**: Advanced PowerShell development with PSScriptAnalyzer
- **Python**: Complete Python development stack with linting and formatting
- **Remote Development**: WSL, SSH, and container development support
- **Security**: Vulnerability scanning with Snyk integration
- **Git Integration**: Enhanced Git workflow with GitLens and Pull Request management

### Development Tools
- **PowerShell Profile**: Custom functions for validation and formatting (`validate`, `format`, `utf8`)
- **Python Environment**: Pre-configured with Black, Pylint, MyPy, Flake8
- **WSL Integration**: Ubuntu development environment with development tools
- **VS Code Tasks**: Automated validation and formatting workflows
- **Hex Editor**: Binary file viewing and editing capabilities

## Repository Structure

```
dotfiles/
├── .github/
│   └── copilot-instructions.md     # AI assistant coding instructions
├── .vscode/
│   ├── settings.json               # VS Code settings
│   ├── extensions.json             # Recommended extensions
│   └── tasks.json                  # Build and validation tasks
├── powershell/
│   ├── profile.ps1                 # PowerShell profile
│   └── scripts/
│       └── script-template.ps1     # PowerShell script template
├── python/
│   ├── .python-version             # Python version
│   ├── requirements.txt            # Python dependencies
│   └── script-template.py          # Python script template
├── wsl/
│   └── .bashrc                     # WSL Bash configuration
├── setup.ps1                      # Initial environment setup
├── CLOUD_SETTINGS.md               # Cloud configuration guide
└── README.md                       # This file
```

## Quick Setup

### Prerequisites
- Windows 11 with PowerShell 7+
- Windows Package Manager (winget)
- Administrator privileges for setup

### Installation

#### 1. Install Dependencies with Winget
```powershell
# Core development tools
winget install Microsoft.Git
winget install Microsoft.VisualStudioCode
winget install Microsoft.PowerShell
winget install Python.Python.3.12

# Essential fonts
winget install JetBrains.JetBrainsMono
# Alternative: Cascadia Code PL (included with Windows Terminal)
winget install Microsoft.WindowsTerminal

# Optional but recommended
winget install Microsoft.WindowsSubsystemForLinux
winget install Canonical.Ubuntu.2404

# Development utilities
winget install gsudo.gsudo  # For administrative operations
winget install chocolatey.chocolatey  # Alternative package manager
```

#### 2. Clone and Setup Repository
```powershell
# Clone repository
git clone https://github.com/your-username/dotfiles.git $env:USERPROFILE\GitHub\dotfile
cd $env:USERPROFILE\GitHub\dotfile

# Run setup as Administrator
gsudo .\setup.ps1
# OR without gsudo:
# Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File .\setup.ps1" -Verb RunAs
```

#### 3. Post-Installation
```powershell
# Restart PowerShell to load new profile
# Restart VS Code to apply settings

# Validate installation
.\validate-all.ps1

# Configure Git (replace with your details)
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### WSL Setup (Optional)
```powershell
# Install Ubuntu in WSL
wsl --install -d Ubuntu

# After Ubuntu installation, run:
wsl cp $env:USERPROFILE/GitHub/dotfile/wsl/.bashrc ~/.bashrc
wsl sudo apt update
wsl sudo apt install -y python3-pip yamllint git curl
wsl pip3 install black pylint mypy
```

## Features

### Coding Standards
- **UTF-8/ASCII enforcement** for scripts (no Unicode symbols)
- **Automatic syntax validation** for PowerShell, Python, JSON, YAML
- **Consistent formatting** rules across all file types
- **Cross-platform compatibility** (Windows/WSL)

### AI Assistant Integration
- **GitHub Copilot**: Automatic instruction loading from `.github/copilot-instructions.md`
- **Cline/Cursor**: Workspace-specific coding standards
- **Enterprise-grade** development practices
- **Security** and performance guidelines

### Development Tools
- **PowerShell Profile**: Custom functions for validation and formatting
- **Python Environment**: Pre-configured with linting and formatting tools
- **WSL Integration**: Ubuntu development environment
- **VS Code Tasks**: Automated validation and formatting

## Usage

### Available VS Code Tasks
- **Validate All Files**: Check syntax of all scripts
- **Setup Environment**: Run initial configuration
- Press `Ctrl+Shift+P` → "Tasks: Run Task" to access

### PowerShell Commands
- `validate`: Validate all script files
- `format`: Format PowerShell scripts
- `utf8`: Convert files to UTF-8 encoding

### WSL Commands
- `validate_python`: Check Python syntax
- `validate_json`: Validate JSON files
- `validate_yaml`: Check YAML syntax
- `format_python`: Format Python code with Black

## Cloud Settings

For cloud-based development (GitHub Codespaces, GitPod, VS Code Online):
- See `CLOUD_SETTINGS.md` for detailed configuration
- AI instructions are automatically loaded
- Settings sync enabled by default

## File Templates

### PowerShell Script Template
Use `powershell/scripts/script-template.ps1` as a starting point for new PowerShell scripts.

### Python Script Template
Use `python/script-template.py` as a starting point for new Python scripts.

## Validation and Formatting

All scripts are automatically validated for:
- **Syntax correctness**
- **UTF-8 encoding**
- **Consistent formatting**
- **Best practices compliance**

## Contributing

1. Follow the coding standards in `.github/copilot-instructions.md`
2. Validate changes with `.\validate-all.ps1`
3. Test on both Windows and WSL
4. Update documentation as needed

## Troubleshooting

### Common Issues
- **Scripts not running**: Check execution policy with `Get-ExecutionPolicy`
- **Encoding problems**: Use `utf8` command to fix file encoding
- **VS Code not loading settings**: Restart VS Code and check Settings Sync
- **Get-Help searching online**: PowerShell 5.1 may search online for help even with comment-based help present. This is a known limitation. Use `.\setup.ps1 -?` or view script comments directly.

### PowerShell Help System
The scripts include comprehensive comment-based help, but PowerShell 5.1 may still search online due to:
- Large script size interfering with help parser
- Windows 11 default configuration preferring online help
- Complex script structure with multiple functions

**Workarounds**:
- Use `Get-Content .\setup.ps1 | Select-Object -First 40` to view help comments
- Run `.\setup.ps1 -?` for parameter help
- Use PowerShell 7+ where available for better help support
- View script comments directly in VS Code or text editor

### Getting Help
- Run validation tasks to identify issues
- Check log files in `$env:TEMP`
- Review AI assistant instructions for guidance

---

**Note**: This repository is designed for enterprise development environments with focus on code quality, security, and cross-platform compatibility.
