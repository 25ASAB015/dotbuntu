#!/usr/bin/env bash
#######################################
# sync-packages.sh - Synchronize NIX packages from packages.nix
#
# Idempotently applies package configuration from packages.nix file.
# Searches multiple locations, verifies NIX installation, executes
# package installation, and reports results.
#
# Usage:
#   ./sync-packages.sh
#
# Globals:
#   SCRIPT_DIR - Directory containing this script
#   HELPER_DIR - Path to helper modules
#   ERROR_LOG - Path to error log file
#   DOTMARCHY_ERROR_LOG - Alternative error log path
#
# Returns:
#   0 - Packages synchronized successfully
#   1 - Synchronization failed
#######################################

set -Eeuo pipefail

# Determine script directory
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly HELPER_DIR="${SCRIPT_DIR}/../helper"

# Source required helpers
# shellcheck source=/dev/null
source "${HELPER_DIR}/load_helpers.sh"
load_helpers "${HELPER_DIR}" colors logger nix-helpers

# Error log fallback
: "${ERROR_LOG:=$HOME/.local/share/dotmarchy/install_errors.log}"
: "${DOTMARCHY_ERROR_LOG:=$ERROR_LOG}"
export ERROR_LOG DOTMARCHY_ERROR_LOG

#######################################
# Find packages.nix configuration file
#
# Searches for packages.nix in multiple standard locations in priority order:
# 1. ~/.config/dotmarchy/packages.nix (user config)
# 2. ~/dotbuntu/packages.nix (repo root)
# 3. Current script directory/../packages.nix (repo template)
#
# Globals:
#   HOME - User's home directory
#   SCRIPT_DIR - Script installation directory
#
# Arguments:
#   None
#
# Returns:
#   0 - packages.nix found
#   1 - packages.nix not found in any location
#
# Outputs:
#   STDOUT - Absolute path to packages.nix file
#   STDERR - Error message if not found
#######################################
find_packages_nix() {
    local search_paths=(
        "$HOME/.config/dotmarchy/packages.nix"
        "$HOME/dotbuntu/packages.nix"
        "${SCRIPT_DIR}/../packages.nix"
    )
    
    for path in "${search_paths[@]}"; do
        if [[ -f "$path" ]]; then
            echo "$path"
            return 0
        fi
    done
    
    echo "ERROR: packages.nix no encontrado en ninguna ubicación estándar" >&2
    echo "Ubicaciones buscadas:" >&2
    printf "  - %s\n" "${search_paths[@]}" >&2
    return 1
}

#######################################
# Verify NIX installation and readiness
#
# Checks that NIX is installed, available in PATH, and the NIX store
# is accessible. Provides specific error messages for each failure case.
#
# Globals:
#   None
#
# Arguments:
#   None
#
# Returns:
#   0 - NIX is installed and ready
#   1 - NIX not available or not functional
#
# Outputs:
#   STDOUT - Verification progress messages
#   STDERR - Specific error messages
#######################################
verify_nix_installed() {
    if ! command -v nix-env &>/dev/null; then
        echo "ERROR: nix-env no encontrado en PATH" >&2
        echo "Instala NIX primero ejecutando: ./scripts/bootstrap-nix.sh" >&2
        return 1
    fi
    
    if [[ ! -d "/nix/store" ]]; then
        echo "ERROR: /nix/store no existe (instalación NIX incompleta)" >&2
        return 1
    fi
    
    if ! nix-env --version &>/dev/null; then
        echo "ERROR: nix-env no responde correctamente" >&2
        return 1
    fi
    
    return 0
}

#######################################
# Count packages in packages.nix
#
# Parses the packages.nix file and counts the number of package
# entries in the paths array. Used for progress reporting.
#
# Globals:
#   None
#
# Arguments:
#   $1 - Path to packages.nix file (required)
#
# Returns:
#   0 - Count retrieved successfully
#   1 - File not readable or parse error
#
# Outputs:
#   STDOUT - Number of packages (integer)
#   STDERR - Error messages
#######################################
count_packages() {
    local packages_file="$1"
    
    if [[ ! -f "$packages_file" ]]; then
        echo "0"
        return 1
    fi
    
    # Count non-comment, non-empty lines in paths array
    local count
    count=$(grep -v '^[[:space:]]*#' "$packages_file" | \
            grep -v '^[[:space:]]*$' | \
            grep -c '[a-zA-Z]' || echo "0")
    
    echo "$count"
}

#######################################
# Synchronize packages from packages.nix
#
# Main synchronization function that:
# 1. Validates packages.nix exists
# 2. Verifies NIX installation
# 3. Backs up error log (if needed)
# 4. Executes nix-env installation
# 5. Reports results and statistics
#
# Globals:
#   ERROR_LOG - Path to error log file
#
# Arguments:
#   $1 - Path to packages.nix file (required)
#
# Returns:
#   0 - Synchronization successful
#   1 - Synchronization failed
#
# Outputs:
#   STDOUT - Synchronization progress and results
#   STDERR - Error messages (also logged to ERROR_LOG)
#######################################
sync_packages() {
    local packages_nix_path="$1"
    
    if [[ ! -f "$packages_nix_path" ]]; then
        echo "ERROR: packages.nix no existe en: $packages_nix_path" >&2
        return 1
    fi
    
    info "Sincronizando paquetes desde: $packages_nix_path"
    
    # Count packages for reporting
    local package_count
    package_count=$(count_packages "$packages_nix_path")
    info "Configuración contiene aproximadamente $package_count paquetes"
    
    # Ensure error log directory exists
    local log_dir
    log_dir=$(dirname "$ERROR_LOG")
    if ! mkdir -p "$log_dir" 2>/dev/null; then
        warn "No se pudo crear directorio de logs: $log_dir"
    fi
    
    # Execute NIX package installation
    info "Ejecutando nix-env -iA myPackages -f $packages_nix_path..."
    echo "Esto puede tardar varios minutos si hay paquetes nuevos..." 
    
    local start_time
    start_time=$(date +%s)
    
    if nix-env -iA myPackages -f "$packages_nix_path" 2>>"$ERROR_LOG"; then
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        success "Paquetes sincronizados exitosamente (${duration}s)"
        
        # Show installed package count
        local installed_count
        installed_count=$(nix-env -q | wc -l)
        info "Paquetes instalados en tu perfil NIX: $installed_count"
        
        return 0
    else
        error "Falló la sincronización de paquetes"
        error "Revisa el log de errores: $ERROR_LOG"
        
        # Show last few lines of error log
        if [[ -f "$ERROR_LOG" ]]; then
            echo "" >&2
            echo "Últimas líneas del log de errores:" >&2
            tail -n 10 "$ERROR_LOG" >&2
        fi
        
        return 1
    fi
}

#######################################
# Display post-sync instructions
#
# Shows helpful next steps after successful package synchronization,
# including how to verify installation, manage packages, and track
# changes in dotbare.
#
# Globals:
#   None
#
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#
# Outputs:
#   STDOUT - Instruction messages
#######################################
show_next_steps() {
    echo ""
    info "Próximos pasos:"
    echo "  1. Verifica paquetes instalados: nix-env -q"
    echo "  2. Añade más paquetes editando packages.nix"
    echo "  3. Versiona en dotbare: dotbare add ~/.config/dotmarchy/packages.nix"
    echo "  4. Si algo sale mal: nix-env --rollback"
    echo ""
    info "Documentación: docs/NIX_SETUP.md"
}

#######################################
# Main orchestration function
#
# Coordinates the entire package synchronization process:
# 1. Display welcome banner
# 2. Verify NIX installation
# 3. Locate packages.nix file
# 4. Synchronize packages
# 5. Display next steps
#
# Globals:
#   BLD, CBL, CNC - Color codes for terminal output
#
# Arguments:
#   None
#
# Returns:
#   0 - Synchronization completed successfully
#   1 - Synchronization failed at any step
#
# Outputs:
#   STDOUT - Progress messages and results
#   STDERR - Error messages
#######################################
main() {
    clear 2>/dev/null || true
    logo "NIX Package Synchronization"
    sleep 1
    
    echo ""
    info "Verificando instalación de NIX..."
    
    if ! verify_nix_installed; then
        error "NIX no está instalado o no funciona correctamente"
        return 1
    fi
    
    local nix_version
    nix_version=$(nix-env --version | head -n1)
    success "NIX disponible: $nix_version"
    
    echo ""
    info "Buscando packages.nix..."
    
    local packages_nix_path
    if ! packages_nix_path=$(find_packages_nix); then
        error "No se pudo localizar packages.nix"
info "Crea uno primero: cp packages.nix ~/.config/dotmarchy/"
        return 1
    fi
    
    success "Encontrado: $packages_nix_path"
    
    echo ""
    if ! sync_packages "$packages_nix_path"; then
        error "Falló la sincronización de paquetes"
        return 1
    fi
    
    show_next_steps
    
    success "¡Sincronización completada!"
    return 0
}

# Execute only if invoked directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
