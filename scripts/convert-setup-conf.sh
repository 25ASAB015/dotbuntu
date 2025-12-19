#!/usr/bin/env bash
#######################################
# convert-setup-conf.sh - Convert setup.conf to packages.nix
#
# Parses legacy setup.conf bash arrays and converts them to NIX packages.nix
# format. Maps known packages to their nixpkgs equivalents using a predefined
# mapping table. Generates commented entries for unmapped packages.
#
# Usage:
#   ./convert-setup-conf.sh [setup.conf]
#
# Globals:
#   SCRIPT_DIR - Directory containing this script
#   HELPER_DIR - Path to helper modules
#   SETUP_CONF - Path to source setup.conf file
#   OUTPUT_FILE - Path to generated packages.nix
#   PACKAGE_MAP - Associative array of package name mappings
#
# Arguments:
#   $1 - Optional path to setup.conf (defaults to ~/.config/dotmarchy/setup.conf)
#
# Returns:
#   0 - Conversion successful
#   1 - Conversion failed (setup.conf not found or generation error)
#
# Outputs:
#   STDOUT - Progress messages and conversion results
#   FILE - packages.nix at ~/.config/dotmarchy/packages.nix
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
# Package name mapping table
#
# Maps distribution-specific and source-specific package names
# to their canonical nixpkgs equivalents. Comment entries indicate
# packages not available in nixpkgs that require manual installation.
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
#
# Looks up package name in PACKAGE_MAP and returns the mapped
# nixpkgs name. If no mapping exists, returns the original name
# unchanged.
#
# Globals:
#   PACKAGE_MAP - Associative array of package mappings
#
# Arguments:
#   $1 - Package name to map (required)
#
# Returns:
#   0 - Always succeeds
#
# Outputs:
#   STDOUT - Mapped package name or original name
#######################################
map_package_name() {
    local pkg="$1"
    
    # Check if we have a mapping
    if [[ -n "${PACKAGE_MAP[$pkg]:-}" ]]; then
        echo "${PACKAGE_MAP[$pkg]}"
    else
        # Return original name (may work as-is in nixpkgs)
        echo "$pkg"
    fi
}

#######################################
# Parse array from setup.conf
#
# Extracts a bash array from setup.conf by sourcing the file
# and dynamically evaluating the array variable. Uses a subshell
# to avoid polluting the current environment.
#
# SECURITY NOTE: This sources user-provided configuration files.
# Only use with trusted input.
#
# Globals:
#   SETUP_CONF - Path to setup.conf file
#
# Arguments:
#   $1 - Array name to extract (e.g., "EXTRA_DEPENDENCIES")
#
# Returns:
#   0 - Array parsed successfully or file not found
#   1 - (Never returned explicitly, but sourcing could fail)
#
# Outputs:
#   STDOUT - Array values, one per line
#######################################
parse_array() {
    local array_name="$1"
    local values=()
    
    if [[ ! -f "$SETUP_CONF" ]]; then
        return 0
    fi
    
    # Source the file in current shell to extract array
    # SECURITY: Only use with trusted configuration files
    # shellcheck disable=SC1090
    source "$SETUP_CONF"
    
    # Get array dynamically using eval
    eval "values=(\"\${${array_name}[@]:-}\")"
    
    # Output array values, one per line
    printf "%s\n" "${values[@]}"
}

#######################################
# Generate packages.nix from setup.conf
#
# Main conversion function that:
# 1. Validates setup.conf exists
# 2. Parses all package arrays (CORE, EXTRA, AUR, NPM)
# 3. Maps package names to nixpkgs equivalents
# 4. Generates formatted packages.nix file
# 5. Reports unmapped packages requiring manual installation
# 6. Displays next steps for user
#
# Globals:
#   SETUP_CONF - Input file path
#   OUTPUT_FILE - Output file path
#
# Arguments:
#   None
#
# Returns:
#   0 - Generation successful
#   1 - setup.conf not found
#
# Outputs:
#   STDOUT - Progress messages, warnings, next steps
#   STDERR - Error messages
#   FILE - Generated packages.nix at OUTPUT_FILE
#######################################
generate_packages_nix() {
    info "Converting setup.conf to packages.nix..."
    
    if [[ ! -f "$SETUP_CONF" ]]; then
        error "setup.conf not found at: $SETUP_CONF"
        error "Create a setup.conf first or specify path as argument"
        return 1
    fi
    
    # Parse all arrays from setup.conf
    local extra_deps core_deps aur_apps npm_packages
    extra_deps=$(parse_array "EXTRA_DEPENDENCIES" 2>/dev/null || true)
    core_deps=$(parse_array "CORE_DEPENDENCIES" 2>/dev/null || true)
    aur_apps=$(parse_array "EXTRA_AUR_APPS" 2>/dev/null || true)
    npm_packages=$(parse_array "EXTRA_NPM_PACKAGES" 2>/dev/null || true)
    
    # Combine all packages into single list
    local all_packages="$core_deps $extra_deps $aur_apps"
    
    # Generate packages.nix header
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
      # CORE & EXTRA DEPENDENCIES
      #======================================================================
EOF
    
    # Process and add mapped packages
    local unmapped=()
    for pkg in $all_packages; do
        [[ -z "$pkg" ]] && continue  # Skip empty entries
        
        local mapped
        mapped=$(map_package_name "$pkg")
        
        if [[ "$mapped" == "#"* ]]; then
            # Comment line - package not in nixpkgs
            echo "      $mapped" >> "$OUTPUT_FILE"
            unmapped+=("$pkg")
        else
            echo "      $mapped  # was: $pkg" >> "$OUTPUT_FILE"
        fi
    done
    
    # Add NPM packages section as comments (install separately)
    if [[ -n "$npm_packages" ]]; then
        cat >> "$OUTPUT_FILE" <<'EOF'
      
      #======================================================================
      # NPM PACKAGES (install via npm after setup)
      #======================================================================
EOF
        for pkg in $npm_packages; do
            [[ -z "$pkg" ]] && continue
            echo "      # npm install -g $pkg" >> "$OUTPUT_FILE"
        done
    fi
    
    # Close packages.nix structure
    cat >> "$OUTPUT_FILE" <<'EOF'
    ];
  };
}
EOF
    
    success "Created packages.nix at: $OUTPUT_FILE"
    
    # Report unmapped packages
    if [[ ${#unmapped[@]} -gt 0 ]]; then
        echo ""
        warn "Unmapped packages (require manual installation):"
        for pkg in "${unmapped[@]}"; do
            echo "  - $pkg"
        done
    fi
    
    # Show next steps
    echo ""
    info "Next steps:"
    echo "  1. Review generated file: vim $OUTPUT_FILE"
    echo "  2. Apply packages: ./scripts/sync-packages.sh"
    echo "  3. Version in dotbare: dotbare add $OUTPUT_FILE"
    echo "  4. Commit and push: dotbare commit -m \"Migrate to NIX packages\" && dotbare push"
    
    return 0
}

#######################################
# Main entry point
#
# Displays banner and initiates conversion process. Catches
# and handles conversion errors gracefully.
#
# Globals:
#   None (uses globals via called functions)
#
# Arguments:
#   None
#
# Returns:
#   0 - Conversion successful
#   1 - Conversion failed
#
# Outputs:
#   STDOUT - Banner and all conversion output
#   STDERR - Error messages (via called functions)
#######################################
main() {
    logo "Setup.conf → packages.nix Converter"
    echo ""
    
    if ! generate_packages_nix; then
        error "Conversion failed"
        return 1
    fi
    
    return 0
}

# Execute only if invoked directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
