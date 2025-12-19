#!/usr/bin/env bash
# shellcheck shell=bash
#
# checks.sh - System validation checks for dotbuntu
#
# Provides functions to verify system requirements and package installation
# status before proceeding with dotbuntu operations. All checks are designed
# to fail fast and provide clear error messages to users.
#
# @author: dotbuntu
# @version: 2.0.0

set -Eeuo pipefail

# Idempotent guard
[[ -n "${_DOTBUNTU_CHECKS_LOADED:-}" ]] && return 0
declare -r _DOTBUNTU_CHECKS_LOADED=1

#######################################
# Constants
#######################################
if [[ -z "${HELPER_DIR:-}" ]]; then
    HELPER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# Network check configuration
readonly PING_HOST="8.8.8.8"
readonly PING_COUNT=1
readonly PING_TIMEOUT=1

# Exit codes (define only if not preset)
: "${EXIT_SUCCESS:=0}"
: "${EXIT_FAILURE:=1}"
: "${EXIT_INVALID_ENVIRONMENT:=4}"

#######################################
# Load Dependencies
#######################################

# Load colors if not already loaded
if [[ -z "${CGR:-}" ]]; then
    # shellcheck source=/dev/null
    source "${HELPER_DIR}/colors.sh" || {
        echo "ERROR: Cannot load colors.sh" >&2
        exit 1
    }
fi

# Load logger if not already loaded
if ! command -v log_error >/dev/null 2>&1; then
    # shellcheck source=/dev/null
    source "${HELPER_DIR}/logger.sh" || {
        echo "ERROR: Cannot load logger.sh" >&2
        exit 1
    }
fi

#######################################
# Check if current user is root
#
# Verifies whether the script is being run as root user.
# Running as root can cause permission issues with dotfiles
# and is a security risk.
#
# Returns:
#   0 - Running as root
#   1 - Not running as root
#
# Example:
#   if is_running_as_root; then
#       echo "Please don't run as root"
#   fi
#######################################
is_running_as_root() {
    [[ "$(id -u)" -eq 0 ]]
}

#######################################
# Verify user is not root
#
# Checks that the script is not being executed with root privileges.
# Exits the script if running as root with appropriate error message.
#
# Globals:
#   EXIT_FAILURE - Exit code for failure (from constants)
#   BLD, CRE, CYE, CBL, CNC - Color variables (from colors.sh)
#
# Returns:
#   0 - Not root, safe to continue
#
# Outputs:
#   STDERR - Error message if running as root
#
# Side Effects:
#   Exits with EXIT_FAILURE if running as root
#######################################
verify_not_root() {
    if is_running_as_root; then
        log_error "This script MUST NOT be run as root user"
        printf "%b\n" "${BLD}${CRE}Este script NO debe ejecutarse como root${CNC}" >&2
        printf "%b\n" "${CYE}Ejecuta como usuario normal: ${CBL}./dotbuntu${CNC}" >&2
        exit "$EXIT_FAILURE"
    fi
    
    debug "User check passed (not root)"
}

#######################################
# Check if internet connection is available
#
# Tests connectivity by pinging a reliable external host (8.8.8.8).
# Uses quick timeout to avoid hanging.
#
# Globals:
#   PING_HOST - Host to ping (default: 8.8.8.8)
#   PING_COUNT - Number of pings (default: 1)
#   PING_TIMEOUT - Timeout in seconds (default: 1)
#
# Returns:
#   0 - Internet connection available
#   1 - No internet connection
#######################################
has_internet_connection() {
    ping -q -c "$PING_COUNT" -W "$PING_TIMEOUT" "$PING_HOST" >/dev/null 2>&1
}

#######################################
# Verify internet connectivity
#
# Ensures that the system has an active internet connection.
# Required for downloading packages and cloning repositories.
# Exits the script if no connection is detected.
#
# Globals:
#   EXIT_FAILURE - Exit code for failure
#   BLD, CRE, CYE, CNC - Color variables (from colors.sh)
#
# Returns:
#   0 - Internet connection verified
#
# Outputs:
#   STDERR - Error message if no connection
#
# Side Effects:
#   Exits with EXIT_FAILURE if no internet connection
#######################################
verify_internet_connection() {
    if ! has_internet_connection; then
        log_error "No internet connection detected"
        printf "%b\n" "${BLD}${CRE}No se detectó conexión a internet${CNC}" >&2
        printf "%b\n" "${CYE}Verifica tu conexión de red e intenta nuevamente${CNC}" >&2
        exit "$EXIT_FAILURE"
    fi
    
    debug "Internet connection verified"
}

#######################################
# Check if a package is installed (multi-distro)
#
# Checks package installation using the appropriate package manager:
# - Arch Linux: pacman -Qq
# - Ubuntu/Debian: dpkg -l
# - Fallback: command -v
#
# NOTE: For new code, prefer is_pkg_installed() from package_manager.sh
# which provides better package name mapping across distributions.
#
# Arguments:
#   $1 - Package name to check
#
# Returns:
#   0 - Package is installed
#   1 - Package not installed or query failed
#######################################
is_package_installed() {
    local package="${1:-}"
    
    if [[ -z "$package" ]]; then
        debug "is_package_installed called with empty package name"
        return "$EXIT_FAILURE"
    fi
    
    # Try pacman first (Arch), then dpkg (Debian/Ubuntu)
    if command -v pacman >/dev/null 2>&1; then
        pacman -Qq "$package" >/dev/null 2>&1
    elif command -v dpkg >/dev/null 2>&1; then
        dpkg -l "$package" 2>/dev/null | grep -q "^ii"
    else
        # Fallback: check if command exists
        command -v "$package" >/dev/null 2>&1
    fi
}

#######################################
# DEPRECATED: Backward compatibility alias
#
# Use is_package_installed() for new code.
# This alias will be removed in version 3.0.0.
#######################################
is_installed() {
    is_package_installed "$@"
}
