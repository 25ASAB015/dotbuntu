#!/usr/bin/env bash
# shellcheck shell=bash
# shfmt: -ln=bash
#
# logger.sh - Logging functions and utilities for dotmarchy
#
# Provides standardized logging functions for all output levels with consistent
# formatting and behavior. This is a core helper module that implements the
# logging interface used throughout the dotmarchy codebase.
#
# All logging functions output user-facing messages in Spanish while maintaining
# English function names and code structure.
#
# Usage:
#   source "${SCRIPT_DIR}/helper/logger.sh"
#   info "Proceso iniciado"
#   warn "Advertencia importante"
#   log_error "Error crítico"
#   debug "Información de depuración"
#
# Log Levels:
#   log()       - Plain output, no formatting
#   info()      - Informational messages (blue)
#   warn()      - Warnings that don't stop execution (yellow)
#   log_error() - Errors logged to file and stderr (red)
#   debug()     - Verbose output only when VERBOSE=1 (bold)
#
# Dependencies:
#   - colors.sh (for color variables)
#   - set_variable.sh (for VERBOSE and ERROR_LOG)
#
# @author: dotmarchy
# @version: 2.0.0

set -Eeuo pipefail

#######################################
# Constants and Configuration
#######################################
readonly HELPER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default error log location (can be overridden by set_variable.sh)
readonly DEFAULT_ERROR_LOG="/tmp/dotmarchy-error.log"

# Log level constants
readonly LOG_LEVEL_DEBUG=0
readonly LOG_LEVEL_INFO=1
readonly LOG_LEVEL_WARN=2
readonly LOG_LEVEL_ERROR=3

#######################################
# Load Dependencies
#######################################

# Load colors if not already loaded
if [ -z "${CGR:-}" ]; then
    source "${HELPER_DIR}/colors.sh" || {
        echo "ERROR: Cannot load colors.sh" >&2
        exit 1
    }
fi

#######################################
# Global Variables Documentation
#
# Configuration Variables (from set_variable.sh):
#   VERBOSE (integer): Controls debug output (0=off, 1=on)
#     Default: 0
#     Used by: debug()
#
#   ERROR_LOG (string): Path to error log file
#     Default: /tmp/dotmarchy-error.log
#     Used by: log_error()
#
# Color Variables (from colors.sh):
#   CRE, CYE, CGR, CBL, BLD, CNC
#
# DO NOT reimplement color definitions.
# DO NOT reimplement configuration loading.
#######################################

#######################################
# Get current timestamp in ISO 8601 format
#
# Returns standardized timestamp for log entries.
# Uses UTC to avoid timezone ambiguity in logs.
#
# Outputs:
#   STDOUT: Timestamp in format "YYYY-MM-DD HH:MM:SS"
#
# Example:
#   timestamp=$(get_timestamp)
#   echo "[$timestamp] Event occurred"
#######################################
get_timestamp() {
    date +"%Y-%m-%d %H:%M:%S"
}

#######################################
# Get error log file path
#
# Returns the configured error log path or default if not set.
# Creates parent directory if it doesn't exist.
#
# Outputs:
#   STDOUT: Path to error log file
#
# Side Effects:
#   - May create parent directories
#######################################
get_error_log_path() {
    local log_path="${ERROR_LOG:-$DEFAULT_ERROR_LOG}"
    local log_dir
    
    log_dir="$(dirname "$log_path")"
    
    # Create directory if it doesn't exist
    [ ! -d "$log_dir" ] && mkdir -p "$log_dir" 2>/dev/null || true
    
    echo "$log_path"
}

#######################################
# Check if verbose mode is enabled
#
# Returns:
#   0: Verbose mode enabled (VERBOSE=1)
#   1: Verbose mode disabled (VERBOSE=0 or unset)
#######################################
is_verbose_enabled() {
    [ "${VERBOSE:-0}" -eq 1 ]
}

#######################################
# Plain output with no formatting
#
# Outputs message exactly as provided without any color or formatting.
# Use for raw output when color would interfere (e.g., piping to files).
#
# Arguments:
#   $*: Message to output
#
# Outputs:
#   STDOUT: Plain text message
#
# Example:
#   log "Plain text output"
#   log "Multiple" "words" "combined"
#######################################
log() {
    printf "%s\n" "$*"
}

#######################################
# Informational message
#
# Displays informational message in blue color. Use for normal
# operational messages that inform the user of progress.
#
# Arguments:
#   $*: Informational message
#
# Outputs:
#   STDOUT: Blue colored message
#
# Example:
#   info "Iniciando instalación de paquetes..."
#   info "Proceso completado exitosamente"
#######################################
info() {
    printf "%b%s%b\n" "${CBL}" "$*" "${CNC}"
}

#######################################
# Informational message (compatibility alias)
#
# Alias for info() function to maintain compatibility with
# older scripts that use print_info().
#
# Arguments:
#   $@: Informational message (passed to info)
#
# Outputs:
#   STDOUT: Blue colored message
#
# Example:
#   print_info "Mensaje informativo"
#######################################
print_info() {
    info "$@"
}

#######################################
# Warning message
#
# Displays warning message in bold yellow. Use for non-critical issues
# that the user should be aware of but don't stop execution.
#
# Arguments:
#   $*: Warning message
#
# Outputs:
#   STDOUT: Bold yellow message
#
# Example:
#   warn "Paquete opcional no encontrado, continuando..."
#   warn "Configuración no óptima detectada"
#######################################
warn() {
    printf "%b⚠ %s%b\n" "${BLD}${CYE}" "$*" "${CNC}"
}

#######################################
# Debug message
#
# Outputs debug message only when VERBOSE=1. Use for detailed
# diagnostic information during development and troubleshooting.
#
# The message is prefixed with "…" to distinguish it from regular output.
#
# Arguments:
#   $*: Debug message
#
# Outputs:
#   STDOUT: Bold message (only if VERBOSE=1)
#   Nothing if VERBOSE=0
#
# Example:
#   debug "Variable value: $var"
#   debug "Entering function: process_data"
#######################################
debug() {
    if is_verbose_enabled; then
        printf "%b… %s%b\n" "${BLD}" "$*" "${CNC}"
    fi
}

#######################################
# Write error to log file
#
# Internal function to append error message to the error log file
# with timestamp. Creates log file if it doesn't exist.
#
# Arguments:
#   $1: Error message to log
#
# Side Effects:
#   - Appends to ERROR_LOG file
#   - Creates log file if missing
#######################################
write_to_error_log() {
    local message="$1"
    local timestamp
    local log_path
    
    timestamp=$(get_timestamp)
    log_path=$(get_error_log_path)
    
    printf "[%s] ERROR: %s\n" "$timestamp" "$message" >> "$log_path" 2>/dev/null || {
        # If we can't write to configured log, try stderr
        printf "[%s] ERROR (log write failed): %s\n" "$timestamp" "$message" >&2
    }
}

#######################################
# Display error to user
#
# Internal function to show formatted error message to stderr.
#
# Arguments:
#   $1: Error message to display
#
# Outputs:
#   STDERR: Red colored error message
#######################################
display_error_to_user() {
    local message="$1"
    printf "%b✗ ERROR:%b %s\n" "${BLD}${CRE}" "${CNC}" "$message" >&2
}

#######################################
# Log error message
#
# Logs error to both file (with timestamp) and displays to user (stderr).
# This is the primary error reporting function that should be used for
# all error conditions.
#
# Error messages are logged to ERROR_LOG for debugging and displayed
# to stderr in bold red for immediate user visibility.
#
# Arguments:
#   $1: Error message
#
# Outputs:
#   STDERR: Colored error message
#
# Side Effects:
#   - Appends to ERROR_LOG file
#
# Example:
#   log_error "No se pudo conectar al servidor"
#   log_error "Archivo de configuración no encontrado: $config"
#######################################
log_error() {
    local error_msg="$1"
    
    # Validate input
    [ -z "$error_msg" ] && {
        display_error_to_user "log_error called with empty message"
        return 1
    }
    
    # Log to file
    write_to_error_log "$error_msg"
    
    # Display to user
    display_error_to_user "$error_msg"
}

#######################################
# Get error context information
#
# Extracts context about where an error occurred for detailed logging.
# Used internally by on_error() trap handler.
#
# Arguments:
#   $1: Exit code
#   $2: Line number
#   $3: Function name (optional)
#
# Outputs:
#   STDOUT: Formatted error context string
#######################################
get_error_context() {
    local exit_code="$1"
    local line_number="${2:-UNKNOWN}"
    local function_name="${3:-main}"
    
    printf "Function: %s | Line: %s | Exit code: %s" \
        "$function_name" "$line_number" "$exit_code"
}

#######################################
# Error trap handler
#
# Automatic error handler triggered by ERR signal (set -E).
# Logs detailed error information and exits with the original error code.
#
# This function should be registered with: trap on_error ERR
#
# Globals:
#   BASH_LINENO: Array of line numbers (bash built-in)
#   BASH_SOURCE: Array of source files (bash built-in)
#   FUNCNAME: Array of function names (bash built-in)
#
# Outputs:
#   STDERR: Error message via log_error()
#
# Side Effects:
#   - Logs error to ERROR_LOG
#   - Exits with original error code
#
# Example:
#   trap on_error ERR
#   # Any command that fails will trigger on_error
#######################################
on_error() {
    local exit_code=$?
    local line_number="${BASH_LINENO[0]:-UNKNOWN}"
    local source_file="${BASH_SOURCE[1]:-UNKNOWN}"
    local function_name="${FUNCNAME[1]:-main}"
    
    # Build detailed error message
    local error_context
    error_context=$(get_error_context "$exit_code" "$line_number" "$function_name")
    
    # Log error with context
    log_error "Fallo en la ejecución"
    
    # Write detailed context to log file only (too technical for user)
    write_to_error_log "Context: $error_context"
    write_to_error_log "Source: $source_file"
    
    # Display user-friendly location info
    printf "%b%sUbicación:%b Línea %s en %s\n" \
        "${BLD}" "${CYE}" "${CNC}" \
        "$line_number" "$(basename "$source_file")" >&2
    
    exit "$exit_code"
}
