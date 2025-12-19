#!/usr/bin/env bash
#==============================================================================
#                              LOGGER
#==============================================================================
# @file logger.sh
# @brief Logging utilities for gitconfig setup
# @description
#   Provides logging functions for both file logging and terminal output.
#   Includes success, error, warning, and info message functions.
#
# Globals:
#   LOG_FILE    Path to log file (from defaults.sh)
#   DEBUG       Debug mode flag (from defaults.sh)
#   COLORS      Color definitions (from defaults.sh)
#
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#==============================================================================

# Prevent double sourcing
[[ -n "${_LOGGER_SOURCED:-}" ]] && return 0
declare -r _LOGGER_SOURCED=1

#==============================================================================
# LOGGING FUNCTIONS
#==============================================================================

# @description Write message to log file with timestamp
# @param $1 message - Message to log
# @example
#   log "Starting SSH key generation"
log() {
    local message="$1"
    local timestamp
    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    # Ensure log directory exists
    local log_dir
    log_dir=$(dirname "$LOG_FILE")
    [[ -d "$log_dir" ]] || mkdir -p "$log_dir"
    
    echo "[$timestamp] $message" >> "$LOG_FILE"
}

# @description Display success message with green color
# @param $1 message - Success message to display
# @example
#   success "SSH key generated successfully"
success() {
    local message="$1"
    printf "%b\n" "$(c bold)$(c success)✓ $message$(cr)"
    log "SUCCESS: $message"
}

# @description Display error message with red color
# @param $1 message - Error message to display
# @example
#   error "Failed to generate SSH key"
error() {
    local message="$1"
    printf "%b\n" "$(c bold)$(c error)✗ ERROR: $message$(cr)" >&2
    log "ERROR: $message"
}

# @description Display warning message with yellow color
# @param $1 message - Warning message to display
# @example
#   warning "SSH key already exists"
warning() {
    local message="$1"
    printf "%b\n" "$(c bold)$(c warning)⚠ WARNING: $message$(cr)"
    log "WARNING: $message"
}

# @description Display info message with blue color
# @param $1 message - Info message to display
# @example
#   info "Checking for existing keys..."
info() {
    local message="$1"
    printf "%b\n" "$(c bold)$(c info)ℹ $message$(cr)"
    log "INFO: $message"
}

# @description Display debug message (only when DEBUG=true)
# @param $1 message - Debug message to display
# @example
#   debug "Variable value: $var"
debug() {
    local message="$1"
    if [[ "$DEBUG" == "true" ]]; then
        printf "%b\n" "$(c muted)[DEBUG] $message$(cr)"
        log "DEBUG: $message"
    fi
}

# @description Display a horizontal separator line
# @example
#   show_separator
#   echo "Section content"
#   show_separator
show_separator() {
    printf "%b\n" "$(c muted)────────────────────────────────────────────────────────────────────────────────$(cr)"
}
