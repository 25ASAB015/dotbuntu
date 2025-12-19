#!/usr/bin/env bash
# shellcheck shell=bash
#
# logger.sh - Logging utilities for gitconfig/git phase
#
# This module provides logging functions for terminal output and file logging.
# It delegates core logging functions to helper/logger.sh and adds additional
# functions needed for the git configuration phase (success, error, warning).
#
# NOTE: This is a COMPATIBILITY SHIM. The canonical logging implementation
# is in helper/logger.sh. This file adds git-phase-specific functions.
#
# @author: dotbuntu
# @version: 2.0.0

# Idempotent guard - prevent double sourcing
[[ -n "${_CORE_LOGGER_SOURCED:-}" ]] && return 0
declare -r _CORE_LOGGER_SOURCED=1

# Determine paths
_CORE_LOGGER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_HELPER_DIR="${_CORE_LOGGER_DIR}/../../helper"

#######################################
# Source canonical logger from helper
#
# The helper/logger.sh provides: log(), info(), warn(), debug(), log_error()
# We source it first to get those functions, then add our own.
#######################################
if [[ -f "${_HELPER_DIR}/logger.sh" ]]; then
    # shellcheck source=/dev/null
    source "${_HELPER_DIR}/logger.sh"
fi

#######################################
# Write message to log file with timestamp
#
# NOTE: This overrides the helper/logger.sh log() function to write to
# LOG_FILE (git phase log) instead of ERROR_LOG (dotmarchy error log).
#
# Globals:
#   LOG_FILE - Path to git phase log file (from defaults.sh)
#
# Arguments:
#   $1 - Message to log
#
# Returns:
#   0 - Always succeeds
#
# Outputs:
#   None (writes to log file only)
#######################################
log() {
    local message="$1"
    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    # Ensure log directory exists
    local log_dir
    log_dir=$(dirname "${LOG_FILE:-/tmp/dotbuntu.log}")
    [[ -d "$log_dir" ]] || mkdir -p "$log_dir"
    
    echo "[$timestamp] $message" >> "${LOG_FILE:-/tmp/dotbuntu.log}"
}

#######################################
# Display success message with green color
#
# Shows a success message with checkmark and logs it.
#
# Globals:
#   c() - Color function (from colors.sh)
#   cr() - Color reset function (from colors.sh)
#
# Arguments:
#   $1 - Success message to display
#
# Returns:
#   0 - Always succeeds
#
# Outputs:
#   STDOUT - Green formatted success message
#######################################
success() {
    local message="$1"
    printf "%b\n" "$(c bold)$(c success)✓ $message$(cr)"
    log "SUCCESS: $message"
}

#######################################
# Display error message with red color
#
# Shows an error message with X mark and logs it.
#
# Globals:
#   c() - Color function (from colors.sh)
#   cr() - Color reset function (from colors.sh)
#
# Arguments:
#   $1 - Error message to display
#
# Returns:
#   0 - Always succeeds
#
# Outputs:
#   STDERR - Red formatted error message
#######################################
error() {
    local message="$1"
    printf "%b\n" "$(c bold)$(c error)✗ ERROR: $message$(cr)" >&2
    log "ERROR: $message"
}

#######################################
# Display warning message with yellow color
#
# Shows a warning message with warning symbol and logs it.
#
# Globals:
#   c() - Color function (from colors.sh)
#   cr() - Color reset function (from colors.sh)
#
# Arguments:
#   $1 - Warning message to display
#
# Returns:
#   0 - Always succeeds
#
# Outputs:
#   STDOUT - Yellow formatted warning message
#######################################
warning() {
    local message="$1"
    printf "%b\n" "$(c bold)$(c warning)⚠ WARNING: $message$(cr)"
    log "WARNING: $message"
}

#######################################
# Display info message with blue color
#
# Shows an informational message and logs it.
# NOTE: This overrides helper/logger.sh info() to use c() function style.
#
# Globals:
#   c() - Color function (from colors.sh)
#   cr() - Color reset function (from colors.sh)
#
# Arguments:
#   $1 - Info message to display
#
# Returns:
#   0 - Always succeeds
#
# Outputs:
#   STDOUT - Blue formatted info message
#######################################
info() {
    local message="$1"
    printf "%b\n" "$(c bold)$(c info)ℹ $message$(cr)"
    log "INFO: $message"
}

#######################################
# Display debug message (only when DEBUG=true)
#
# Shows a debug message only if DEBUG mode is enabled.
# NOTE: This checks DEBUG (string) vs helper's VERBOSE (integer).
#
# Globals:
#   DEBUG - Debug mode flag from defaults.sh (true/false)
#   c() - Color function (from colors.sh)
#   cr() - Color reset function (from colors.sh)
#
# Arguments:
#   $1 - Debug message to display
#
# Returns:
#   0 - Always succeeds
#
# Outputs:
#   STDOUT - Muted formatted debug message (if DEBUG=true)
#######################################
debug() {
    local message="$1"
    if [[ "${DEBUG:-false}" == "true" ]] || [[ "${VERBOSE:-0}" -eq 1 ]]; then
        printf "%b\n" "$(c muted)[DEBUG] $message$(cr)"
        log "DEBUG: $message"
    fi
}

#######################################
# Display a horizontal separator line
#
# Shows a decorative horizontal line for visual separation.
#
# Globals:
#   c() - Color function (from colors.sh)
#   cr() - Color reset function (from colors.sh)
#
# Returns:
#   0 - Always succeeds
#
# Outputs:
#   STDOUT - Horizontal separator line
#######################################
show_separator() {
    printf "%b\n" "$(c muted)────────────────────────────────────────────────────────────────────────────────$(cr)"
}
