#!/usr/bin/env bash
# shellcheck shell=bash
# shfmt: -ln=bash
#
# package_manager.sh - Package manager abstraction layer for dotbuntu
#
# Provides unified functions for package management across different Linux
# distributions (Arch Linux and Ubuntu/Debian).
#
# Usage:
#   source "${HELPER_DIR}/package_manager.sh"
#   pkg_install "git" "curl" "wget"
#   pkg_update
#
# Supported distributions:
#   - Arch Linux (pacman)
#   - Ubuntu/Debian (apt)
#
# @author: dotbuntu
# @version: 1.0.0

set -Eeuo pipefail

# Idempotent guard
DOTBUNTU_PKG_MANAGER_LOADED=${DOTBUNTU_PKG_MANAGER_LOADED:-0}
if [ "${DOTBUNTU_PKG_MANAGER_LOADED}" -eq 1 ]; then
    return 0
fi
DOTBUNTU_PKG_MANAGER_LOADED=1

#######################################
# Constants
#######################################
if [ -z "${HELPER_DIR:-}" ]; then
    HELPER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# Package name mappings (Arch -> Ubuntu)
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
if [ -z "${CGR:-}" ]; then
    # shellcheck source=/dev/null
    source "${HELPER_DIR}/colors.sh" 2>/dev/null || true
fi

if ! command -v info >/dev/null 2>&1; then
    # shellcheck source=/dev/null
    source "${HELPER_DIR}/logger.sh" 2>/dev/null || true
fi

#######################################
# Detect the current package manager
# Outputs:
#   Package manager name (pacman, apt, unknown)
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
# Outputs:
#   Package manager name
#######################################
pkg_get_manager() {
    if [ -z "${_PKG_MANAGER_CACHE:-}" ]; then
        _PKG_MANAGER_CACHE=$(detect_package_manager)
    fi
    echo "$_PKG_MANAGER_CACHE"
}

#######################################
# Map package name to current distribution
# Arguments:
#   $1: Package name (Arch-style)
# Outputs:
#   Mapped package name for current distro
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
# Arguments:
#   $1: Package name
# Returns:
#   0 if installed, 1 otherwise
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
# Returns:
#   0 on success, 1 on failure
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
# Returns:
#   0 on success, 1 on failure
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
# Arguments:
#   $@: Package names (Arch-style, will be mapped)
# Returns:
#   0 on success, 1 on failure
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
# Arguments:
#   $1: Package name
# Returns:
#   0 on success, 1 on failure
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
# Returns:
#   0 if Arch-based, 1 otherwise
#######################################
is_arch_based() {
    [[ "$(pkg_get_manager)" == "pacman" ]]
}

#######################################
# Check if running on Debian-based distro
# Returns:
#   0 if Debian-based, 1 otherwise
#######################################
is_debian_based() {
    [[ "$(pkg_get_manager)" == "apt" ]]
}

#######################################
# Get human-readable package manager name
# Outputs:
#   Human-readable name
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
