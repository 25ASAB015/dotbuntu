#!/usr/bin/env bash
# shellcheck shell=bash
#
# colors.sh - Color output utilities for terminal display
#
# Provides color helper functions for consistent terminal output.
# Includes the c() function for color codes and cr() for reset.
#
# NOTE: This works with the COLORS associative array from config/defaults.sh.
# The helper/colors.sh provides $CGR/$CRE/$CYE variables instead.
# The helper/compat.sh bridges these two systems.
#
# @author: dotbuntu
# @version: 2.0.0

# Idempotent guard - prevent double sourcing
[[ -n "${_COLORS_SOURCED:-}" ]] && return 0
declare -r _COLORS_SOURCED=1

#######################################
# Get color escape code by name
#
# Returns the ANSI escape code for a named color from the
# COLORS associative array. Falls back to text color if
# the requested color is not found.
#
# Globals:
#   COLORS - Associative array of color codes (from defaults.sh)
#
# Arguments:
#   $1 - Color name (primary, success, error, warning, info, muted, bold, text)
#
# Returns:
#   0 - Always succeeds
#
# Outputs:
#   STDOUT - ANSI escape code for the color
#
# Example:
#   printf "%b\n" "$(c primary)Hello$(cr)"
#   printf "%b\n" "$(c error)Error:$(cr) message"
#######################################
c() {
    local color_name="${1:-text}"
    printf '%b' "${COLORS[$color_name]:-${COLORS[text]:-}}"
}

#######################################
# Get reset escape code
#
# Returns the ANSI escape code to reset all terminal formatting.
#
# Globals:
#   COLORS - Associative array with 'reset' key (from defaults.sh)
#
# Returns:
#   0 - Always succeeds
#
# Outputs:
#   STDOUT - ANSI reset escape code
#
# Example:
#   printf "%b\n" "$(c error)Error:$(cr) normal text"
#######################################
cr() {
    printf '%b' "${COLORS[reset]:-\033[0m}"
}

#######################################
# Check if terminal supports Unicode
#
# Checks locale and terminal settings to determine if Unicode
# characters (like ✓, ✗, ⚠) can be displayed.
#
# Returns:
#   0 - Unicode is supported
#   1 - Unicode is not supported (use ASCII fallbacks)
#
# Example:
#   if check_unicode_support; then
#       echo "✓"
#   else
#       echo "[OK]"
#   fi
#######################################
check_unicode_support() {
    local lang="${LANG:-}"
    local lc_all="${LC_ALL:-}"
    local term="${TERM:-}"
    
    # Check if locale supports UTF-8
    if [[ "$lang" == *"UTF-8"* ]] || [[ "$lang" == *"utf8"* ]] || \
       [[ "$lc_all" == *"UTF-8"* ]] || [[ "$lc_all" == *"utf8"* ]]; then
        # Additional check for terminal capability
        if [[ "$term" != "dumb" ]] && [[ -n "$term" ]]; then
            return 0
        fi
    fi
    
    return 1
}

#######################################
# Get appropriate symbol based on Unicode support
#
# Returns either a Unicode symbol or its ASCII fallback
# based on terminal capability detection.
#
# Arguments:
#   $1 - Unicode symbol to use if supported
#   $2 - ASCII fallback if Unicode not supported
#
# Returns:
#   0 - Always succeeds
#
# Outputs:
#   STDOUT - Appropriate symbol for the terminal
#
# Example:
#   echo "$(get_symbol '✓' '[OK]') Done"
#   echo "$(get_symbol '✗' '[FAIL]') Error"
#######################################
get_symbol() {
    local unicode_symbol="$1"
    local ascii_fallback="$2"
    
    if check_unicode_support; then
        printf '%s' "$unicode_symbol"
    else
        printf '%s' "$ascii_fallback"
    fi
}
