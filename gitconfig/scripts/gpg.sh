#!/usr/bin/env bash
#==============================================================================
#                              GPG
#==============================================================================
# @file gpg.sh
# @brief GPG key generation and management
# @description
#   Provides functions for generating GPG keys, configuring the GPG
#   environment, and managing GPG processes.
#
# Globals:
#   USER_NAME     Git user name
#   USER_EMAIL    Git user email
#   GPG_KEY_ID    GPG key ID (set after generation)
#   DEBUG         Debug mode flag
#
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#==============================================================================

# Prevent double sourcing
[[ -n "${_GPG_SOURCED:-}" ]] && return 0
declare -r _GPG_SOURCED=1

#==============================================================================
# GPG KEY GENERATION
#==============================================================================

# @description Generate a new GPG key for signing commits
# @return 0 on success, 1 on failure
# @example
#   if ! generate_gpg_key; then
#       warning "GPG key generation failed"
#   fi
generate_gpg_key() {
    show_separator
    echo -e "$(c bold)🔑 GENERACIÓN DE LLAVE GPG$(cr)"
    show_separator
    
    # Setup GPG environment first
    setup_gpg_environment
    
    # Check for existing GPG key
    if command -v gpg &> /dev/null; then
        local existing_key
        # Allow the pipeline to fail quietly when no key exists to avoid aborting under set -euo pipefail
        existing_key=$(gpg --list-secret-keys --keyid-format=long "$USER_EMAIL" 2>/dev/null | grep 'sec' | head -n1 | sed 's/.*\/\([A-Z0-9]*\).*/\1/' || true)
        
        if [[ -n "$existing_key" ]]; then
            info "Ya existe una llave GPG para $USER_EMAIL"
            GPG_KEY_ID="$existing_key"
            success "Usando llave GPG existente: $GPG_KEY_ID"
            return 0
        fi
    fi
    
    info "Generando nueva llave GPG para firmar commits..."
    
    # Create temporary GPG config file
    local gpg_config
    gpg_config=$(mktemp)
    cat > "$gpg_config" << EOF
%echo Generando llave GPG para GitHub
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: $USER_NAME
Name-Email: $USER_EMAIL
Expire-Date: 2y
%no-protection
%commit
%echo Llave GPG generada exitosamente
EOF
    
    info "Archivo de configuración GPG creado: $gpg_config"
    
    if [[ "$DEBUG" == "true" ]]; then
        printf "%b\n" "$(c warning)Contenido del archivo de configuración GPG:$(cr)"
        cat "$gpg_config"
        echo ""
    fi
    
    # Generate GPG key with retries
    info "Ejecutando: gpg --batch --generate-key $gpg_config"
    
    local gpg_output
    local gpg_exit_code
    local max_retries=3
    local retry_count=0
    
    while [[ $retry_count -lt $max_retries ]]; do
        info "Intento $((retry_count + 1)) de $max_retries..."
        
        # Clean processes before each retry
        if [[ $retry_count -gt 0 ]]; then
            cleanup_gpg_processes
            sleep 3
        fi
        
        # Capture both stdout and stderr
        gpg_output=$(timeout 60 gpg --batch --generate-key "$gpg_config" 2>&1)
        gpg_exit_code=$?
        
        if [[ $gpg_exit_code -eq 0 ]]; then
            success "Llave GPG generada exitosamente"
            log "GPG output: $gpg_output"
            break
        elif [[ $gpg_output == *"waiting for lock"* ]] || [[ $gpg_output == *"Connection timed out"* ]]; then
            warning "Bloqueo detectado, limpiando y reintentando..."
            cleanup_gpg_processes
            sleep 5
            retry_count=$((retry_count + 1))
            continue
        else
            error "No se pudo generar la llave GPG (código de salida: $gpg_exit_code)"
            error "Salida de GPG: $gpg_output"
            log "GPG ERROR: $gpg_output"
            break
        fi
    done
    
    # Cleanup temp file
    rm -f "$gpg_config"
    
    # If all attempts failed, try alternative method
    if [[ $gpg_exit_code -ne 0 ]]; then
        warning "Intentando método alternativo de generación..."
        if generate_gpg_key_alternative; then
            return 0
        else
            return 1
        fi
    fi
    
    # Get GPG key ID
    info "Obteniendo ID de la llave GPG generada..."
    GPG_KEY_ID=$(gpg --list-secret-keys --keyid-format=long "$USER_EMAIL" 2>/dev/null | grep 'sec' | head -n1 | sed 's/.*\/\([A-Z0-9]*\).*/\1/')
    
    if [[ -z "$GPG_KEY_ID" ]]; then
        error "No se pudo obtener el ID de la llave GPG"
        warning "Intentando método alternativo para obtener el ID..."
        
        GPG_KEY_ID=$(gpg --list-secret-keys --keyid-format=long | grep -A1 "$USER_EMAIL" | grep 'sec' | sed 's/.*\/\([A-Z0-9]*\).*/\1/')
        
        if [[ -z "$GPG_KEY_ID" ]]; then
            error "No se pudo obtener el ID de la llave GPG con métodos alternativos"
            return 1
        fi
    fi
    
    success "ID de llave GPG obtenido: $GPG_KEY_ID"
    return 0
}

# @description Alternative method for GPG key generation
# @return 0 on success, 1 on failure
generate_gpg_key_alternative() {
    info "Intentando generación alternativa de llave GPG..."
    
    local temp_script
    temp_script=$(mktemp)
    cat > "$temp_script" << EOF
#!/bin/bash
echo "1"  # RSA and RSA
echo "4096"  # Key size
echo "2y"  # Expiration
echo "y"  # Confirm expiration
echo "$USER_NAME"  # Real name
echo "$USER_EMAIL"  # Email
echo ""  # Comment (empty)
echo "O"  # Okay
echo ""  # Passphrase (empty)
echo ""  # Confirm passphrase (empty)
EOF
    
    chmod +x "$temp_script"
    
    if gpg --batch --full-generate-key < "$temp_script" &>/dev/null; then
        success "Llave GPG generada con método alternativo"
        rm -f "$temp_script"
        return 0
    else
        error "Método alternativo también falló"
        rm -f "$temp_script"
        return 1
    fi
}

#==============================================================================
# GPG ENVIRONMENT MANAGEMENT
#==============================================================================

# @description Setup GPG environment for key generation
# @return 0 always
# @example
#   setup_gpg_environment
setup_gpg_environment() {
    info "Configurando entorno GPG..."
    
    # Clean locked processes first
    cleanup_gpg_processes
    
    local gpg_home="$HOME/.gnupg"
    
    # Create GPG directory if not exists
    if [[ ! -d "$gpg_home" ]]; then
        mkdir -p "$gpg_home"
        chmod 700 "$gpg_home"
        success "Directorio GPG creado: $gpg_home"
    fi
    
    # Configure GPG for batch mode
    local gpg_config="$gpg_home/gpg.conf"
    if [[ ! -f "$gpg_config" ]]; then
        cat > "$gpg_config" << EOF
# Configuración GPG para GitHub
batch
no-tty
use-agent
pinentry-mode loopback
EOF
        chmod 600 "$gpg_config"
        success "Archivo de configuración GPG creado"
    fi
    
    # Configure gpg-agent
    local gpg_agent_config="$gpg_home/gpg-agent.conf"
    if [[ ! -f "$gpg_agent_config" ]]; then
        cat > "$gpg_agent_config" << EOF
# Configuración gpg-agent
default-cache-ttl 600
max-cache-ttl 7200
pinentry-program /usr/bin/pinentry-curses
allow-loopback-pinentry
EOF
        chmod 600 "$gpg_agent_config"
        success "Archivo de configuración gpg-agent creado"
    fi
    
    # Start clean gpg-agent
    info "Iniciando gpg-agent..."
    if command -v gpgconf &> /dev/null; then
        gpgconf --launch gpg-agent 2>/dev/null || true
        sleep 1
    fi
    
    # Verify no locked processes
    local retry_count=0
    while [[ $retry_count -lt 3 ]]; do
        if ! pgrep -f "gpg.*batch.*generate-key" > /dev/null; then
            break
        fi
        warning "Proceso GPG aún bloqueado, esperando..."
        sleep 2
        ((retry_count++))
    done
    
    success "Entorno GPG configurado correctamente"
    return 0
}

# @description Clean up locked GPG processes
# @return 0 always
# @example
#   cleanup_gpg_processes
cleanup_gpg_processes() {
    info "Limpiando procesos GPG bloqueados..."
    
    local gpg_processes=("gpg-agent" "keyboxd" "gpg")
    
    for process in "${gpg_processes[@]}"; do
        if pgrep "$process" > /dev/null; then
            info "Terminando proceso: $process"
            pkill -f "$process" 2>/dev/null || true
            sleep 1
        fi
    done
    
    # Use gpgconf to clean completely
    if command -v gpgconf &> /dev/null; then
        info "Limpiando configuración GPG con gpgconf..."
        gpgconf --kill all 2>/dev/null || true
        sleep 2
    fi
    
    # Clean lock files
    local gpg_home="$HOME/.gnupg"
    if [[ -d "$gpg_home" ]]; then
        find "$gpg_home" -name "*.lock" -delete 2>/dev/null || true
        find "$gpg_home" -name "lock" -delete 2>/dev/null || true
        info "Archivos de bloqueo eliminados"
    fi
    
    sleep 2
    
    success "Limpieza de procesos GPG completada"
    return 0
}
