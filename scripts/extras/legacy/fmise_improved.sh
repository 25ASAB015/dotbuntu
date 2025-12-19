#!/usr/bin/env bash
# shellcheck shell=bash
# shfmt: -ln=bash
#
# fmise - Install MISE packages globally
#
# Installs MISE packages from config or defaults. Only runs if --extras flag is set.
#
# @params
# Globals:
#   ${INSTALL_EXTRAS}: Must be 1 to run
#   ${SETUP_CONFIG}: Path to configuration file
#   ${ERROR_LOG}: Error log path
# Arguments:
#   -h|--help: Show help
#   --force: Force execution in standalone mode
# Returns:
#   0 on success, 1 on failure

set -Eeuo pipefail

# Get script directory and source dependencies
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly mydir="$SCRIPT_DIR"
readonly HELPER_DIR="${SCRIPT_DIR}/../../helper"

# shellcheck source=/dev/null
source "${HELPER_DIR}/load_helpers.sh"
load_helpers "${HELPER_DIR}" set_variable colors logger prompts checks
trap on_error ERR

# Global tracking arrays - declared at script level
declare -a missing_mise=()
declare -a skipped_packages=()
declare -a already_installed_mise=()
declare -a already_installed_path=()
declare -a already_installed_npm=()
declare -a already_installed_pacman=()
declare -a mise_failed=()

function usage() {
    cat << EOF
Usage: fmise [-h|--help|--force]

Install MISE packages globally. Requires --extras flag when called from dotmarchy.

Optional arguments:
  -h, --help      Show this help message
  --force         Force execution (standalone mode)

Configuration:
  Reads MISE_PACKAGES array from: ~/.config/dotmarchy/setup.conf
  
Examples:
  # From dotmarchy with --extras flag
  ./install_all_dependencies.sh --extras
  
  # Standalone mode
  ./fmise --force
EOF
}

function is_package_installed() {
    local package="$1"
    local bin_name="$2"

    # Skip pip packages - mise doesn't support them
    if [[ "$package" == pip:* ]]; then
        return 1
    fi

    # Check if installed via mise
    if mise list 2>/dev/null | grep -qE "^${package}[[:space:]]"; then
        printf "%b\n" "  ${CGR}✅ ${CYE}$package ${CBL}ya está instalado en mise${CNC}"
        already_installed_mise+=("$package")
        return 0
    fi

    # Special handling for npm packages - check global npm
    if [[ "$package" == npm:* ]]; then
        local npm_pkg_name="${package#npm:}"
        # Remove @version if present
        npm_pkg_name="${npm_pkg_name%@*}"
        
        # Escape special characters for grep
        local escaped_pkg_name
        escaped_pkg_name=$(printf '%s\n' "$npm_pkg_name" | sed 's/[[\.*^$()+?{|]/\\&/g')
        
        if npm list -g --depth=0 2>/dev/null | grep -qE "(├──|└──) ${escaped_pkg_name}@"; then
            printf "%b\n" "  ${CGR}✅ ${CYE}$package ${CBL}ya está instalado globalmente con npm${CNC}"
            already_installed_npm+=("$package")
            return 0
        fi
    fi

    # Check if binary is available in PATH
    if command -v "$bin_name" >/dev/null 2>&1; then
        printf "%b\n" "  ${CGR}✅ ${CYE}$package ${CBL}ya está disponible en PATH (binario: $bin_name)${CNC}"
        already_installed_path+=("$package")
        return 0
    fi

    return 1
}

function generate_summary() {
    local total_packages="${1:-0}"
    local already_installed=$(( ${#already_installed_mise[@]} + ${#already_installed_path[@]} + ${#already_installed_npm[@]} + ${#already_installed_pacman[@]} ))
    local successfully_installed=$(( ${#missing_mise[@]} - ${#mise_failed[@]} ))
    local failed_count=${#mise_failed[@]}

    printf "\n%b\n" "${BLD}${CYE}📊 RESUMEN DETALLADO DE INSTALACIÓN${CNC}"
    printf "%b\n" "${BLD}${CYE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CNC}"

    # Total overview
    printf "%b\n" "${CBL}📦 Total de paquetes procesados: ${CYE}${total_packages}${CNC}"
    printf "%b\n" "${CGR}✅ Ya instalados: ${CYE}${already_installed}${CNC}"

    # Already installed breakdown
    if [ ${#already_installed_mise[@]} -gt 0 ]; then
        printf "%b\n" "${CGR}   • En MISE: ${CYE}${#already_installed_mise[@]}${CNC}"
    fi
    if [ ${#already_installed_path[@]} -gt 0 ]; then
        printf "%b\n" "${CGR}   • En PATH: ${CYE}${#already_installed_path[@]}${CNC}"
    fi
    if [ ${#already_installed_npm[@]} -gt 0 ]; then
        printf "%b\n" "${CGR}   • Via NPM global: ${CYE}${#already_installed_npm[@]}${CNC}"
    fi
    if [ ${#already_installed_pacman[@]} -gt 0 ]; then
        printf "%b\n" "${CGR}   • Via Pacman: ${CYE}${#already_installed_pacman[@]}${CNC}"
    fi

    # Successfully installed
    if [ $successfully_installed -gt 0 ]; then
        printf "%b\n" "${CGR}✅ Instalados correctamente: ${CYE}${successfully_installed}${CNC}"
    fi

    # Failed packages
    if [ $failed_count -gt 0 ]; then
        printf "%b\n" "${CRE}❌ Fallaron en instalarse: ${CYE}${failed_count}${CNC}"
        for pkg in "${mise_failed[@]}"; do
            printf "%b\n" "${CRE}   • $pkg${CNC}"
        done
        printf "%b\n" "${CYE}   → Revisa el log de errores: ${ERROR_LOG}${CNC}"
    fi

    # Skipped packages
    if [ ${#skipped_packages[@]} -gt 0 ]; then
        printf "%b\n" "${CYE}⚠️  Omitidos (${#skipped_packages[@]}):${CNC}"
        for pkg in "${skipped_packages[@]}"; do
            local pip_pkg="${pkg#pip:}"
            printf "%b\n" "${CYE}   • $pkg ${CBL}(instalar con: pip install $pip_pkg)${CNC}"
        done
    fi

    # Recommendations
    printf "\n%b\n" "${BLD}${CYE}💡 RECOMENDACIONES${CNC}"
    printf "%b\n" "${BLD}${CYE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CNC}"

    if [ $failed_count -gt 0 ]; then
        printf "%b\n" "${CRE}• Paquetes que fallaron pueden requerir dependencias del sistema${CNC}"
        printf "%b\n" "${CRE}• Revisa los logs en: ${ERROR_LOG}${CNC}"
        printf "%b\n" "${CRE}• Intenta reinstalar manualmente: mise use -g <paquete>${CNC}"
    fi

    printf "%b\n" "${CBL}• Verifica las versiones instaladas: ${CYE}mise list${CNC}"
    printf "%b\n" "${CBL}• Actualiza regularmente: ${CYE}mise upgrade${CNC}"
    printf "%b\n" "${CBL}• Usa shims automáticos: ${CYE}eval \"\$(mise activate bash)\"${CNC}"

    # Final status
    printf "\n%b\n" "${BLD}${CYE}📈 ESTADO FINAL${CNC}"
    printf "%b\n" "${BLD}${CYE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CNC}"

    if [ $failed_count -eq 0 ] && [ ${#missing_mise[@]} -gt 0 ]; then
        printf "%b\n" "${CGR}${BLD}🎉 ¡Instalación completada exitosamente!${CNC}"
        printf "%b\n" "${CGR}   Todos los paquetes MISE están listos para usar${CNC}"
    elif [ $failed_count -eq 0 ] && [ ${#missing_mise[@]} -eq 0 ]; then
        printf "%b\n" "${CGR}${BLD}✅ Todos los paquetes ya estaban instalados${CNC}"
    else
        local success_rate=$(( (total_packages - failed_count) * 100 / total_packages ))
        printf "%b\n" "${CYE}📊 Tasa de éxito: ${success_rate}%${CNC}"
        printf "%b\n" "${CYE}⚠️  Revisa los paquetes que fallaron antes de continuar${CNC}"
    fi
}

function load_mise_packages() {
    local config_file="$1"
    local -n packages_ref=$2  # nameref to array
    
    info "Buscando archivo de configuración: $config_file"
    
    if [ ! -f "$config_file" ]; then
        warn "Archivo de configuración no encontrado: $config_file"
        return 1
    fi
    
    info "Archivo de configuración encontrado, cargando..."
    
    # Source the config file in a subshell to extract the array safely
    local temp_file
    temp_file=$(mktemp)
    trap 'rm -f "$temp_file"' RETURN
    
    # Extract MISE_PACKAGES array from config file
    if grep -q "^MISE_PACKAGES=(" "$config_file" 2>/dev/null; then
        # shellcheck source=/dev/null
        source "$config_file"
        
        if [ "${MISE_PACKAGES+set}" = "set" ] && [ "${#MISE_PACKAGES[@]}" -gt 0 ]; then
            # Copy array to reference
            for pkg in "${MISE_PACKAGES[@]}"; do
                packages_ref+=("$pkg")
            done
            info "Encontrados ${#packages_ref[@]} paquetes en MISE_PACKAGES"
            return 0
        else
            warn "MISE_PACKAGES no está definido o está vacío en $config_file"
            return 1
        fi
    else
        warn "No se encontró MISE_PACKAGES en $config_file"
        return 1
    fi
}

function extract_binary_name() {
    local package="$1"
    local bin_name="$package"
    
    # Remove backend prefix (npm:, cargo:, etc.)
    if [[ "$package" == *":"* ]]; then
        bin_name="${package#*:}"
    fi
    
    # Remove version suffix (@latest, @1.0.0, etc.)
    if [[ "$bin_name" == *"@"* ]]; then
        bin_name="${bin_name%@*}"
    fi
    
    # Handle scoped packages (@org/package -> package)
    if [[ "$bin_name" == @*/* ]]; then
        bin_name="${bin_name##*/}"
    fi
    
    echo "$bin_name"
}

function check_pacman_conflicts() {
    local package="$1"
    local bin_name="$2"
    
    # Only check cargo packages for pacman conflicts
    if [[ "$package" != cargo:* ]]; then
        return 1
    fi
    
    # Map common cargo packages to their pacman equivalents
    local pacman_pkg="$bin_name"
    case "$bin_name" in
        bob-nvim) pacman_pkg="bob" ;;
        tree-sitter-cli) pacman_pkg="tree-sitter" ;;
        stylua) pacman_pkg="stylua" ;;
    esac
    
    if is_installed "$pacman_pkg" 2>/dev/null; then
        printf "%b\n" "  ${CGR}✅ ${CYE}$package ${CBL}ya está instalado con pacman ($pacman_pkg)${CNC}"
        already_installed_pacman+=("$package")
        return 0
    fi
    
    return 1
}

function display_packages_grid() {
    local -n packages=$1
    local cols=3
    local i=0
    
    for package in "${packages[@]}"; do
        if [ $(( i % cols )) -eq 0 ]; then
            printf "\n  "
        fi
        printf "%-35s" "${CBL}• ${CYE}${package}${CNC}"
        i=$(( i + 1 ))
    done
    printf "\n"
}

function main() {
    local force_mode=false

    # Parse arguments
    case "${1:-}" in
        -h|--help)
            usage
            exit 0
            ;;
        --force)
            force_mode=true
            shift
            ;;
    esac

    # Configuration file path
    SETUP_CONFIG="${SETUP_CONFIG:-${HOME}/.config/dotmarchy/setup.conf}"

    info "fmise: Iniciando verificación de paquetes MISE..."

    # Only run if --extras is set (when called from dotmarchy) or --force is used
    if [ "${INSTALL_EXTRAS:-0}" -ne 1 ] && [ "$force_mode" != "true" ]; then
        warn "fmise: INSTALL_EXTRAS no está activado, saltando instalación de paquetes MISE"
        warn "Para ejecutar standalone: ./fmise --force"
        return 0
    fi

    logo "Instalando paquetes MISE globales"
    
    # Check if mise is installed
    if ! command -v mise >/dev/null 2>&1; then
        log_error "mise no está instalado"
        cat >&2 << EOF

Para instalar mise:
  En Arch Linux:    sudo pacman -S mise
  Otros sistemas:   curl https://mise.run | sh
  
Documentación:      https://mise.jdx.dev

EOF
        return 1
    fi
    
    # Load package list from config
    local -a mise_packages=()
    if ! load_mise_packages "$SETUP_CONFIG" mise_packages; then
        warn "No se pudieron cargar paquetes desde $SETUP_CONFIG"
        return 0
    fi
    
    # If no packages configured, exit gracefully
    if [ "${#mise_packages[@]}" -eq 0 ]; then
        warn "No hay paquetes MISE configurados para instalar"
        return 0
    fi
    
    # Display configured packages
    printf "\n%b\n" "${BLD}${CYE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CNC}"
    printf "%b\n" "${BLD}${CBL}📦 Paquetes configurados (${#mise_packages[@]}):${CNC}"
    printf "%b\n" "${BLD}${CYE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CNC}"
    display_packages_grid mise_packages
    
    printf "\n%b\n\n" "${BLD}${CYE}🔍 Verificando paquetes MISE...${CNC}"
    
    # Check each package
    for package in "${mise_packages[@]}"; do
        # Extract binary name
        local bin_name
        bin_name=$(extract_binary_name "$package")

        # Skip pip packages (mise doesn't support pip, only pipx)
        if [[ "$package" == pip:* ]]; then
            warn "Saltando $package (mise no soporta 'pip:', solo 'pipx:' para aplicaciones CLI)"
            skipped_packages+=("$package")
            continue
        fi

        # Check for pacman conflicts with cargo packages
        if check_pacman_conflicts "$package" "$bin_name"; then
            continue
        fi

        # Check if package is already available
        if ! is_package_installed "$package" "$bin_name"; then
            missing_mise+=("$package")
            printf "%b\n" "  ${CRE}❌ ${CYE}$package ${CRE}no instalado${CNC}"
        fi
    done
    
    # Display skipped packages if any
    if [ "${#skipped_packages[@]}" -gt 0 ]; then
        printf "\n%b\n" "${CYE}${BLD}⚠️  Paquetes omitidos (${#skipped_packages[@]}):${CNC}"
        for pkg in "${skipped_packages[@]}"; do
            local pip_pkg_name="${pkg#pip:}"
            printf "%b\n" "${CYE}  • $pkg ${CBL}(instalar con: pip install --user $pip_pkg_name)${CNC}"
        done
    fi
    
    # Install missing packages
    if [ "${#missing_mise[@]}" -gt 0 ]; then
        printf "\n%b\n" "${BLD}${CYE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CNC}"
        printf "%b\n" "${BLD}${CBL}🚀 Instalando ${#missing_mise[@]} paquetes MISE...${CNC}"
        printf "%b\n\n" "${BLD}${CYE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CNC}"

        local count=0
        for package in "${missing_mise[@]}"; do
            count=$((count + 1))
            printf "%b" "${CBL}[$count/${#missing_mise[@]}] Instalando: ${CYE}$package${CNC}..."
            
            if mise use -g "$package" >>"$ERROR_LOG" 2>&1; then
                printf "%b\n" "${CGR} ✅${CNC}"
            else
                printf "%b\n" "${CRE} ❌${CNC}"
                mise_failed+=("$package")
                log_error "Failed to install $package - check $ERROR_LOG"
            fi
        done

        printf "\n%b\n" "${BLD}${CYE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CNC}"
        if [ "${#mise_failed[@]}" -gt 0 ]; then
            printf "%b\n" "${CRE}${BLD}❌ Algunos paquetes fallaron (${#mise_failed[@]}/${#missing_mise[@]})${CNC}"
        else
            printf "%b\n" "${CGR}${BLD}✅ Todos los paquetes instalados correctamente${CNC}"
        fi
        printf "%b\n" "${BLD}${CYE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CNC}"
    else
        printf "\n%b\n" "${BLD}${CYE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CNC}"
        printf "%b\n" "${CGR}${BLD}✅ Todos los paquetes ya están instalados${CNC}"
        printf "%b\n" "${BLD}${CYE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CNC}"
    fi
    
    # Generate comprehensive summary
    generate_summary "${#mise_packages[@]}"

    printf "\n%b\n" "${BLD}${CYE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CNC}"
    printf "%b\n" "${BLD}${CBL}🎉 fmise: Proceso completado${CNC}"
    printf "%b\n" "${BLD}${CYE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CNC}"
    
    # Return appropriate exit code
    if [ "${#mise_failed[@]}" -gt 0 ]; then
        return 1
    fi
    return 0
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && main "$@"