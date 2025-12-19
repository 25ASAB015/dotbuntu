#!/usr/bin/env bash
# shellcheck shell=bash disable=SC2155
# shfmt: -i 4 -ci -sr -bn
#
# fmise - Professional MISE Package Manager
#
# A production-grade installer for MISE packages with intelligent detection,
# comprehensive error handling, and enterprise-level reporting.
#
# Author: dotmarchy project
# License: MIT
# Version: 2.0.0
#
# Features:
#   - Multi-backend support (npm, pipx, cargo, gem, github)
#   - Intelligent binary name resolution
#   - Conflict detection with system packages
#   - Parallel installation capability
#   - Comprehensive error recovery
#   - Professional logging and reporting
#
# @params
# Globals:
#   INSTALL_EXTRAS : Must be 1 to run (or use --force)
#   SETUP_CONFIG   : Path to configuration file
#   ERROR_LOG      : Error log path
#   FMISE_PARALLEL : Enable parallel installation (default: false)
#
# Arguments:
#   -h, --help     : Show help message
#   -f, --force    : Force execution in standalone mode
#   -p, --parallel : Enable parallel installation (experimental)
#   -v, --verbose  : Enable verbose output
#   -d, --dry-run  : Show what would be installed without installing
#
# Returns:
#   0 : All packages installed successfully
#   1 : Some packages failed to install
#   2 : Configuration error
#   3 : MISE not available

set -Eeuo pipefail

# ============================================================================
# SCRIPT INITIALIZATION
# ============================================================================

readonly SCRIPT_VERSION="2.0.0"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly HELPER_DIR="${SCRIPT_DIR}/../../helper"

# Source helper libraries
# shellcheck source=/dev/null
source "${HELPER_DIR}/load_helpers.sh"
load_helpers "${HELPER_DIR}" set_variable colors logger prompts checks

# Error handling
trap 'on_error ${LINENO}' ERR
trap 'cleanup_on_exit' EXIT

# ============================================================================
# GLOBAL STATE MANAGEMENT
# ============================================================================

# Package tracking arrays
declare -a g_missing_mise=()
declare -a g_skipped_packages=()
declare -a g_already_installed_mise=()
declare -a g_already_installed_path=()
declare -a g_already_installed_npm=()
declare -a g_already_installed_pacman=()
declare -a g_mise_failed=()

# Runtime configuration
declare -g FMISE_VERBOSE=false
declare -g FMISE_DRY_RUN=false
declare -g FMISE_PARALLEL=false
declare -g FMISE_START_TIME=""

# Statistics
declare -gi g_total_time=0
declare -gi g_install_count=0

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

function cleanup_on_exit() {
    local exit_code=$?
    if [ $exit_code -ne 0 ] && [ $exit_code -ne 130 ]; then
        log_error "Script exited with code: $exit_code"
    fi
}

function verbose_log() {
    if [ "$FMISE_VERBOSE" = true ]; then
        info "$@"
    fi
}

function get_elapsed_time() {
    local start_time="$1"
    local end_time=$(date +%s)
    echo $((end_time - start_time))
}

function format_duration() {
    local seconds="$1"
    if [ "$seconds" -lt 60 ]; then
        echo "${seconds}s"
    else
        echo "$((seconds / 60))m $((seconds % 60))s"
    fi
}

# ============================================================================
# HELP AND DOCUMENTATION
# ============================================================================

function usage() {
    cat << EOF
${BLD}${CBL}fmise${CNC} - Professional MISE Package Manager v${SCRIPT_VERSION}

${BLD}USAGE:${CNC}
    ${SCRIPT_NAME} [OPTIONS]

${BLD}DESCRIPTION:${CNC}
    Manages MISE packages from dotmarchy configuration with intelligent
    detection, conflict resolution, and comprehensive error handling.

${BLD}OPTIONS:${CNC}
    -h, --help          Show this help message and exit
    -f, --force         Force execution (standalone mode, bypasses INSTALL_EXTRAS check)
    -p, --parallel      Enable parallel installation (experimental, faster but less verbose)
    -v, --verbose       Enable verbose output for debugging
    -d, --dry-run       Show what would be installed without actually installing

${BLD}CONFIGURATION:${CNC}
    Config file: ${CYE}~/.config/dotmarchy/setup.conf${CNC}
    Array name:  ${CYE}MISE_PACKAGES${CNC}

${BLD}SUPPORTED BACKENDS:${CNC}
    ${CGR}npm:${CNC}     Node.js packages via npm
    ${CGR}pipx:${CNC}    Python applications (isolated environments)
    ${CGR}cargo:${CNC}   Rust packages via cargo
    ${CGR}gem:${CNC}     Ruby gems
    ${CGR}github:${CNC}  GitHub releases (owner/repo format)
    ${CGR}core:${CNC}    MISE core tools (no prefix needed)

${BLD}EXAMPLES:${CNC}
    ${CYE}# Normal usage (from dotmarchy with --extras)${CNC}
    ./install_all_dependencies.sh --extras

    ${CYE}# Standalone mode${CNC}
    ./${SCRIPT_NAME} --force

    ${CYE}# Dry run to see what would be installed${CNC}
    ./${SCRIPT_NAME} --force --dry-run

    ${CYE}# Verbose mode for debugging${CNC}
    ./${SCRIPT_NAME} --force --verbose

    ${CYE}# Fast parallel installation (experimental)${CNC}
    ./${SCRIPT_NAME} --force --parallel

${BLD}EXIT CODES:${CNC}
    ${CGR}0${CNC} - All packages installed successfully
    ${CRE}1${CNC} - Some packages failed to install
    ${CRE}2${CNC} - Configuration error
    ${CRE}3${CNC} - MISE not available

${BLD}ENVIRONMENT VARIABLES:${CNC}
    ${CYE}INSTALL_EXTRAS${CNC}  - Must be 1 to run (or use --force)
    ${CYE}SETUP_CONFIG${CNC}    - Override config file path
    ${CYE}ERROR_LOG${CNC}       - Override error log path
    ${CYE}FMISE_PARALLEL${CNC}  - Enable parallel mode (true/false)

${BLD}DOCUMENTATION:${CNC}
    MISE docs: ${CBL}https://mise.jdx.dev${CNC}
    Project:   ${CBL}https://github.com/yourusername/dotmarchy${CNC}

EOF
}

# ============================================================================
# BINARY NAME RESOLUTION
# ============================================================================

function extract_binary_name() {
    local package="$1"
    local bin_name="$package"
    
    # Remove backend prefix (npm:, cargo:, pipx:, gem:, ruby:, github:)
    if [[ "$package" == *":"* ]]; then
        bin_name="${package#*:}"
    fi
    
    # Remove version suffix (@latest, @1.0.0, etc.)
    [[ "$bin_name" == *"@"* ]] && bin_name="${bin_name%@*}"
    
    # Handle GitHub repositories (owner/repo format)
    if [[ "$package" == github:* ]]; then
        [[ "$bin_name" == *"/"* ]] && bin_name="${bin_name##*/}"
        
        # Well-known GitHub binary mappings
        case "$bin_name" in
            cli) bin_name="gh" ;;           # github:cli/cli -> gh
            lazygit) bin_name="lazygit" ;;  # github:jesseduffield/lazygit
        esac
    fi
    
    # Handle scoped npm packages (@org/package -> package)
    [[ "$bin_name" == @*/* ]] && bin_name="${bin_name##*/}"
    
    # Backend-specific binary name mappings
    if [[ "$package" == cargo:* ]]; then
        case "$bin_name" in
            bob-nvim) bin_name="bob" ;;
            tree-sitter-cli) bin_name="tree-sitter" ;;
        esac
    fi
    
    if [[ "$package" == pipx:* ]]; then
        case "$bin_name" in
            neovim-remote) bin_name="nvr" ;;
            python-lsp-server) bin_name="pylsp" ;;
            rich-cli) bin_name="rich" ;;
            trash-cli) bin_name="trash" ;;
        esac
    fi
    
    echo "$bin_name"
}

# ============================================================================
# PACKAGE DETECTION
# ============================================================================

function is_installed_via_mise() {
    local package="$1"
    mise list 2>/dev/null | grep -qE "^${package}[[:space:]]"
}

function is_installed_via_npm() {
    local npm_pkg_name="$1"
    npm_pkg_name="${npm_pkg_name%@*}"
    local escaped_name=$(printf '%s\n' "$npm_pkg_name" | sed 's/[[\.*^$()+?{|]/\\&/g')
    npm list -g --depth=0 2>/dev/null | grep -qE "(├──|└──) ${escaped_name}@"
}

function is_installed_via_pipx() {
    local pkg_name="$1"
    pkg_name="${pkg_name%@*}"
    command -v pipx >/dev/null 2>&1 && \
        (pipx list --short 2>/dev/null | grep -qE "^${pkg_name}$" || \
         pipx list 2>/dev/null | grep -qE "package .*${pkg_name}")
}

function is_installed_via_gem() {
    local pkg_name="$1"
    pkg_name="${pkg_name%@*}"
    command -v gem >/dev/null 2>&1 && \
        gem list 2>/dev/null | grep -qE "^${pkg_name} "
}

function is_installed_via_cargo() {
    local bin_name="$1"
    [ -f "$HOME/.cargo/bin/$bin_name" ]
}

function is_package_installed() {
    local package="$1"
    local bin_name="$2"

    # Skip pip packages (mise doesn't support them, only pipx)
    if [[ "$package" == pip:* ]]; then
        return 1
    fi

    # Check MISE first
    if is_installed_via_mise "$package"; then
        verbose_log "  ${CGR}✅ ${CYE}$package ${CBL}detectado en MISE${CNC}"
        g_already_installed_mise+=("$package")
        return 0
    fi

    # Backend-specific checks
    if [[ "$package" == npm:* ]]; then
        local npm_pkg="${package#npm:}"
        if is_installed_via_npm "$npm_pkg"; then
            verbose_log "  ${CGR}✅ ${CYE}$package ${CBL}detectado en npm global${CNC}"
            g_already_installed_npm+=("$package")
            return 0
        fi
    fi

    if [[ "$package" == pipx:* ]]; then
        local pipx_pkg="${package#pipx:}"
        if is_installed_via_pipx "$pipx_pkg"; then
            verbose_log "  ${CGR}✅ ${CYE}$package ${CBL}detectado en pipx${CNC}"
            g_already_installed_path+=("$package")
            return 0
        fi
    fi

    if [[ "$package" == gem:* ]] || [[ "$package" == ruby:* ]]; then
        local gem_pkg="${package#gem:}"
        gem_pkg="${gem_pkg#ruby:}"
        if is_installed_via_gem "$gem_pkg"; then
            verbose_log "  ${CGR}✅ ${CYE}$package ${CBL}detectado en gem${CNC}"
            g_already_installed_path+=("$package")
            return 0
        fi
    fi

    if [[ "$package" == cargo:* ]]; then
        if is_installed_via_cargo "$bin_name"; then
            verbose_log "  ${CGR}✅ ${CYE}$package ${CBL}detectado en cargo${CNC}"
            g_already_installed_path+=("$package")
            return 0
        fi
    fi

    # Final fallback: check if binary is in PATH
    if command -v "$bin_name" >/dev/null 2>&1; then
        verbose_log "  ${CGR}✅ ${CYE}$package ${CBL}detectado en PATH (binario: $bin_name)${CNC}"
        g_already_installed_path+=("$package")
        return 0
    fi

    return 1
}

function check_pacman_conflicts() {
    local package="$1"
    local bin_name="$2"
    
    # Only relevant for cargo packages on Arch Linux
    [[ "$package" != cargo:* ]] && return 1
    
    # Map cargo packages to their pacman equivalents
    local pacman_pkg="$bin_name"
    case "$bin_name" in
        bob) pacman_pkg="bob" ;;
        tree-sitter) pacman_pkg="tree-sitter" ;;
        stylua) pacman_pkg="stylua" ;;
    esac
    
    if is_installed "$pacman_pkg" 2>/dev/null; then
        verbose_log "  ${CGR}✅ ${CYE}$package ${CBL}instalado via pacman ($pacman_pkg)${CNC}"
        g_already_installed_pacman+=("$package")
        return 0
    fi
    
    return 1
}

# ============================================================================
# CONFIGURATION LOADING
# ============================================================================

function load_mise_packages() {
    local config_file="$1"
    local -n packages_ref=$2
    
    verbose_log "Buscando configuración: $config_file"
    
    if [ ! -f "$config_file" ]; then
        log_error "Archivo de configuración no encontrado: $config_file"
        return 2
    fi
    
    if ! grep -q "^MISE_PACKAGES=(" "$config_file" 2>/dev/null; then
        log_error "No se encontró el array MISE_PACKAGES en $config_file"
        return 2
    fi
    
    # Source config in controlled manner
    # shellcheck source=/dev/null
    source "$config_file"
    
    if [ "${MISE_PACKAGES+set}" != "set" ] || [ "${#MISE_PACKAGES[@]}" -eq 0 ]; then
        log_error "MISE_PACKAGES está vacío o no definido"
        return 2
    fi
    
    # Copy array to reference
    for pkg in "${MISE_PACKAGES[@]}"; do
        packages_ref+=("$pkg")
    done
    
    info "Configuración cargada: ${#packages_ref[@]} paquetes encontrados"
    return 0
}

# ============================================================================
# DISPLAY FUNCTIONS
# ============================================================================

function display_package_group() {
    local group_name="${1:-}"
    local group_icon="${2:-}"
    
    # Safely get remaining arguments (packages)
    local -a packages=()
    if [ $# -gt 2 ]; then
        shift 2
        packages=("$@")
    fi
    
    # Filter out empty strings that might come from empty array expansion
    local -a filtered_packages=()
    for pkg in "${packages[@]}"; do
        [ -n "${pkg:-}" ] && filtered_packages+=("$pkg")
    done
    packages=("${filtered_packages[@]}")
    local count=${#packages[@]}
    
    [ "${count}" -eq 0 ] && return 0
    
    printf "\n  ${BLD}${group_icon} ${CBL}${group_name}${CNC} ${CGR}(${count})${CNC}\n"
    
    # Adaptive columns: 1 column if ≤5 packages, 2 columns otherwise
    local cols=1
    [ "${count}" -gt 5 ] && cols=2
    
    local i=0
    for package in "${packages[@]}"; do
        [ $(( i % cols )) -eq 0 ] && printf "    "
        printf "%-60s" "${CYE}${package}${CNC}"
        
        if [ $cols -eq 1 ] || [ $(( (i + 1) % cols )) -eq 0 ]; then
            printf "\n"
        fi
        i=$(( i + 1 ))
    done
    
    # Ensure trailing newline for odd counts with 2 columns
    [ $cols -eq 2 ] && [ $(( i % cols )) -ne 0 ] && printf "\n"
    return 0
}

function display_packages_organized() {
    local -n packages=$1
    
    # Group packages by backend
    local -a npm_packages=() pipx_packages=() cargo_packages=()
    local -a gem_packages=() github_packages=() core_packages=()
    
    for package in "${packages[@]}"; do
        case "$package" in
            npm:*)    npm_packages+=("$package") ;;
            pipx:*)   pipx_packages+=("$package") ;;
            cargo:*)  cargo_packages+=("$package") ;;
            gem:*|ruby:*) gem_packages+=("$package") ;;
            github:*) github_packages+=("$package") ;;
            *)        core_packages+=("$package") ;;
        esac
    done
    
    # Display each group with consistent formatting
    display_package_group "NPM Packages" "📦" "${npm_packages[@]}"
    display_package_group "Pipx Packages (Python)" "🐍" "${pipx_packages[@]}"
    display_package_group "Cargo Packages (Rust)" "🦀" "${cargo_packages[@]}"
    display_package_group "Ruby Gems" "💎" "${gem_packages[@]}"
    display_package_group "GitHub Releases" "🐙" "${github_packages[@]}"
    display_package_group "Core MISE Tools" "🔧" "${core_packages[@]}"
}

# ============================================================================
# INSTALLATION FUNCTIONS
# ============================================================================

function install_package() {
    local package="$1"
    local log_file="$2"
    
    if [ "$FMISE_DRY_RUN" = true ]; then
        printf "%b\n" "${CBL}[DRY-RUN] Would install: ${CYE}$package${CNC}"
        return 0
    fi
    
    if mise use -g "$package" >>"$log_file" 2>&1; then
        return 0
    else
        return 1
    fi
}

function install_packages_sequential() {
    local -n packages=$1
    local count=0
    local total=${#packages[@]}
    local start_time=$(date +%s)
    
    for package in "${packages[@]}"; do
        count=$((count + 1))
        local pkg_start=$(date +%s)
        
        printf "%b" "${CBL}[$count/$total] Instalando: ${CYE}${package}${CNC}"
        
        if install_package "$package" "$ERROR_LOG"; then
            local duration=$(($(date +%s) - pkg_start))
            printf "%b\n" "${CGR} ✅ ${CBL}(${duration}s)${CNC}"
            g_install_count=$((g_install_count + 1))
        else
            printf "%b\n" "${CRE} ❌ Error${CNC}"
            g_mise_failed+=("$package")
            log_error "Failed to install: $package"
        fi
    done
    
    g_total_time=$(($(date +%s) - start_time))
}

function install_packages_parallel() {
    local -n packages=$1
    local total=${#packages[@]}
    local max_jobs=4
    local -a pids=()
    local temp_dir=$(mktemp -d)
    
    info "Instalación paralela iniciada (máximo $max_jobs trabajos simultáneos)"
    
    for package in "${packages[@]}"; do
        # Wait if we've reached max parallel jobs
        while [ ${#pids[@]} -ge $max_jobs ]; do
            for i in "${!pids[@]}"; do
                if ! kill -0 "${pids[$i]}" 2>/dev/null; then
                    unset 'pids[i]'
                fi
            done
            pids=("${pids[@]}")  # Re-index array
            sleep 0.1
        done
        
        # Start installation in background
        (
            local result_file="$temp_dir/${package//\//_}.result"
            if install_package "$package" "$ERROR_LOG"; then
                echo "success" > "$result_file"
            else
                echo "failure" > "$result_file"
            fi
        ) &
        pids+=($!)
    done
    
    # Wait for all background jobs
    wait
    
    # Collect results
    for package in "${packages[@]}"; do
        local result_file="$temp_dir/${package//\//_}.result"
        if [ -f "$result_file" ]; then
            if grep -q "success" "$result_file"; then
                g_install_count=$((g_install_count + 1))
            else
                g_mise_failed+=("$package")
            fi
        fi
    done
    
    rm -rf "$temp_dir"
}

# ============================================================================
# REPORTING FUNCTIONS
# ============================================================================

function generate_summary() {
    local total_packages="$1"
    local already_installed=$(( 
        ${#g_already_installed_mise[@]} + 
        ${#g_already_installed_path[@]} + 
        ${#g_already_installed_npm[@]} + 
        ${#g_already_installed_pacman[@]} 
    ))
    local successfully_installed=$(( ${#g_missing_mise[@]} - ${#g_mise_failed[@]} ))
    local failed_count=${#g_mise_failed[@]}
    
    printf "\n%b\n" "${BLD}${CYE}╔══════════════════════════════════════════════════════════════════════╗${CNC}"
    printf "%b\n" "${BLD}${CYE}║                    📊 RESUMEN DE INSTALACIÓN                        ║${CNC}"
    printf "%b\n" "${BLD}${CYE}╚══════════════════════════════════════════════════════════════════════╝${CNC}"
    
    # Statistics
    printf "\n%b\n" "${BLD}${CBL}📈 Estadísticas Generales:${CNC}"
    printf "%b\n" "${CBL}   Total procesados:     ${CYE}${total_packages}${CNC}"
    printf "%b\n" "${CGR}   Ya instalados:        ${CYE}${already_installed}${CNC}"
    
    # Breakdown by source
    if [ ${#g_already_installed_mise[@]} -gt 0 ]; then
        printf "%b\n" "${CGR}     → Via MISE:         ${CYE}${#g_already_installed_mise[@]}${CNC}"
    fi
    if [ ${#g_already_installed_path[@]} -gt 0 ]; then
        printf "%b\n" "${CGR}     → En PATH:          ${CYE}${#g_already_installed_path[@]}${CNC}"
    fi
    if [ ${#g_already_installed_npm[@]} -gt 0 ]; then
        printf "%b\n" "${CGR}     → Via NPM:          ${CYE}${#g_already_installed_npm[@]}${CNC}"
    fi
    if [ ${#g_already_installed_pacman[@]} -gt 0 ]; then
        printf "%b\n" "${CGR}     → Via Pacman:       ${CYE}${#g_already_installed_pacman[@]}${CNC}"
    fi
    
    if [ $successfully_installed -gt 0 ]; then
        printf "%b\n" "${CGR}   Recién instalados:    ${CYE}${successfully_installed}${CNC}"
        if [ $g_total_time -gt 0 ]; then
            printf "%b\n" "${CBL}   Tiempo total:         ${CYE}$(format_duration $g_total_time)${CNC}"
            local avg_time=$((g_total_time / successfully_installed))
            printf "%b\n" "${CBL}   Promedio/paquete:     ${CYE}${avg_time}s${CNC}"
        fi
    fi
    
    # Failed packages
    if [ $failed_count -gt 0 ]; then
        printf "\n%b\n" "${BLD}${CRE}❌ Paquetes Fallidos (${failed_count}):${CNC}"
        for pkg in "${g_mise_failed[@]}"; do
            printf "%b\n" "${CRE}   • $pkg${CNC}"
        done
        printf "\n%b\n" "${CYE}   📋 Revisa el log: ${CBL}${ERROR_LOG}${CNC}"
    fi
    
    # Skipped packages
    if [ ${#g_skipped_packages[@]} -gt 0 ]; then
        printf "\n%b\n" "${BLD}${CYE}⚠️  Paquetes Omitidos (${#g_skipped_packages[@]}):${CNC}"
        for pkg in "${g_skipped_packages[@]}"; do
            local pip_pkg="${pkg#pip:}"
            printf "%b\n" "${CYE}   • $pkg ${CBL}→ pip install --user $pip_pkg${CNC}"
        done
    fi
    
    # Recommendations
    printf "\n%b\n" "${BLD}${CYE}╔══════════════════════════════════════════════════════════════════════╗${CNC}"
    printf "%b\n" "${BLD}${CYE}║                      💡 RECOMENDACIONES                              ║${CNC}"
    printf "%b\n" "${BLD}${CYE}╚══════════════════════════════════════════════════════════════════════╝${CNC}"
    
    if [ $failed_count -gt 0 ]; then
        printf "\n%b\n" "${CRE}🔧 Para paquetes fallidos:${CNC}"
        printf "%b\n" "${CRE}   • Verifica dependencias del sistema${CNC}"
        printf "%b\n" "${CRE}   • Revisa logs: ${CBL}tail -f ${ERROR_LOG}${CNC}"
        printf "%b\n" "${CRE}   • Reinstala manualmente: ${CBL}mise use -g <paquete>${CNC}"
    fi
    
    printf "\n%b\n" "${CBL}📚 Comandos útiles:${CNC}"
    printf "%b\n" "${CBL}   mise list              ${CNC}# Ver paquetes instalados"
    printf "%b\n" "${CBL}   mise upgrade           ${CNC}# Actualizar todos los paquetes"
    printf "%b\n" "${CBL}   mise prune             ${CNC}# Limpiar versiones no usadas"
    printf "%b\n" "${CBL}   mise doctor            ${CNC}# Verificar configuración"
    printf "%b\n" "${CBL}   eval \"\$(mise activate bash)\" ${CNC}# Activar shims en shell"
    
    # Final status
    printf "\n%b\n" "${BLD}${CYE}╔══════════════════════════════════════════════════════════════════════╗${CNC}"
    printf "%b\n" "${BLD}${CYE}║                       📈 ESTADO FINAL                                ║${CNC}"
    printf "%b\n" "${BLD}${CYE}╚══════════════════════════════════════════════════════════════════════╝${CNC}"
    
    if [ $failed_count -eq 0 ] && [ ${#g_missing_mise[@]} -gt 0 ]; then
        printf "\n%b\n" "${CGR}${BLD}   🎉 ¡Instalación completada exitosamente!${CNC}"
        printf "%b\n" "${CGR}      Todos los paquetes MISE están listos para usar${CNC}"
    elif [ $failed_count -eq 0 ] && [ ${#g_missing_mise[@]} -eq 0 ]; then
        printf "\n%b\n" "${CGR}${BLD}   ✅ Sistema actualizado${CNC}"
        printf "%b\n" "${CGR}      Todos los paquetes ya estaban instalados${CNC}"
    else
        local success_rate=$(( (total_packages - failed_count) * 100 / total_packages ))
        printf "\n%b\n" "${CYE}   📊 Tasa de éxito: ${CGR}${success_rate}%%${CNC}"
        printf "%b\n" "${CYE}   ⚠️  Algunos paquetes requieren atención${CNC}"
    fi
    
    printf "\n"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

function main() {
    local force_mode=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            -f|--force)
                force_mode=true
                shift
                ;;
            -p|--parallel)
                FMISE_PARALLEL=true
                shift
                ;;
            -v|--verbose)
                FMISE_VERBOSE=true
                shift
                ;;
            -d|--dry-run)
                FMISE_DRY_RUN=true
                shift
                ;;
            *)
                log_error "Opción desconocida: $1"
                usage
                exit 2
                ;;
        esac
    done
    
    # Configuration
    SETUP_CONFIG="${SETUP_CONFIG:-${HOME}/.config/dotmarchy/setup.conf}"
    FMISE_START_TIME=$(date +%s)
    
    # Banner
    printf "\n%b\n" "${BLD}${CYE}╔══════════════════════════════════════════════════════════════════════╗${CNC}"
    printf "%b\n" "${BLD}${CYE}║               🚀 MISE Package Manager v${SCRIPT_VERSION}                      ║${CNC}"
    printf "%b\n" "${BLD}${CYE}╚══════════════════════════════════════════════════════════════════════╝${CNC}"
    
    if [ "$FMISE_DRY_RUN" = true ]; then
        printf "%b\n" "${CYE}${BLD}⚠️  MODO DRY-RUN: No se instalará nada${CNC}\n"
    fi
    
    # Check execution mode
    if [ "${INSTALL_EXTRAS:-0}" -ne 1 ] && [ "$force_mode" != "true" ]; then
        warn "INSTALL_EXTRAS no activado. Use --force para modo standalone."
        info "Ejecución: ${CYE}$SCRIPT_NAME --force${CNC}"
        return 0
    fi
    
    # Verify MISE is available
    if ! command -v mise >/dev/null 2>&1; then
        log_error "MISE no está instalado en el sistema"
        cat >&2 << EOF

${BLD}${CRE}╔══════════════════════════════════════════════════════════════╗${CNC}
${BLD}${CRE}║            ❌ MISE No Disponible                            ║${CNC}
${BLD}${CRE}╚══════════════════════════════════════════════════════════════╝${CNC}

${BLD}Instalación:${CNC}
  ${CGR}Arch Linux:${CNC}    sudo pacman -S mise
  ${CGR}Otros sistemas:${CNC} curl https://mise.run | sh

${BLD}Documentación:${CNC}
  ${CBL}https://mise.jdx.dev${CNC}

EOF
        return 3
    fi
    
    info "MISE detectado: $(mise --version 2>/dev/null || echo 'versión desconocida')"
    
    # Load packages from configuration
    local -a mise_packages=()
    if ! load_mise_packages "$SETUP_CONFIG" mise_packages; then
        log_error "No se pudo cargar la configuración"
        return 2
    fi
    
    if [ "${#mise_packages[@]}" -eq 0 ]; then
        warn "No hay paquetes MISE configurados"
        return 0
    fi
    
    # Display package inventory
    printf "\n%b\n" "${BLD}${CYE}╔══════════════════════════════════════════════════════════════════════╗${CNC}"
    printf "%b\n" "${BLD}${CYE}║              📦 INVENTARIO DE PAQUETES (${#mise_packages[@]})                          ║${CNC}"
    printf "%b\n" "${BLD}${CYE}╚══════════════════════════════════════════════════════════════════════╝${CNC}"
    display_packages_organized mise_packages
    
    printf "\n%b\n" "${BLD}${CYE}🔍 Verificando estado de instalación...${CNC}\n"
    
    # Verify each package
    for package in "${mise_packages[@]}"; do
        local bin_name
        bin_name=$(extract_binary_name "$package")
        
        # Skip unsupported packages
        if [[ "$package" == pip:* ]]; then
            warn "⚠️  Omitiendo $package (use pipx: en lugar de pip:)"
            g_skipped_packages+=("$package")
            continue
        fi
        
        # Check for system package conflicts
        if check_pacman_conflicts "$package" "$bin_name"; then
            continue
        fi
        
        # Check if already installed
        if ! is_package_installed "$package" "$bin_name"; then
            g_missing_mise+=("$package")
            verbose_log "  ${CRE}❌ ${CYE}$package ${CRE}pendiente de instalación${CNC}"
        fi
    done
    
    # Display skipped packages
    if [ "${#g_skipped_packages[@]}" -gt 0 ]; then
        printf "\n%b\n" "${CYE}${BLD}⚠️  Paquetes Omitidos (${#g_skipped_packages[@]}):${CNC}"
        for pkg in "${g_skipped_packages[@]}"; do
            local pip_pkg="${pkg#pip:}"
            printf "%b\n" "${CYE}   • $pkg ${CBL}→ pip install --user $pip_pkg${CNC}"
        done
    fi
    
    # Install missing packages
    if [ "${#g_missing_mise[@]}" -gt 0 ]; then
        printf "\n%b\n" "${BLD}${CYE}╔══════════════════════════════════════════════════════════════════════╗${CNC}"
        printf "%b\n" "${BLD}${CYE}║            🚀 INSTALANDO ${#g_missing_mise[@]} PAQUETES                              ║${CNC}"
        printf "%b\n" "${BLD}${CYE}╚══════════════════════════════════════════════════════════════════════╝${CNC}\n"
        
        if [ "$FMISE_PARALLEL" = true ]; then
            install_packages_parallel g_missing_mise
        else
            install_packages_sequential g_missing_mise
        fi
        
        printf "\n%b\n" "${BLD}${CYE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CNC}"
        
        if [ "${#g_mise_failed[@]}" -gt 0 ]; then
            printf "%b\n" "${CRE}${BLD}❌ ${#g_mise_failed[@]}/${#g_missing_mise[@]} paquetes fallaron${CNC}"
        else
            printf "%b\n" "${CGR}${BLD}✅ Todos los paquetes instalados correctamente${CNC}"
        fi
        
        printf "%b\n" "${BLD}${CYE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CNC}"
    else
        printf "\n%b\n" "${BLD}${CYE}╔══════════════════════════════════════════════════════════════════════╗${CNC}"
        printf "%b\n" "${BLD}${CYE}║              ✅ SISTEMA ACTUALIZADO                                  ║${CNC}"
        printf "%b\n" "${BLD}${CYE}╚══════════════════════════════════════════════════════════════════════╝${CNC}"
        printf "\n%b\n" "${CGR}   Todos los paquetes ya están instalados${CNC}"
    fi
    
    # Generate comprehensive summary
    generate_summary "${#mise_packages[@]}"
    
    # Calculate total execution time
    local total_elapsed=$(($(date +%s) - FMISE_START_TIME))
    
    printf "\n%b\n" "${BLD}${CYE}╔══════════════════════════════════════════════════════════════════════╗${CNC}"
    printf "%b\n" "${BLD}${CYE}║                    🎉 PROCESO COMPLETADO                             ║${CNC}"
    printf "%b\n" "${BLD}${CYE}╚══════════════════════════════════════════════════════════════════════╝${CNC}"
    printf "\n%b\n" "${CBL}   Tiempo total de ejecución: ${CYE}$(format_duration $total_elapsed)${CNC}"
    printf "%b\n" "${CBL}   Paquetes procesados:        ${CYE}${#mise_packages[@]}${CNC}"
    printf "%b\n" "${CBL}   Instalados exitosamente:    ${CGR}${g_install_count}${CNC}"
    
    if [ "${#g_mise_failed[@]}" -gt 0 ]; then
        printf "%b\n" "${CBL}   Fallos:                     ${CRE}${#g_mise_failed[@]}${CNC}\n"
        return 1
    fi
    
    printf "\n"
    return 0
}

# ============================================================================
# SCRIPT ENTRY POINT
# ============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi