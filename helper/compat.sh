#!/usr/bin/env bash
# shellcheck shell=bash
#
# compat.sh - Compatibility bridge between logging/color systems
#
# This file bridges the two logging/color systems in dotbuntu:
#
# System 1 (helper/logger.sh): Uses $CGR, $CRE, etc. color variables
#   Functions: info(), warn(), debug(), log_error()
#
# System 2 (scripts/core/logger.sh): Uses c(), cr() color functions
#   Functions: log(), success(), error(), warning(), info(), debug()
#
# By sourcing this file after both systems, scripts get consistent access
# to all functions regardless of which system they were written for.
#
# @author: dotbuntu
# @version: 1.0.0

# Idempotent guard - prevent double sourcing
[[ -n "${_COMPAT_SOURCED:-}" ]] && return 0
declare -r _COMPAT_SOURCED=1

# Determine helper directory for potential fallback sourcing
COMPAT_HELPER_DIR="${HELPER_DIR:-$(dirname "${BASH_SOURCE[0]}")}"

#######################################
# Display success message
#
# Bridge function that provides success() if not already defined.
# Uses green color with checkmark prefix.
#
# Arguments:
#   $1 - Success message to display
#
# Outputs:
#   STDOUT - Green formatted success message
#######################################
if ! declare -f success >/dev/null 2>&1; then
    success() {
        local message="$1"
        if declare -f info >/dev/null 2>&1; then
            printf "%b\n" "${BLD:-}${CGR:-\033[0;32m}✓ $message${CNC:-\033[0m}"
        else
            echo "✓ $message"
        fi
    }
fi

#######################################
# Display error message
#
# Bridge function that provides error() if not already defined.
# Delegates to log_error() if available, otherwise formats directly.
#
# Arguments:
#   $1 - Error message to display
#
# Outputs:
#   STDERR - Red formatted error message
#######################################
if ! declare -f error >/dev/null 2>&1; then
    error() {
        local message="$1"
        if declare -f log_error >/dev/null 2>&1; then
            log_error "$message"
        else
            printf "%b\n" "${BLD:-}${CRE:-\033[0;31m}✗ ERROR: $message${CNC:-\033[0m}" >&2
        fi
    }
fi

#######################################
# Display warning message
#
# Bridge function that provides warning() if not already defined.
# Delegates to warn() for consistency.
#
# Arguments:
#   $1 - Warning message to display
#
# Outputs:
#   STDOUT - Yellow formatted warning message
#######################################
if ! declare -f warning >/dev/null 2>&1; then
    warning() {
        if declare -f warn >/dev/null 2>&1; then
            warn "$@"
        else
            local message="$1"
            printf "%b\n" "${BLD:-}${CYE:-\033[0;33m}⚠ WARNING: $message${CNC:-\033[0m}"
        fi
    }
fi

#######################################
# Display warning message (alias)
#
# Bridge function that provides warn() if not already defined.
# Delegates to warning() for consistency.
#
# Arguments:
#   $1 - Warning message to display
#
# Outputs:
#   STDOUT - Yellow formatted warning message
#######################################
if ! declare -f warn >/dev/null 2>&1; then
    warn() {
        if declare -f warning >/dev/null 2>&1; then
            warning "$@"
        else
            local message="$1"
            printf "%b\n" "${BLD:-}${CYE:-\033[0;33m}⚠ $message${CNC:-\033[0m}"
        fi
    }
fi

#######################################
# Get color escape code by name
#
# Bridge function that provides c() if not already defined.
# Maps semantic color names to color variables.
#
# Arguments:
#   $1 - Color name (bold, success, error, warning, info, muted, primary, text)
#
# Outputs:
#   STDOUT - ANSI escape code for the color
#
# Example:
#   printf "%b\n" "$(c success)Done$(cr)"
#######################################
if ! declare -f c >/dev/null 2>&1; then
    c() {
        local color="$1"
        case "$color" in
            bold)    printf "%s" "${BLD:-}" ;;
            success) printf "%s" "${CGR:-}" ;;
            error)   printf "%s" "${CRE:-}" ;;
            warning) printf "%s" "${CYE:-}" ;;
            info)    printf "%s" "${CBL:-}" ;;
            muted)   printf "%s" "${CGR:-}" ;;
            primary) printf "%s" "${CBL:-}" ;;
            text)    printf "%s" "${CNC:-}" ;;
            *)       printf "%s" "" ;;
        esac
    }
fi

#######################################
# Get color reset escape code
#
# Bridge function that provides cr() if not already defined.
# Returns the reset/clear escape code.
#
# Outputs:
#   STDOUT - ANSI reset escape code
#
# Example:
#   printf "%b\n" "$(c error)Error$(cr)"
#######################################
if ! declare -f cr >/dev/null 2>&1; then
    cr() {
        printf "%s" "${CNC:-\033[0m}"
    }
fi

#######################################
# Display horizontal separator line
#
# Bridge function that provides show_separator() if not already defined.
# Displays a decorative line for visual separation.
#
# Outputs:
#   STDOUT - Horizontal line with color
#######################################
if ! declare -f show_separator >/dev/null 2>&1; then
    show_separator() {
        printf "%b\n" "${CGR:-}────────────────────────────────────────────────────────────────────────────────${CNC:-}"
    }
fi
