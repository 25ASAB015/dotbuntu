#!/usr/bin/env bash
# shellcheck shell=bash
#
# Centralized helper loader to avoid duplicated sourcing blocks.
# Usage:
#   source "/path/to/helper/load_helpers.sh"
#   load_helpers "/path/to/helper" set_variable colors logger ...
#
# If no helpers are specified, the default order is used.

# Prevent redefinition when sourced multiple times
if declare -f load_helpers >/dev/null 2>&1; then
    return 0 2>/dev/null || exit 0
fi

DEFAULT_HELPER_ORDER=(set_variable colors logger prompts checks utils)
CORE_HELPERS=("${DEFAULT_HELPER_ORDER[@]}")
EXTRAS_HELPERS=("${DEFAULT_HELPER_ORDER[@]}")

_loader_error() {
    local msg="$1"
    if command -v log_error >/dev/null 2>&1; then
        log_error "$msg"
    else
        printf "ERROR: %s\n" "$msg" >&2
    fi
}

load_helpers() {
    local helper_dir="${1:-}"
    shift || true

    if [ -z "$helper_dir" ]; then
        _loader_error "Helper directory is required"
        return 1
    fi

    if [ ! -d "$helper_dir" ]; then
        _loader_error "Helper directory not found: $helper_dir"
        return 1
    fi

    local helpers=("$@")
    if [ ${#helpers[@]} -eq 0 ]; then
        helpers=("${DEFAULT_HELPER_ORDER[@]}")
    fi

    local helper_path
    local helper
    for helper in "${helpers[@]}"; do
        helper_path="${helper_dir%/}/${helper}.sh"
        if [ ! -f "$helper_path" ]; then
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

load_core_helpers() {
    local helper_dir="${1:-}"
    shift || true
    load_helpers "$helper_dir" "${CORE_HELPERS[@]}" "$@"
}

load_extras_helpers() {
    local helper_dir="${1:-}"
    shift || true
    load_helpers "$helper_dir" "${EXTRAS_HELPERS[@]}" "$@"
}
