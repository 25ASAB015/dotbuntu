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
SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
LOG_FILE="${LOG_FILE:-$HOME/.gitconfig_setup.log}"

# Debug mode
DEBUG="${DEBUG:-false}"

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
