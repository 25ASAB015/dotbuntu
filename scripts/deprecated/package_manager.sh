#!/usr/bin/env bash
# shellcheck shell=bash
#
# package_manager.sh - Package manager abstraction layer
#
# Provides unified functions for package management across different Linux
# distributions (Arch Linux and Ubuntu/Debian). This abstraction allows
# scripts to use a single API regardless of the underlying package manager.
#
# Supported distributions:
#   - Arch Linux (pacman)
#   - Ubuntu/Debian (apt)
#
# @author: dotbuntu
# @version: 1.0.0

set -Eeuo pipefail

# Idempotent guard
[[ -n "${_DOTBUNTU_PKG_MANAGER_LOADED:-}" ]] && return 0
declare -r _DOTBUNTU_PKG_MANAGER_LOADED=1

#######################################
# Constants
#######################################
if [[ -z "${HELPER_DIR:-}" ]]; then
    HELPER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

#######################################
# Package name mappings (Arch -> Ubuntu)
#
# Maps Arch Linux package names to their Ubuntu/Debian equivalents.
# Used by pkg_map_name() to translate package names.
#######################################
declare -A PKG_MAP_ARCH_TO_UBUNTU=(
    ["base-devel"]="build-essential"
    ["fd"]="fd-find"
    ["github-cli"]="gh"
    ["bat"]="bat"
    ["ripgrep"]="ripgrep"
    ["zsh"]="zsh"
    ["git"]="git"
    ["curl"]="curl"
    ["wget"]="wget"
    ["tree"]="tree"
    ["fzf"]="fzf"
    ["tmux"]="tmux"
    ["neovim"]="neovim"
    ["unzip"]="unzip"
    ["nodejs"]="nodejs"
    ["npm"]="npm"
    ["python3"]="python3"
    ["python-pip"]="python3-pip"
)

#######################################
# Load dependencies
#######################################
if [[ -z "${CGR:-}" ]]; then
    # shellcheck source=/dev/null
    source "${HELPER_DIR}/colors.sh" 2>/dev/null || true
fi

if ! command -v info >/dev/null 2>&1; then
    # shellcheck source=/dev/null
    source "${HELPER_DIR}/logger.sh" 2>/dev/null || true
fi

#######################################
# Detect the system package manager
#
# Checks for available package managers in order of preference
# and returns the first one found.
#
# Returns:
#   0 - Always succeeds
#
# Outputs:
#   STDOUT - Package manager name (pacman, apt, unknown)
#######################################
detect_package_manager() {
    if command -v pacman >/dev/null 2>&1; then
        echo "pacman"
    elif command -v apt >/dev/null 2>&1; then
        echo "apt"
    else
        echo "unknown"
    fi
}

#######################################
# Get the current package manager (cached)
#
# Returns the detected package manager, caching the result
# for subsequent calls to avoid repeated detection.
#
# Globals:
#   _PKG_MANAGER_CACHE - Internal cache variable
#
# Returns:
#   0 - Always succeeds
#
# Outputs:
#   STDOUT - Package manager name
#######################################
pkg_get_manager() {
    if [[ -z "${_PKG_MANAGER_CACHE:-}" ]]; then
        _PKG_MANAGER_CACHE=$(detect_package_manager)
    fi
    echo "$_PKG_MANAGER_CACHE"
}

#######################################
# Map package name to current distribution
#
# Translates an Arch-style package name to the equivalent
# name for the current distribution.
#
# Arguments:
#   $1 - Package name (Arch-style)
#
# Returns:
#   0 - Always succeeds
#
# Outputs:
#   STDOUT - Mapped package name for current distro
#######################################
pkg_map_name() {
    local pkg="$1"
    local manager
    manager=$(pkg_get_manager)
    
    case "$manager" in
        apt)
            # Check if we have a mapping
            if [[ -v PKG_MAP_ARCH_TO_UBUNTU["$pkg"] ]]; then
                echo "${PKG_MAP_ARCH_TO_UBUNTU[$pkg]}"
            else
                echo "$pkg"
            fi
            ;;
        *)
            echo "$pkg"
            ;;
    esac
}

#######################################
# Check if a package is installed
#
# Uses the appropriate package manager to check if a package
# is currently installed on the system.
#
# Arguments:
#   $1 - Package name to check
#
# Returns:
#   0 - Package is installed
#   1 - Package is not installed
#######################################
is_pkg_installed() {
    local pkg="$1"
    local manager
    manager=$(pkg_get_manager)
    
    case "$manager" in
        pacman)
            pacman -Qi "$pkg" >/dev/null 2>&1
            ;;
        apt)
            dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"
            ;;
        *)
            command -v "$pkg" >/dev/null 2>&1
            ;;
    esac
}

#######################################
# Update package database/index
#
# Refreshes the package database without upgrading packages.
#
# Returns:
#   0 - Success
#   1 - Failure or unsupported manager
#
# Outputs:
#   STDOUT - Update progress (varies by manager)
#######################################
pkg_update() {
    local manager
    manager=$(pkg_get_manager)
    
    case "$manager" in
        pacman)
            sudo pacman -Sy --noconfirm
            ;;
        apt)
            sudo apt update
            ;;
        *)
            warn "Package manager not supported: $manager"
            return 1
            ;;
    esac
}

#######################################
# Upgrade all installed packages
#
# Updates package database and upgrades all installed packages.
#
# Returns:
#   0 - Success
#   1 - Failure or unsupported manager
#
# Outputs:
#   STDOUT - Upgrade progress (varies by manager)
#######################################
pkg_upgrade() {
    local manager
    manager=$(pkg_get_manager)
    
    case "$manager" in
        pacman)
            sudo pacman -Syu --noconfirm
            ;;
        apt)
            sudo apt update && sudo apt upgrade -y
            ;;
        *)
            warn "Package manager not supported: $manager"
            return 1
            ;;
    esac
}

#######################################
# Install one or more packages
#
# Installs packages using the system package manager.
# Package names are automatically mapped for cross-distro support.
#
# Arguments:
#   $@ - Package names (Arch-style, will be mapped)
#
# Returns:
#   0 - Success
#   1 - Failure or unsupported manager
#
# Outputs:
#   STDOUT - Installation progress
#######################################
pkg_install() {
    local manager
    manager=$(pkg_get_manager)
    local mapped_pkgs=()
    
    # Map package names
    for pkg in "$@"; do
        mapped_pkgs+=("$(pkg_map_name "$pkg")")
    done
    
    case "$manager" in
        pacman)
            sudo pacman -S --noconfirm "${mapped_pkgs[@]}"
            ;;
        apt)
            sudo apt install -y "${mapped_pkgs[@]}"
            ;;
        *)
            warn "Package manager not supported: $manager"
            return 1
            ;;
    esac
}

#######################################
# Install a single package silently
#
# Installs a package without producing output.
# Useful for scripts that want to suppress installation logs.
#
# Arguments:
#   $1 - Package name
#
# Returns:
#   0 - Success
#   1 - Failure
#######################################
pkg_install_silent() {
    local pkg="$1"
    local mapped_pkg
    local manager
    manager=$(pkg_get_manager)
    mapped_pkg=$(pkg_map_name "$pkg")
    
    case "$manager" in
        pacman)
            sudo pacman -S --noconfirm "$mapped_pkg" >/dev/null 2>&1
            ;;
        apt)
            sudo apt install -y "$mapped_pkg" >/dev/null 2>&1
            ;;
        *)
            return 1
            ;;
    esac
}

#######################################
# Check if running on Arch-based distro
#
# Returns:
#   0 - Running on Arch-based distro
#   1 - Not running on Arch-based distro
#######################################
is_arch_based() {
    [[ "$(pkg_get_manager)" == "pacman" ]]
}

#######################################
# Check if running on Debian-based distro
#
# Returns:
#   0 - Running on Debian-based distro
#   1 - Not running on Debian-based distro
#######################################
is_debian_based() {
    [[ "$(pkg_get_manager)" == "apt" ]]
}

#######################################
# Get human-readable package manager name
#
# Returns a descriptive string identifying the package manager
# and distribution family.
#
# Returns:
#   0 - Always succeeds
#
# Outputs:
#   STDOUT - Human-readable description
#######################################
pkg_get_manager_name() {
    local manager
    manager=$(pkg_get_manager)
    
    case "$manager" in
        pacman) echo "pacman (Arch Linux)" ;;
        apt) echo "apt (Ubuntu/Debian)" ;;
        *) echo "Unknown" ;;
    esac
}
