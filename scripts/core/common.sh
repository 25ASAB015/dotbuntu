#!/usr/bin/env bash
#==============================================================================
#                              COMMON
#==============================================================================
# @file common.sh
# @brief Common utility functions
# @description
#   Provides general utility functions used across the application including
#   OS detection, clipboard operations, and initial checks.
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
[[ -n "${_COMMON_SOURCED:-}" ]] && return 0
declare -r _COMMON_SOURCED=1

#==============================================================================
# OS DETECTION
#==============================================================================

# @description Detect the current operating system and distribution
# @return OS identifier string (e.g., arch, ubuntu, darwin)
# @example
#   os=$(detect_os)
#   case "$os" in
#       arch) pacman -S package ;;
#       ubuntu) apt install package ;;
#   esac
detect_os() {
    local os_type
    os_type=$(uname -s)
    
    case "$os_type" in
        "Darwin")
            echo "darwin"
            ;;
        "Linux")
            # Check for common distributions
            if [[ -f /etc/os-release ]]; then
                # shellcheck source=/dev/null
                source /etc/os-release
                case "$ID" in
                    arch|manjaro|endeavouros|garuda)
                        echo "$ID"
                        ;;
                    ubuntu|debian|linuxmint|pop|elementary)
                        echo "$ID"
                        ;;
                    fedora|rhel|centos|rocky|alma)
                        echo "$ID"
                        ;;
                    *)
                        echo "linux"
                        ;;
                esac
            else
                echo "linux"
            fi
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

#==============================================================================
# CLIPBOARD OPERATIONS
#==============================================================================

# @description Copy file contents to clipboard
# @param $1 file_path - Path to file to copy
# @return 0 on success, 1 on failure
# @example
#   copy_to_clipboard "$HOME/.ssh/id_ed25519.pub"
copy_to_clipboard() {
    local file_path="$1"
    local os_type
    os_type=$(detect_os)
    
    if [[ ! -f "$file_path" ]]; then
        error "Archivo no encontrado: $file_path"
        return 1
    fi
    
    # Leer contenido una sola vez
    local content
    content=$(cat "$file_path")
    
    # Elegir herramienta priorizando entorno (Wayland > X11 > macOS)
    local clipboard_cmd=""
    local verify_cmd=""
    local method_name=""
    
    if [[ -n "${WAYLAND_DISPLAY:-}" ]] && command -v wl-copy &> /dev/null; then
        clipboard_cmd="wl-copy"
        verify_cmd="wl-paste"
        method_name="wl-copy (Wayland)"
    elif [[ -n "${DISPLAY:-}" ]] && command -v xsel &> /dev/null; then
        clipboard_cmd="xsel --clipboard --input"
        verify_cmd="xsel --clipboard --output"
        method_name="xsel (X11)"
    elif [[ -n "${DISPLAY:-}" ]] && command -v xclip &> /dev/null; then
        clipboard_cmd="xclip -selection clipboard"
        verify_cmd="xclip -selection clipboard -o"
        method_name="xclip (X11)"
    elif [[ "$os_type" == "darwin" ]] && command -v pbcopy &> /dev/null; then
        clipboard_cmd="pbcopy"
        verify_cmd="pbpaste"
        method_name="pbcopy (macOS)"
    fi
    
    if [[ -z "$clipboard_cmd" ]]; then
        warning "No se encontró herramienta de portapapeles ni sesión gráfica activa"
        info "Instala: xclip/xsel (X11) o wl-clipboard (Wayland). En macOS, pbcopy ya viene instalado."
        return 1
    fi
    
    if echo -n "$content" | eval "$clipboard_cmd" 2>/dev/null; then
        # Verificar si es posible
        if command -v $(echo "$verify_cmd" | awk '{print $1}') &> /dev/null; then
            local clipboard_content
            clipboard_content=$(eval "$verify_cmd" 2>/dev/null || true)
            if [[ "$clipboard_content" == "$content" ]]; then
                success "Llave copiada al portapapeles ($method_name)"
                return 0
            else
                warning "El contenido del portapapeles no coincide (método: $method_name)"
                return 1
            fi
        else
            success "Llave copiada al portapapeles ($method_name, sin verificación)"
            return 0
        fi
    fi
    
    warning "No se pudo copiar al portapapeles usando $method_name"
    return 1
}

#==============================================================================
# INITIAL CHECKS
#==============================================================================

# @description Perform initial environment checks
# @return 0 on success, 1 on failure
# @example
#   if ! initial_checks; then
#       exit 1
#   fi
initial_checks() {
    # Check if running as root (not recommended)
    if [[ $EUID -eq 0 ]]; then
        warning "No se recomienda ejecutar este script como root"
        if ! ask_yes_no "¿Deseas continuar de todos modos?" "n"; then
            exit 1
        fi
    fi
    
    
    return 0
}

#==============================================================================
# DIRECTORY OPERATIONS
#==============================================================================

# @description Setup required directories for SSH and GPG
# @return 0 on success, 1 on failure
# @example
#   setup_directories
setup_directories() {
    local ssh_dir="$HOME/.ssh"
    local gnupg_dir="$HOME/.gnupg"
    
    # Create SSH directory
    if [[ ! -d "$ssh_dir" ]]; then
        mkdir -p "$ssh_dir"
        chmod 700 "$ssh_dir"
        log "SSH directory created: $ssh_dir"
    fi
    
    # Create GPG directory
    if [[ ! -d "$gnupg_dir" ]]; then
        mkdir -p "$gnupg_dir"
        chmod 700 "$gnupg_dir"
        log "GPG directory created: $gnupg_dir"
    fi
    
    success "Directorios configurados correctamente"
    echo ""
    return 0
}

#==============================================================================
# BACKUP OPERATIONS
#==============================================================================

# @description Backup existing SSH keys
# @return 0 always
# @example
#   backup_existing_keys
backup_existing_keys() {
    local ssh_dir="$HOME/.ssh"
    local backup_dir="$ssh_dir/backup-$(date +%Y%m%d_%H%M%S)"
    local existing_keys=()
    
    # Check for existing keys (both RSA and Ed25519)
    local ssh_files=("$ssh_dir/id_rsa" "$ssh_dir/id_rsa.pub" "$ssh_dir/id_ed25519" "$ssh_dir/id_ed25519.pub")
    
    for file in "${ssh_files[@]}"; do
        if [[ -f "$file" ]]; then
            existing_keys+=("$file")
        fi
    done
    
    # If keys found, show warning with list and ask for backup
    if [[ ${#existing_keys[@]} -gt 0 ]]; then
        warning "Se encontraron ${#existing_keys[@]} llave(s) SSH existente(s):"
        for file in "${existing_keys[@]}"; do
            echo "  $(c bold)•$(cr) $(c bold)$(basename "$file")$(cr)"
        done
        echo ""
        
        if ask_yes_no "¿Deseas hacer un backup de seguridad de las llaves existentes antes de continuar?" "y"; then
            info "Creando backup de seguridad de llaves existentes..."
            mkdir -p "$backup_dir"
            
            for file in "${existing_keys[@]}"; do
                if cp "$file" "$backup_dir/" 2>/dev/null; then
                    success "Backup de seguridad creado: $(basename "$file")"
                    log "Backed up: $file"
                else
                    error "No se pudo hacer backup de: $(basename "$file")"
                fi
            done
            
            echo ""
            success "Backup de seguridad completado en: $(c primary)$backup_dir$(cr)"
            info "$(c muted)(Este backup contiene tus llaves anteriores antes de ser sobrescritas)$(cr)"
        else
            info "Continuando sin hacer backup de seguridad"
        fi
    fi
    
    echo ""
    return 0
}
