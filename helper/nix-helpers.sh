#!/usr/bin/env bash
#######################################
# nix-helpers.sh - NIX utility functions
#
# Provides reusable helper functions for NIX package management operations
# including installation checks, version queries, package management,
# cleanup, and search capabilities.
#
# Usage:
#   source helper/nix-helpers.sh
#   if nix_is_installed; then
#       nix_cleanup
#   fi
#
# Globals:
#   HOME - User's home directory
#
# Returns:
#   N/A - This file is sourced, not executed
#######################################

# Prevent double sourcing
[[ -n "${_NIX_HELPERS_SOURCED:-}" ]] && return 0
declare -r _NIX_HELPERS_SOURCED=1

#######################################
# Check if NIX is installed
#
# Verifies that the nix-env command is available in PATH.
# This is the primary NIX package management tool.
#
# Globals:
#   None
#
# Arguments:
#   None
#
# Returns:
#   0 - NIX is installed and available
#   1 - NIX is not installed
#
# Outputs:
#   None
#######################################
nix_is_installed() {
    command -v nix-env &>/dev/null
}

#######################################
# Get installed NIX version
#
# Retrieves and formats the currently installed NIX version string.
# Returns empty string if NIX is not installed.
#
# Globals:
#   None
#
# Arguments:
#   None
#
# Returns:
#   0 - Version retrieved successfully
#   1 - NIX not installed or version command failed
#
# Outputs:
#   STDOUT - NIX version string (e.g., "nix-env (Nix) 2.18.0")
#######################################
nix_get_version() {
    if ! nix_is_installed; then
        return 1
    fi
    
    nix-env --version 2>/dev/null | head -n1
}

#######################################
# Check if a specific NIX package is installed
#
# Queries the NIX profile to determine if a package with the given
# name is currently installed in the user's environment.
#
# Globals:
#   None
#
# Arguments:
#   $1 - Package name to check (required)
#
# Returns:
#   0 - Package is installed
#   1 - Package is not installed or NIX unavailable
#
# Outputs:
#   None
#######################################
nix_package_installed() {
    local package_name="$1"
    
    if [[ -z "$package_name" ]]; then
        return 1
    fi
    
    if ! nix_is_installed; then
        return 1
    fi
    
    nix-env -q | grep -q "^${package_name}" 2>/dev/null
}

#######################################
# Perform NIX garbage collection
#
# Removes old generations and unused packages from the NIX store
# to reclaim disk space. Optionally deletes all old generations.
#
# Globals:
#   None
#
# Arguments:
#   $1 - Optional: "-d" or "--delete-old" to remove all old generations
#
# Returns:
#   0 - Cleanup completed successfully
#   1 - Cleanup failed or NIX not installed
#
# Outputs:
#   STDOUT - Cleanup progress and space reclaimed
#   STDERR - Error messages
#######################################
nix_cleanup() {
    if ! nix_is_installed; then
        echo "ERROR: NIX no está instalado" >&2
        return 1
    fi
    
    local delete_old=""
    if [[ "${1:-}" == "-d" ]] || [[ "${1:-}" == "--delete-old" ]]; then
        delete_old="-d"
    fi
    
    echo "Ejecutando garbage collection de NIX..."
    
    if nix-collect-garbage $delete_old 2>&1; then
        echo "Limpieza de NIX completada"
        return 0
    else
        echo "ERROR: Falló la limpieza de NIX" >&2
        return 1
    fi
}

#######################################
# Source NIX profile into current shell
#
# Loads NIX environment variables by sourcing the appropriate profile
# script. Attempts both multi-user (daemon) and single-user locations.
#
# Globals:
#   HOME - User's home directory
#
# Arguments:
#   None
#
# Returns:
#   0 - Profile sourced successfully
#   1 - Profile script not found
#
# Outputs:
#   None
#######################################
nix_source_profile() {
    local daemon_profile="/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
    local user_profile="$HOME/.nix-profile/etc/profile.d/nix.sh"
    
    if [[ -f "$daemon_profile" ]]; then
        # shellcheck source=/dev/null
        source "$daemon_profile"
        return 0
    elif [[ -f "$user_profile" ]]; then
        # shellcheck source=/dev/null
        source "$user_profile"
        return 0
    fi
    
    return 1
}

#######################################
# List all installed NIX packages
#
# Displays a list of packages currently installed in the user's
# NIX profile, one per line.
#
# Globals:
#   None
#
# Arguments:
#   None
#
# Returns:
#   0 - List retrieved successfully
#   1 - NIX not installed or query failed
#
# Outputs:
#   STDOUT - Package names, one per line
#   STDERR - Error messages
#######################################
nix_list_packages() {
    if ! nix_is_installed; then
        echo "ERROR: NIX no está instalado" >&2
        return 1
    fi
    
    nix-env -q 2>/dev/null || {
        echo "ERROR: Falló al listar paquetes NIX" >&2
        return 1
    }
}

#######################################
# Search for packages in nixpkgs
#
# Queries the nixpkgs repository for packages matching the given
# search term. Requires flakes to be enabled.
#
# Globals:
#   None
#
# Arguments:
#   $1 - Search query (required)
#
# Returns:
#   0 - Search completed successfully
#   1 - Search failed or NIX not installed
#
# Outputs:
#   STDOUT - Matching packages with descriptions
#   STDERR - Error messages
#######################################
nix_search() {
    local query="$1"
    
    if [[ -z "$query" ]]; then
        echo "ERROR: Se requiere un término de búsqueda" >&2
        echo "Uso: nix_search <paquete>" >&2
        return 1
    fi
    
    if ! nix_is_installed; then
        echo "ERROR: NIX no está instalado" >&2
        return 1
    fi
    
    echo "Buscando '$query' en nixpkgs..."
    
    if nix search nixpkgs "$query" 2>/dev/null; then
        return 0
    else
        echo "ERROR: Falló la búsqueda (asegúrate de que flakes esté habilitado)" >&2
        return 1
    fi
}

#######################################
# Get NIX store disk usage
#
# Calculates and displays the total disk space used by /nix/store.
#
# Globals:
#   None
#
# Arguments:
#   None
#
# Returns:
#   0 - Usage retrieved successfully
#   1 - /nix/store not found or du command failed
#
# Outputs:
#   STDOUT - Disk usage in human-readable format (e.g., "5.2G")
#   STDERR - Error messages
#######################################
nix_store_usage() {
    if [[ ! -d "/nix/store" ]]; then
        echo "ERROR: /nix/store no existe" >&2
        return 1
    fi
    
    du -sh /nix/store 2>/dev/null | awk '{print $1}' || {
        echo "ERROR: Falló al calcular uso de disco" >&2
        return 1
    }
}

#######################################
# Rollback to previous NIX generation
#
# Reverts the user's NIX profile to the previous generation,
# undoing the most recent package installation/removal operation.
#
# Globals:
#   None
#
# Arguments:
#   None
#
# Returns:
#   0 - Rollback successful
#   1 - Rollback failed or NIX not installed
#
# Outputs:
#   STDOUT - Rollback confirmation
#   STDERR - Error messages
#######################################
nix_rollback() {
    if ! nix_is_installed; then
        echo "ERROR: NIX no está instalado" >&2
        return 1
    fi
    
    echo "Revirtiendo a la generación anterior de NIX..."
    
    if nix-env --rollback 2>&1; then
        echo "Rollback completado exitosamente"
        return 0
    else
        echo "ERROR: Falló el rollback" >&2
        return 1
    fi
}

#######################################
# List NIX profile generations
#
# Displays a list of all available profile generations with
# their creation dates and active status.
#
# Globals:
#   None
#
# Arguments:
#   None
#
# Returns:
#   0 - List retrieved successfully
#   1 - NIX not installed or command failed
#
# Outputs:
#   STDOUT - Generation list with timestamps
#   STDERR - Error messages
#######################################
nix_list_generations() {
    if ! nix_is_installed; then
        echo "ERROR: NIX no está instalado" >&2
        return 1
    fi
    
    nix-env --list-generations 2>/dev/null || {
        echo "ERROR: Falló al listar generaciones" >&2
        return 1
    }
}
