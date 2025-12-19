#!/usr/bin/env bash
# shellcheck shell=bash
#
# set_variable.sh - Environment variables and configuration defaults for dotmarchy
#
# This helper sets up all environment variables, constants, and configuration
# defaults used throughout dotmarchy. It should be sourced first by any script
# that needs access to these variables.
#
# @params
# Globals (exported):
#   ${DOTBARE_DIR}: Location of the bare repository (default: $HOME/.cfg)
#   ${DOTBARE_TREE}: Folder the bare repo tracks (default: $HOME)
#   ${DOTBARE_BACKUP}: Backup directory for tracked files
#   ${REPO_URL}: Git repository URL for dotfiles
#   ${SETUP_CONFIG}: Path to setup configuration file
#   ${ERROR_LOG}: Path to error log file
#   ${INSTALL_EXTRAS}: Flag for installing extra packages
#   ${SETUP_ENVIRONMENT}: Flag for environment setup
#   ${DRY_RUN}: Flag for dry-run mode
#   ${VERBOSE}: Flag for verbose output
#   ${FORCE}: Flag for forcing operations
#   ${VERIFY_MODE}: Flag for verification mode
#   ${DOTMARCHY_VERSION}: Current version of dotmarchy
#   ${INSTALL_START_TIME}: Timestamp when installation started
#   ${PACKAGES_INSTALLED}: Counter for installed packages
#   ${PACKAGES_SKIPPED}: Counter for skipped packages
# Arrays (declared):
#   ${EXTRA_DEPENDENCIES}: Array of extra system packages
#   ${EXTRA_CHAOTIC_DEPENDENCIES}: Array of Chaotic-AUR packages
#   ${EXTRA_AUR_APPS}: Array of AUR packages
#   ${EXTRA_NPM_PACKAGES}: Array of npm packages
#   ${CARGO_PACKAGES}: Array of Rust/cargo packages
#   ${PIP_PACKAGES}: Array of Python pip packages
#   ${PIPX_PACKAGES}: Array of Python pipx applications
#   ${GEM_PACKAGES}: Array of Ruby gems
#   ${DIRECTORIES}: Array of directories to create
#   ${GIT_REPOS}: Array of git repositories to clone
#   ${SCRIPTS}: Array of scripts to download
#   ${SHELL_LINES}: Array of lines to add to shell config

# Idempotent load guard (not exported to avoid inheritance)
DOTMARCHY_VARIABLES_LOADED=${DOTMARCHY_VARIABLES_LOADED:-0}
if [ "${DOTMARCHY_VARIABLES_LOADED}" -eq 1 ]; then
    return 0
fi

# Version (only set if not already defined)
if [ -z "${DOTMARCHY_VERSION+x}" ]; then
    export DOTMARCHY_VERSION="v2.0.0"
fi

# Dotbare configuration (from dotbare pattern)
export DOTBARE_DIR="${DOTBARE_DIR:-$HOME/.cfg}"
export DOTBARE_TREE="${DOTBARE_TREE:-$HOME}"
export DOTBARE_BACKUP="${DOTBARE_BACKUP:-${XDG_DATA_HOME:-$HOME/.local/share}/dotbare}"

# Default repository URL
export REPO_URL="${REPO_URL:-git@github.com:25ASAB015/dotfiles.git}"

# Configuration paths
export SETUP_CONFIG="${SETUP_CONFIG:-$HOME/.config/dotmarchy/setup.conf}"

# Error logging
export ERROR_LOG="${ERROR_LOG:-$HOME/.local/share/dotmarchy/install_errors.log}"
mkdir -p "$(dirname "$ERROR_LOG")" 2>/dev/null || true

# Operational flags (can be overridden by environment or CLI)
export DRY_RUN="${DRY_RUN:-0}"
export FORCE="${FORCE:-0}"
export VERBOSE="${VERBOSE:-0}"
export INSTALL_EXTRAS="${INSTALL_EXTRAS:-0}"
export SETUP_ENVIRONMENT="${SETUP_ENVIRONMENT:-0}"
export SKIP_SYSTEM="${SKIP_SYSTEM:-0}"
export VERIFY_MODE="${VERIFY_MODE:-0}"

# Core dependencies (always installed)
export CORE_DEPENDENCIES="zsh tree bat highlight ruby-coderay git-delta diff-so-fancy npm"

# Default extra packages (can be overridden by SETUP_CONFIG)
export DEFAULT_EXTRA_DEPENDENCIES="neovim tmux htop ripgrep fd fzf"
export DEFAULT_EXTRA_CHAOTIC_DEPENDENCIES="brave-bin visual-studio-code-bin"
export DEFAULT_EXTRA_AUR_APPS="zsh-theme-powerlevel10k-git zsh-autosuggestions zsh-syntax-highlighting"
export DEFAULT_EXTRA_NPM_PACKAGES="@fission-ai/openspec"

# Arrays for extra packages (initialize to avoid unbound variable errors)
declare -a EXTRA_DEPENDENCIES=()
declare -a EXTRA_CHAOTIC_DEPENDENCIES=()
declare -a EXTRA_AUR_APPS=()
declare -a EXTRA_NPM_PACKAGES=()
declare -a CARGO_PACKAGES=()
declare -a PIP_PACKAGES=()
declare -a PIPX_PACKAGES=()
declare -a GEM_PACKAGES=()

# Arrays for environment setup
declare -a DIRECTORIES=()
declare -a GIT_REPOS=()
declare -a SCRIPTS=()
declare -a SHELL_LINES=()

# Installation statistics
export INSTALL_START_TIME=$(date +%s)
export PACKAGES_INSTALLED=0
export PACKAGES_SKIPPED=0

# Mark as loaded
DOTMARCHY_VARIABLES_LOADED=1

