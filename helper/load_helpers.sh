#!/usr/bin/env bash
# shellcheck shell=bash
#
# load_helpers.sh - Centralized helper module loader
#
# Provides functions to dynamically load helper modules in the correct order,
# avoiding duplicate sourcing and ensuring dependencies are satisfied.
#
# @author: dotbuntu
# @version: 2.0.0

# Idempotent guard - prevent redefinition when sourced multiple times
if declare -f load_helpers >/dev/null 2>&1; then
    return 0 2>/dev/null || exit 0
fi

#######################################
# Default helper loading order
#
# This order ensures dependencies are satisfied:
# 1. set_variable - Global configuration (no dependencies)
# 2. colors - Color definitions (no dependencies)
# 3. logger - Logging functions (depends on colors)
# 4. prompts - User interaction (depends on colors, logger)
# 5. checks - System validation (depends on colors, logger)
# 6. utils - Utility functions (depends on all above)
#######################################
readonly DEFAULT_HELPER_ORDER=(set_variable colors logger prompts checks utils)
readonly CORE_HELPERS=("${DEFAULT_HELPER_ORDER[@]}")
readonly EXTRAS_HELPERS=("${DEFAULT_HELPER_ORDER[@]}")

#######################################
# Display loader error message
#
# Internal function to output error messages consistently,
# using log_error if available or falling back to stderr.
#
# Arguments:
#   $1 - Error message to display
#
# Outputs:
#   STDERR - Error message
#######################################
_loader_error() {
    local msg="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "$msg"
    else
        printf "ERROR: %s\n" "$msg" >&2
    fi
}

#######################################
# Load helper modules dynamically
#
# Sources helper modules from the specified directory in the given order.
# If no helpers are specified, loads the default set in dependency order.
#
# Globals:
#   DEFAULT_HELPER_ORDER - Default helpers to load if none specified
#
# Arguments:
#   $1 - Helper directory path (required)
#   $@ - Helper names to load (optional, defaults to DEFAULT_HELPER_ORDER)
#
# Returns:
#   0 - All helpers loaded successfully
#   1 - Helper directory not found or helper failed to load
#
# Outputs:
#   STDERR - Error messages via _loader_error
#
# Example:
#   source "${SCRIPT_DIR}/helper/load_helpers.sh"
#   load_helpers "${SCRIPT_DIR}/helper" colors logger utils
#######################################
load_helpers() {
    local helper_dir="${1:-}"
    shift || true

    if [[ -z "$helper_dir" ]]; then
        _loader_error "Helper directory is required"
        return 1
    fi

    if [[ ! -d "$helper_dir" ]]; then
        _loader_error "Helper directory not found: $helper_dir"
        return 1
    fi

    local helpers=("$@")
    if [[ ${#helpers[@]} -eq 0 ]]; then
        helpers=("${DEFAULT_HELPER_ORDER[@]}")
    fi

    local helper_path
    local helper
    for helper in "${helpers[@]}"; do
        helper_path="${helper_dir%/}/${helper}.sh"
        if [[ ! -f "$helper_path" ]]; then
            _loader_error "Cannot load ${helper}.sh from ${helper_dir}"
            return 1
        fi
        # shellcheck source=/dev/null
        if ! source "$helper_path"; then
            _loader_error "Failed to source ${helper}.sh"
            return 1
        fi
    done
}

#######################################
# Load core helper set
#
# Convenience function to load the standard set of helpers
# needed for core operations.
#
# Arguments:
#   $1 - Helper directory path (required)
#   $@ - Additional helpers to load after core set (optional)
#
# Returns:
#   0 - Success
#   1 - Failure
#######################################
load_core_helpers() {
    local helper_dir="${1:-}"
    shift || true
    load_helpers "$helper_dir" "${CORE_HELPERS[@]}" "$@"
}

#######################################
# Load extras helper set
#
# Convenience function to load helpers needed for
# extras operations (same as core for now).
#
# Arguments:
#   $1 - Helper directory path (required)
#   $@ - Additional helpers to load after extras set (optional)
#
# Returns:
#   0 - Success
#   1 - Failure
#######################################
load_extras_helpers() {
    local helper_dir="${1:-}"
    shift || true
    load_helpers "$helper_dir" "${EXTRAS_HELPERS[@]}" "$@"
}
