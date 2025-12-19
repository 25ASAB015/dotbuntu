#!/usr/bin/env bash
#===============================================================================
# FILE: compat.sh
# DESCRIPTION: Compatibility bridge between logging systems
# AUTHOR: dotbuntu
# VERSION: 1.0.0
#===============================================================================
#
# This file provides aliases to bridge between the two logging systems:
#
# System 1 (helper/logger.sh): Uses $CGR, $CRE, etc. colors
#   - info(), warn(), debug(), log_error()
#
# System 2 (scripts/core/logger.sh): Uses c(), cr() color functions
#   - log(), success(), error(), warning(), info(), debug()
#
# By sourcing this file, scripts get access to functions from both systems.
#
#===============================================================================

# Prevent double sourcing
[[ -n "${_COMPAT_SOURCED:-}" ]] && return 0
declare -r _COMPAT_SOURCED=1

# Determine which system is loaded
COMPAT_HELPER_DIR="${HELPER_DIR:-$(dirname "${BASH_SOURCE[0]}")}"

#===============================================================================
# Bridge functions - provide missing functions from each system
#===============================================================================

# If success() is not available (from core/logger.sh), provide it
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

# If error() is not available (display function), provide it
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

# If warning() is not available (core/logger uses warning, helper uses warn)
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

# If warn() is not available, alias to warning()
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

#===============================================================================
# Color bridge - provide c() and cr() if not available
#===============================================================================

if ! declare -f c >/dev/null 2>&1; then
    # Simple color function that maps to existing color variables
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

if ! declare -f cr >/dev/null 2>&1; then
    # Color reset
    cr() {
        printf "%s" "${CNC:-\033[0m}"
    }
fi

#===============================================================================
# Show separator if not available
#===============================================================================

if ! declare -f show_separator >/dev/null 2>&1; then
    show_separator() {
        printf "%b\n" "${CGR:-}────────────────────────────────────────────────────────────────────────────────${CNC:-}"
    }
fi
