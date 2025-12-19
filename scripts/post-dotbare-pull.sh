#!/usr/bin/env bash
#######################################
# post-dotbare-pull.sh - Post-pull hook for dotbare
#
# Automatically detects changes to packages.nix after dotbare pull
# and offers to sync packages. Can run in automatic mode with --auto-sync.
# Designed to be called by dotbare or manually after pulling dotfiles.
#
# Usage:
#   ./post-dotbare-pull.sh [--auto-sync]
#
# Globals:
#   SCRIPT_DIR - Directory containing this script
#   HELPER_DIR - Path to helper modules
#   HOME - User's home directory
#   AUTO_SYNC - Environment variable for automatic sync (0=ask, 1=auto)
#
# Arguments:
#   --auto-sync - Automatically sync packages without prompting
#
# Returns:
#   0 - Hook executed successfully (sync or skip)
#   1 - Hook execution failed
#
# Outputs:
#   STDOUT - Status messages and sync progress
#   STDERR - Error messages
#######################################

set -Eeuo pipefail

# Determine script directory
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly HELPER_DIR="${SCRIPT_DIR}/../helper"

# Source required helpers
# shellcheck source=/dev/null
source "${HELPER_DIR}/load_helpers.sh"
load_helpers "${HELPER_DIR}" colors logger prompts nix-helpers

# Parse command-line arguments
AUTO_SYNC="${AUTO_SYNC:-0}"
for arg in "$@"; do
    case "$arg" in
        --auto-sync)
            AUTO_SYNC=1
            shift
            ;;
    esac
done

#######################################
# Detect if packages.nix was modified in last pull
#
# Checks git log to determine if packages.nix changed in the most
# recent pull operation. Looks in standard locations.
#
# Globals:
#   HOME - User's home directory
#   DOTBARE_DIR - Dotbare repository location
#
# Arguments:
#   None
#
# Returns:
#   0 - packages.nix was modified
#   1 - packages.nix was not modified or git check failed
#
# Outputs:
#   None
#######################################
packages_nix_modified() {
    local dotbare_dir="${DOTBARE_DIR:-$HOME/.cfg}"
    local packages_nix_path=".config/dotmarchy/packages.nix"
    
    # Check if dotbare repo exists
    if [[ ! -d "$dotbare_dir" ]]; then
        return 1
    fi
    
    # Check if packages.nix was modified in last pull (HEAD vs HEAD@{1})
    if git --git-dir="$dotbare_dir" --work-tree="$HOME" diff --name-only HEAD@{1} HEAD 2>/dev/null | grep -q "$packages_nix_path"; then
        return 0
    fi
    
    return 1
}

#######################################
# Show packages.nix diff
#
# Displays the differences in packages.nix between previous and
# current version to help user review changes before syncing.
#
# Globals:
#   HOME - User's home directory
#   DOTBARE_DIR - Dotbare repository location
#
# Arguments:
#   None
#
# Returns:
#   0 - Diff displayed successfully
#   1 - Failed to show diff
#
# Outputs:
#   STDOUT - Colorized diff of packages.nix changes
#######################################
show_packages_diff() {
    local dotbare_dir="${DOTBARE_DIR:-$HOME/.cfg}"
    local packages_nix_path=".config/dotmarchy/packages.nix"
    
    info "Cambios detectados en packages.nix:"
    echo ""
    
    if command -v diff-so-fancy &>/dev/null; then
        git --git-dir="$dotbare_dir" --work-tree="$HOME" diff HEAD@{1} HEAD -- "$packages_nix_path" 2>/dev/null | diff-so-fancy
    elif command -v delta &>/dev/null; then
        git --git-dir="$dotbare_dir" --work-tree="$HOME" diff HEAD@{1} HEAD -- "$packages_nix_path" 2>/dev/null | delta
    else
        git --git-dir="$dotbare_dir" --work-tree="$HOME" diff HEAD@{1} HEAD -- "$packages_nix_path" 2>/dev/null
    fi
    
    echo ""
}

#######################################
# Execute package synchronization
#
# Runs sync-packages.sh to apply changes from packages.nix.
# Handles both success and failure cases with appropriate messaging.
#
# Globals:
#   SCRIPT_DIR - Used to locate sync-packages.sh
#
# Arguments:
#   None
#
# Returns:
#   0 - Sync completed successfully
#   1 - Sync failed
#
# Outputs:
#   STDOUT - Sync progress and results
#   STDERR - Error messages
#######################################
sync_packages() {
    info "Sincronizando paquetes desde packages.nix..."
    echo ""
    
    if "${SCRIPT_DIR}/sync-packages.sh"; then
        success "Paquetes sincronizados exitosamente"
        return 0
    else
        error "Falló la sincronización de paquetes"
        info "Puedes intentar manualmente: ./scripts/sync-packages.sh"
        return 1
    fi
}

#######################################
# Main hook execution function
#
# Orchestrates the post-pull workflow:
# 1. Check if NIX is installed (skip if not)
# 2. Detect packages.nix modifications
# 3. Show diff of changes
# 4. Ask user or auto-sync (based on --auto-sync flag)
# 5. Execute sync if approved
#
# Globals:
#   AUTO_SYNC - Automatic sync flag
#
# Arguments:
#   None
#
# Returns:
#   0 - Hook completed successfully
#   1 - Hook failed
#
# Outputs:
#   STDOUT - Hook progress and user prompts
#   STDERR - Error messages
#######################################
main() {
    # Check if NIX is installed
    if ! nix_is_installed; then
        # Silent exit if NIX not installed (not an error)
        return 0
    fi
    
    # Check if packages.nix was modified
    if ! packages_nix_modified; then
        # No changes, nothing to do
        return 0
    fi
    
    # Show banner
    echo ""
    info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    info "  Cambios detectados en packages.nix"
    info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Show diff
    show_packages_diff
    
    # Decide whether to sync
    local should_sync=0
    
    if [[ "$AUTO_SYNC" -eq 1 ]]; then
        info "Modo automático activado (--auto-sync)"
        should_sync=1
    else
        if ask_yes_no "¿Deseas sincronizar los paquetes ahora?" "y"; then
            should_sync=1
        fi
    fi
    
    # Execute sync if approved
    if [[ "$should_sync" -eq 1 ]]; then
        sync_packages
        return $?
    else
        info "Sincronización omitida"
        info "Para sincronizar manualmente más tarde, ejecuta:"
        echo "  ./scripts/sync-packages.sh"
        return 0
    fi
}

# Execute only if invoked directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

