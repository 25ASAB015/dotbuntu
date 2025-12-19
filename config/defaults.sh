#!/usr/bin/env bash
#==============================================================================
#                              DEFAULTS
#==============================================================================
# @file defaults.sh
# @brief Default configuration values for gitconfig setup
# @description
#   Centralized configuration defaults including colors, workflow steps,
#   and runtime settings. Source this file to access all default values.
#
# Globals:
#   COLORS              Associative array of color escape codes
#   WORKFLOW_STEPS      Associative array of workflow step descriptions
#   EMAIL_REGEX         Email validation regex pattern
#   SCRIPT_DIR          Directory containing the main script
#   LOG_FILE            Path to log file
#   DEBUG               Enable debug output (true/false)
#   INTERACTIVE_MODE    Run in interactive mode (true/false)
#   AUTO_UPLOAD_KEYS    Auto-upload keys to GitHub (true/false)
#   GH_INSTALL_ATTEMPTED  Track if GitHub CLI install was attempted
#   SSH_KEY_UPLOADED    Track if SSH key was uploaded
#   GPG_KEY_UPLOADED    Track if GPG key was uploaded
#   USER_NAME           Git user name
#   USER_EMAIL          Git user email
#   GPG_KEY_ID          GPG key ID for signing commits
#   GENERATE_GPG        Whether to generate GPG key (true/false)
#   GIT_DEFAULT_BRANCH  Default Git branch name (main/master)
#   TOTAL_STEPS         Total number of workflow steps
#   CURRENT_STEP        Current step in workflow
#
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#==============================================================================

# Prevent double sourcing
[[ -n "${_DEFAULTS_SOURCED:-}" ]] && return 0
declare -r _DEFAULTS_SOURCED=1

#==============================================================================
# COLOR DEFINITIONS
#==============================================================================
# ANSI color codes for terminal output
# Usage: echo -e "${COLORS[primary]}text${COLORS[reset]}"
declare -A COLORS=(
    # Reset
    [reset]='\033[0m'
    
    # Text styles
    [bold]='\033[1m'
    [dim]='\033[2m'
    [italic]='\033[3m'
    [underline]='\033[4m'
    
    # Base colors
    [text]='\033[38;5;252m'
    [muted]='\033[38;5;245m'
    
    # Semantic colors
    [primary]='\033[38;5;75m'
    [secondary]='\033[38;5;183m'
    [accent]='\033[38;5;215m'
    [success]='\033[38;5;114m'
    [warning]='\033[38;5;221m'
    [error]='\033[38;5;204m'
    [info]='\033[38;5;117m'
    
    # Background colors
    [bg_primary]='\033[48;5;75m'
    [bg_secondary]='\033[48;5;183m'
    [bg_success]='\033[48;5;114m'
    [bg_warning]='\033[48;5;221m'
    [bg_error]='\033[48;5;204m'
)

# Dotmarchy-style color variables (for compatibility)
export BLD='\033[1m'
export CGR='\033[38;5;114m'
export CRE='\033[38;5;204m'
export CYE='\033[38;5;221m'
export CBL='\033[38;5;117m'
export CNC='\033[0m'

#==============================================================================
# WORKFLOW STEP DESCRIPTIONS
#==============================================================================
# Human-readable descriptions for each workflow step
# Used by progress bar and logging
declare -A WORKFLOW_STEPS=(
    [1]="Verificando dependencias..."
    [2]="Configurando directorios..."
    [3]="Respaldando llaves existentes..."
    [4]="Recopilando información del usuario..."
    [5]="Generando llave SSH..."
    [6]="Generando llave GPG..."
    [7]="Configurando Git..."
    [8]="Configurando ssh-agent..."
    [9]="Finalizando configuración..."
)

#==============================================================================
# RUNTIME CONFIGURATION
#==============================================================================

# Script location and logging
# Ensure SCRIPT_DIR is set to root if not already defined
if [[ -z "${SCRIPT_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi
export SCRIPT_DIR
LOG_FILE="${LOG_FILE:-$HOME/.gitconfig_setup.log}"
export LOG_FILE

# Debug mode
DEBUG="${DEBUG:-false}"
VERBOSE="${VERBOSE:-0}"

# Interactive mode (can be overridden by --non-interactive)
INTERACTIVE_MODE="${INTERACTIVE_MODE:-true}"

# Auto-upload keys to GitHub (set by --auto-upload flag)
AUTO_UPLOAD_KEYS="${AUTO_UPLOAD_KEYS:-false}"

# Track GitHub CLI installation attempt
GH_INSTALL_ATTEMPTED="${GH_INSTALL_ATTEMPTED:-false}"

# Track key upload status
SSH_KEY_UPLOADED="${SSH_KEY_UPLOADED:-false}"
GPG_KEY_UPLOADED="${GPG_KEY_UPLOADED:-false}"

#==============================================================================
# DOTMARCHY CONFIGURATION
#==============================================================================

# Dotbare configuration
export DOTBARE_DIR="${DOTBARE_DIR:-$HOME/.cfg}"
export DOTBARE_TREE="${DOTBARE_TREE:-$HOME}"
export DOTBARE_BACKUP="${DOTBARE_BACKUP:-${XDG_DATA_HOME:-$HOME/.local/share}/dotbare}"

# Versioning
export DOTMARCHY_VERSION="${DOTMARCHY_VERSION:-v2.0.0}"
export DOTBUNTU_VERSION="v1.0.0"

# Dotmarchy Operational flags
export DRY_RUN="${DRY_RUN:-0}"
export FORCE="${FORCE:-0}"
export INSTALL_EXTRAS="${INSTALL_EXTRAS:-0}"
export SETUP_ENVIRONMENT="${SETUP_ENVIRONMENT:-0}"
export SKIP_SYSTEM="${SKIP_SYSTEM:-0}"
export VERIFY_MODE="${VERIFY_MODE:-0}"

# Default repository URL
export REPO_URL="${REPO_URL:-git@github.com:25ASAB015/dotfiles.git}"

# Configuration paths
export SETUP_CONFIG="${SETUP_CONFIG:-$HOME/.config/dotmarchy/setup.conf}"
export DOTMARCHY_ERROR_LOG="${ERROR_LOG:-$HOME/.local/share/dotmarchy/install_errors.log}"

# Core dependencies (always installed by dotmarchy)
# Note: git-delta and diff-so-fancy are platform-specific and installed via alternative methods
export CORE_DEPENDENCIES="zsh tree bat highlight ruby-coderay npm"

# Default extra packages
export DEFAULT_EXTRA_DEPENDENCIES="neovim tmux htop ripgrep fd fzf git-delta"
export DEFAULT_EXTRA_CHAOTIC_DEPENDENCIES="brave-bin visual-studio-code-bin"
export DEFAULT_EXTRA_AUR_APPS="zsh-theme-powerlevel10k-git zsh-autosuggestions zsh-syntax-highlighting"
export DEFAULT_EXTRA_NPM_PACKAGES="@fission-ai/openspec diff-so-fancy"

# Initialize arrays for extra packages
declare -a EXTRA_DEPENDENCIES=()
declare -a EXTRA_CHAOTIC_DEPENDENCIES=()
declare -a EXTRA_AUR_APPS=()
declare -a EXTRA_NPM_PACKAGES=()
declare -a CARGO_PACKAGES=()
declare -a PIP_PACKAGES=()
declare -a PIPX_PACKAGES=()
declare -a GEM_PACKAGES=()

# Arrays for environment setup
declare -a DIRECTORIES=()
declare -a GIT_REPOS=()
declare -a SCRIPTS=()
declare -a SHELL_LINES=()

# Installation statistics
export INSTALL_START_TIME=$(date +%s)
export PACKAGES_INSTALLED=0
export PACKAGES_SKIPPED=0

#==============================================================================
# USER CONFIGURATION (set during runtime)
#==============================================================================

# Git user information (collected during setup)
USER_NAME="${USER_NAME:-}"
USER_EMAIL="${USER_EMAIL:-}"

# GPG configuration
GPG_KEY_ID="${GPG_KEY_ID:-}"
GENERATE_GPG="${GENERATE_GPG:-false}"

# Git configuration
GIT_DEFAULT_BRANCH="${GIT_DEFAULT_BRANCH:-main}"

#==============================================================================
# PROGRESS TRACKING
#==============================================================================

# Total workflow steps
TOTAL_STEPS="${TOTAL_STEPS:-9}"

# Current step in workflow
CURRENT_STEP="${CURRENT_STEP:-0}"

#==============================================================================
# VALIDATION PATTERNS
#==============================================================================

# Email validation regex
readonly EMAIL_REGEX='^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'

