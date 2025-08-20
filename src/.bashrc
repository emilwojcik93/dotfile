# ~/.bashrc for WSL Ubuntu development environment

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# History settings
HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s histappend
shopt -s checkwinsize

# Set UTF-8 locale
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export PYTHONIOENCODING=utf-8

# Color support
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Useful aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias ~='cd ~'
alias cls='clear'

# Development aliases
alias py='python3'
alias pip='pip3'
alias venv='python3 -m venv'
alias activate='source venv/bin/activate'
alias pwsh='powershell.exe'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'
alias gb='git branch'
alias gco='git checkout'

# Validation functions
validate_python() {
    echo "Validating Python files..."
    find . -name "*.py" -exec python3 -m py_compile {} \; 2>/dev/null && echo "✓ Python syntax valid" || echo "✗ Python syntax errors found"
}

validate_json() {
    echo "Validating JSON files..."
    for file in $(find . -name "*.json"); do
        if python3 -m json.tool "$file" > /dev/null 2>&1; then
            echo "✓ $file"
        else
            echo "✗ $file"
        fi
    done
}

validate_yaml() {
    echo "Validating YAML files..."
    if command -v yamllint >/dev/null 2>&1; then
        find . -name "*.yml" -o -name "*.yaml" | xargs yamllint
    else
        echo "yamllint not installed. Install with: pip install yamllint"
    fi
}

# Format functions
format_python() {
    echo "Formatting Python files..."
    if command -v black >/dev/null 2>&1; then
        black .
    else
        echo "black not installed. Install with: pip install black"
    fi
}

# Export validation functions
export -f validate_python validate_json validate_yaml format_python

# Custom prompt with Git branch
parse_git_branch() {
    git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1)/'
}

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[01;31m\]$(parse_git_branch)\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w$(parse_git_branch)\$ '
fi

# Enable programmable completion features
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# Python environment
if [ -d "$HOME/.pyenv" ]; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
fi

# Add local bin to PATH
if [ -d "$HOME/.local/bin" ]; then
    PATH="$HOME/.local/bin:$PATH"
fi

# Welcome message
echo "WSL Ubuntu Development Environment Loaded"
echo "Available functions: validate_python, validate_json, validate_yaml, format_python"
echo "UTF-8 encoding configured"
