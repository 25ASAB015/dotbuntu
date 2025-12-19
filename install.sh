#!/usr/bin/env bash
#######################################
# install.sh - Unified NIX + dotbare installer
#
# Orchestrates the complete setup:
# 1. Install NIX package manager
# 2. Configure dotbare for dotfiles
# 3. Sync packages from packages.nix
#
# Usage:
#   ./install.sh [--non-interactive] [--nix] [--repo URL]
#
# Returns:
#   0 - Setup completed successfully
#   1 - Setup failed
#######################################

set -Eeuo pipefail

# Determine script directory
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly HELPER_DIR="${SCRIPT_DIR}/helper"

# Source required helpers
# shellcheck source=/dev/null
source "${HELPER_DIR}/load_helpers.sh"
load_helpers "${HELPER_DIR}" colors logger prompts nix-helpers

# Default settings
INSTALL_NIX="${INSTALL_NIX:-1}"
INSTALL_DOTBARE="${INSTALL_DOTBARE:-1}"
SYNC_PACKAGES="${SYNC_PACKAGES:-1}"
INTERACTIVE="${INTERACTIVE:-1}"

#######################################
# Display usage information
#######################################
usage() {
    cat <<EOF
Usage: install.sh [OPTIONS]

Unified installer for NIX package manager and dotbare dotfiles management.

Options:
  --non-interactive   Run without user prompts (use defaults)
  --nix               Install NIX package manager
  --no-nix            Skip NIX installation
  --dotbare           Configure dotbare dotfiles
  --no-dotbare        Skip dotbare configuration  
  --repo URL          Override dotfiles repository URL
  -h, --help          Show this help message

Examples:
  ./install.sh                          # Interactive full setup
  ./install.sh --nix --no-dotbare       # Only NIX installation
  ./install.sh --non-interactive        # Automated setup
  ./install.sh --repo git@github.com:user/dotfiles.git
EOF
}

#######################################
# Parse command-line arguments
#######################################
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --non-interactive)
                INTERACTIVE=0
                shift
                ;;
            --nix)
                INSTALL_NIX=1
                shift
                ;;
            --no-nix)
                INSTALL_NIX=0
                shift
                ;;
            --dotbare)
                INSTALL_DOTBARE=1
                shift
                ;;
            --no-dotbare)
                INSTALL_DOTBARE=0
                shift
                ;;
            --repo)
                [[ -z "${2:-}" ]] && { error "Option --repo requires an argument"; exit 2; }
                export REPO_URL="$2"
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
}

#######################################
# Display welcome banner
#######################################
show_welcome() {
    clear 2>/dev/null || true
    logo "Dotmarchy Unified Installer"
    echo ""
    printf "%b\n" "${BLD}${CBL}Complete development environment setup${CNC}"
    echo ""
    printf "%b\n" "  ${CGR}•${CNC} NIX package manager (reproducible packages)"
    printf "%b\n" "  ${CGR}•${CNC} dotbare dotfiles management (Git-based)"
    printf "%b\n" "  ${CGR}•${CNC} Automatic package synchronization"
    echo ""
    sleep 2
}

#######################################
# Ask what to install (interactive mode)
#######################################
ask_installation_options() {
    [[ "$INTERACTIVE" -eq 0 ]] && return 0
    
    echo ""
    if ask_yes_no "Install NIX package manager?" "y"; then
        INSTALL_NIX=1
    else
        INSTALL_NIX=0
    fi
    
    if ask_yes_no "Configure dotbare for dotfiles management?" "y"; then
        INSTALL_DOTBARE=1
    else
        INSTALL_DOTBARE=0
    fi
    
    if [[ "$INSTALL_NIX" -eq 1 ]] && ask_yes_no "Sync packages from packages.nix after setup?" "y"; then
        SYNC_PACKAGES=1
    else
        SYNC_PACKAGES=0
    fi
}

#######################################
# Install NIX package manager
#######################################
install_nix_step() {
    [[ "$INSTALL_NIX" -eq 0 ]] && return 0
    
    echo ""
    printf "%b\n" "${BLD}${CYE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CNC}"
    printf "%b\n" "${BLD}${CYE}  Step 1/3: NIX Package Manager${CNC}"
    printf "%b\n" "${BLD}${CYE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CNC}"
    echo ""
    
    if nix_is_installed; then
        local version
        version=$(nix_get_version)
        success "NIX already installed: $version"
        return 0
    fi
    
    info "Installing NIX package manager..."
    "${SCRIPT_DIR}/scripts/bootstrap-nix.sh" || {
        error "NIX installation failed"
        return 1
    }
    
    success "NIX installed successfully"
}

#######################################
# Configure dotbare
#######################################
configure_dotbare_step() {
    [[ "$INSTALL_DOTBARE" -eq 0 ]] && return 0
    
    echo ""
    printf "%b\n" "${BLD}${CYE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CNC}"
    printf "%b\n" "${BLD}${CYE}  Step 2/3: Dotbare Dotfiles Management${CNC}"
    printf "%b\n" "${BLD}${CYE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CNC}"
    echo ""
    
    info "Configuring dotbare for dotfiles..."
    "${SCRIPT_DIR}/scripts/core/fdotbare" || {
        error "Dotbare configuration failed"
        return 1
    }
    
    success "Dotbare configured successfully"
}

#######################################
# Sync packages from packages.nix
#######################################
sync_packages_step() {
    [[ "$SYNC_PACKAGES" -eq 0 ]] && return 0
    [[ "$INSTALL_NIX" -eq 0 ]] && return 0
    
    echo ""
    printf "%b\n" "${BLD}${CYE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CNC}"
    printf "%b\n" "${BLD}${CYE}  Step 3/3: Package Synchronization${CNC}"
    printf "%b\n" "${BLD}${CYE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CNC}"
    echo ""
    
    local packages_nix="$HOME/.config/dotmarchy/packages.nix"
    
    # Check if packages.nix exists
    if [[ ! -f "$packages_nix" ]]; then
        # Copy template from repo
        if [[ -f "${SCRIPT_DIR}/packages.nix" ]]; then
            info "Creating packages.nix from template..."
            mkdir -p "$(dirname "$packages_nix")"
            cp "${SCRIPT_DIR}/packages.nix" "$packages_nix"
        else
            warn "No packages.nix found. Skipping package sync."
            info "Create one at: $packages_nix"
            return 0
        fi
    fi
    
    info "Syncing packages from packages.nix..."
    "${SCRIPT_DIR}/scripts/sync-packages.sh" || {
        warn "Some packages may not have installed correctly"
        return 0  # Non-fatal
    }
    
    success "Packages synchronized successfully"
}

#######################################
# Display completion summary
#######################################
show_completion_summary() {
    echo ""
    printf "%b\n" "${BLD}${CGR}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CNC}"
    printf "%b\n" "${BLD}${CGR}  Installation Complete!${CNC}"
    printf "%b\n" "${BLD}${CGR}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CNC}"
    echo ""
    
    if [[ "$INSTALL_NIX" -eq 1 ]]; then
        printf "%b\n" "  ${CGR}✓${CNC} NIX package manager installed"
    fi
    
    if [[ "$INSTALL_DOTBARE" -eq 1 ]]; then
        printf "%b\n" "  ${CGR}✓${CNC} Dotbare dotfiles configured"
    fi
    
    if [[ "$SYNC_PACKAGES" -eq 1 ]]; then
        printf "%b\n" "  ${CGR}✓${CNC} Packages synchronized"
    fi
    
    echo""
    printf "%b\n" "${BLD}${CBL}Next steps:${CNC}"
    echo ""
    
    if [[ "$INSTALL_DOTBARE" -eq 1 ]]; then
        printf "%b\n" "  1. Add files to dotbare: ${CGR}dotbare add <file>${CNC}"
        printf "%b\n" "  2. Commit changes: ${CGR}dotbare commit -m \"message\"${CNC}"
        printf "%b\n" "  3. Push to remote: ${CGR}dotbare push${CNC}"
    fi
    
    if [[ "$INSTALL_NIX" -eq 1 ]]; then
        printf "%b\n" "  4. Edit packages: ${CGR}vim ~/.config/dotmarchy/packages.nix${CNC}"
        printf "%b\n" "  5. Sync packages: ${CGR}./scripts/sync-packages.sh${CNC}"
    fi
    
    echo ""
    printf "%b\n" "${BLD}${CYE}Documentation: ${CBL}docs/NIX_SETUP.md${CNC}"
    echo ""
}

#######################################
# Main installation function
#######################################
main() {
    parse_arguments "$@"
    show_welcome
    ask_installation_options
    
    # Execute installation steps
    install_nix_step || {
        error "Installation failed at NIX step"
        return 1
    }
    
    configure_dotbare_step || {
        error "Installation failed at dotbare step"
        return 1
    }
    
    sync_packages_step || {
        warn "Package sync had issues (non-fatal)"
    }
    
    show_completion_summary
    success "Setup completed successfully!"
}

# Execute only if invoked directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
