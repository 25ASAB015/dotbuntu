#!/usr/bin/env bash
#######################################
# sync-packages.sh - Apply packages.nix configuration
#
# Idempotent script to install packages defined in packages.nix.
# Searches for packages.nix in multiple locations.
#
# Usage:
#   ./sync-packages.sh
#
# Returns:
#   0 - Packages synced successfully
#   1 - Sync failed or NIX not installed
#######################################

set -Eeuo pipefail

# Determine script directory
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly HELPER_DIR="${SCRIPT_DIR}/../helper"

# Source required helpers
# shellcheck source=/dev/null
source "${HELPER_DIR}/load_helpers.sh"
load_helpers "${HELPER_DIR}" colors logger nix-helpers

# Ensure ERROR_LOG is set
: "${ERROR_LOG:=$HOME/.local/share/dotmarchy/install_errors.log}"
export ERROR_LOG

#######################################
# Locate packages.nix file
# Returns: path to packages.nix or exits if not found
#######################################
find_packages_nix() {
    local locations=(
        "$HOME/.config/dotmarchy/packages.nix"
        "${SCRIPT_DIR}/../packages.nix"
        "$HOME/.dotfiles/packages.nix"
        "./packages.nix"
    )
    
    for loc in "${locations[@]}"; do
        if [[ -f "$loc" ]]; then
            echo "$loc"
            return 0
        fi
    done
    
    error "No se encontró packages.nix en las ubicaciones esperadas:"
    for loc in "${locations[@]}"; do
        echo "  - $loc"
    done
    return 1
}

#######################################
# Sync packages from packages.nix
#######################################
sync_packages() {
    local packages_file
    packages_file=$(find_packages_nix) || return 1
    
    info "Usando configuración: $packages_file"
    
    # Check NIX is installed
    if ! nix_is_installed; then
        error "NIX no está instalado. Ejecuta bootstrap-nix.sh primero"
        return 1
    fi
    
    local nix_version
    nix_version=$(nix_get_version)
    info "NIX version: $nix_version"
    
    # Install packages
    info "Sincronizando paquetes (esto puede tardar unos minutos)..."
    printf "%b\n" "${BLD}${CYE}Instalando paquetes desde $packages_file${CNC}"
    
    local install_output
    local install_status=0
    
    # Run nix-env to install packages
    install_output=$(nix-env -iA myPackages -f "$packages_file" 2>&1) || install_status=$?
    
    # Log output
    echo "$install_output" | tee -a "$ERROR_LOG" >/dev/null
    
    if [[ $install_status -eq 0 ]]; then
        success "Paquetes sincronizados exitosamente"
        
        # Count installed packages
        local pkg_count
        pkg_count=$(nix-env -q | wc -l)
        info "Total de paquetes en el perfil: $pkg_count"
        
        return 0
    else
        error "Error al sincronizar paquetes"
        warn "Últimas líneas del error:"
        echo "$install_output" | tail -5 | while IFS= read -r line; do
            printf "  %b\n" "${CRE}$line${CNC}"
        done || true
        
        return 1
    fi
}

#######################################
# Main function
#######################################
main() {
    clear 2>/dev/null || true
    logo "Sincronizar Paquetes NIX"
    sleep 1
    
    sync_packages || {
        error "Fallo la sincronización de paquetes"
        info "Revisa el log: $ERROR_LOG"
        return 1
    }
    
    echo ""
    success "¡Sincronización completada!"
    info "Tip: Ejecuta 'nix-env -q' para ver los paquetes instalados"
}

# Execute only if invoked directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
