#!/usr/bin/env bash
#==============================================================================
#                              GITHUB
#==============================================================================
# @file github.sh
# @brief GitHub CLI integration and key uploading
# @description
#   Provides functions for GitHub CLI authentication, SSH and GPG key
#   uploading, and GitHub connectivity testing.
#
# Globals:
#   AUTO_UPLOAD_KEYS     Auto-upload flag
#   INTERACTIVE_MODE     Interactive mode flag
#   SSH_KEY_UPLOADED     Track SSH key upload status
#   GPG_KEY_UPLOADED     Track GPG key upload status
#   GH_INSTALL_ATTEMPTED Track if GH CLI install was attempted
#   GPG_KEY_ID           GPG key ID
#
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#==============================================================================

# Prevent double sourcing
[[ -n "${_GITHUB_SOURCED:-}" ]] && return 0
declare -r _GITHUB_SOURCED=1

#==============================================================================
# GITHUB CLI SETUP
#==============================================================================

# @description Ensure GitHub CLI is installed and authenticated
# @param $1 early_mode - "early" for startup check, empty for runtime check
# @return 0 if ready, 1 if not available
# @example
#   if ! ensure_github_cli_ready "early"; then
#       exit 1
#   fi
ensure_github_cli_ready() {
    local early_mode="${1:-false}"
    
    # Check if gh is installed
    if ! command -v gh &> /dev/null; then
        show_separator
        printf "%b\n" "$(c bold)$(c warning)⚠️  GITHUB CLI NO ESTÁ INSTALADO$(cr)"
        show_separator
        echo ""
        
        if [[ "$early_mode" == "early" ]]; then
            error "El flag --auto-upload requiere que GitHub CLI (gh) esté instalado y configurado."
            echo ""
            info "GitHub CLI es necesario para subir automáticamente las llaves SSH y GPG a tu cuenta de GitHub."
            echo ""
        else
            info "Para subir llaves automáticamente a GitHub, necesitas instalar GitHub CLI (gh)."
            echo ""
        fi
        
        if [[ "$INTERACTIVE_MODE" == "true" ]]; then
            if ask_yes_no "¿Deseas que el script intente instalar GitHub CLI automáticamente?" "y"; then
                local os_type
                os_type=$(detect_os)
                
                case "$os_type" in
                    arch|manjaro|endeavouros|garuda)
                        GH_INSTALL_ATTEMPTED=true
                        if auto_install_dependencies "$os_type" github-cli; then
                            success "GitHub CLI instalado correctamente"
                            echo ""
                        else
                            error "No se pudo instalar GitHub CLI automáticamente"
                            show_manual_gh_install_instructions "$os_type"
                            if [[ "$early_mode" == "early" ]]; then
                                echo ""
                                error "No se puede continuar sin GitHub CLI instalado."
                                echo ""
                                info "Instala GitHub CLI manualmente y vuelve a ejecutar el script con $(c primary)--auto-upload$(cr)"
                                exit 1
                            fi
                            return 1
                        fi
                        ;;
                    ubuntu|debian|linuxmint|pop|elementary)
                        GH_INSTALL_ATTEMPTED=true
                        if auto_install_dependencies "$os_type" gh; then
                            success "GitHub CLI instalado correctamente"
                            echo ""
                        else
                            error "No se pudo instalar GitHub CLI automáticamente"
                            show_manual_gh_install_instructions "$os_type"
                            if [[ "$early_mode" == "early" ]]; then
                                echo ""
                                error "No se puede continuar sin GitHub CLI instalado."
                                echo ""
                                info "Instala GitHub CLI manualmente y vuelve a ejecutar el script con $(c primary)--auto-upload$(cr)"
                                exit 1
                            fi
                            return 1
                        fi
                        ;;
                    *)
                        show_manual_gh_install_instructions "$os_type"
                        if [[ "$early_mode" == "early" ]]; then
                            echo ""
                            error "No se puede continuar sin GitHub CLI instalado."
                            echo ""
                            info "Instala GitHub CLI manualmente y vuelve a ejecutar el script con $(c primary)--auto-upload$(cr)"
                            exit 1
                        fi
                        return 1
                        ;;
                esac
            else
                show_manual_gh_install_instructions "$(detect_os)"
                if [[ "$early_mode" == "early" ]]; then
                    echo ""
                    error "El flag --auto-upload requiere GitHub CLI instalado y configurado."
                    echo ""
                    info "El script no puede continuar sin GitHub CLI. Instálalo y vuelve a ejecutar con $(c primary)--auto-upload$(cr)"
                    exit 1
                fi
                return 1
            fi
        else
            # Non-interactive mode
            show_manual_gh_install_instructions "$(detect_os)"
            if [[ "$early_mode" == "early" ]]; then
                echo ""
                error "El flag --auto-upload requiere que GitHub CLI (gh) esté instalado y autenticado."
                echo ""
                info "En modo no-interactivo, debes instalar y autenticar GitHub CLI antes de ejecutar este script:"
                echo ""
                echo "  1. Instala GitHub CLI:"
                echo "     $(c primary)sudo pacman -S github-cli$(cr)  # Arch Linux"
                echo "     $(c primary)sudo apt update$(cr)            # Ubuntu/Debian"
                echo "     $(c primary)sudo apt install wget apt-transport-https ca-certificates -y$(cr)"
                echo "     $(c primary)wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | \\$(cr)"
                echo "         sudo tee /usr/share/keyrings/githubcli-archive-keyring.gpg > /dev/null$(cr)"
                echo "     $(c primary)echo \"deb [arch=\$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \\$(cr)"
                echo "          https://cli.github.com/packages stable main\" | \\$(cr)"
                echo "         sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null$(cr)"
                echo "     $(c primary)sudo apt update$(cr)"
                echo "     $(c primary)sudo apt install gh -y$(cr)"
                echo ""
                echo "  2. Autentica GitHub CLI:"
                echo "     $(c primary)gh auth login$(cr)"
                echo ""
                echo "  3. Vuelve a ejecutar este script con $(c primary)--auto-upload$(cr)"
                echo ""
                exit 1
            fi
            return 1
        fi
    fi
    
    # Check authentication
    local auth_status
    auth_status=$(gh auth status 2>&1)
    local auth_exit_code=$?
    
    if [[ $auth_exit_code -eq 0 ]]; then
        return 0
    fi
    
    # Not authenticated
    show_separator
    printf "%b\n" "$(c bold)$(c warning)⚠️  GITHUB CLI NO ESTÁ AUTENTICADO$(cr)"
    show_separator
    echo ""
    
    if [[ "$INTERACTIVE_MODE" == "true" ]]; then
        if [[ "$early_mode" == "early" ]]; then
            error "El flag --auto-upload requiere que GitHub CLI (gh) esté autenticado."
            echo ""
            info "GitHub CLI está instalado pero necesita autenticación para subir automáticamente las llaves SSH y GPG a tu cuenta de GitHub."
            echo ""
        else
            info "GitHub CLI está instalado pero requiere autenticación para subir llaves."
            echo ""
        fi
        info "Opciones de autenticación:"
        echo "  1. $(c primary)gh auth login$(cr) - Autenticación interactiva (recomendada)"
        echo "  2. $(c primary)gh auth login --with-token$(cr) - Autenticación con token"
        echo ""
        
        if ask_yes_no "¿Deseas ejecutar 'gh auth login' ahora?" "y"; then
            echo ""
            info "Ejecutando autenticación de GitHub CLI..."
            echo "$(c muted)Nota: Sigue las instrucciones en pantalla para completar la autenticación.$(cr)"
            echo ""
            
            if gh auth login; then
                echo ""
                success "Autenticación de GitHub CLI completada exitosamente"
                return 0
            else
                echo ""
                error "La autenticación de GitHub CLI falló"
                echo ""
                if [[ "$early_mode" == "early" ]]; then
                    error "No se puede continuar sin GitHub CLI autenticado."
                    echo ""
                    info "Autentica GitHub CLI manualmente con $(c primary)gh auth login$(cr) y vuelve a ejecutar el script con $(c primary)--auto-upload$(cr)"
                    exit 1
                fi
                info "Puedes autenticarte manualmente más tarde con: $(c primary)gh auth login$(cr)"
                return 1
            fi
        else
            echo ""
            if [[ "$early_mode" == "early" ]]; then
                error "El flag --auto-upload requiere GitHub CLI autenticado."
                echo ""
                info "El script no puede continuar sin autenticación. Autentica GitHub CLI con $(c primary)gh auth login$(cr) y vuelve a ejecutar con $(c primary)--auto-upload$(cr)"
                exit 1
            fi
            warning "Autenticación omitida. Las llaves no se subirán automáticamente."
            echo ""
            info "Para autenticarte más tarde, ejecuta: $(c primary)gh auth login$(cr)"
            return 1
        fi
    else
        # Non-interactive mode
        if [[ "$early_mode" == "early" ]]; then
            error "El flag --auto-upload requiere que GitHub CLI (gh) esté autenticado."
            echo ""
            info "GitHub CLI está instalado pero necesita autenticación para subir automáticamente las llaves SSH y GPG a tu cuenta de GitHub."
            echo ""
            info "En modo no-interactivo, debes autenticar GitHub CLI antes de ejecutar este script:"
            echo ""
            echo "  1. Autentica GitHub CLI manualmente:"
            echo "     $(c primary)gh auth login$(cr)"
            echo ""
            echo "  2. O usa un token de GitHub:"
            echo "     $(c primary)echo 'tu_token_github' | gh auth login --with-token$(cr)"
            echo ""
            echo "  3. Vuelve a ejecutar este script con $(c primary)--auto-upload$(cr)"
            echo ""
            exit 1
        else
            info "GitHub CLI está instalado pero requiere autenticación para subir llaves."
            echo ""
            printf "%b\n" "$(c warning)Para habilitar la subida automática en modo no-interactivo:$(cr)"
            echo ""
            echo "  1. Autentica GitHub CLI manualmente:"
            echo "     $(c primary)gh auth login$(cr)"
            echo ""
            echo "  2. O usa un token de GitHub:"
            echo "     $(c primary)echo 'tu_token_github' | gh auth login --with-token$(cr)"
            echo ""
            echo "  3. Luego vuelve a ejecutar este script con $(c primary)--auto-upload$(cr)"
            echo ""
            warning "Omitiendo subida automática. Las llaves se guardarán localmente."
            return 1
        fi
    fi
}

#==============================================================================
# KEY UPLOADING
#==============================================================================

# @description Upload SSH key to GitHub
# @return 0 on success, 1 on failure
# @example
#   upload_ssh_key_to_github
upload_ssh_key_to_github() {
    local ssh_key_file="$HOME/.ssh/id_ed25519.pub"
    
    if [[ ! -f "$ssh_key_file" ]]; then
        warning "No se encontró la llave SSH pública para subirla a GitHub."
        return 1
    fi
    
    local title="${SSH_KEY_TITLE:-$(hostname)-$(date +%Y%m%d_%H%M)}"
    
    if gh ssh-key add "$ssh_key_file" --title "$title" &>/dev/null; then
        success "Llave SSH subida a GitHub automáticamente (${title})"
        SSH_KEY_UPLOADED=true
        return 0
    else
        warning "No se pudo subir la llave SSH automáticamente."
        return 1
    fi
}

# @description Upload GPG key to GitHub
# @return 0 on success, 1 on failure
# @example
#   upload_gpg_key_to_github
upload_gpg_key_to_github() {
    if [[ -z "$GPG_KEY_ID" ]]; then
        info "No hay llave GPG nueva para subir."
        return 1
    fi
    
    # Check OAuth scopes for GPG
    local scope_check_output
    scope_check_output=$(gh gpg-key list 2>&1 || true)
    
    if echo "$scope_check_output" | grep -qi "insufficient OAuth scopes\|write:gpg_key"; then
        show_separator
        warning "GitHub CLI necesita permisos adicionales para gestionar llaves GPG"
        show_separator
        echo ""
        info "Se requiere el scope $(c primary)write:gpg_key$(cr) para subir llaves GPG a GitHub."
        echo ""
        
        if [[ "$INTERACTIVE_MODE" == "true" ]]; then
            if ask_yes_no "¿Deseas actualizar los permisos de GitHub CLI ahora?" "y"; then
                echo ""
                info "Actualizando permisos de GitHub CLI..."
                echo "$(c muted)Nota: Es posible que se abra tu navegador para autorizar los permisos adicionales.$(cr)"
                echo ""
                
                if gh auth refresh -s write:gpg_key; then
                    echo ""
                    success "Permisos actualizados exitosamente"
                    echo ""
                else
                    echo ""
                    error "No se pudieron actualizar los permisos"
                    echo ""
                    info "Puedes actualizar los permisos manualmente ejecutando:"
                    echo "  $(c primary)gh auth refresh -s write:gpg_key$(cr)"
                    return 1
                fi
            else
                echo ""
                warning "Permisos no actualizados. No se podrá subir la llave GPG automáticamente."
                echo ""
                info "Para subir la llave GPG más tarde, ejecuta:"
                echo "  $(c primary)gh auth refresh -s write:gpg_key$(cr)"
                echo "  $(c primary)gh gpg-key add <archivo-llave-gpg>$(cr)"
                return 1
            fi
        else
            echo ""
            warning "GitHub CLI requiere permisos adicionales para gestionar llaves GPG."
            echo ""
            info "En modo no-interactivo, actualiza los permisos manualmente:"
            echo "  $(c primary)gh auth refresh -s write:gpg_key$(cr)"
            echo ""
            info "Luego vuelve a ejecutar este script."
            return 1
        fi
    fi
    
    # Check if GPG key already exists on GitHub
    local existing_keys
    existing_keys=$(gh gpg-key list 2>/dev/null | grep -i "$GPG_KEY_ID" || true)
    if [[ -n "$existing_keys" ]]; then
        info "La llave GPG $(c primary)$GPG_KEY_ID$(cr) ya existe en tu cuenta de GitHub."
        GPG_KEY_UPLOADED=true
        return 0
    fi
    
    local gpg_temp
    gpg_temp=$(mktemp)
    
    if ! gpg --armor --export "$GPG_KEY_ID" > "$gpg_temp" 2>/dev/null; then
        warning "No se pudo exportar la llave GPG para subirla a GitHub."
        rm -f "$gpg_temp"
        return 1
    fi
    
    # Try to upload and capture error
    local gh_output
    local gh_exit_code
    gh_output=$(gh gpg-key add "$gpg_temp" 2>&1)
    gh_exit_code=$?
    
    if [[ $gh_exit_code -eq 0 ]]; then
        success "Llave GPG subida a GitHub automáticamente"
        GPG_KEY_UPLOADED=true
        rm -f "$gpg_temp"
        return 0
    else
        if echo "$gh_output" | grep -qi "already exists\|duplicate\|already registered"; then
            info "La llave GPG $(c primary)$GPG_KEY_ID$(cr) ya existe en tu cuenta de GitHub."
            GPG_KEY_UPLOADED=true
            rm -f "$gpg_temp"
            return 0
        else
            warning "No se pudo subir la llave GPG automáticamente."
            if [[ -n "$gh_output" ]]; then
                printf "%b\n" "$(c muted)Error: ${gh_output}$(cr)"
            fi
            rm -f "$gpg_temp"
            return 1
        fi
    fi
}

# @description Decide whether to upload keys and execute upload
# @example
#   maybe_upload_keys
maybe_upload_keys() {
    local should_upload=false
    
    if [[ "$INTERACTIVE_MODE" == "true" ]]; then
        if [[ "$AUTO_UPLOAD_KEYS" == "true" ]]; then
            should_upload=true
        else
            if ask_yes_no "¿Deseas subir automáticamente las llaves a GitHub usando GitHub CLI?" "y"; then
                should_upload=true
            fi
        fi
    else
        if [[ "$AUTO_UPLOAD_KEYS" == "true" ]]; then
            should_upload=true
        else
            info "El flag --auto-upload no está activo. Omitiendo subida automática."
            return
        fi
    fi
    
    if [[ "$should_upload" != "true" ]]; then
        return
    fi
    
    # Safety check
    if ! ensure_github_cli_ready; then
        echo ""
        warning "GitHub CLI no está disponible. No se pudieron subir las llaves automáticamente."
        info "Las llaves se guardarán localmente para que puedas subirlas manualmente."
        echo ""
        return
    fi
    
    # Upload keys
    echo ""
    show_separator
    printf "%b\n" "$(c bold)$(c success)🚀 SUBIENDO LLAVES A GITHUB$(cr)"
    show_separator
    echo ""
    
    local ssh_uploaded=false
    local gpg_uploaded=false
    
    if upload_ssh_key_to_github; then
        ssh_uploaded=true
    fi
    
    if [[ -n "$GPG_KEY_ID" ]]; then
        if upload_gpg_key_to_github; then
            gpg_uploaded=true
        fi
    fi
    
    echo ""
    show_separator
    
    if [[ "$ssh_uploaded" == "true" ]] || [[ "$gpg_uploaded" == "true" ]]; then
        success "Subida de llaves completada"
        echo ""
        if [[ "$ssh_uploaded" == "true" ]]; then
            info "  • Llave SSH: $(c success)Subida exitosamente$(cr)"
        fi
        if [[ "$gpg_uploaded" == "true" ]]; then
            info "  • Llave GPG: $(c success)Subida exitosamente$(cr)"
        fi
    else
        warning "No se pudieron subir las llaves automáticamente"
        echo ""
        info "Puedes subirlas manualmente desde:"
        echo "  $(c primary)https://github.com/settings/ssh/new$(cr) (SSH)"
        echo "  $(c primary)https://github.com/settings/gpg/new$(cr) (GPG)"
    fi
    
    show_separator
    echo ""
    echo ""
}

#==============================================================================
# CONNECTIVITY TESTING
#==============================================================================

# @description Test SSH connection to GitHub
# @example
#   test_github_connection
test_github_connection() {
    show_separator
    printf "%b\n" "$(c bold)$(c text)🧪 PRUEBA DE CONECTIVIDAD$(cr)"
    show_separator
    
    if ask_yes_no "¿Deseas probar la conexión SSH con GitHub ahora?"; then
        info "Probando conexión SSH con GitHub..."
        
        # Temporarily disable exit on error since ssh returns 1 even on success
        set +e
        local ssh_output
        local ssh_exit_code
        ssh_output=$(ssh -T git@github.com 2>&1)
        ssh_exit_code=$?
        set -e
        
        if [[ $ssh_exit_code -eq 1 ]] && [[ $ssh_output == *"successfully authenticated"* ]]; then
            success "¡Conexión SSH con GitHub exitosa!"
            printf "%b\n" "$(c success)$ssh_output$(cr)"
            echo ""
        else
            warning "La conexión SSH falló o está pendiente de configuración"
            printf "%b\n" "$(c warning)Salida: $ssh_output$(cr)"
            printf "%b\n" "$(c primary)Asegúrate de haber agregado la llave SSH a tu cuenta de GitHub$(cr)"
            echo ""
        fi
    fi
}
