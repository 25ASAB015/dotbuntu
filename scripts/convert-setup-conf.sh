#!/usr/bin/env bash
#######################################
# convert-setup-conf.sh - Convert setup.conf to packages.nix
#
# Parses old setup.conf bash arrays and converts to NIX packages.nix format.
# Maps known packages to nixpkgs equivalents.
#
# Usage:
#   ./convert-setup-conf.sh [setup.conf]
#
# Output:
#   Generates packages.nix in ~/.config/dotmarchy/
#######################################

set -Eeuo pipefail

# Determine script directory
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly HELPER_DIR="${SCRIPT_DIR}/../helper"

# Source required helpers
# shellcheck source=/dev/null
source "${HELPER_DIR}/load_helpers.sh"
load_helpers "${HELPER_DIR}" colors logger

# Default setup.conf location
SETUP_CONF="${1:-$HOME/.config/dotmarchy/setup.conf}"
OUTPUT_FILE="$HOME/.config/dotmarchy/packages.nix"

#######################################
# Package name mappings
#######################################
declare -A PACKAGE_MAP=(
    # Distribution-specific → NIX universal
    ["ninja-build"]="ninja"
    ["git-delta"]="delta"
    
    # AUR → nixpkgs
    ["dotbare"]="# dotbare - manual install from GitHub (not in nixpkgs)"
    ["brave-bin"]="brave"
    ["visual-studio-code-bin"]="vscode"
    ["zsh-theme-powerlevel10k-git"]="zsh-powerlevel10k"
    ["zsh-autosuggestions"]="zsh-autosuggestions"
    ["zsh-syntax-highlighting"]="zsh-syntax-highlighting"
    
    # NPM → nixpkgs
    ["diff-so-fancy"]="diff-so-fancy"
    ["@fission-ai/openspec"]="# openspec - install via npm after NIX setup"
    
   # Cargo → nixpkgs
    ["bat"]="bat"
    ["ripgrep"]="ripgrep"
    ["fd-find"]="fd"
    ["exa"]="exa"
    
    # Keep as-is (already correct)
    ["neovim"]="neovim"
    ["tmux"]="tmux"
    ["fzf"]="fzf"
    ["htop"]="htop"
)

#######################################
# Map package name to nixpkgs equivalent
#######################################
map_package_name() {
    local pkg="$1"
    
    # Check if we have a mapping
    if [[ -n "${PACKAGE_MAP[$pkg]:-}" ]]; then
        echo "${PACKAGE_MAP[$pkg]}"
    else
        # Return original name
        echo "$pkg"
    fi
}

#######################################
# Parse array from setup.conf
#######################################
parse_array() {
    local array_name="$1"
    local values=()
    
    if [[ ! -f "$SETUP_CONF" ]]; then
        return
    fi
    
    # Source the file in a subshell to extract array
    # shellcheck disable=SC1090
    source "$SETUP_CONF"
    
    # Get array dynamically
    eval "values=(\"\${${array_name}[@]:-}\")"
    
    printf "%s\n" "${values[@]}"
}

#######################################
# Generate packages.nix from setup.conf
#######################################
generate_packages_nix() {
    info "Converting setup.conf to packages.nix..."
    
    if [[ ! -f "$SETUP_CONF" ]]; then
        error "setup.conf not found at: $SETUP_CONF"
        return 1
    fi
    
    # Parse arrays
    local extra_deps core_deps aur_apps npm_packages
    extra_deps=$(parse_array "EXTRA_DEPENDENCIES" 2>/dev/null || true)
    core_deps=$(parse_array "CORE_DEPENDENCIES" 2>/dev/null || true)
    aur_apps=$(parse_array "EXTRA_AUR_APPS" 2>/dev/null || true)
    npm_packages=$(parse_array "EXTRA_NPM_PACKAGES" 2>/dev/null || true)
    
    # Combine all packages
    local all_packages="$core_deps $extra_deps $aur_apps"
    
    # Start generating packages.nix
    cat > "$OUTPUT_FILE" <<'EOF'
# NIX Package Configuration
# Generated from setup.conf
#
# Usage:
#   nix-env -iA myPackages -f packages.nix
#
# To add/remove packages, edit the 'paths' list below

{ pkgs ? import <nixpkgs> {} }:

{
  myPackages = pkgs.buildEnv {
    name = "dotbuntu-packages";
    paths = with pkgs; [
      #======================================================================
      # CORE \u0026 EXTRA DEPENDENCIES
      #======================================================================
EOF
    
    # Add mapped packages
    local unmapped=()
    for pkg in $all_packages; do
        local mapped
        mapped=$(map_package_name "$pkg")
        
        if [[ "$mapped" == "#"* ]]; then
            # Comment line
            echo "      $mapped" >> "$OUTPUT_FILE"
            unmapped+=("$pkg")
        else
            echo "      $mapped  # was: $pkg" >> "$OUTPUT_FILE"
        fi
    done
    
    # Add NPM packages as comments
    if [[ -n "$npm_packages" ]]; then
        cat >> "$OUTPUT_FILE" <<'EOF'
      
      #======================================================================
      # NPM PACKAGES (install via npm after setup)
      #======================================================================
EOF
        for pkg in $npm_packages; do
            echo "      # npm install -g $pkg" >> "$OUTPUT_FILE"
        done
    fi
    
    # Close the file
    cat >> "$OUTPUT_FILE" <<'EOF'
    ];
  };
}
EOF
    
    success "Created packages.nix at: $OUTPUT_FILE"
    
    # Show unmapped packages
    if [[ ${#unmapped[@]} -gt 0 ]]; then
        warn "Unmapped packages (require manual installation):"
        for pkg in "${unmapped[@]}"; do
            echo "  - $pkg"
        done
    fi
    
    echo ""
    info "Next steps:"
    echo "  1. Review: vim $OUTPUT_FILE"
    echo "  2. Apply: ./scripts/sync-packages.sh"
    echo "  3. Version: dotbare add $OUTPUT_FILE"
}

#######################################
# Main
#######################################
main() {
    logo "Setup.conf → packages.nix Converter"
    echo ""
    
    generate_packages_nix
}

# Execute only if invoked directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
