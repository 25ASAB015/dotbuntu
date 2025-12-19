#!/usr/bin/env bash
# shellcheck shell=bash
#
# utils.sh - General utility functions for dotmarchy
#
# This helper provides utility functions for command execution, repository URL
# handling, system checks, and Node.js/npm management. It depends on colors.sh
# and logger.sh for output formatting.
#
# @params
# Globals:
#   ${DRY_RUN}: Flag for dry-run mode (from set_variable.sh)
#   ${SKIP_SYSTEM}: Flag for skipping system checks (from set_variable.sh)
#
# Functions:
#   run(): Execute command with description and timing
#   require_cmd(): Verify command exists or exit
#   normalize_repo_url(): Normalize git URL for comparison
#   ssh_to_https(): Convert SSH URL to HTTPS
#   check_ssh_auth(): Check if SSH authentication is available
#   get_nvm_dir(): Get NVM directory (XDG first, then ~/.nvm)
#   preflight_utils(): Check required utilities for GitHub downloads
#   ensure_node_available(): Ensure Node.js >= 18 is available
#   dotmarchy_usage(): Show primary CLI usage/help
#   parse_arguments(): Parse CLI arguments and set flags
#   initialize_error_log(): Reset error log file
#   execute_core_script(): Run core script with error handling
#   execute_extras_script(): Run extras script with error handling
#   execute_setup_script(): Run setup script with error handling
#   configure_dotbare(): Configure dotbare (critical)
#   execute_core_operations(): Run core installation flow
#   execute_extras_operations(): Run extras installation flow
#   execute_setup_operations(): Run setup flow
#   run_verification_mode(): Execute verification mode and exit

set -Eeuo pipefail

# Source dependencies if not already loaded
if [ -z "${CGR:-}" ]; then
    HELPER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${HELPER_DIR}/colors.sh"
    source "${HELPER_DIR}/logger.sh"
fi

#######################################
# Execute command with description and timing
# Respects DRY_RUN flag
# Arguments:
#   $1: Description of the command
#   $@: Command to execute
# Outputs:
#   Step description, command (if DRY_RUN), timing
#######################################
run() {
    local desc="$1"
    shift
    step "$desc"
    debug "Comando: $*"
    
    if [ "${DRY_RUN:-0}" -eq 1 ]; then
        log "   ↳ (dry-run) $*"
        return 0
    fi
    
    local start end dur
    start=$(now_ms)
    "$@"
    end=$(now_ms)
    dur=$((end - start))
    log "   ↳ ✔ Hecho en $(fmt_ms "$dur")"
}

#######################################
# Verify that a command exists
# Exits with code 127 if command not found
# Arguments:
#   $1: Command name to check
# Returns:
#   0 if command exists
#   127 if command not found (exits)
#######################################
require_cmd() {
    local name="$1"
    command -v "$name" >/dev/null 2>&1 || {
        log_error "No se encontró el comando requerido: $name"
        exit 127
    }
}

#######################################
# Normalize repository URL for comparison
# Converts URLs to host/owner/repo format in lowercase
# Arguments:
#   $1: Git repository URL (SSH or HTTPS)
# Outputs:
#   Normalized URL (e.g., github.com/owner/repo)
#######################################
normalize_repo_url() {
    local url="$1"
    url=${url%%.git}
    
    # SSH format: git@github.com:owner/repo
    if [[ $url =~ ^git@([^:]+):(.+)$ ]]; then
        echo "${BASH_REMATCH[1]}/${BASH_REMATCH[2]}" | tr '[:upper:]' '[:lower:]'
        return 0
    fi
    
    # HTTPS format: https://github.com/owner/repo
    if [[ $url =~ ^https?://([^/]+)/(.+)$ ]]; then
        echo "${BASH_REMATCH[1]}/${BASH_REMATCH[2]}" | tr '[:upper:]' '[:lower:]'
        return 0
    fi
    
    # Already normalized: host/owner/repo
    echo "$url" | tr '[:upper:]' '[:lower:]'
}

#######################################
# Convert SSH URL to HTTPS format
# Arguments:
#   $1: Git repository URL
# Outputs:
#   HTTPS URL
#######################################
ssh_to_https() {
    local url="$1"
    
    # SSH format: git@github.com:owner/repo -> https://github.com/owner/repo
    if [[ $url =~ ^git@([^:]+):(.+)$ ]]; then
        local host="${BASH_REMATCH[1]}"
        local path="${BASH_REMATCH[2]}"
        # Add .git if not present
        [[ $path =~ \.git$ ]] || path="${path}.git"
        echo "https://${host}/${path}"
        return 0
    fi
    
    # Already HTTPS, return as-is
    echo "$url"
}

#######################################
# Check if SSH authentication is available for GitHub
# Tests SSH connection to git@github.com
# Returns:
#   0 if SSH is configured and working
#   1 if SSH is not configured or fails
#######################################
check_ssh_auth() {
    # Attempt SSH connection to GitHub (short timeout)
    local ssh_output ssh_exit
    ssh_output=$(ssh -T -o ConnectTimeout=5 -o StrictHostKeyChecking=no git@github.com 2>&1)
    ssh_exit=$?
    
    # Check for successful authentication message
    if echo "$ssh_output" | grep -qi "successfully authenticated"; then
        return 0
    fi
    
    # Check for permission denied
    if [ "$ssh_exit" -eq 1 ] && echo "$ssh_output" | grep -qi "permission denied\|publickey"; then
        return 1
    fi
    
    # Other errors (timeout, network, etc.)
    return 1
}

#######################################
# Get NVM directory
# Prefers XDG config location, falls back to ~/.nvm
# Outputs:
#   Path to NVM directory
#######################################
get_nvm_dir() {
    local xdg="${XDG_CONFIG_HOME:-$HOME/.config}/nvm"
    
    if [ -d "$xdg" ]; then
        echo "$xdg"
        return
    fi
    
    if [ -d "$HOME/.nvm" ]; then
        echo "$HOME/.nvm"
        return
    fi
    
    # Prefer XDG if neither exists
    echo "$xdg"
}

#######################################
# Check for required utilities for GitHub downloads
# Verifies: curl, wget, jq, tar, unzip
# Globals:
#   ${SKIP_SYSTEM}: If set and utilities missing, exits with error
# Returns:
#   0 if all utilities present
#   1 if utilities missing and SKIP_SYSTEM=1
#######################################
preflight_utils() {
    local req=(curl wget jq tar unzip)
    local missing=()
    
    for c in "${req[@]}"; do
        command -v "$c" >/dev/null 2>&1 || missing+=("$c")
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        if [ "${SKIP_SYSTEM:-0}" -eq 1 ]; then
            log_error "Faltan utilidades requeridas: ${missing[*]}"
            log_error "Ejecuta el instalador completo sin -s para instalarlas automáticamente."
            exit 1
        fi
    fi
}

#######################################
# Ensure Node.js >= 18 is available
# If not available or version < 18, attempts to install via NVM
# Globals:
#   ${NVM_DIR}: NVM directory path (exported)
#   ${PATH}: Updated with npm prefix if needed
# Returns:
#   0 if npm is available
#   1 if npm cannot be made available
#######################################
ensure_node_available() {
    local need_install=
    
    # Check if Node.js is installed and version is sufficient
    if command -v node >/dev/null 2>&1; then
        local ver
        ver=$(node -v 2>/dev/null | sed -E 's/^v([0-9]+).*/\1/')
        if [ -z "${ver:-}" ] || [ "$ver" -lt 18 ]; then
            print_info "Node.js < 18 detectado. Intentando usar NVM para instalar LTS ..."
            need_install=1
        fi
    else
        print_info "Node.js no detectado. Intentando instalar con NVM (LTS) ..."
        need_install=1
    fi
    
    # Install or load NVM if needed
    if [ "${need_install:-}" ]; then
        local NVM_DIR
        NVM_DIR="$(get_nvm_dir)"
        export NVM_DIR
        
        if [ -s "$NVM_DIR/nvm.sh" ]; then
            # shellcheck disable=SC1090,SC1091
            . "$NVM_DIR/nvm.sh"
        else
            # Install NVM
            mkdir -p "$(dirname "$NVM_DIR")"
            export NVM_DIR
            curl -sS --connect-timeout 5 --max-time 30 --retry 3 --retry-delay 2 \
                https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
            # shellcheck disable=SC1090,SC1091
            [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
        fi
        
        # Install and use LTS version
        if command -v nvm >/dev/null 2>&1; then
            nvm install --lts >/dev/null 2>&1 || nvm install --lts
            nvm use --lts >/dev/null 2>&1 || nvm use --lts
        else
            warn "No se pudo instalar/cargar NVM. Continuando con Node.js existente si lo hay."
        fi
    fi
    
    # Configure npm prefix if not using NVM
    if ! command -v nvm >/dev/null 2>&1; then
        export PATH="$HOME/.local/bin:$PATH"
        
        if command -v npm >/dev/null 2>&1; then
            local prefix
            prefix=$(npm config get prefix 2>/dev/null || echo "")
            if [ -z "$prefix" ] || [ "$prefix" = "/usr" ] || [ "$prefix" = "/usr/local" ]; then
                npm config set prefix "$HOME/.local" >/dev/null 2>&1 || true
            fi
        fi
    fi
    
    # Final verification
    if ! command -v npm >/dev/null 2>&1; then
        log_error "npm no está disponible tras intentar instalar Node.js."
        return 1
    fi
    
    return 0
}

#######################################
# Primary CLI helpers used by dotmarchy
# These functions rely on globals defined in dotmarchy/set_variable.sh:
#   SCRIPT_DIR, SCRIPT_NAME, DOTMARCHY_VERSION
#   EXIT_SUCCESS, EXIT_FAILURE, EXIT_INVALID_INPUT
#   REPO_URL, INSTALL_EXTRAS, SETUP_ENVIRONMENT, VERIFY_MODE,
#   ERROR_LOG, INSTALL_START_TIME
#######################################

dotmarchy_usage() {
    cat << EOF
${BLD}${CBL}dotmarchy${CNC} ${DOTMARCHY_VERSION}
Modular dotfiles installation and system setup tool for Arch Linux

${BLD}Usage:${CNC}
  ${SCRIPT_NAME} [OPTIONS] [REPO_URL]

${BLD}Options:${CNC}
  -h, --help          Show this help message and exit
  --extras            Install extra packages (npm, cargo, pip, etc.)
  --setup-env         Setup environment (directories, repos, shell config)
  --verify            Run verification checks and exit
  --repo URL          Override default dotfiles repository URL
  -v, --verbose       Enable verbose output
  -f, --force         Force operations without prompts

${BLD}Examples:${CNC}
  ${SCRIPT_NAME}
  ${SCRIPT_NAME} --extras --setup-env
  ${SCRIPT_NAME} --repo git@github.com:user/dotfiles.git
  ${SCRIPT_NAME} --verify

${BLD}Environment Variables:${CNC}
  REPO_URL            Override default repository URL
  INSTALL_EXTRAS      Set to 1 to install extras (same as --extras)
  SETUP_ENVIRONMENT   Set to 1 to setup environment (same as --setup-env)
  FORCE               Set to 1 to force operations
  VERBOSE             Set to 1 for verbose output

${BLD}Exit Codes:${CNC}
  0  Success
  1  General failure
  2  Invalid input
  3  Missing dependencies

For more information, visit: https://github.com/25asab015/dotfiles
EOF
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                dotmarchy_usage
                exit "${EXIT_SUCCESS:-0}"
                ;;
            --extras)
                export INSTALL_EXTRAS=1
                debug "Extras installation enabled"
                shift
                ;;
            --setup-env)
                export SETUP_ENVIRONMENT=1
                debug "Environment setup enabled"
                shift
                ;;
            --verify)
                export VERIFY_MODE=1
                debug "Verification mode enabled"
                shift
                ;;
            --repo)
                [ -z "${2:-}" ] && {
                    log_error "Option --repo requires an argument"
                    dotmarchy_usage
                    exit "${EXIT_INVALID_INPUT:-2}"
                }
                export REPO_URL="$2"
                debug "Repository URL overridden: $REPO_URL"
                shift 2
                ;;
            -v|--verbose)
                export VERBOSE=1
                debug "Verbose mode enabled"
                shift
                ;;
            -f|--force)
                export FORCE=1
                debug "Force mode enabled"
                shift
                ;;
            -*)
                log_error "Unknown option: $1"
                dotmarchy_usage
                exit "${EXIT_INVALID_INPUT:-2}"
                ;;
            *)
                export REPO_URL="$1"
                debug "Repository URL from argument: $REPO_URL"
                shift
                ;;
        esac
    done
}

initialize_error_log() {
    : > "${ERROR_LOG}" || {
        warn "No se pudo limpiar el log de errores: ${ERROR_LOG}"
    }
}

execute_core_script() {
    local script_name="$1"
    local is_critical="${2:-non-critical}"
    local script_path="${SCRIPT_DIR}/scripts/core/${script_name}"
    
    [ ! -f "$script_path" ] && {
        log_error "Script not found: $script_path"
        [ "$is_critical" = "critical" ] && exit "${EXIT_FAILURE:-1}"
        return "${EXIT_FAILURE:-1}"
    }
    
    [ ! -x "$script_path" ] && {
        log_error "Script not executable: $script_path"
        [ "$is_critical" = "critical" ] && exit "${EXIT_FAILURE:-1}"
        return "${EXIT_FAILURE:-1}"
    }
    
    debug "Executing: $script_name"
    
    if "$script_path"; then
        debug "Completed: $script_name"
        return "${EXIT_SUCCESS:-0}"
    fi
    
    log_error "Failed: $script_name"
    
    if [ "$is_critical" = "critical" ]; then
        log_error "Critical script failed, aborting installation"
        exit "${EXIT_FAILURE:-1}"
    fi
    
    warn "Script falló pero continuando instalación..."
    return "${EXIT_FAILURE:-1}"
}

execute_extras_script() {
    local script_name="$1"
    local script_path="${SCRIPT_DIR}/scripts/extras/${script_name}"
    
    [ ! -f "$script_path" ] && {
        warn "Script extra no encontrado: $script_name"
        return "${EXIT_FAILURE:-1}"
    }
    
    debug "Executing extras: $script_name"
    
    if "$script_path"; then
        debug "Completed extras: $script_name"
        return "${EXIT_SUCCESS:-0}"
    fi
    
    warn "Script extra falló: $script_name (continuando)"
    return "${EXIT_FAILURE:-1}"
}

execute_setup_script() {
    local script_name="$1"
    local script_path="${SCRIPT_DIR}/scripts/setup/${script_name}"
    
    [ ! -f "$script_path" ] && {
        warn "Script de setup no encontrado: $script_name"
        return "${EXIT_FAILURE:-1}"
    }
    
    debug "Executing setup: $script_name"
    
    if "$script_path"; then
        debug "Completed setup: $script_name"
        return "${EXIT_SUCCESS:-0}"
    fi
    
    warn "Script de setup falló: $script_name"
    return "${EXIT_FAILURE:-1}"
}

configure_dotbare() {
    info "Configurando dotbare (clonando dotfiles)..."
    execute_core_script "fdotbare" "critical"
}

execute_core_operations() {
    info "Iniciando operaciones core..."
    
    execute_core_script "fupdate" "critical"
    execute_core_script "fchaotic" "critical"
    
    execute_core_script "fdeps" || {
        warn "Algunos paquetes oficiales fallaron, pero continuando..."
    }
    
    execute_core_script "fchaotic-deps"
    execute_core_script "faur"
    
    info "Configurando Zsh como shell predeterminada..."
    execute_core_script "fzsh" "critical"
}

execute_extras_operations() {
    [ "${INSTALL_EXTRAS:-0}" -eq 0 ] && {
        debug "Saltando extras (--extras no activado)"
        return "${EXIT_SUCCESS:-0}"
    }
    
    info "Iniciando instalación de extras..."
    execute_extras_script "fmise"
    execute_extras_script "fmise-extras"
    
    return "${EXIT_SUCCESS:-0}"
}

execute_setup_operations() {
    [ "${SETUP_ENVIRONMENT:-0}" -eq 0 ] && {
        debug "Saltando setup (--setup-env no activado)"
        return "${EXIT_SUCCESS:-0}"
    }
    
    info "Iniciando configuración de entorno..."
    execute_setup_script "fenv-setup"
    
    return "${EXIT_SUCCESS:-0}"
}

run_verification_mode() {
    [ "${VERIFY_MODE:-0}" -eq 0 ] && return "${EXIT_SUCCESS:-0}"
    
    info "Modo de verificación activado"
    exec "${SCRIPT_DIR}/scripts/fverify"
}

