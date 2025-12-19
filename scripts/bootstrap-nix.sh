#!/usr/bin/env bash
#######################################
# bootstrap-nix.sh - Install NIX package manager
#
# Detects existing NIX installation or provides interactive menu
# to install via Determinate Systems, Official installer, or distro packages.
# Validates prerequisites, integrates with shell profiles, and verifies installation.
#
# Usage:
#   ./bootstrap-nix.sh
#
# Globals:
#   SCRIPT_DIR - Directory containing this script
#   HELPER_DIR - Path to helper modules
#   ERROR_LOG - Path to error log file
#
# Returns:
#   0 - NIX installed successfully or already present
#   1 - Installation failed or prerequisites missing
#######################################

set -Eeuo pipefail

# Determine script directory
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly HELPER_DIR="${SCRIPT_DIR}/../helper"

# Source required helpers
# shellcheck source=/dev/null
source "${HELPER_DIR}/load_helpers.sh"
load_helpers "${HELPER_DIR}" colors logger prompts

# Minimum free disk space required (GB)
readonly MIN_DISK_SPACE_GB=2

#######################################
# Check if NIX is already installed
#
# Verifies presence of nix-env command and displays version if found.
#
# Globals:
#   None
#
# Arguments:
#   None
#
# Returns:
#   0 - NIX is installed
#   1 - NIX is not installed
#
# Outputs:
#   STDOUT - Installation status message
#######################################
check_nix_installed() {
    if command -v nix-env &>/dev/null; then
        local version
        version=$(nix-env --version 2>/dev/null | head -n1)
        info "NIX ya está instalado: $version"
        return 0
    fi
    return 1
}

#######################################
# Validate installation prerequisites
#
# Checks for required tools (curl, sudo), internet connectivity,
# and sufficient disk space before attempting NIX installation.
#
# Globals:
#   MIN_DISK_SPACE_GB - Minimum required disk space
#
# Arguments:
#   None
#
# Returns:
#   0 - All prerequisites met
#   1 - One or more prerequisites missing
#
# Outputs:
#   STDOUT - Progress messages
#   STDERR - Error messages for missing prerequisites
#######################################
check_prerequisites() {
    local all_good=0
    
    info "Verificando prerequisitos de instalación..."
    
    # Check for curl
    if ! command -v curl &>/dev/null; then
        error "curl no está instalado (requerido para descargar el instalador)"
        info "Instala curl primero: sudo apt install curl  o  sudo pacman -S curl"
        all_good=1
    else
        info "✓ curl encontrado"
    fi
    
    # Check for sudo (needed for daemon install)
    if ! command -v sudo &>/dev/null; then
        warn "sudo no encontrado (puede ser necesario para algunos métodos de instalación)"
    else
        info "✓ sudo disponible"
    fi
    
    # Check internet connectivity
    if ! ping -c 1 -W 2 8.8.8.8 &>/dev/null && ! ping -c 1 -W 2 1.1.1.1 &>/dev/null; then
        error "Sin conexión a internet (requerida para descargar NIX)"
        all_good=1
    else
        info "✓ Conexión a internet disponible"
    fi
    
    # Check disk space
    local free_space_gb
    free_space_gb=$(df -BG / | tail -1 | awk '{print $4}' | tr -d 'G')
    
    if [[ "$free_space_gb" -lt "$MIN_DISK_SPACE_GB" ]]; then
        error "Espacio en disco insuficiente: ${free_space_gb}GB libre (mínimo: ${MIN_DISK_SPACE_GB}GB)"
        all_good=1
    else
        info "✓ Espacio en disco suficiente (${free_space_gb}GB libre)"
    fi
    
    if [[ "$all_good" -ne 0 ]]; then
        error "Prerequisitos no cumplidos. Corrige los errores anteriores e intenta de nuevo."
        return 1
    fi
    
    success "Todos los prerequisitos cumplidos"
    return 0
}

#######################################
# Detect user's shell
#
# Determines the user's default shell and returns the corresponding
# configuration file path for profile integration.
#
# Globals:
#   SHELL - User's default shell
#   HOME - User's home directory
#
# Arguments:
#   None
#
# Returns:
#   0 - Shell detected successfully
#   1 - Unknown shell
#
# Outputs:
#   STDOUT - Shell RC file path (e.g., ~/.zshrc, ~/.bashrc)
#######################################
detect_shell_rc() {
    case "$SHELL" in
        */zsh)
            echo "$HOME/.zshrc"
            ;;
        */bash)
            echo "$HOME/.bashrc"
            ;;
        *)
            echo "$HOME/.profile"
            ;;
    esac
}

#######################################
# Integrate NIX profile into shell configuration
#
# Adds source command to user's shell RC file to automatically
# load NIX profile on new shell sessions. Checks for existing
# integration to avoid duplication.
#
# Globals:
#   HOME - User's home directory
#
# Arguments:
#   None
#
# Returns:
#   0 - Integration successful or already exists
#   1 - Integration failed
#
# Outputs:
#   STDOUT - Status messages
#######################################
integrate_shell_profile() {
    local shell_rc
    shell_rc=$(detect_shell_rc)
    
    local nix_profile_script="/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
    
    # Check if already integrated
    if [[ -f "$shell_rc" ]] && grep -q "nix-daemon.sh" "$shell_rc" 2>/dev/null; then
        info "NIX ya está integrado en $shell_rc"
        return 0
    fi
    
    info "Integrando NIX profile en $shell_rc..."
    
    # Add to shell RC file
    {
        echo ""
        echo "# NIX package manager"
        echo "if [ -f \"$nix_profile_script\" ]; then"
        echo "    . \"$nix_profile_script\""
        echo "fi"
    } >> "$shell_rc"
    
    success "NIX profile integrado en $shell_rc"
    info "Los cambios serán efectivos en nuevas sesiones de shell"
    info "Para la sesión actual, ejecuta: source $shell_rc"
    
    return 0
}

#######################################
# Source NIX profile for current session
#
# Loads NIX environment variables into the current shell session
# by sourcing the appropriate NIX profile script.
#
# Globals:
#   HOME - User's home directory
#
# Arguments:
#   None
#
# Returns:
#   0 - Profile sourced successfully
#   1 - Profile script not found
#
# Outputs:
#   STDOUT - Status messages
#######################################
source_nix_profile() {
    if [[ -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]]; then
        # shellcheck source=/dev/null
        source "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
        info "NIX profile cargado en la sesión actual"
        return 0
    elif [[ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]]; then
        # shellcheck source=/dev/null
        source "$HOME/.nix-profile/etc/profile.d/nix.sh"
        info "NIX profile cargado (instalación de usuario)"
        return 0
    else
        warn "No se encontró el script del perfil NIX"
        return 1
    fi
}

#######################################
# Install NIX via Determinate Systems installer
#
# Downloads and executes the Determinate Systems NIX installer.
# This method enables easy uninstallation and includes flakes by default.
#
# Globals:
#   None
#
# Arguments:
#   None
#
# Returns:
#   0 - Installation successful
#   1 - Installation failed
#
# Outputs:
#   STDOUT - Installation progress
#   STDERR - Error messages
#######################################
install_determinate() {
    info "Instalando NIX via Determinate Systems Installer..."
    info "Este método permite desinstalación fácil con 'nix-installer uninstall'"
    
    if curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install; then
        success "NIX instalado exitosamente via Determinate Systems"
        source_nix_profile
        integrate_shell_profile
        return 0
    else
        error "Falló la instalación via Determinate Systems"
        return 1
    fi
}

#######################################
# Install NIX via official installer
#
# Downloads and executes the official NIX installer in daemon mode.
# This is the standard multi-user installation method.
#
# Globals:
#   None
#
# Arguments:
#   None
#
# Returns:
#   0 - Installation successful
#   1 - Installation failed
#
# Outputs:
#   STDOUT - Installation progress
#   STDERR - Error messages
#######################################
install_official() {
    info "Instalando NIX via instalador oficial..."
    info "Este método instala NIX en modo multi-usuario (daemon)"
    
    if sh <(curl -L https://nixos.org/nix/install) --daemon; then
        success "NIX instalado exitosamente via instalador oficial"
        source_nix_profile
        integrate_shell_profile
        return 0
    else
        error "Falló la instalación via instalador oficial"
        return 1
    fi
}

#######################################
# Install NIX via distribution package manager
#
# Installs NIX using the system's native package manager (currently
# supports Arch Linux via pacman). Sets up daemon and user groups.
#
# Globals:
#   USER - Current username
#
# Arguments:
#   None
#
# Returns:
#   0 - Installation successful
#   1 - Installation failed or unsupported distribution
#
# Outputs:
#   STDOUT - Installation progress
#   STDERR - Error messages
#######################################
install_distro() {
    info "Instalando NIX via gestor de paquetes del sistema..."
    
    if command -v pacman &>/dev/null; then
        info "Detectado: Arch Linux (pacman)"
        
        if ! sudo pacman -S --noconfirm nix; then
            error "Falló la instalación via pacman"
            return 1
        fi
        
        info "Habilitando y e iniciando el daemon de NIX..."
        if ! sudo systemctl enable nix-daemon.service; then
            error "Falló al habilitar nix-daemon.service"
            return 1
        fi
        
        if ! sudo systemctl start nix-daemon.service; then
            error "Falló al iniciar nix-daemon.service"
            return 1
        fi
        
        # Add user to nix-users group
        info "Agregando usuario al grupo nix-users..."
        if ! sudo usermod -aG nix-users "$USER"; then
            warn "Falló al agregar usuario al grupo nix-users"
        fi
        
        success "NIX instalado via pacman"
        warn "IMPORTANTE: Cierra sesión y vuelve a iniciar para que los cambios surtan efecto"
        
        source_nix_profile
        integrate_shell_profile
        return 0
        
    elif command -v apt &>/dev/null; then
        warn "Ubuntu/Debian no tiene NIX en repositorios oficiales"
        info "Se recomienda usar Determinate Systems o el instalador oficial"
        return 1
    else
        error "Gestor de paquetes no soportado para instalación de NIX"
        info "Distribuciones soportadas: Arch Linux"
        info "Usar método 1 o 2 para otras distribuciones"
        return 1
    fi
}

#######################################
# Enable flakes and nix-command experimental features
#
# Creates or updates NIX configuration to enable flakes and nix-command.
# Checks for existing configuration to avoid duplication.
#
# Globals:
#   HOME - User's home directory
#
# Arguments:
#   None
#
# Returns:
#   0 - Features enabled successfully or already enabled
#   1 - Configuration failed
#
# Outputs:
#   STDOUT - Status messages
#######################################
enable_flakes() {
    local nix_conf_dir="$HOME/.config/nix"
    local nix_conf="$nix_conf_dir/nix.conf"
    
    if ! mkdir -p "$nix_conf_dir" 2>/dev/null; then
        error "Falló al crear directorio de configuración NIX"
        return 1
    fi
    
    if [[ -f "$nix_conf" ]] && grep -q "experimental-features" "$nix_conf"; then
        info "Características experimentales ya configuradas"
        return 0
    fi
    
    info "Habilitando flakes y nix-command..."
    
    if ! echo "experimental-features = nix-command flakes" >> "$nix_conf"; then
        error "Falló al escribir configuración NIX"
        return 1
    fi
    
    success "Flakes habilitados en $nix_conf"
    return 0
}

#######################################
# Verify NIX installation completeness
#
# Performs comprehensive verification of NIX installation including:
# - nix-env command availability
# - NIX store directory existence
# - Basic nix-env functionality
# - NIX in PATH verification
#
# Globals:
#   None
#
# Arguments:
#   None
#
# Returns:
#   0 - Installation verified successfully
#   1 - Verification failed
#
# Outputs:
#   STDOUT - Verification progress
#   STDERR - Error messages
#######################################
verify_installation() {
    info "Verificando instalación de NIX..."
    
    # Check nix-env in PATH
    if ! command -v nix-env &>/dev/null; then
        error "nix-env no encontrado en PATH"
        info "Solución: source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
        return 1
    fi
    info "✓ nix-env encontrado en PATH"
    
    # Check NIX store exists
    if [[ ! -d "/nix/store" ]]; then
        error "/nix/store no existe (instalación incompleta)"
        return 1
    fi
    info "✓ /nix/store existe"
    
    # Get and display version
    local version
    if ! version=$(nix-env --version 2>/dev/null); then
        error "nix-env --version falló"
        return 1
    fi
    success "NIX instalado correctamente: $version"
    
    # Test basic functionality
    if ! nix-env --version &>/dev/null; then
        error "nix-env no responde correctamente"
        return 1
    fi
    info "✓ nix-env funciona correctamente"
    
    return 0
}

#######################################
# Main installation orchestration function
#
# Coordinates the entire NIX installation process:
# 1. Check prerequisites
# 2. Detect existing installation
# 3. Present installation menu
# 4. Execute chosen installation method
# 5. Enable flakes
# 6. Verify installation
# 7. Integrate with shell
#
# Globals:
#   BLD, CYE, CNC - Color codes for terminal output
#
# Arguments:
#   None
#
# Returns:
#   0 - NIX installation completed successfully
#   1 - Installation failed or was cancelled
#
# Outputs:
#   STDOUT - Installation progress and results
#   STDERR - Error messages
#######################################
main() {
    clear 2>/dev/null || true
    logo "Bootstrap NIX Package Manager"
    sleep 1
    
    # Validate prerequisites first
    if ! check_prerequisites; then
        error "No se puede continuar sin cumplir los prerequisitos"
        return 1
    fi
    
    echo ""
    
    # Check if already installed
    if check_nix_installed; then
        if ask_yes_no "NIX ya está instalado. ¿Deseas verificar la instalación?" "y"; then
            verify_installation || return 1
            enable_flakes || return 1
            integrate_shell_profile || return 1
        fi
        return 0
    fi
    
    # Show installation menu
    echo ""
    info "Selecciona el método de instalación de NIX:"
    echo ""
    echo "  1) Determinate Systems Installer (Recomendado)"
    echo "     └─ Desinstalación fácil, mejor UX, flakes habilitados"
    echo ""
    echo "  2) Instalador Oficial de NIX"
    echo "     └─ Método estándar, multi-usuario (daemon)"
    echo ""
    echo "  3) Paquetes de la distribución"
    echo "     └─ Solo Arch Linux, requiere configuración manual"
    echo ""
    echo "  4) Cancelar"
    echo ""
    
    local choice
    read -rp "$(printf "%b" "${BLD}${CYE}Opción [1-4]: ${CNC}")" choice
    
    case "$choice" in
        1)
            if ! install_determinate; then
                error "Instalación fallida"
                return 1
            fi
            ;;
        2)
            if ! install_official; then
                error "Instalación fallida"
                return 1
            fi
            ;;
        3)
            if ! install_distro; then
                error "Instalación fallida"
                return 1
            fi
            ;;
        4)
            warn "Instalación cancelada por el usuario"
            return 1
            ;;
        *)
            error "Opción inválida: $choice"
            return 1
            ;;
    esac
    
    # Post-installation configuration
    echo ""
    info "Configurando NIX..."
    
    if ! enable_flakes; then
        warn "Falló la configuración de flakes (no crítico)"
    fi
    
    if ! verify_installation; then
        error "La verificación de instalación falló"
        return 1
    fi
    
    echo ""
    success "¡NIX instalado exitosamente!"
    info "Ahora puedes usar 'nix-env' para instalar paquetes"
    info "Los paquetes de dotbuntu se sincronizarán automáticamente"
    echo ""
    
    # Try to source NIX profile for current session
    local nix_profile_script="/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
    if [[ -f "$nix_profile_script" ]]; then
        info "Cargando NIX en la sesión actual..."
        # shellcheck source=/dev/null
        if source "$nix_profile_script" 2>/dev/null; then
            success "NIX disponible en esta sesión"
        else
            warn "No se pudo cargar NIX automáticamente"
            info "Ejecuta manualmente: source $nix_profile_script"
        fi
    fi
    
    info "Para nuevas sesiones, NIX se cargará automáticamente desde $(detect_shell_rc)"
    
    return 0
}

# Execute only if invoked directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
