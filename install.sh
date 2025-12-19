#!/usr/bin/env bash
#######################################
# install.sh - Unified NIX + dotbare installer
#
# Orchestrates the complete development environment setup by coordinating
# NIX package manager installation, dotbare dotfiles configuration, and
# packages.nix synchronization. Provides interactive and non-interactive modes.
#
# Usage:
#   ./install.sh [OPTIONS]
#
# Globals:
#   SCRIPT_DIR - Directory containing this script
#   HELPER_DIR - Path to helper modules
#   INSTALL_NIX - Flag to install NIX (0=skip, 1=install)
#   INSTALL_DOTBARE - Flag to configure dotbare (0=skip, 1=configure)
#   SYNC_PACKAGES - Flag to sync packages (0=skip, 1=sync)
#   INTERACTIVE - Interactive mode flag (0=non-interactive, 1=interactive)
#   REPO_URL - Dotfiles repository URL (exported for fdotbare)
#
# Returns:
#   0 - Setup completed successfully
#   1 - Setup failed at any step
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
#
# Shows comprehensive help message with available options,
# usage examples, and descriptions for each flag.
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
#   STDOUT - Usage information
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
#
# Processes all command-line flags and sets corresponding global
# variables. Validates required arguments for flags that need them.
#
# Globals:
#   INTERACTIVE - Set based on --non-interactive flag
#   INSTALL_NIX - Set based on --nix/--no-nix flags
#   INSTALL_DOTBARE - Set based on --dotbare/--no-dotbare flags
#   REPO_URL - Set from --repo argument (exported)
#
# Arguments:
#   $@ - All command-line arguments
#
# Returns:
#   0 - Parsing successful
#   1 - Invalid argument encountered
#   2 - Missing required argument value
#
# Outputs:
#   STDERR - Error messages for invalid arguments
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
                if [[ -z "${2:-}" ]]; then
                    error "Option --repo requires an argument"
                    return 2
                fi
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
                return 1
                ;;
        esac
    done
    
    return 0
}

#######################################
# Display welcome banner
#
# Shows branded welcome screen with feature overview.
# Clears screen and displays logo with main features list.
#
# Globals:
#   BLD, CBL, CGR, CNC - Color codes for formatting
#
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#
# Outputs:
#   STDOUT - Welcome banner
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
# Ask user for installation preferences (interactive mode)
#
# Presents yes/no prompts to determine which components to install.
# Only runs in interactive mode. Sets global flags based on responses.
#
# Globals:
#   INTERACTIVE - Checked to determine if prompts should be shown
#   INSTALL_NIX - Set based on user response
#   INSTALL_DOTBARE - Set based on user response
#   SYNC_PACKAGES - Set based on user response
#
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#
# Outputs:
#   STDOUT - Interactive prompts (if INTERACTIVE=1)
#######################################
ask_installation_options() {
    if [[ "$INTERACTIVE" -eq 0 ]]; then
        return 0
    fi
    
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
# Install NIX package manager (Step 1/3)
#
# Executes NIX installation via bootstrap-nix.sh script. Skips if
# INSTALL_NIX flag is 0 or NIX is already installed. Displays
# progress banner and handles errors.
#
# Globals:
#   INSTALL_NIX - Installation flag (checked)
#   SCRIPT_DIR - Used to locate bootstrap-nix.sh
#   BLD, CYE, CNC, CGR - Color codes for output
#
# Arguments:
#   None
#
# Returns:
#   0 - NIX installed successfully or skipped
#   1 - NIX installation failed
#
# Outputs:
#   STDOUT - Progress messages and installation status
#   STDERR - Error messages
#######################################
install_nix_step() {
    if [[ "$INSTALL_NIX" -eq 0 ]]; then
        return 0
    fi
    
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
    
    if ! "${SCRIPT_DIR}/scripts/bootstrap-nix.sh"; then
        error "NIX installation failed"
        return 1
    fi
    
    success "NIX installed successfully"
    return 0
}

#######################################
# Configure dotbare for dotfiles management (Step 2/3)
#
# Executes dotbare configuration via fdotbare script. Skips if
# INSTALL_DOTBARE flag is 0. Displays progress banner and handles errors.
#
# Globals:
#   INSTALL_DOTBARE - Configuration flag (checked)
#   SCRIPT_DIR - Used to locate fdotbare script
#   BLD, CYE, CNC - Color codes for output
#
# Arguments:
#   None
#
# Returns:
#   0 - Dotbare configured successfully or skipped
#   1 - Dotbare configuration failed
#
# Outputs:
#   STDOUT - Progress messages and configuration status
#   STDERR - Error messages
#######################################
configure_dotbare_step() {
    if [[ "$INSTALL_DOTBARE" -eq 0 ]]; then
        return 0
    fi
    
    echo ""
    printf "%b\n" "${BLD}${CYE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CNC}"
    printf "%b\n" "${BLD}${CYE}  Step 2/3: Dotbare Dotfiles Management${CNC}"
    printf "%b\n" "${BLD}${CYE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CNC}"
    echo ""
    
    info "Configuring dotbare for dotfiles..."
    
    if ! "${SCRIPT_DIR}/scripts/core/fdotbare"; then
        error "Dotbare configuration failed"
        return 1
    fi
    
    success "Dotbare configured successfully"
    return 0
}

#######################################
# Synchronize packages from packages.nix (Step 3/3)
#
# Executes package synchronization via sync-packages.sh script. Skips if
# SYNC_PACKAGES or INSTALL_NIX flags are 0. Creates packages.nix from
# template if it doesn't exist. Treats sync errors as non-fatal warnings.
#
# Globals:
#   SYNC_PACKAGES - Sync flag (checked)
#   INSTALL_NIX - Checked to ensure NIX is available
#   SCRIPT_DIR - Used to locate sync-packages.sh
#   HOME - Used to locate packages.nix
#   BLD, CYE, CNC - Color codes for output
#
# Arguments:
#   None
#
# Returns:
#   0 - Packages synced successfully, skipped, or non-fatal errors
#
# Outputs:
#   STDOUT - Progress messages and sync status
#   STDERR - Warning messages for sync failures
#######################################
sync_packages_step() {
    if [[ "$SYNC_PACKAGES" -eq 0 ]] || [[ "$INSTALL_NIX" -eq 0 ]]; then
        return 0
    fi
    
    echo ""
    printf "%b\n" "${BLD}${CYE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CNC}"
    printf "%b\n" "${BLD}${CYE}  Step 3/3: Package Synchronization${CNC}"
    printf "%b\n" "${BLD}${CYE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CNC}"
    echo ""
    
    local packages_nix="$HOME/.config/dotmarchy/packages.nix"
    
    # Check if packages.nix exists, create from template if not
    if [[ ! -f "$packages_nix" ]]; then
        if [[ -f "${SCRIPT_DIR}/packages.nix" ]]; then
            info "Creating packages.nix from template..."
            
            local packages_dir
            packages_dir=$(dirname "$packages_nix")
            
            if ! mkdir -p "$packages_dir" 2>/dev/null; then
                warn "Failed to create directory: $packages_dir"
                return 0
            fi
            
            if ! cp "${SCRIPT_DIR}/packages.nix" "$packages_nix" 2>/dev/null; then
                warn "Failed to copy template packages.nix"
                return 0
            fi
        else
            warn "No packages.nix found. Skipping package sync."
            info "Create one at: $packages_nix"
            return 0
        fi
    fi
    
    info "Syncing packages from packages.nix..."
    
    if ! "${SCRIPT_DIR}/scripts/sync-packages.sh"; then
        warn "Some packages may not have installed correctly"
        warn "Check error log for details"
        return 0  # Non-fatal
    fi
    
    success "Packages synchronized successfully"
    return 0
}

#######################################
# Display installation completion summary
#
# Shows visual summary of completed installation steps with checkmarks,
# next steps recommendations, and documentation links. Lists actions
# for dotbare and NIX package management.
#
# Globals:
#   INSTALL_NIX - Checked to show NIX completion
#   INSTALL_DOTBARE - Checked to show dotbare completion
#   SYNC_PACKAGES - Checked to show package sync completion
#   BLD, CGR, CBL, CYE, CNC - Color codes for output
#
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#
# Outputs:
#   STDOUT - Completion summary and next steps
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
    
    echo ""
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
# Main installation orchestration function
#
# Coordinates the entire installation process by calling all setup
# functions in sequence. Handles argument parsing, displays welcome
# banner, prompts for options (if interactive), executes installation
# steps, and shows completion summary. Returns non-zero on any step failure.
#
# Globals:
#   All globals used by called functions
#
# Arguments:
#   $@ - Command-line arguments (passed to parse_arguments)
#
# Returns:
#   0 - Installation completed successfully
#   1 - Installation failed at any step
#
# Outputs:
#   STDOUT - Full installation progress and results
#   STDERR - Error messages
#######################################
main() {
    if ! parse_arguments "$@"; then
        return 1
    fi
    
    show_welcome
    ask_installation_options
    
    # Execute installation steps
    if ! install_nix_step; then
        error "Installation failed at NIX step"
        return 1
    fi
    
    if ! configure_dotbare_step; then
        error "Installation failed at dotbare step"
        return 1
    fi
    
    # Package sync errors are non-fatal
    if ! sync_packages_step; then
        warn "Package sync had issues (non-fatal)"
    fi
    
    show_completion_summary
    success "Setup completed successfully!"
    
    return 0
}

# Execute only if invoked directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
