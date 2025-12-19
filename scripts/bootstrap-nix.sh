#!/usr/bin/env bash
#######################################
# bootstrap-nix.sh - Install NIX package manager
#
# Detects existing NIX installation or provides interactive menu
# to install via Determinate Systems, Official installer, or distro packages.
#
# Usage:
#   ./bootstrap-nix.sh
#
# Returns:
#   0 - NIX installed successfully
#   1 - Installation failed
#######################################

set -Eeuo pipefail

# Determine script directory
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly HELPER_DIR="${SCRIPT_DIR}/../helper"

# Source required helpers
# shellcheck source=/dev/null
source "${HELPER_DIR}/load_helpers.sh"
load_helpers "${HELPER_DIR}" colors logger prompts

#######################################
# Check if NIX is already installed
# Returns:
#   0 if installed, 1 otherwise
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
# Source NIX profile for current session
#######################################
source_nix_profile() {
    if [[ -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]]; then
        # shellcheck source=/dev/null
        source "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
        info "NIX profile cargado en la sesión actual"
    elif [[ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]]; then
        # shellcheck source=/dev/null
        source "$HOME/.nix-profile/etc/profile.d/nix.sh"
        info "NIX profile cargado (instalación de usuario)"
    fi
}

#######################################
# Install NIX via Determinate Systems installer
# Returns:
#   0 on success, 1 on failure
#######################################
install_determinate() {
    info "Instalando NIX via Determinate Systems Installer..."
    info "Este método permite desinstalación fácil con 'nix-installer uninstall'"
    
    if curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install; then
        success "NIX instalado exitosamente via Determinate Systems"
        source_nix_profile
        return 0
    else
        error "Fallo la instalación via Determinate Systems"
        return 1
    fi
}

#######################################
# Install NIX via official installer
# Returns:
#   0 on success, 1 on failure
#######################################
install_official() {
    info "Instalando NIX via instalador oficial..."
    info "Este método instala NIX en modo multi-usuario (daemon)"
    
    if sh <(curl -L https://nixos.org/nix/install) --daemon; then
        success "NIX instalado exitosamente via instalador oficial"
        source_nix_profile
        return 0
    else
        error "Fallo la instalación via instalador oficial"
        return 1
    fi
}

#######################################
# Install NIX via distribution package manager
# Returns:
#   0 on success, 1 on failure
#######################################
install_distro() {
    info "Instalando NIX via gestor de paquetes del sistema..."
    
    if command -v pacman &>/dev/null; then
        info "Detectado: Arch Linux (pacman)"
        if sudo pacman -S --noconfirm nix; then
            info "Habilitando y iniciando el daemon de NIX..."
            sudo systemctl enable nix-daemon.service
            sudo systemctl start nix-daemon.service
            
            # Add user to nix-users group
            sudo usermod -aG nix-users "$USER"
            
            success "NIX instalado via pacman"
            warn "IMPORTANTE: Cierra sesión y vuelve a iniciar para que los cambios surtan efecto"
            source_nix_profile
            return 0
        else
            error "Fallo la instalación via pacman"
            return 1
        fi
    elif command -v apt &>/dev/null; then
        warn "Ubuntu/Debian no tiene NIX en repositorios oficiales"
        info "Se recomienda usar Determinate Systems o el instalador oficial"
        return 1
    else
        error "Gestor de paquetes no soportado para instalación de NIX"
        return 1
    fi
}

#######################################
# Enable flakes and nix-command
#######################################
enable_flakes() {
    local nix_conf_dir="$HOME/.config/nix"
    local nix_conf="$nix_conf_dir/nix.conf"
    
    mkdir -p "$nix_conf_dir"
    
    if [[ -f "$nix_conf" ]] && grep -q "experimental-features" "$nix_conf"; then
        info "Características experimentales ya configuradas"
        return 0
    fi
    
    info "Habilitando flakes y nix-command..."
    echo "experimental-features = nix-command flakes" >> "$nix_conf"
    success "Flakes habilitados en $nix_conf"
}

#######################################
# Verify NIX installation
# Returns:
#   0 if working, 1 otherwise
#######################################
verify_installation() {
    info "Verificando instalación de NIX..."
    
    if ! command -v nix-env &>/dev/null; then
        error "nix-env no encontrado en PATH"
        info "Intenta: source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
        return 1
    fi
    
    local version
    version=$(nix-env --version 2>/dev/null)
    success "NIX instalado correctamente: $version"
    
    # Test basic functionality
    if nix-env --version &>/dev/null; then
        info "✓ nix-env funciona correctamente"
        return 0
    else
        error "nix-env no responde correctamente"
        return 1
    fi
}

#######################################
# Main installation flow
#######################################
main() {
    clear 2>/dev/null || true
    logo "Bootstrap NIX Package Manager"
    sleep 1
    
    # Check if already installed
    if check_nix_installed; then
        if ask_yes_no "NIX ya está instalado. ¿Deseas verificar la instalación?" "y"; then
            verify_installation
            enable_flakes
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
            install_determinate || {
                error "Instalación fallida"
                return 1
            }
            ;;
        2)
            install_official || {
                error "Instalación fallida"
                return 1
            }
            ;;
        3)
            install_distro || {
                error "Instalación fallida"
                return 1
            }
            ;;
        4)
            warn "Instalación cancelada"
            return 1
            ;;
        *)
            error "Opción inválida: $choice"
            return 1
            ;;
    esac
    
    # Post-installation
    enable_flakes
    verify_installation
    
    echo ""
    success "¡NIX instalado exitosamente!"
    info "Ahora puedes usar 'nix-env' para instalar paquetes"
    info "Los paquetes de dotbuntu se sincronizarán automáticamente"
}

# Execute only if invoked directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
