#!/bin/bash
# Script Validation Template for Bash Scripts
# Based on Infrastructure as Code principles and best practices

# =============================================================================
# BASH SCRIPT VALIDATION FUNCTIONS
# =============================================================================

# Exit on error, undefined variables, and pipe failures
set -euo pipefail

# Script metadata
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "$0")"
readonly SCRIPT_VERSION="1.0.0"

# Logging functions with timestamps
log() {
    local level="${1:-INFO}"
    local message="${2:-}"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

    case "$level" in
        ERROR)   echo -e "\033[31m[$timestamp] [ERROR] $message\033[0m" >&2 ;;
        WARN)    echo -e "\033[33m[$timestamp] [WARN]  $message\033[0m" >&2 ;;
        SUCCESS) echo -e "\033[32m[$timestamp] [SUCCESS] $message\033[0m" ;;
        *)       echo "[$timestamp] [INFO]  $message" ;;
    esac
}

# Validation functions following Test-Path equivalent patterns
validate_command() {
    local cmd="$1"
    if command -v "$cmd" >/dev/null 2>&1; then
        log "INFO" "Command validation passed: $cmd"
        return 0
    else
        log "ERROR" "Required command not found: $cmd"
        return 1
    fi
}

validate_path() {
    local path="$1"
    local path_type="${2:-any}"  # any, file, directory

    if [[ ! -e "$path" ]]; then
        log "ERROR" "Path does not exist: $path"
        return 1
    fi

    case "$path_type" in
        file)
            if [[ ! -f "$path" ]]; then
                log "ERROR" "Path is not a file: $path"
                return 1
            fi
            ;;
        directory)
            if [[ ! -d "$path" ]]; then
                log "ERROR" "Path is not a directory: $path"
                return 1
            fi
            ;;
    esac

    log "INFO" "Path validation passed: $path"
    return 0
}

validate_writable() {
    local path="$1"

    if [[ -w "$path" ]]; then
        log "INFO" "Write access validated: $path"
        return 0
    else
        log "ERROR" "Path is not writable: $path"
        return 1
    fi
}

validate_network() {
    local host="${1:-github.com}"

    if ping -c 1 -W 5 "$host" >/dev/null 2>&1; then
        log "SUCCESS" "Network connectivity validated: $host"
        return 0
    else
        log "WARN" "Network connectivity test failed: $host"
        return 1
    fi
}

validate_os() {
    local required_os="$1"  # linux, darwin, etc.
    local current_os
    current_os="$(uname -s | tr '[:upper:]' '[:lower:]')"

    if [[ "$current_os" == *"$required_os"* ]]; then
        log "SUCCESS" "Operating system validation passed: $current_os"
        return 0
    else
        log "ERROR" "Unsupported operating system. Required: $required_os, Found: $current_os"
        return 1
    fi
}

validate_user_permission() {
    if [[ $EUID -eq 0 ]]; then
        log "INFO" "Running as root"
        return 0
    else
        log "INFO" "Running as regular user: $(whoami)"
        return 0
    fi
}

# Comprehensive system validation
validate_system() {
    log "INFO" "Starting system validation..."

    local validation_errors=0

    # Basic system information
    log "INFO" "System: $(uname -a)"
    log "INFO" "User: $(whoami)"
    log "INFO" "Shell: $SHELL"
    log "INFO" "Script: $SCRIPT_NAME v$SCRIPT_VERSION"

    # Validate required commands
    local required_commands=("bash" "date" "whoami")
    for cmd in "${required_commands[@]}"; do
        if ! validate_command "$cmd"; then
            ((validation_errors++))
        fi
    done

    # Validate paths
    if ! validate_path "$SCRIPT_DIR" "directory"; then
        ((validation_errors++))
    fi

    if ! validate_path "/tmp" "directory"; then
        ((validation_errors++))
    fi

    if ! validate_writable "/tmp"; then
        ((validation_errors++))
    fi

    # Network validation (optional)
    validate_network "github.com" || log "WARN" "Network validation failed, continuing anyway"

    if [[ $validation_errors -gt 0 ]]; then
        log "ERROR" "System validation failed with $validation_errors errors"
        return 1
    else
        log "SUCCESS" "System validation completed successfully"
        return 0
    fi
}

# Error handling with cleanup
cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log "ERROR" "Script exited with error code: $exit_code"
    fi
    # Add any cleanup operations here
}

# Set trap for cleanup
trap cleanup EXIT

# Auto-timeout function for user prompts
prompt_with_timeout() {
    local prompt="$1"
    local timeout="${2:-10}"
    local default="${3:-}"

    echo -n "$prompt (auto-continues in ${timeout}s): "

    if read -t "$timeout" -r response; then
        echo "$response"
    else
        echo
        log "WARN" "No input detected, using default: $default"
        echo "$default"
    fi
}

# Usage example:
# validate_system || exit 1
# response=$(prompt_with_timeout "Continue? (y/N)" 10 "n")

log "INFO" "Bash validation functions loaded successfully"
