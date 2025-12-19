#!/usr/bin/env bash
# shellcheck shell=bash
#
# set_variable.sh - Environment variables shim (DEPRECATED)
#
# DEPRECATION NOTICE:
#   This file is maintained for backward compatibility only.
#   The canonical source for all configuration is config/defaults.sh.
#   This file will be removed in version 3.0.0.
#
# Migration:
#   Replace: source "${HELPER_DIR}/set_variable.sh"
#   With:    source "${SCRIPT_DIR}/config/defaults.sh"
#
# @author: dotbuntu
# @version: 2.0.0 (deprecated)

# Idempotent load guard
[[ -n "${_SET_VARIABLE_SOURCED:-}" ]] && return 0
declare -r _SET_VARIABLE_SOURCED=1

#######################################
# Determine config location and source
#
# This shim delegates to config/defaults.sh which is the single
# source of truth for all configuration variables.
#######################################

# Find the config directory relative to this file
_SET_VAR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_CONFIG_DIR="${_SET_VAR_DIR}/../config"

# Source the canonical configuration
if [[ -f "${_CONFIG_DIR}/defaults.sh" ]]; then
    # shellcheck source=/dev/null
    source "${_CONFIG_DIR}/defaults.sh"
else
    # Fallback: define minimal required variables if defaults.sh not found
    # This ensures scripts don't break if the file structure changes
    
    # Version (only set if not already defined)
    : "${DOTMARCHY_VERSION:=v2.0.0}"
    export DOTMARCHY_VERSION
    
    # Dotbare configuration
    export DOTBARE_DIR="${DOTBARE_DIR:-$HOME/.cfg}"
    export DOTBARE_TREE="${DOTBARE_TREE:-$HOME}"
    export DOTBARE_BACKUP="${DOTBARE_BACKUP:-${XDG_DATA_HOME:-$HOME/.local/share}/dotbare}"
    
    # Default repository URL
    export REPO_URL="${REPO_URL:-git@github.com:25ASAB015/dotfiles.git}"
    
    # Configuration paths
    export SETUP_CONFIG="${SETUP_CONFIG:-$HOME/.config/dotmarchy/setup.conf}"
    export ERROR_LOG="${ERROR_LOG:-$HOME/.local/share/dotmarchy/install_errors.log}"
    mkdir -p "$(dirname "$ERROR_LOG")" 2>/dev/null || true
    
    # Operational flags
    export DRY_RUN="${DRY_RUN:-0}"
    export FORCE="${FORCE:-0}"
    export VERBOSE="${VERBOSE:-0}"
    export INSTALL_EXTRAS="${INSTALL_EXTRAS:-0}"
    export SETUP_ENVIRONMENT="${SETUP_ENVIRONMENT:-0}"
    export SKIP_SYSTEM="${SKIP_SYSTEM:-0}"
    export VERIFY_MODE="${VERIFY_MODE:-0}"
    
    # Core dependencies
    # Note: git-delta and diff-so-fancy moved to extras (platform-specific)
    export CORE_DEPENDENCIES="zsh tree bat highlight ruby-coderay npm"
    
    # Installation statistics
    export INSTALL_START_TIME="${INSTALL_START_TIME:-$(date +%s)}"
    export PACKAGES_INSTALLED="${PACKAGES_INSTALLED:-0}"
    export PACKAGES_SKIPPED="${PACKAGES_SKIPPED:-0}"
fi

# Clean up internal variables
unset _SET_VAR_DIR _CONFIG_DIR
