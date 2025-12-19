#!/usr/bin/env bash
#==============================================================================
#                              FINALIZE
#==============================================================================
# @file finalize.sh
# @brief Finalization routines for gitconfig setup
# @description
#   Provides functions for displaying generated keys, saving keys to files,
#   and showing final instructions to the user.
#
# Globals:
#   USER_NAME          Git user name
#   USER_EMAIL         Git user email
#   GPG_KEY_ID         GPG key ID
#   SSH_KEY_UPLOADED   SSH key upload status
#   GPG_KEY_UPLOADED   GPG key upload status
#   AUTO_UPLOAD_KEYS   Auto-upload flag
#   LOG_FILE           Log file path
#   SCRIPT_DIR         Script directory
#
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#==============================================================================

# Prevent double sourcing
[[ -n "${_FINALIZE_SOURCED:-}" ]] && return 0
declare -r _FINALIZE_SOURCED=1

#==============================================================================
# KEY DISPLAY
#==============================================================================

# @description Display generated SSH and GPG keys
# @example
#   display_keys
display_keys() {
    # Skip display if auto-upload was used
    if [[ "$AUTO_UPLOAD_KEYS" == "true" ]]; then
        return 0
    fi
    
    show_separator
    echo -e "$(c bold)📋 RESUMEN DE LLAVES GENERADAS$(cr)"
    show_separator
    echo ""
    
    # SSH Key
    info "1. LLAVE SSH PÚBLICA (para agregar a GitHub):"
    echo ""
    
    if [[ -f "$HOME/.ssh/id_ed25519.pub" ]]; then
        show_separator
        printf "%b\n" "$(c bold)$(c success)$(cat "$HOME/.ssh/id_ed25519.pub")$(cr)"
        show_separator
        echo ""
        
        if ask_yes_no "¿Deseas copiar la llave SSH al portapapeles?"; then
            # Avoid aborting the whole script if clipboard tooling is missing
            if ! copy_to_clipboard "$HOME/.ssh/id_ed25519.pub"; then
                warning "No se pudo copiar la llave SSH al portapapeles (instala xclip/xsel/wl-copy)."
            fi
            echo ""
        fi
    else
        error "No se encontró la llave SSH pública en $HOME/.ssh/id_ed25519.pub"
    fi
    
    echo ""
    
    # GPG Key
    if [[ -n "$GPG_KEY_ID" ]]; then
        info "2. LLAVE GPG PÚBLICA (para agregar a GitHub):"
        echo ""
        info "ID de la llave GPG: $(c bold)$(c primary)$GPG_KEY_ID$(cr)"
        echo ""
        
        local gpg_temp
        gpg_temp=$(mktemp)
        
        if gpg --armor --export "$GPG_KEY_ID" > "$gpg_temp" 2>/dev/null; then
            show_separator
            cat "$gpg_temp"
            show_separator
            echo ""
            
            if ask_yes_no "¿Deseas copiar la llave GPG al portapapeles?"; then
                # Avoid aborting if clipboard tooling is missing
                if ! copy_to_clipboard "$gpg_temp"; then
                    warning "No se pudo copiar la llave GPG al portapapeles (instala xclip/xsel/wl-copy)."
                fi
                echo ""
            fi
        else
            error "No se pudo exportar la llave GPG"
        fi
        
        rm -f "$gpg_temp"
    else
        info "2. LLAVE GPG: No se generó (opcional)"
    fi
    
    echo ""
    show_separator
    echo ""
    info "Próximos pasos:"
    echo ""
    echo "  $(c bold)$(c warning)Para la llave SSH:$(cr)"
    echo "    $(c bold)1.$(cr) Ve a: $(c bold)$(c primary)https://github.com/settings/ssh/new$(cr)"
    echo "    $(c bold)2.$(cr) Pega la llave SSH mostrada arriba"
    echo "    $(c bold)3.$(cr) Dale un título descriptivo"
    echo ""
    
    if [[ -n "$GPG_KEY_ID" ]]; then
        echo "  $(c bold)$(c warning)Para la llave GPG:$(cr)"
        echo "    $(c bold)1.$(cr) Ve a: $(c bold)$(c primary)https://github.com/settings/gpg/new$(cr)"
        echo "    $(c bold)2.$(cr) Pega la llave GPG mostrada arriba"
        echo "    $(c bold)3.$(cr) Tus commits aparecerán como 'Verified' ✓"
        echo ""
    fi
    
    show_separator
    echo ""
}

#==============================================================================
# KEY SAVING
#==============================================================================

# @description Save keys to files for future reference
# @example
#   save_keys_to_files
save_keys_to_files() {
    show_separator
    printf "%b\n" "$(c bold)$(c text)💾 EXPORTANDO LLAVES PÚBLICAS PARA GITHUB$(cr)"
    show_separator
    echo ""
    info "Guardando llaves públicas para que puedas agregarlas a tu cuenta de GitHub..."
    echo ""
    
    local output_dir="$HOME/.github-keys-setup/keys-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$output_dir"
    
    # Save SSH key
    if [[ -f "$HOME/.ssh/id_ed25519.pub" ]]; then
        cp "$HOME/.ssh/id_ed25519.pub" "$output_dir/ssh_public_key.txt"
        success "Llave SSH pública guardada en: $output_dir/ssh_public_key.txt"
    fi
    
    # Save GPG key
    if [[ -n "$GPG_KEY_ID" ]]; then
        gpg --armor --export "$GPG_KEY_ID" > "$output_dir/gpg_public_key.txt"
        success "Llave GPG pública guardada en: $output_dir/gpg_public_key.txt"
    fi
    
    # Create info file
    cat > "$output_dir/key_info.txt" << EOF
INFORMACIÓN DE LLAVES GENERADAS
===============================

Fecha de generación: $(date)
Usuario: $USER_NAME
Email: $USER_EMAIL
GPG Key ID: $GPG_KEY_ID

INSTRUCCIONES:
1. Agrega la llave SSH a tu cuenta de GitHub en: https://github.com/settings/ssh/new
2. Agrega la llave GPG a tu cuenta de GitHub en: https://github.com/settings/gpg/new
3. Las llaves están guardadas en este directorio para referencia futura

NOTA: Mantén estos archivos seguros y no los compartas públicamente.
EOF
    
    success "Información guardada en: $output_dir/key_info.txt"
    echo ""
    info "Directorio de exportación: $(c primary)$output_dir$(cr)"
    info "$(c muted)(Estas son las llaves públicas que debes agregar a GitHub)$(cr)"
    echo ""
}

#==============================================================================
# FINAL INSTRUCTIONS
#==============================================================================

# @description Show final instructions to the user
# @example
#   show_final_instructions
show_final_instructions() {
    echo ""
    show_separator
    printf "%b\n" "$(c bold)$(c accent)📚 INSTRUCCIONES FINALES PARA GITHUB$(cr)"
    show_separator
    echo ""
    
    if [[ "$SSH_KEY_UPLOADED" == true ]] || [[ "$GPG_KEY_UPLOADED" == true ]]; then
        info "Subida automática: $(c success)SSH $( [[ "$SSH_KEY_UPLOADED" == true ]] && echo '✓' || echo '✗' )$(cr)  |  $(c success)GPG $( [[ "$GPG_KEY_UPLOADED" == true ]] && echo '✓' || echo '✗' )$(cr)"
        echo ""
    fi
    
    # Only show key addition steps if not uploaded automatically
    if [[ "$SSH_KEY_UPLOADED" != true ]]; then
        printf "%b\n" "$(c bold)$(c accent)🔐 PASO 1: AGREGAR LLAVE SSH$(cr)"
        printf "%b\n" "$(c muted)$(cr)   ├─ $(c bold)$(c primary)URL:$(cr) $(c bold)https://github.com/settings/ssh/new$(cr)"
        printf "%b\n" "$(c muted)$(cr)   ├─ $(c bold)$(c primary)Título sugerido:$(cr) $(c bold)$(hostname)-$(date +%Y%m%d)$(cr)"
        printf "%b\n" "$(c muted)$(cr)   └─ $(c bold)$(c warning)Pega la llave SSH pública que se mostró arriba$(cr)"
        echo ""
    else
        printf "%b\n" "$(c bold)$(c accent)🔐 PASO 1: LLAVE SSH$(cr)"
        printf "%b\n" "$(c muted)$(cr)   └─ $(c success)✓ Ya agregada automáticamente a tu cuenta de GitHub$(cr)"
        echo ""
    fi
    
    if [[ "$GPG_KEY_UPLOADED" != true ]]; then
        if [[ -n "$GPG_KEY_ID" ]]; then
            printf "%b\n" "$(c bold)$(c accent)🔑 PASO 2: AGREGAR LLAVE GPG (Opcional)$(cr)"
            printf "%b\n" "$(c muted)$(cr)   ├─ $(c bold)$(c primary)URL:$(cr) $(c bold)https://github.com/settings/gpg/new$(cr)"
            printf "%b\n" "$(c muted)$(cr)   ├─ $(c bold)$(c warning)Pega la llave GPG pública que se mostró arriba$(cr)"
            printf "%b\n" "$(c muted)$(cr)   └─ $(c muted)Esto permitirá que tus commits aparezcan como 'Verified'$(cr)"
            echo ""
        fi
    else
        printf "%b\n" "$(c bold)$(c accent)🔑 PASO 2: LLAVE GPG$(cr)"
        printf "%b\n" "$(c muted)$(cr)   └─ $(c success)✓ Ya agregada automáticamente a tu cuenta de GitHub$(cr)"
        echo ""
    fi
    
    # Adjust step number
    local paso_num=3
    if [[ "$SSH_KEY_UPLOADED" == true ]] && [[ "$GPG_KEY_UPLOADED" == true ]]; then
        paso_num=1
    elif [[ "$SSH_KEY_UPLOADED" == true ]] || [[ "$GPG_KEY_UPLOADED" == true ]]; then
        paso_num=2
    fi
    
    printf "%b\n" "$(c bold)$(c accent)✅ PASO ${paso_num}: VERIFICAR CONFIGURACIÓN$(cr)"
    printf "%b\n" "$(c muted)$(cr)   ├─ $(c bold)$(c primary)Probar SSH:$(cr) $(c bold)$(c success)ssh -T git@github.com$(cr)"
    printf "%b\n" "$(c muted)$(cr)   │  $(c muted)→ Deberías ver: 'Hi username! You've successfully authenticated...'$(cr)"
    printf "%b\n" "$(c muted)$(cr)   └─ $(c bold)$(c primary)Probar GPG:$(cr) $(c muted)Haz un commit y verifica el badge 'Verified' en GitHub$(cr)"
    echo ""
    echo ""
    
    paso_num=$((paso_num + 1))
    printf "%b\n" "$(c bold)$(c accent)📁 PASO ${paso_num}: ARCHIVOS GENERADOS$(cr)"
    printf "%b\n" "$(c muted)$(cr)   ├─ $(c bold)$(c primary)~/.gitconfig$(cr)     $(c muted)→ Configuración profesional de Git$(cr)"
    printf "%b\n" "$(c muted)$(cr)   ├─ $(c bold)$(c primary)~/.gitmessage$(cr)    $(c muted)→ Plantilla para mensajes de commit$(cr)"
    printf "%b\n" "$(c muted)$(cr)   ├─ $(c bold)$(c primary)~/.ssh/config$(cr)    $(c muted)→ Configuración SSH optimizada$(cr)"
    printf "%b\n" "$(c muted)$(cr)   └─ $(c bold)$(c primary)~/.ssh/id_ed25519$(cr) $(c muted)→ Tu llave SSH privada (¡nunca la compartas!)$(cr)"
    echo ""
    echo ""
    
    paso_num=$((paso_num + 1))
    printf "%b\n" "$(c bold)$(c accent)🔐 PASO ${paso_num}: CREDENTIAL MANAGER$(cr)"
    printf "%b\n" "$(c muted)$(cr)   ├─ $(c bold)$(c success)✓$(cr) $(c bold)Git Credential Manager configurado$(cr)"
    printf "%b\n" "$(c muted)$(cr)   ├─ $(c muted)No se solicitará contraseña en cada operación$(cr)"
    printf "%b\n" "$(c muted)$(cr)   ├─ $(c bold)$(c warning)En el primer push, se abrirá el navegador para autenticar$(cr)"
    printf "%b\n" "$(c muted)$(cr)   └─ $(c bold)$(c primary)Pre-autenticar (opcional):$(cr) $(c bold)$(c success)git-credential-manager github login$(cr)"
    echo ""
    echo ""
    
    printf "%b\n" "$(c bold)$(c accent)💡 COMANDOS ÚTILES:$(cr)"
    printf "%b\n" "$(c muted)$(cr)   ├─ $(c bold)$(c primary)Ver configuración Git:$(cr)    $(c bold)git config --list --show-origin$(cr)"
    printf "%b\n" "$(c muted)$(cr)   ├─ $(c bold)$(c primary)Ver llaves SSH:$(cr)          $(c bold)ls -la ~/.ssh/$(cr)"
    printf "%b\n" "$(c muted)$(cr)   ├─ $(c bold)$(c primary)Ver llaves GPG:$(cr)          $(c bold)gpg --list-secret-keys --keyid-format=long$(cr)"
    printf "%b\n" "$(c muted)$(cr)   └─ $(c bold)$(c primary)Ver logs del script:$(cr)     $(c bold)cat $LOG_FILE$(cr)"
    echo ""
    
    show_separator
    printf "%b\n" "$(c bold)$(c success)✨ ¡CONFIGURACIÓN COMPLETADA EXITOSAMENTE! ✨$(cr)"
    printf "%b\n" "$(c accent)Tu entorno de desarrollo Git está configurado de forma profesional.$(cr)"
    printf "%b\n" "$(c muted)Ahora puedes trabajar con GitHub con autenticación SSH y commits firmados.$(cr)"
    show_separator
    echo ""
}

#==============================================================================
# POST-INSTALLATION VERIFICATION
#==============================================================================

# @description Run comprehensive verification suite to test all configured components
# @return 0 if all critical tests pass, 1 if any critical test fails
# @example
#   run_verification_suite
run_verification_suite() {
    show_separator
    printf "%b\n" "$(c bold)$(c accent)🧪 VERIFICACIÓN POST-INSTALACIÓN$(cr)"
    show_separator
    echo ""
    
    local tests_passed=0
    local tests_failed=0
    local tests_warnings=0
    local tests_total=0
    
    # Calcular el ancho máximo necesario para alinear los símbolos
    local max_width=0
    local test_names=(
        "Verificando configuración de Git..."
        "Verificando llave SSH..."
        "Verificando SSH agent..."
    )
    [[ -n "${GPG_KEY_ID:-}" ]] && test_names+=("Verificando llave GPG...")
    test_names+=(
        "Verificando GitHub CLI..."
        "Verificando Git Credential Manager..."
        "Verificando conectividad con GitHub..."
    )
    
    for name in "${test_names[@]}"; do
        local len=${#name}
        [[ $len -gt $max_width ]] && max_width=$len
    done
    
    # Agregar padding para el símbolo (2 espacios + símbolo)
    local total_width=$((max_width + 4))
    
    # Test 1: Git config
    tests_total=$((tests_total + 1))
    local test_name="Verificando configuración de Git..."
    local name_len=${#test_name}
    local padding=$((total_width - name_len))
    printf "  %s%*s" "$test_name" "$padding" ""
    if git config --global user.name &>/dev/null && git config --global user.email &>/dev/null; then
        printf "%b\n" "$(c success)✓$(cr)"
        tests_passed=$((tests_passed + 1))
    else
        printf "%b\n" "$(c error)✗$(cr)"
        tests_failed=$((tests_failed + 1))
    fi
    
    # Test 2: SSH key
    tests_total=$((tests_total + 1))
    test_name="Verificando llave SSH..."
    name_len=${#test_name}
    padding=$((total_width - name_len))
    printf "  %s%*s" "$test_name" "$padding" ""
    if [[ -f "$HOME/.ssh/id_ed25519" ]] && [[ -f "$HOME/.ssh/id_ed25519.pub" ]]; then
        printf "%b\n" "$(c success)✓$(cr)"
        tests_passed=$((tests_passed + 1))
    else
        printf "%b\n" "$(c error)✗$(cr)"
        tests_failed=$((tests_failed + 1))
    fi
    
    # Test 3: SSH agent
    tests_total=$((tests_total + 1))
    test_name="Verificando SSH agent..."
    name_len=${#test_name}
    padding=$((total_width - name_len))
    printf "  %s%*s" "$test_name" "$padding" ""
    if ssh-add -l &>/dev/null; then
        printf "%b\n" "$(c success)✓$(cr)"
        tests_passed=$((tests_passed + 1))
    else
        printf "%b\n" "$(c warning)⚠$(cr)"
        tests_warnings=$((tests_warnings + 1))
    fi
    
    # Test 4: GPG key (conditional)
    if [[ -n "${GPG_KEY_ID:-}" ]]; then
        tests_total=$((tests_total + 1))
        test_name="Verificando llave GPG..."
        name_len=${#test_name}
        padding=$((total_width - name_len))
        printf "  %s%*s" "$test_name" "$padding" ""
        if gpg --list-secret-keys "$GPG_KEY_ID" &>/dev/null; then
            printf "%b\n" "$(c success)✓$(cr)"
            tests_passed=$((tests_passed + 1))
        else
            printf "%b\n" "$(c error)✗$(cr)"
            tests_failed=$((tests_failed + 1))
        fi
    fi
    
    # Test 5: GitHub CLI
    tests_total=$((tests_total + 1))
    test_name="Verificando GitHub CLI..."
    name_len=${#test_name}
    padding=$((total_width - name_len))
    printf "  %s%*s" "$test_name" "$padding" ""
    if command -v gh &>/dev/null && gh auth status &>/dev/null; then
        printf "%b\n" "$(c success)✓$(cr)"
        tests_passed=$((tests_passed + 1))
    else
        printf "%b\n" "$(c warning)⚠$(cr)"
        tests_warnings=$((tests_warnings + 1))
    fi
    
    # Test 6: Git Credential Manager
    tests_total=$((tests_total + 1))
    test_name="Verificando Git Credential Manager..."
    name_len=${#test_name}
    padding=$((total_width - name_len))
    printf "  %s%*s" "$test_name" "$padding" ""
    if command -v git-credential-manager &>/dev/null || command -v git-credential-manager-core &>/dev/null; then
        printf "%b\n" "$(c success)✓$(cr)"
        tests_passed=$((tests_passed + 1))
    else
        printf "%b\n" "$(c error)✗$(cr)"
        tests_failed=$((tests_failed + 1))
    fi
    
    # Test 7: Conectividad GitHub (usando la misma lógica que test_github_connection)
    tests_total=$((tests_total + 1))
    test_name="Verificando conectividad con GitHub..."
    name_len=${#test_name}
    padding=$((total_width - name_len))
    printf "  %s%*s" "$test_name" "$padding" ""
    set +e
    local ssh_output
    local ssh_exit_code
    ssh_output=$(timeout 5 ssh -T git@github.com 2>&1)
    ssh_exit_code=$?
    set -e
    
    if [[ $ssh_exit_code -eq 1 ]] && [[ $ssh_output == *"successfully authenticated"* ]]; then
        printf "%b\n" "$(c success)✓$(cr)"
        tests_passed=$((tests_passed + 1))
    else
        printf "%b\n" "$(c warning)⚠$(cr)"
        tests_warnings=$((tests_warnings + 1))
    fi
    
    # Resumen
    echo ""
    show_separator
    printf "%b\n" "$(c bold)$(c info)Resumen de verificación:$(cr)"
    printf "  Tests ejecutados: %d\n" "$tests_total"
    printf "  $(c success)✓ Pasados: %d$(cr)\n" "$tests_passed"
    if [[ $tests_warnings -gt 0 ]]; then
        printf "  $(c warning)⚠ Advertencias: %d$(cr)\n" "$tests_warnings"
    fi
    if [[ $tests_failed -gt 0 ]]; then
        printf "  $(c error)✗ Fallidos: %d$(cr)\n" "$tests_failed"
    fi
    show_separator
    echo ""
    
    if [[ $tests_failed -eq 0 ]]; then
        success "¡Todas las verificaciones pasaron correctamente!"
        log "Verification suite: All tests passed ($tests_passed/$tests_total)"
        return 0
    else
        warning "Algunas verificaciones fallaron. Revisa la configuración."
        log "Verification suite: Some tests failed ($tests_failed/$tests_total failed, $tests_passed/$tests_total passed)"
        return 1
    fi
}
