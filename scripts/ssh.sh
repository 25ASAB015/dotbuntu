#!/usr/bin/env bash
#==============================================================================
#                              SSH
#==============================================================================
# @file ssh.sh
# @brief SSH key generation and management
# @description
#   Provides functions for generating SSH keys, configuring ssh-agent,
#   and managing SSH configuration.
#
# Globals:
#   USER_NAME     Git user name
#   USER_EMAIL    Git user email
#
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#==============================================================================

# Prevent double sourcing
[[ -n "${_SSH_SOURCED:-}" ]] && return 0
declare -r _SSH_SOURCED=1

#==============================================================================
# SSH KEY GENERATION
#==============================================================================

# @description Generate a new SSH key for GitHub
# @return 0 on success, 1 on failure
# @example
#   if ! generate_ssh_key; then
#       error "SSH key generation failed"
#   fi
generate_ssh_key() {
    local ssh_dir="$HOME/.ssh"
    local key_file="$ssh_dir/id_ed25519"
    
    show_separator
    echo -e "$(c bold)🔐 GENERACIÓN DE LLAVE SSH$(cr)"
    show_separator
    
    # Check if key already exists
    if [[ -f "$key_file" ]]; then
        info "Ya existe una llave SSH en $key_file"
        
        if ask_yes_no "¿Deseas usar la llave existente?" "y"; then
            success "Usando llave SSH existente"
            echo ""
            return 0
        fi
        
        if ! ask_yes_no "¿Deseas generar una nueva llave (se respaldará la existente)?" "n"; then
            return 1
        fi
        
        # Backup existing key
        local backup_suffix=".backup-$(date +%Y%m%d_%H%M%S)"
        mv "$key_file" "${key_file}${backup_suffix}"
        mv "${key_file}.pub" "${key_file}.pub${backup_suffix}"
        success "Llave existente respaldada con sufijo: $backup_suffix"
    fi
    
    # Generate new SSH key
    info "Generando nueva llave SSH Ed25519..."
    
    if ssh-keygen -t ed25519 -C "$USER_EMAIL" -f "$key_file" -N "" -q; then
        chmod 600 "$key_file"
        chmod 644 "${key_file}.pub"
        success "Llave SSH generada exitosamente"
        log "SSH key generated: $key_file"
        
        # Start ssh-agent and add key
        start_ssh_agent
        
        return 0
    else
        error "Error al generar la llave SSH"
        return 1
    fi
}

#==============================================================================
# SSH AGENT MANAGEMENT
#==============================================================================

# @description Start ssh-agent and add the SSH key
# @return 0 on success, 1 on failure
# @example
#   start_ssh_agent
start_ssh_agent() {
    local key_file="$HOME/.ssh/id_ed25519"
    
    info "Iniciando ssh-agent..."
    
    # Start ssh-agent
    eval "$(ssh-agent -s)" &>/dev/null
    
    # Add key to agent
    if ssh-add "$key_file" &>/dev/null; then
        success "Llave SSH agregada al ssh-agent"
        return 0
    else
        warning "No se pudo agregar la llave al ssh-agent automáticamente"
        return 1
    fi
}

# @description Create SSH configuration and shell integration script
# @example
#   create_ssh_agent_script
create_ssh_agent_script() {
    local ssh_config="$HOME/.ssh/config"
    local bashrc_addition
    bashrc_addition=$(mktemp)
    
    info "Creando configuración permanente para ssh-agent..."
    
    # Create SSH config if not exists
    if [[ ! -f "$ssh_config" ]]; then
        cat > "$ssh_config" << EOF
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
EOF
        chmod 600 "$ssh_config"
        success "Archivo de configuración SSH creado"
    fi
    
    # Create addition for shell configs
    cat > "$bashrc_addition" << 'EOF'
# GitHub SSH Agent Configuration (generado automáticamente)
if [ -f ~/.ssh/id_ed25519 ]; then
    eval "$(ssh-agent -s)" &>/dev/null
    ssh-add ~/.ssh/id_ed25519 &>/dev/null
fi
EOF
    
    # Detect available shell config files
    local shell_configs=()
    local shell_names=()
    
    if [[ -f "$HOME/.bashrc" ]]; then
        shell_configs+=("$HOME/.bashrc")
        shell_names+=("bashrc")
    fi
    
    if [[ -f "$HOME/.zshrc" ]]; then
        shell_configs+=("$HOME/.zshrc")
        shell_names+=("zshrc")
    fi
    
    # Show configuration to add
    echo ""
    info "Configuración para ssh-agent automático:"
    show_separator
    cat "$bashrc_addition"
    show_separator
    echo ""
    
    # If config files available, offer to add
    if [[ ${#shell_configs[@]} -gt 0 ]]; then
        info "Archivos de configuración de shell detectados:"
        for name in "${shell_names[@]}"; do
            echo "  • ~/.${name}"
        done
        echo ""
        
        local prompt_msg="¿Deseas agregar esta configuración a"
        if [[ ${#shell_configs[@]} -eq 1 ]]; then
            prompt_msg+=" ~/.${shell_names[0]}?"
        else
            prompt_msg+=" todos estos archivos?"
        fi
        
        if ask_yes_no "$prompt_msg"; then
            local added_count=0
            
            for i in "${!shell_configs[@]}"; do
                local config_file="${shell_configs[$i]}"
                local config_name="${shell_names[$i]}"
                
                # Check if already exists
                if grep -q "GitHub SSH Agent Configuration" "$config_file" 2>/dev/null; then
                    info "✓ La configuración de ssh-agent ya está presente en ~/.${config_name} (no se requiere acción)"
                else
                    echo "" >> "$config_file"
                    cat "$bashrc_addition" >> "$config_file"
                    success "Configuración agregada a ~/.${config_name}"
                    added_count=$((added_count + 1))
                fi
            done
            
            if [[ $added_count -gt 0 ]]; then
                echo ""
                success "Configuración agregada a ${added_count} archivo(s)"
                info "Reinicia tu terminal o ejecuta: $(c primary)source ~/.bashrc$(cr) / $(c primary)source ~/.zshrc$(cr)"
                echo ""
            fi
        else
            info "Configuración no agregada. Puedes agregarla manualmente usando el código mostrado arriba"
            echo ""
        fi
    else
        warning "No se encontraron archivos ~/.bashrc ni ~/.zshrc"
        info "Crea uno de estos archivos y agrega manualmente la configuración mostrada arriba"
        echo ""
    fi
    
    # Cleanup
    rm -f "$bashrc_addition"
}
