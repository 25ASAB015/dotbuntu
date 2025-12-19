#!/usr/bin/env bash
# shellcheck shell=bash
#
# prompts.sh - User interaction and CLI parsing for dotmarchy
#
# Provides the user-facing prompts (logo, usage, welcome, farewell) and CLI
# parsing. Messages for users stay in Spanish; code, variables, and comments
# remain in English for consistency with project standards.

set -Eeuo pipefail

# Source dependencies if not already loaded (mirrors checks.sh behavior)
: "${HELPER_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"

if [ -z "${CGR:-}" ]; then
    source "${HELPER_DIR}/colors.sh" || {
        echo "ERROR: Cannot load colors.sh" >&2
        exit 1
    }
fi

if ! command -v log_error >/dev/null 2>&1; then
    source "${HELPER_DIR}/logger.sh" || {
        echo "ERROR: Cannot load logger.sh" >&2
        exit 1
    }
fi

#######################################
# Global Variables Documentation
# Available from dependencies:
#   colors.sh: BLD, CGR, CRE, CYE, CBL, CNC
#   logger.sh: info(), warn(), log_error(), debug()
# Globals consumed or modified:
#   REPO_URL, INSTALL_EXTRAS, SETUP_ENVIRONMENT, VERIFY_MODE,
#   SETUP_CONFIG, CORE_DEPENDENCIES, ERROR_LOG,
#   DEFAULT_EXTRA_DEPENDENCIES, DEFAULT_EXTRA_CHAOTIC_DEPENDENCIES,
#   DEFAULT_EXTRA_AUR_APPS, DEFAULT_EXTRA_NPM_PACKAGES,
#   EXTRA_DEPENDENCIES, EXTRA_CHAOTIC_DEPENDENCIES, EXTRA_AUR_APPS,
#   EXTRA_NPM_PACKAGES, CARGO_PACKAGES, PIPX_PACKAGES, GEM_PACKAGES,
#   DIRECTORIES, GIT_REPOS, SCRIPTS, SHELL_LINES,
#   INSTALL_START_TIME, PACKAGES_INSTALLED, PACKAGES_SKIPPED
#######################################

# Internal guards and defaults
SETUP_CONFIG_LOADED=${SETUP_CONFIG_LOADED:-0}
readonly DEFAULT_GITHUB_COUNT=7   # NVM, Lua-LS, lazygit, gh, zoxide, tldr, deno
readonly DEFAULT_CARGO_COUNT=3    # bob-nvim, tree-sitter-cli, stylua
readonly DEFAULT_PIPX_COUNT=11    # doq, beautysh, black, ruff, nvr, flake8, pylsp, pyright, rich-cli, trash-cli, codespell
readonly DEFAULT_GEM_COUNT=1      # neovim

#######################################
# Display ASCII logo with message
# Arguments:
#   $1: Message text to display below logo
#######################################
logo() {
    local text="$1"
    printf "%b" "
   ▗▖                              ▗▖        
   ▐▌      ▐▌                      ▐▌        
 ▟█▟▌ ▟█▙ ▐███ ▐█▙█▖ ▟██▖ █▟█▌ ▟██▖▐▙██▖▝█ █▌
▐▛ ▜▌▐▛ ▜▌ ▐▌  ▐▌█▐▌ ▘▄▟▌ █▘  ▐▛  ▘▐▛ ▐▌ █▖█ 
▐▌ ▐▌▐▌ ▐▌ ▐▌  ▐▌█▐▌▗█▀▜▌ █   ▐▌   ▐▌ ▐▌ ▐█▛ 
▝█▄█▌▝█▄█▘ ▐▙▄ ▐▌█▐▌▐▙▄█▌ █   ▝█▄▄▌▐▌ ▐▌  █▌ 
 ▝▀▝▘ ▝▀▘   ▀▀ ▝▘▀▝▘ ▀▀▝▘ ▀    ▝▀▀ ▝▘ ▝▘  █  
                                         █▌  

   ${BLD}${CRE}[ ${CYE}${text} ${CRE}]${CNC}\n\n"
}

#######################################
# Public functions (primary API)
#######################################

# logo()               - Display ASCII logo with custom message
# welcome()            - Show welcome flow and request confirmation
# farewell()           - Show final summary after installation

#######################################
# Show welcome screen and request confirmation
# Returns:
#   0 if user confirms, exits 0 if user cancels
#######################################
welcome() {
    clear_screen
    logo "Bienvenido a dotmarchy, $USER"
    show_welcome_intro
    show_basic_operations
    show_extras_section
    show_setup_section
    show_safety_section
    prompt_user_confirmation
}

#######################################
# Farewell message with installation summary
#######################################
farewell() {
    local end_time
    local duration
    local minutes
    local seconds

    end_time=$(date +%s)
    duration=$((end_time - INSTALL_START_TIME))
    minutes=$((duration / 60))
    seconds=$((duration % 60))

    clear_screen
    print_farewell_banner
    print_completion_header minutes seconds
    print_operation_summary
    print_next_steps
    print_resources
    sleep 2
}

#######################################
# Helper functions - config and counts
#######################################

load_setup_configuration_once() {
    [ "${SETUP_CONFIG_LOADED}" -eq 1 ] && return 0
    if [ -r "${SETUP_CONFIG}" ]; then
        # shellcheck source=/dev/null
        source "${SETUP_CONFIG}"
        SETUP_CONFIG_LOADED=1
        return 0
    fi
    return 1
}

count_words() {
    local text="$1"
    [ -z "$text" ] && {
        echo 0
        return 0
    }
    set -- $text
    echo $#
}

calculate_core_count() {
    count_words "${CORE_DEPENDENCIES:-}"
}

calculate_extra_totals() {
    local -n dev_ref=$1
    local -n chaotic_ref=$2
    local -n aur_ref=$3
    local -n npm_ref=$4
    local -n cargo_ref=$5
    local -n pipx_ref=$6
    local -n gem_ref=$7
    local -n total_ref=$8

    dev_ref=$(count_words "${DEFAULT_EXTRA_DEPENDENCIES}")
    chaotic_ref=$(count_words "${DEFAULT_EXTRA_CHAOTIC_DEPENDENCIES}")
    aur_ref=$(count_words "${DEFAULT_EXTRA_AUR_APPS}")
    npm_ref=$(count_words "${DEFAULT_EXTRA_NPM_PACKAGES}")
    cargo_ref=${DEFAULT_CARGO_COUNT}
    pipx_ref=${DEFAULT_PIPX_COUNT}
    gem_ref=${DEFAULT_GEM_COUNT}

    if load_setup_configuration_once; then
        dev_ref=${#EXTRA_DEPENDENCIES[@]}
        chaotic_ref=${#EXTRA_CHAOTIC_DEPENDENCIES[@]}
        aur_ref=${#EXTRA_AUR_APPS[@]}
        npm_ref=${#EXTRA_NPM_PACKAGES[@]}
        cargo_ref=${#CARGO_PACKAGES[@]}
        pipx_ref=${#PIPX_PACKAGES[@]}
        gem_ref=${#GEM_PACKAGES[@]}
    fi

    total_ref=$((dev_ref + chaotic_ref + aur_ref + npm_ref + cargo_ref + pipx_ref + gem_ref + DEFAULT_GITHUB_COUNT))
}

calculate_setup_counts() {
    local -n dir_ref=$1
    local -n repo_ref=$2
    local -n script_ref=$3
    local -n shell_ref=$4

    dir_ref=0
    repo_ref=0
    script_ref=0
    shell_ref=0

    if load_setup_configuration_once; then
        dir_ref=${#DIRECTORIES[@]}
        repo_ref=${#GIT_REPOS[@]}
        script_ref=${#SCRIPTS[@]}
        shell_ref=${#SHELL_LINES[@]}
    fi
}

#######################################
# Helper functions - rendering (welcome flow)
#######################################

clear_screen() {
    clear 2>/dev/null || true
}

show_welcome_intro() {
    printf "%b" "${BLD}${CGR}Este script instalará y configurará tus dotfiles de forma segura y automatizada.${CNC}\n\n"
}

show_basic_operations() {
    local core_count
    core_count=$(calculate_core_count)
    printf "%b" "${BLD}${CBL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CNC}
${BLD}${CBL}  OPERACIONES BÁSICAS ${CGR}(se ejecutarán siempre)${CNC}
${BLD}${CBL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CNC}

  ${CGR}✓${CNC} Actualización del sistema con ${BLD}pacman -Syu${CNC}
  ${CGR}✓${CNC} Configuración del repositorio ${BLD}Chaotic-AUR${CNC}
  ${CGR}✓${CNC} Instalación de paquetes CORE (${CYE}${core_count}${CNC} paquetes):
      ${BLD}→${CNC} ${CYE}${CORE_DEPENDENCIES}${CNC}
  ${CGR}✓${CNC} Configuración de ${BLD}dotbare${CNC} para gestión de dotfiles
  ${CGR}✓${CNC} Clonado de repositorio: ${BLD}${CBL}$(format_repo_name)${CNC}
  ${CGR}✓${CNC} Respaldos automáticos de configuraciones existentes

"
}

show_extras_section() {
    local dev_count=0 chaotic_count=0 aur_count=0 npm_count=0
    local cargo_count=0 pipx_count=0 gem_count=0 total_extras=0

    calculate_extra_totals dev_count chaotic_count aur_count npm_count cargo_count pipx_count gem_count total_extras

    if [ "${INSTALL_EXTRAS}" -eq 1 ]; then
        printf "%b" "${BLD}${CBL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CNC}
${BLD}${CBL}  PAQUETES EXTRAS ${CGR}(--extras ACTIVADO ✓)${CNC}
${BLD}${CBL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CNC}

  ${CGR}✓${CNC} ${BLD}Total de paquetes extras a instalar: ${CYE}${total_extras}${CNC}
  ${CBL}ℹ${CNC}  Incluyendo paquetes del sistema, npm, cargo, python, ruby, y GitHub

"
        [ "${dev_count}" -gt 0 ] && printf "%b" "  ${CGR}✓${CNC} Paquetes desde repositorios oficiales (${CYE}${dev_count}${CNC} paquetes)\n"
        [ "${chaotic_count}" -gt 0 ] && printf "%b" "  ${CGR}✓${CNC} Paquetes desde Chaotic-AUR (${CYE}${chaotic_count}${CNC} paquetes)\n"
        [ "${aur_count}" -gt 0 ] && printf "%b" "  ${CGR}✓${CNC} Paquetes desde AUR (${CYE}${aur_count}${CNC} paquetes)\n"
        [ "${npm_count}" -gt 0 ] && printf "%b" "  ${CGR}✓${CNC} Paquetes globales de npm (${CYE}${npm_count}${CNC} paquetes)\n"
        [ "${cargo_count}" -gt 0 ] && printf "%b" "  ${CGR}✓${CNC} Paquetes de Rust/Cargo (${CYE}${cargo_count}${CNC} paquetes)\n"
        [ "${pipx_count}" -gt 0 ] && printf "%b" "  ${CGR}✓${CNC} Aplicaciones Python/pipx (${CYE}${pipx_count}${CNC} paquetes)\n"
        [ "${gem_count}" -gt 0 ] && printf "%b" "  ${CGR}✓${CNC} Gemas de Ruby (${CYE}${gem_count}${CNC} paquete(s))\n"
        printf "%b" "  ${CGR}✓${CNC} Herramientas desde GitHub (${CYE}${DEFAULT_GITHUB_COUNT}${CNC} herramientas):
      ${BLD}→${CNC} ${CYE}NVM, Lua-LS, lazygit, gh, zoxide, tldr, deno${CNC}

  ${CBL}ℹ${CNC}  Personaliza estos paquetes en: ${CBL}${SETUP_CONFIG}${CNC}

"
        return 0
    fi

    local core_count
    core_count=$(calculate_core_count)
    printf "%b" "${BLD}${CYE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CNC}
${BLD}${CYE}  PAQUETES EXTRAS ${CRE}(--extras NO activado ✗)${CNC}
${BLD}${CYE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CNC}

  ${CYE}⚠${CNC}  Solo se instalarán los ${core_count} paquetes CORE básicos.
  
  ${CGR}💡 Activa --extras para instalar ~100+ paquetes adicionales desde:${CNC}
      ${BLD}→${CNC} Repositorios oficiales (pacman) - herramientas del sistema
      ${BLD}→${CNC} Chaotic-AUR (binarios precompilados) - apps populares
      ${BLD}→${CNC} AUR (compilación local) - temas y plugins
      ${BLD}→${CNC} npm (paquetes globales) - Language Servers y herramientas JS
      ${BLD}→${CNC} cargo (Rust) - herramientas modernas (bob, tree-sitter, stylua)
      ${BLD}→${CNC} pipx (Python) - formatters, linters, LSPs
      ${BLD}→${CNC} gem (Ruby) - cliente Neovim
      ${BLD}→${CNC} GitHub releases - lazygit, gh, zoxide, tldr, deno, etc.

  ${BLD}Uso:${CNC} ${CYE}dotmarchy --extras${CNC}
  ${BLD}Personaliza:${CNC} ${CBL}${SETUP_CONFIG}${CNC}

"
}

show_setup_section() {
    if [ "${SETUP_ENVIRONMENT}" -ne 1 ]; then
        printf "%b" "${BLD}${CYE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CNC}
${BLD}${CYE}  CONFIGURACIÓN DE ENTORNO ${CRE}(--setup-env NO activado ✗)${CNC}
${BLD}${CYE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CNC}

  ${CYE}⚠${CNC}  No se configurará el entorno de desarrollo.
  
  ${CGR}💡 Activa --setup-env para:${CNC}
      ${BLD}→${CNC} Crear directorios de trabajo automáticamente
      ${BLD}→${CNC} Clonar repositorios Git necesarios
      ${BLD}→${CNC} Descargar scripts y herramientas
      ${BLD}→${CNC} Configurar tu shell (.zshrc/.bashrc)

  ${BLD}Uso:${CNC} ${CYE}dotmarchy --setup-env${CNC}
  ${BLD}Config:${CNC} ${CBL}${SETUP_CONFIG}${CNC}

"
        return 0
    fi

    local dir_count=0 repo_count=0 script_count=0 shell_count=0
    calculate_setup_counts dir_count repo_count script_count shell_count

    printf "%b" "${BLD}${CBL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CNC}
${BLD}${CBL}  CONFIGURACIÓN DE ENTORNO ${CGR}(--setup-env ACTIVADO ✓)${CNC}
${BLD}${CBL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CNC}

"

    if [ $((dir_count + repo_count + script_count + shell_count)) -gt 0 ]; then
        printf "%b" "  ${CGR}✓${CNC} Configuración cargada desde: ${CBL}${SETUP_CONFIG}${CNC}
      ${BLD}→${CNC} ${CYE}${dir_count}${CNC} directorios a crear
      ${BLD}→${CNC} ${CYE}${repo_count}${CNC} repositorios Git a clonar
      ${BLD}→${CNC} ${CYE}${script_count}${CNC} scripts a descargar
      ${BLD}→${CNC} ${CYE}${shell_count}${CNC} líneas a agregar a la shell config

"
        return 0
    fi

    printf "%b" "  ${CYE}⚠${CNC}  Archivo de configuración no encontrado o vacío
  ${CBL}ℹ${CNC}  Crea el archivo: ${CBL}${SETUP_CONFIG}${CNC}
  ${CBL}ℹ${CNC}  Usa como plantilla: ${CBL}setup.conf.example${CNC}

"
}

show_safety_section() {
    printf "%b" "${BLD}${CBL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CNC}
${BLD}${CBL}  GARANTÍAS DE SEGURIDAD${CNC}
${BLD}${CBL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CNC}

  ${CGR}✓${CNC} NO requiere ni permite ejecución como root
  ${CGR}✓${CNC} NO modifica configuraciones críticas del sistema
  ${CGR}✓${CNC} Todos los cambios son reversibles (backups automáticos)
  ${CGR}✓${CNC} Logging completo en: ${CBL}${ERROR_LOG}${CNC}

"
}

prompt_user_confirmation() {
    while :; do
        printf " %b" "${BLD}${CGR}¿Deseas continuar con esta configuración?${CNC} [s/N]: "
        read -r yn
        case "$yn" in
            [SsYy])
                return 0
                ;;
            [Nn] | "")
                printf "\n%b\n" "${BLD}${CYE}Operación cancelada${CNC}"
                exit 0
                ;;
            *)
                printf "\n%b\n" "${BLD}${CRE}Error:${CNC} Digita '${BLD}${CYE}s/y${CNC}' para sí o '${BLD}${CYE}n${CNC}' para no"
                ;;
        esac
    done
}

format_repo_name() {
    local repo="${REPO_URL:-dotfiles}"
    basename "$repo" .git
}

#######################################
# Helper functions - rendering (farewell flow)
#######################################

print_farewell_banner() {
    logo "Instalación completada"
}

print_completion_header() {
    local minutes="$1"
    local seconds="$2"
    printf "%b" "${BLD}${CBL}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                    🎉 INSTALACIÓN COMPLETADA 🎉
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
${CNC}\n"
    printf "\n%b" "${BLD}${CYE}⏱  Tiempo total: ${CGR}${minutes}m ${seconds}s${CNC}\n\n"
    printf "%b" "${BLD}${CBL}═══ RESUMEN DE OPERACIONES ═══${CNC}\n\n"
}

print_operation_summary() {
    printf "%b" "${CGR}✓${CNC} ${BLD}Operaciones completadas:${CNC}\n"
    printf "%b" "  ${CGR}→${CNC} Sistema actualizado con ${BLD}pacman -Syu${CNC}\n"
    printf "%b" "  ${CGR}→${CNC} Repositorio ${BLD}Chaotic-AUR${CNC} configurado\n"
    printf "%b" "  ${CGR}→${CNC} Paquetes ${BLD}CORE${CNC} instalados\n"

    if [ "${INSTALL_EXTRAS}" -eq 1 ]; then
        printf "%b" "  ${CGR}→${CNC} Paquetes ${BLD}EXTRAS${CNC} instalados (pacman, AUR, npm, cargo, pipx, gem, GitHub)\n"
        if [ "${PACKAGES_INSTALLED}" -gt 0 ]; then
            printf "%b" "  ${CGR}→${CNC} ${BLD}${PACKAGES_INSTALLED}${CNC} paquete(s) nuevo(s) instalado(s)\n"
        fi
        if [ "${PACKAGES_SKIPPED}" -gt 0 ]; then
            printf "%b" "  ${CGR}→${CNC} ${BLD}${PACKAGES_SKIPPED}${CNC} paquete(s) ya instalado(s) ${CBL}(omitidos)${CNC}\n"
        fi
        if [ "${PACKAGES_INSTALLED}" -eq 0 ] && [ "${PACKAGES_SKIPPED}" -eq 0 ]; then
            printf "%b" "  ${CGR}→${CNC} Todos los paquetes extras procesados correctamente\n"
        fi
    fi

    if [ "${SETUP_ENVIRONMENT}" -eq 1 ]; then
        printf "%b" "  ${CGR}→${CNC} Entorno de desarrollo ${BLD}configurado${CNC}\n"
    fi

    printf "%b" "  ${CGR}→${CNC} Configuración de ${BLD}dotbare${CNC} completada\n"
    printf "%b" "  ${CGR}→${CNC} Variables de entorno ${BLD}PATH${CNC} configuradas\n"
    printf "%b" "  ${CGR}→${CNC} Dotfiles clonados desde ${BLD}$(format_repo_name)${CNC}\n\n"

    if [ -f "${ERROR_LOG}" ] && [ -s "${ERROR_LOG}" ]; then
        local error_count
        error_count=$(wc -l <"${ERROR_LOG}" 2>/dev/null || echo 0)
        if [ "${error_count}" -gt 0 ]; then
            printf "%b" "${CYE}⚠${CNC} ${BLD}Advertencias encontradas: ${CYE}${error_count}${CNC}\n"
            printf "%b" "  ${CBL}→${CNC} Ver detalles en: ${CBL}${ERROR_LOG}${CNC}\n\n"
        fi
    fi
}

print_next_steps() {
    printf "%b" "${BLD}${CBL}═══ PRÓXIMOS PASOS ═══${CNC}\n\n"
    printf "%b" "${BLD}${CGR}1.${CNC} ${BLD}Aplica la configuración de PATH:${CNC}\n"
    if [ -f "$HOME/.zshrc" ]; then
        printf "%b" "   ${CGR}\$ ${CYE}source ~/.zshrc${CNC}\n"
    elif [ -f "$HOME/.bashrc" ]; then
        printf "%b" "   ${CGR}\$ ${CYE}source ~/.bashrc${CNC}\n"
    fi
    printf "%b" "   ${CBL}(o cierra y vuelve a abrir tu terminal)${CNC}\n\n"

    printf "%b" "${BLD}${CGR}2.${CNC} ${BLD}Verifica que las herramientas estén disponibles:${CNC}\n"
    printf "%b" "   ${CGR}\$ ${CYE}dotmarchy --verify${CNC}\n\n"

    if [ "${INSTALL_EXTRAS}" -eq 1 ]; then
        printf "%b" "${BLD}${CGR}3.${CNC} ${BLD}Instala Neovim con bob (si aún no lo tienes):${CNC}\n"
        printf "%b" "   ${CGR}\$ ${CYE}bob install stable${CNC}\n"
        printf "%b" "   ${CGR}\$ ${CYE}bob use stable${CNC}\n\n"
    fi
}

print_resources() {
    printf "%b" "${BLD}${CBL}═══ RECURSOS ÚTILES ═══${CNC}\n\n"
    printf "%b" "  ${CBL}📖${CNC} Documentación: ${CBL}https://github.com/25ASAB015/dotmarchy${CNC}\n"
    printf "%b" "  ${CBL}🔍${CNC} Verificación:  ${CYE}dotmarchy --verify${CNC}\n"
    printf "%b" "  ${CBL}📝${CNC} Log de errores: ${CBL}${ERROR_LOG}${CNC}\n"
    printf "%b" "  ${CBL}⚙️${CNC}  Configuración:  ${CBL}~/.config/dotmarchy/setup.conf${CNC}\n\n"
    printf "%b" "${BLD}${CBL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CNC}\n"
    printf "%b" "
${BLD}${CGR}    ¡Gracias por usar dotmarchy!${CNC} ${CBL}Tu entorno está listo.${CNC} ${CYE}✨🚀${CNC}
    
    ${CBL}Personaliza tu configuración en ${CYE}~/.config/dotmarchy/setup.conf${CNC}
    ${CBL}y vuelve a ejecutar ${CYE}dotmarchy --extras${CBL} para actualizar.${CNC}
    
${BLD}${CBL}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CNC}
\n"
}

