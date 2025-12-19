#!/usr/bin/env bash
# shellcheck shell=bash
# shfmt: -ln=bash
#
# checks.sh - System validation checks for dotmarchy
#
# Provides functions to verify system requirements and package installation
# status before proceeding with dotmarchy operations. All checks are designed
# to fail fast and provide clear error messages to users.
#
# This is a helper module that should be sourced by other scripts.
#
# Usage:
#   source "${SCRIPT_DIR}/helper/checks.sh"
#   initial_checks  # Run all system validations
#   is_installed "git"  # Check specific package
#
# Dependencies:
#   - colors.sh (for color variables)
#   - logger.sh (for logging functions)
#
# @author: dotmarchy
# @version: 2.0.0

set -Eeuo pipefail

# Idempotent guard (not exported)
DOTMARCHY_CHECKS_LOADED=${DOTMARCHY_CHECKS_LOADED:-0}
if [ "${DOTMARCHY_CHECKS_LOADED}" -eq 1 ]; then
    return 0
fi

#######################################
# Constants and Configuration
#######################################
if [ -z "${HELPER_DIR+x}" ]; then
    readonly HELPER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# Network check configuration
readonly PING_HOST="8.8.8.8"
readonly PING_COUNT=1
readonly PING_TIMEOUT=1

# Exit codes (define only if not preset)
if [ -z "${EXIT_SUCCESS+x}" ]; then
    readonly EXIT_SUCCESS=0
fi
if [ -z "${EXIT_FAILURE+x}" ]; then
    readonly EXIT_FAILURE=1
fi
if [ -z "${EXIT_INVALID_ENVIRONMENT+x}" ]; then
    readonly EXIT_INVALID_ENVIRONMENT=4
fi

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

# Load logger if not already loaded
if ! command -v log_error >/dev/null 2>&1; then
    source "${HELPER_DIR}/logger.sh" || {
        echo "ERROR: Cannot load logger.sh" >&2
        exit 1
    }
fi

#######################################
# Global Variables Documentation
#
# Color Variables (from colors.sh):
#   CGR, CRE, CYE, CBL, BLD, CNC
#
# Logging Functions (from logger.sh):
#   log_error(msg): Log error and print to stderr
#   warn(msg): Log warning message
#   info(msg): Log informational message
#   debug(msg): Log debug message
#
# DO NOT reimplement these functions.
#######################################

#######################################
# Check if current user is root
#
# Verifies that the script is NOT being run as root user.
# Running as root can cause permission issues with dotfiles
# and is a security risk.
#
# Returns:
#   0: Not running as root (good)
#   1: Running as root (bad)
#
# Example:
#   if is_running_as_root; then
#       echo "Please don't run as root"
#   fi
#######################################
is_running_as_root() {
    [ "$(id -u)" -eq 0 ]
}

#######################################
# Verify user is not root
#
# Checks that the script is not being executed with root privileges.
# Exits the script if running as root with appropriate error message.
#
# Returns:
#   0: Not root (safe to continue)
#
# Side Effects:
#   - Exits with code 1 if running as root
#######################################
verify_not_root() {
    if is_running_as_root; then
        log_error "This script MUST NOT be run as root user"
        printf "%b\n" "${BLD}${CRE}Este script NO debe ejecutarse como root${CNC}" >&2
        printf "%b\n" "${CYE}Ejecuta como usuario normal: ${CBL}./dotmarchy${CNC}" >&2
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
# Returns:
#   0: Internet connection available
#   1: No internet connection
#######################################
has_internet_connection() {
    ping -q -c "$PING_COUNT" -W "$PING_TIMEOUT" "$PING_HOST" >/dev/null 2>&1
}

#######################################
# Verify internet connectivity
#
# Ensures that the system has an active internet connection.
# Required for downloading packages and cloning repositories.
#
# Returns:
#   0: Internet connection verified
#
# Side Effects:
#   - Exits with code 1 if no internet connection
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
# Check if pacman package manager is available
#
# Verifies that pacman is installed and accessible in PATH.
# This indicates the system is Arch Linux or an Arch-based distro.
#
# Returns:
#   0: Pacman is available
#   1: Pacman not found
#######################################
has_pacman() {
    command -v pacman >/dev/null 2>&1
}

#######################################
# Verify system is Arch Linux based
#
# Ensures the script is running on an Arch Linux system by checking
# for the presence of pacman package manager.
#
# Returns:
#   0: Arch Linux detected
#
# Side Effects:
#   - Exits with code 1 if not Arch Linux
#######################################
verify_arch_linux() {
    if ! has_pacman; then
        log_error "System is not Arch Linux (pacman not found)"
        printf "%b\n" "${BLD}${CRE}Este script está diseñado para Arch Linux${CNC}" >&2
        printf "%b\n" "${CYE}Se requiere pacman como gestor de paquetes${CNC}" >&2
        exit "$EXIT_FAILURE"
    fi
    
    debug "Arch Linux detected (pacman available)"
}

#######################################
# Check if a package is installed (pacman)
#
# Arguments:
#   $1: Package name to check
#
# Returns:
#   0: Package is installed
#   1: Package not installed or query failed
#######################################
is_installed() {
    local package="${1:-}"
    
    if [ -z "$package" ]; then
        debug "is_installed called with empty package name"
        return "$EXIT_FAILURE"
    fi
    
    pacman -Qq "$package" >/dev/null 2>&1
}

#######################################
# Perform all initial system checks
#
# Runs comprehensive validation of system requirements before
# allowing installation to proceed. This is the main entry point
# for system validation and should be called early in the main script.
#
# Checks performed:
#   1. User is not root
#   2. Internet connection available
#   3. Running on Arch Linux (pacman present)
#
# Returns:
#   0: All checks passed
#
# Side Effects:
#   - Exits with code 1 if any check fails
#   - Logs all check results
#
# Example:
#   initial_checks  # Run at start of main script
#######################################
initial_checks() {
    debug "Starting initial system checks"
    
    # Check 1: Verify not running as root
    verify_not_root
    
    # Check 2: Verify internet connection
    verify_internet_connection
    
    # Check 3: Verify Arch Linux system
    verify_arch_linux
    
    debug "All initial checks passed"
    return "$EXIT_SUCCESS"
}

# Mark as loaded
DOTMARCHY_CHECKS_LOADED=1

#######################################
# MODULARITY NOTE:
#
# This module provides system validation and package checking
# functionality specific to Arch Linux systems. It should not
# be confused with general utilities in utils.sh.
#
# Relationship to other helpers:
#   - Depends on: colors.sh, logger.sh
#   - Used by: Main installation scripts
#   - Complements: utils.sh (general utilities)
#
# If other scripts need similar validation logic, they should
# use this module rather than reimplementing checks.
#######################################