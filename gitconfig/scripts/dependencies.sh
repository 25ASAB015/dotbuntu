#!/usr/bin/env bash
#==============================================================================
#                              DEPENDENCIES
#==============================================================================
# @file dependencies.sh
# @brief Dependency checking and installation
# @description
#   Provides functions for checking and installing required dependencies
#   like git, ssh, gpg, and git-credential-manager.
#
# Globals:
#   Various from defaults.sh
#
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#==============================================================================

# Prevent double sourcing
[[ -n "${_DEPENDENCIES_SOURCED:-}" ]] && return 0
declare -r _DEPENDENCIES_SOURCED=1

#==============================================================================
# DEPENDENCY CHECKING
#==============================================================================

# @description Check if all required dependencies are installed
# @return 0 if all dependencies met, 1 otherwise
# @example
#   if ! check_dependencies; then
#       exit 1
#   fi
check_dependencies() {
    local missing_deps=()
    local required_deps=("git" "ssh" "ssh-keygen")
    
    for dep in "${required_deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        error "Faltan las siguientes dependencias: ${missing_deps[*]}"
        
        if [[ "$INTERACTIVE_MODE" == "true" ]]; then
            if ask_yes_no "¿Deseas intentar instalar las dependencias automáticamente?"; then
                local os_type
                os_type=$(detect_os)
                
                for dep in "${missing_deps[@]}"; do
                    if ! auto_install_dependencies "$os_type" "$dep"; then
                        error "No se pudo instalar: $dep"
                        return 1
                    fi
                done
            else
                return 1
            fi
        else
            return 1
        fi
    fi
    
    success "Todas las dependencias requeridas están instaladas"
    
    # Show required dependencies list
    info "Dependencias requeridas:"
    for dep in "${required_deps[@]}"; do
        if command -v "$dep" &> /dev/null; then
            printf "  $(c bold)$(c success)✓$(cr) $(c bold)%s$(cr)\n" "$dep"
        else
            printf "  $(c error)✗$(cr) $(c bold)%s$(cr) $(c error)(no encontrado)$(cr)\n" "$dep"
        fi
    done
    
    # Check optional dependencies (without header since it's part of required check)
    check_optional_dependencies "true"
    
    echo ""
    return 0
}

# @description Check optional dependencies and inform user
# @param $1 no_header - If "true", don't show header (default: false, shows header)
# @return 0 always
# @example
#   check_optional_dependencies          # Shows header
#   check_optional_dependencies "true"    # No header
check_optional_dependencies() {
    local no_header="${1:-false}"
    local optional_deps=("gpg" "gh" "git-credential-manager")
    local missing_optional=()
    local has_clipboard=false
    local clipboard_status="✓"
    
    if [[ "$no_header" != "true" ]]; then
        info "Dependencias opcionales:"
    fi
    
    for dep in "${optional_deps[@]}"; do
        local found=false
        if [[ "$dep" == "git-credential-manager" ]]; then
            # Algunos paquetes instalan el binario como git-credential-manager-core
            if command -v git-credential-manager &> /dev/null || command -v git-credential-manager-core &> /dev/null; then
                found=true
            fi
        else
            if command -v "$dep" &> /dev/null; then
                found=true
            fi
        fi

        if [[ "$found" == true ]]; then
            printf "  $(c bold)$(c success)✓$(cr) $(c bold)%s$(cr)\n" "$dep"
        else
            printf "  $(c muted)○$(cr) $(c bold)%s$(cr) $(c muted)(no instalado)$(cr)\n" "$dep"
            missing_optional+=("$dep")
        fi
    done

    # Detectar herramienta de portapapeles (cualquiera de xclip/xsel/wl-copy)
    if command -v wl-copy &> /dev/null || command -v xclip &> /dev/null || command -v xsel &> /dev/null; then
        has_clipboard=true
    else
        clipboard_status="○ (no instalado)"
    fi

    # Mostrar estado de portapapeles
    printf "  $(c bold)%s$(cr) $(c bold)Clipboard (xclip/xsel/wl-copy)$(cr)\n" "${has_clipboard:+$(c success)✓$(cr):-$(c muted)○$(cr)}"

    # Ofrecer instalación interactiva de opcionales cuando falten
    if [[ "$INTERACTIVE_MODE" == "true" ]] && [[ ${#missing_optional[@]} -gt 0 ]]; then
        local os_type
        os_type=$(detect_os)

        for dep in "${missing_optional[@]}"; do
            # git-credential-manager y gh son críticos para la experiencia GitHub
            local default_answer="y"
            if ask_yes_no "No se encontró '$dep'. ¿Deseas instalarlo automáticamente?" "$default_answer"; then
                if auto_install_dependencies "$os_type" "$dep"; then
                    success "$dep instalado correctamente"
                else
                    warning "No se pudo instalar '$dep' automáticamente"
                fi
            fi
        done
    fi

    # Ofrecer instalar herramientas de portapapeles si no hay ninguna
    if [[ "$INTERACTIVE_MODE" == "true" ]] && [[ "$has_clipboard" != true ]]; then
        local os_type
        os_type=$(detect_os)
        local clipboard_pkgs=()

        case "$os_type" in
            arch|manjaro|endeavouros|garuda)
                clipboard_pkgs=("wl-clipboard" "xclip")
                ;;
            ubuntu|debian|linuxmint|pop|elementary)
                clipboard_pkgs=("wl-clipboard" "xclip")
                ;;
            fedora|rhel|centos|rocky|alma)
                clipboard_pkgs=("wl-clipboard" "xclip")
                ;;
            darwin)
                # pbcopy ya viene instalado
                clipboard_pkgs=()
                ;;
            *)
                clipboard_pkgs=("xclip")
                ;;
        esac

        if [[ ${#clipboard_pkgs[@]} -gt 0 ]] && ask_yes_no "No se encontró herramienta de portapapeles. ¿Deseas instalar ${clipboard_pkgs[*]} ahora?" "y"; then
            for pkg in "${clipboard_pkgs[@]}"; do
                if ! auto_install_dependencies "$os_type" "$pkg"; then
                    warning "No se pudo instalar '$pkg' automáticamente"
                fi
            done
        fi
    fi
}

#==============================================================================
# AUTOMATIC INSTALLATION
#==============================================================================

# @description Attempt to install a dependency automatically
# @param $1 os_type - Operating system type
# @param $2 package - Package name to install
# @return 0 on success, 1 on failure
# @example
#   auto_install_dependencies "arch" "git"
auto_install_dependencies() {
    local os_type="$1"
    local package="$2"
    local pkg_to_install="$package"
    
    # Map package names per OS when repos use different identifiers
    case "$os_type" in
        arch|manjaro|endeavouros|garuda)
            case "$package" in
                git-credential-manager)
                    pkg_to_install="git-credential-manager-bin"
                    ;;
                gh)
                    pkg_to_install="github-cli"
                    ;;
            esac
            ;;
    esac
    
    info "Intentando instalar $package..."
    
    case "$os_type" in
        arch|manjaro|endeavouros|garuda)
            if command -v pacman &> /dev/null; then
                if sudo pacman -S --noconfirm "$pkg_to_install" 2>/dev/null; then
                    success "$package instalado correctamente"
                    return 0
                fi
            fi

            # Fallback a AUR con yay para paquetes no disponibles en pacman
            if command -v yay &> /dev/null; then
                # Lista de candidatos en AUR según el paquete lógico solicitado
                local aur_candidates=("$pkg_to_install")
                if [[ "$package" == "git-credential-manager" ]]; then
                    # Orden de preferencia: paquete AUR directo, luego variantes core/bin
                    aur_candidates=("git-credential-manager-bin")
                fi

                for aur_pkg in "${aur_candidates[@]}"; do
                    if yay -S --noconfirm "$aur_pkg" 2>/dev/null; then
                        success "$package instalado correctamente (AUR: $aur_pkg)"
                        return 0
                    fi
                done
            fi
            ;;
        ubuntu|debian|linuxmint|pop|elementary)
            if command -v apt &> /dev/null; then
                # Instalación especial para Git Credential Manager en Debian/Ubuntu
                if [[ "$package" == "git-credential-manager" ]]; then
                    info "Detectado sistema Debian/Ubuntu, instalando git-credential-manager..."
                    
                    # Descargar el .deb oficial desde GitHub Releases (versión fija)
                    local gcm_tmp_deb="/tmp/gcm-linux_amd64.2.5.1.deb"
                    local gcm_url="https://github.com/GitCredentialManager/git-credential-manager/releases/download/v2.5.1/gcm-linux_amd64.2.5.1.deb"

                    info "Actualizando repositorios e instalando dependencias..."
                    if ! sudo apt update; then
                        warning "Falló apt update"
                    fi
                    
                    if ! sudo apt install -y wget ca-certificates; then
                        warning "Falló la instalación de wget/ca-certificates"
                    fi

                    info "Descargando git-credential-manager desde GitHub..."
                    if wget -O "$gcm_tmp_deb" "$gcm_url"; then
                        info "Descarga exitosa, instalando paquete .deb..."
                        
                        # Primer intento de instalación
                        if sudo dpkg -i "$gcm_tmp_deb"; then
                            rm -f "$gcm_tmp_deb"
                            success "git-credential-manager instalado correctamente"
                            return 0
                        else
                            info "Resolviendo dependencias faltantes..."
                            # Resolver dependencias faltantes e intentar de nuevo
                            sudo apt -f install -y
                            if sudo dpkg -i "$gcm_tmp_deb"; then
                                rm -f "$gcm_tmp_deb"
                                success "git-credential-manager instalado correctamente (con dependencias resueltas)"
                                return 0
                            else
                                warning "Falló dpkg -i incluso después de resolver dependencias"
                            fi
                        fi
                    else
                        warning "Falló la descarga del .deb desde: $gcm_url"
                    fi

                    rm -f "$gcm_tmp_deb"
                fi

                # Instalación especial para GitHub CLI usando el repo oficial
                if [[ "$package" == "gh" || "$package" == "github-cli" ]]; then
                    if \
                        sudo apt update && \
                        sudo apt install wget apt-transport-https ca-certificates -y && \
                        wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /usr/share/keyrings/githubcli-archive-keyring.gpg > /dev/null && \
                        echo "deb [arch=\$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
                        sudo apt update && \
                        sudo apt install gh -y
                    then
                        success "GitHub CLI (gh) instalado correctamente desde el repositorio oficial"
                        return 0
                    fi
                else
                    if sudo apt update -qq && sudo apt install -y "$pkg_to_install" 2>/dev/null; then
                        success "$package instalado correctamente"
                        return 0
                    fi
                fi
            fi
            ;;
        fedora|rhel|centos|rocky|alma)
            if command -v dnf &> /dev/null; then
                if sudo dnf install -y "$pkg_to_install" 2>/dev/null; then
                    success "$package instalado correctamente"
                    return 0
                fi
            elif command -v yum &> /dev/null; then
                if sudo yum install -y "$pkg_to_install" 2>/dev/null; then
                    success "$package instalado correctamente"
                    return 0
                fi
            fi
            ;;
        darwin)
            if command -v brew &> /dev/null; then
                if brew install "$pkg_to_install" 2>/dev/null; then
                    success "$package instalado correctamente"
                    return 0
                fi
            fi
            ;;
    esac
    
    error "No se pudo instalar $package automáticamente"
    return 1
}

#==============================================================================
# MANUAL INSTALLATION INSTRUCTIONS
#==============================================================================

# @description Show manual installation instructions for GitHub CLI
# @param $1 os_type - Operating system type
# @example
#   show_manual_gh_install_instructions "arch"
show_manual_gh_install_instructions() {
    local os_type="$1"
    echo ""
    printf "%b\n" "$(c bold)$(c accent)📦 INSTRUCCIONES DE INSTALACIÓN MANUAL:$(cr)"
    echo ""
    
    case "$os_type" in
        arch|manjaro|endeavouros|garuda)
            printf "%b\n" "$(c warning)Arch Linux / Manjaro:$(cr)"
            echo "  $(c primary)sudo pacman -S github-cli$(cr)"
            echo "  $(c muted)o desde AUR:$(cr) $(c primary)yay -S github-cli$(cr)"
            ;;
        ubuntu|debian|linuxmint|pop|elementary)
            printf "%b\n" "$(c warning)Ubuntu / Debian:$(cr)"
            echo "  $(c primary)sudo apt update$(cr)"
            echo "  $(c primary)sudo apt install wget apt-transport-https ca-certificates -y$(cr)"
            echo "  $(c primary)wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | \\$(cr)"
            echo "      sudo tee /usr/share/keyrings/githubcli-archive-keyring.gpg > /dev/null$(cr)"
            echo "  $(c primary)echo \"deb [arch=\$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \\$(cr)"
            echo "       https://cli.github.com/packages stable main\" | \\$(cr)"
            echo "      sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null$(cr)"
            echo "  $(c primary)sudo apt update$(cr)"
            echo "  $(c primary)sudo apt install gh -y$(cr)"
            ;;
        fedora|rhel|centos|rocky|alma)
            printf "%b\n" "$(c warning)Fedora / RHEL / CentOS:$(cr)"
            echo "  $(c primary)sudo dnf install gh$(cr)"
            ;;
        darwin)
            printf "%b\n" "$(c warning)macOS:$(cr)"
            echo "  $(c primary)brew install gh$(cr)"
            ;;
        *)
            printf "%b\n" "$(c warning)Instalación genérica:$(cr)"
            echo "  Visita: $(c primary)https://cli.github.com$(cr)"
            ;;
    esac
    
    echo ""
    info "Después de instalar, vuelve a ejecutar este script con $(c primary)--auto-upload$(cr)"
    echo ""
}
