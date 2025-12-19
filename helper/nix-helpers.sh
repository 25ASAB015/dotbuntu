#!/usr/bin/env bash
#==============================================================================
#                            NIX HELPERS
#==============================================================================
# @file nix-helpers.sh
# @brief Helper functions for NIX package manager operations
# @description
#   Utility functions for checking NIX installation, querying packages,
#   and performing common NIX operations.
#
# Functions:
#   nix_is_installed()       - Check if NIX is available
#   nix_get_version()        - Get NIX version string
#   nix_package_installed()  - Check if specific package is installed
#   nix_cleanup()            - Run garbage collection
#   nix_source_profile()     - Source NIX profile for current session
#==============================================================================

# Prevent double sourcing
[[ -n "${_NIX_HELPERS_SOURCED:-}" ]] && return 0
declare -r _NIX_HELPERS_SOURCED=1

#######################################
# Check if NIX package manager is installed
# Returns:
#   0 if NIX is installed, 1 otherwise
#######################################
nix_is_installed() {
    command -v nix-env &>/dev/null
}

#######################################
# Get NIX version
# Outputs:
#   NIX version string (e.g., "nix (Nix) 2.18.1")
# Returns:
#   0 on success, 1 if NIX not installed
#######################################
nix_get_version() {
    if ! nix_is_installed; then
        return 1
    fi
    nix-env --version 2>/dev/null | head -n1
}

#######################################
# Check if a specific package is installed via NIX
# Arguments:
#   $1 - Package name to check
# Returns:
#   0 if package is installed, 1 otherwise
#######################################
nix_package_installed() {
    local pkg_name="${1:-}"
    
    if [[ -z "$pkg_name" ]]; then
        return 1
    fi
    
    if ! nix_is_installed; then
        return 1
    fi
    
    nix-env -q | grep -q "^${pkg_name}" 2>/dev/null
}

#######################################
# Run NIX garbage collection
# Removes old generations and unused packages
# Returns:
#   0 on success, 1 on failure
#######################################
nix_cleanup() {
    if ! nix_is_installed; then
        echo "NIX no está instalado"
        return 1
    fi
    
    echo "Ejecutando garbage collection de NIX..."
    nix-collect-garbage -d
}

#######################################
# Source NIX profile to make commands available
# Useful when NIX was just installed or in fresh shells
# Returns:
#   0 if profile sourced, 1 if not found
#######################################
nix_source_profile() {
    # Multi-user installation (daemon)
    if [[ -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]]; then
        # shellcheck source=/dev/null
        source "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
        return 0
    fi
    
    # Single-user installation
    if [[ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]]; then
        # shellcheck source=/dev/null
        source "$HOME/.nix-profile/etc/profile.d/nix.sh"
        return 0
    fi
    
    return 1
}

#######################################
# List all NIX-installed packages
# Outputs:
#   List of installed package names
# Returns:
#   0 on success
#######################################
nix_list_packages() {
    if ! nix_is_installed; then
        echo "NIX no está instalado"
        return 1
    fi
    
    nix-env -q
}

#######################################
# Search for packages in nixpkgs
# Arguments:
#   $1 - Search term
# Returns:
#   0 on success
#######################################
nix_search() {
    local search_term="${1:-}"
    
    if [[ -z "$search_term" ]]; then
        echo "Uso: nix_search <término>"
        return 1
    fi
    
    if ! nix_is_installed; then
        echo "NIX no está instalado"
        return 1
    fi
    
    nix search nixpkgs "$search_term"
}
