#!/usr/bin/env bash
#==============================================================================
#                              GIT-CONFIG
#==============================================================================
# @file git-config.sh
# @brief Git configuration generation and management
# @description
#   Provides functions for generating .gitconfig file, commit templates,
#   and configuring Git settings.
#
# Globals:
#   USER_NAME     Git user name
#   USER_EMAIL    Git user email
#   GPG_KEY_ID    GPG key ID for signing
#   SCRIPT_DIR    Directory containing templates
#
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#==============================================================================

# Prevent double sourcing
[[ -n "${_GIT_CONFIG_SOURCED:-}" ]] && return 0
declare -r _GIT_CONFIG_SOURCED=1

#==============================================================================
# USER INFORMATION COLLECTION
#==============================================================================

# @description Collect user information for Git configuration
# @return 0 on success, 1 on failure
# @example
#   if ! collect_user_info; then
#       error "Failed to collect user info"
#   fi
collect_user_info() {
    show_separator
    echo -e "$(c bold)👤 INFORMACIÓN DEL USUARIO$(cr)"
    show_separator
    
    # Try to get existing Git config
    local existing_name
    local existing_email
    existing_name=$(git config --global user.name 2>/dev/null || echo "")
    existing_email=$(git config --global user.email 2>/dev/null || echo "")
    
    # Get user name
    if [[ -n "$existing_name" ]]; then
        info "Nombre actual en Git: $(c bold)$(c primary)$existing_name$(cr)"
        if ask_yes_no "¿Deseas usar este nombre?"; then
            USER_NAME="$existing_name"
        else
            read_input "Ingresa tu nombre completo" "" USER_NAME
        fi
    else
        read_input "Ingresa tu nombre completo" "" USER_NAME
    fi
    
    if [[ -z "$USER_NAME" ]]; then
        error "El nombre es requerido"
        return 1
    fi
    
    # Get user email
    if [[ -n "$existing_email" ]]; then
        info "Email actual en Git: $(c bold)$(c primary)$existing_email$(cr)"
        if ask_yes_no "¿Deseas usar este email?"; then
            USER_EMAIL="$existing_email"
        else
            while true; do
                read_input "Ingresa tu email" "" USER_EMAIL
                if validate_email "$USER_EMAIL"; then
                    break
                else
                    error "Email inválido. Por favor ingresa un email válido."
                fi
            done
        fi
    else
        while true; do
            read_input "Ingresa tu email" "" USER_EMAIL
            if validate_email "$USER_EMAIL"; then
                break
            else
                error "Email inválido. Por favor ingresa un email válido."
            fi
        done
    fi
    
    # Get default branch preference
    if [[ "$INTERACTIVE_MODE" == "true" ]]; then
        echo ""
        info "Selecciona la rama por defecto para nuevos repositorios:"
        echo "  1. $(c bold)$(c primary)master$(cr) - $(c bold)Rama tradicional$(cr)"
        echo "  2. $(c bold)$(c primary)main$(cr) - $(c bold)Rama moderna (recomendada)$(cr)"
        echo ""
        
        local branch_choice
        while true; do
            printf "  $(c accent)Selecciona [1/2]$(cr) (default: 2): "
            read -r branch_choice
            
            # Use default if empty
            if [[ -z "$branch_choice" ]]; then
                branch_choice="2"
            fi
            
            case "$branch_choice" in
                1)
                    GIT_DEFAULT_BRANCH="master"
                    break
                    ;;
                2)
                    GIT_DEFAULT_BRANCH="main"
                    break
                    ;;
                *)
                    error "Opción inválida. Por favor selecciona 1 o 2."
                    ;;
            esac
        done
    else
        # Non-interactive mode: use environment variable or default to main
        GIT_DEFAULT_BRANCH="${GIT_DEFAULT_BRANCH:-main}"
        log "Using default branch: $GIT_DEFAULT_BRANCH (non-interactive mode)"
    fi
    
    echo ""
    success "Información recopilada:"
    echo "  $(c bold)Nombre:$(cr) $(c bold)$(c primary)$USER_NAME$(cr)"
    echo "  $(c bold)Email:$(cr)  $(c bold)$(c primary)$USER_EMAIL$(cr)"
    echo "  $(c bold)Rama default:$(cr) $(c bold)$(c primary)$GIT_DEFAULT_BRANCH$(cr)"
    echo ""
    echo ""
    
    log "User info collected: $USER_NAME <$USER_EMAIL>, default branch: $GIT_DEFAULT_BRANCH"
    return 0
}

#==============================================================================
# CHANGES SUMMARY
#==============================================================================

# @description Show a summary of changes before applying
# @return 0 if user confirms, 1 if cancelled
# @example
#   if ! show_changes_summary; then
#       exit 0
#   fi
show_changes_summary() {
    echo ""
    show_separator
    printf "%b\n" "$(c bold)$(c accent)📋 RESUMEN DE CAMBIOS A REALIZAR$(cr)"
    show_separator
    echo ""
    
    printf "%b\n" "$(c bold)$(c accent)🔧 Archivos que se crearán/modificarán:$(cr)"
    echo ""
    
    # SSH keys
    if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
        printf "  $(c success)[CREAR]$(cr)    ~/.ssh/id_ed25519\n"
        printf "  $(c success)[CREAR]$(cr)    ~/.ssh/id_ed25519.pub\n"
    else
        printf "  $(c error)[SOBRESCRIBIR]$(cr) ~/.ssh/id_ed25519\n"
        printf "  $(c error)[SOBRESCRIBIR]$(cr) ~/.ssh/id_ed25519.pub\n"
    fi
    
    # .gitconfig
    if [[ -f "$HOME/.gitconfig" ]]; then
        printf "  $(c warning)[MODIFICAR]$(cr) ~/.gitconfig $(c muted)(backup: ~/.gitconfig.backup-*)$(cr)\n"
    else
        printf "  $(c success)[CREAR]$(cr)    ~/.gitconfig\n"
    fi
    
    # GPG key
    if [[ "${GENERATE_GPG:-false}" == "true" ]]; then
        if [[ -n "$GPG_KEY_ID" ]]; then
            printf "  $(c info)[USAR EXISTENTE]$(cr) Llave GPG (ID: $GPG_KEY_ID)\n"
        else
            printf "  $(c success)[CREAR]$(cr)    Llave GPG (4096-bit RSA)\n"
        fi
    fi
    
    # Shell configs
    if [[ -f "$HOME/.bashrc" ]]; then
        printf "  $(c warning)[MODIFICAR]$(cr) ~/.bashrc $(c muted)(agregar configuración SSH agent)$(cr)\n"
    fi
    if [[ -f "$HOME/.zshrc" ]]; then
        printf "  $(c warning)[MODIFICAR]$(cr) ~/.zshrc $(c muted)(agregar configuración SSH agent)$(cr)\n"
    fi
    
    echo ""
    printf "%b\n" "$(c bold)$(c accent)📦 Configuración Git:$(cr)"
    echo ""
    
    # Determine credential helper (same logic as generate_gitconfig)
    local credential_helper="manager"
    local os_type
    os_type=$(uname -s)
    
    case $os_type in
        "Darwin")
            if ! command -v git-credential-manager &> /dev/null; then
                credential_helper="osxkeychain"
            fi
            ;;
        "Linux")
            if ! command -v git-credential-manager &> /dev/null; then
                credential_helper="store"
            else
                credential_helper="manager (secretservice)"
            fi
            ;;
    esac
    
    printf "  $(c bold)$(c primary)Nombre:$(cr)        $(c bold)$USER_NAME$(cr)\n"
    printf "  $(c bold)$(c primary)Email:$(cr)         $(c bold)$USER_EMAIL$(cr)\n"
    printf "  $(c bold)$(c primary)Rama default:$(cr)  $(c bold)${GIT_DEFAULT_BRANCH:-main}$(cr)\n"
    if [[ "${GENERATE_GPG:-false}" == "true" ]]; then
        if [[ -n "$GPG_KEY_ID" ]]; then
            printf "  $(c bold)$(c primary)GPG signing:$(cr)   $(c bold)$(c success)true$(cr) $(c muted)(usando llave existente: $(c bold)${GPG_KEY_ID}$(cr)$(c muted))$(cr)\n"
        else
            printf "  $(c bold)$(c primary)GPG signing:$(cr)   $(c bold)$(c success)true$(cr) $(c muted)(se generará nueva llave)$(cr)\n"
        fi
    else
        printf "  $(c bold)$(c primary)GPG signing:$(cr)   $(c bold)$(c warning)false$(cr)\n"
    fi
    printf "  $(c bold)$(c primary)Credential:$(cr)    $(c bold)$credential_helper$(cr)\n"
    
    echo ""
    printf "%b\n" "$(c bold)$(c accent)📝 Notas importantes:$(cr)"
    echo ""
    if [[ -f "$HOME/.gitconfig" ]]; then
        printf "  $(c muted)•$(cr) Se creará un backup de tu $(c bold)$(c primary).gitconfig$(cr) actual antes de modificarlo\n"
    fi
    if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
        printf "  $(c muted)•$(cr) Las llaves SSH existentes serán $(c bold)$(c warning)sobrescritas$(cr)\n"
    fi
    if [[ "${GENERATE_GPG:-false}" == "true" ]] && [[ -n "$GPG_KEY_ID" ]]; then
        printf "  $(c muted)•$(cr) Se usará tu llave GPG existente $(c bold)$(c primary)($GPG_KEY_ID)$(cr)\n"
    fi
    if [[ "${AUTO_UPLOAD_KEYS:-false}" == "true" ]]; then
        printf "  $(c muted)•$(cr) Las llaves se subirán automáticamente a GitHub $(c bold)$(c success)(--auto-upload activo)$(cr)\n"
    fi
    echo ""
    show_separator
    echo ""
    echo ""
    
    if ! ask_yes_no "¿Deseas continuar con estos cambios?" "y"; then
        info "Operación cancelada por el usuario"
        return 1
    fi
    
    echo ""
    return 0
}

#==============================================================================
# GIT CONFIGURATION
#==============================================================================

# @description Clean up duplicate credential helper entries in .gitconfig
# @param $1 gitconfig_path - Path to .gitconfig file
# @return 0 on success, 1 on failure
# @example
#   cleanup_credential_duplicates "$HOME/.gitconfig"
cleanup_credential_duplicates() {
    local gitconfig_path="$1"
    
    if [[ ! -f "$gitconfig_path" ]]; then
        return 1
    fi
    
    # Use awk to process the file and remove duplicate helper entries
    # Keep only the first non-empty helper entry in the [credential] section
    awk '
    BEGIN {
        in_credential = 0
        helper_found = 0
    }
    /^\[credential\]/ {
        in_credential = 1
        helper_found = 0
        print
        next
    }
    /^\[/ {
        in_credential = 0
        helper_found = 0
        print
        next
    }
    in_credential && /^[[:space:]]*helper[[:space:]]*=/ {
        if (helper_found == 0) {
            # Keep the first helper entry even if empty, we will clean it later
            helper_value = $0
            gsub(/^[[:space:]]*helper[[:space:]]*=[[:space:]]*/, "", helper_value)
            gsub(/[[:space:]]*$/, "", helper_value)
            if (helper_value != "") {
                print $0
                helper_found = 1
            }
            # If empty, skip it - do not print
        }
        # Skip all subsequent helper entries - these are duplicates
        next
    }
    {
        print
    }
    ' "$gitconfig_path" > "${gitconfig_path}.tmp" && \
    mv "${gitconfig_path}.tmp" "$gitconfig_path"
}

# @description Configure Git with generated settings
# @return 0 on success, 1 on failure
# @example
#   configure_git
configure_git() {
    show_separator
    echo -e "$(c bold)⚙️  CONFIGURACIÓN DE GIT$(cr)"
    show_separator
    
    # Generate .gitconfig file
    generate_gitconfig || {
        error "No se pudo generar el archivo .gitconfig"
        return 1
    }
    
    # Configure Git Credential Manager if available
    # Note: We already configured the helper in generate_gitconfig with the full path,
    # so git-credential-manager configure should not add duplicates. However, we run it
    # to ensure any additional configuration is set up correctly.
    if command -v git-credential-manager &> /dev/null; then
        info "Verificando configuración de Git Credential Manager..."
        
        # Run configure (it should detect existing config and not duplicate)
        if git-credential-manager configure &>/dev/null; then
            # Clean up any potential duplicates that might have been added
            cleanup_credential_duplicates "$HOME/.gitconfig"
            success "Git Credential Manager configurado correctamente"
        fi
    fi
    
    success "Configuración Git completada exitosamente"
    echo ""
    info "Puedes ver tu configuración con: $(c primary)git config --global --list$(cr)"
    echo ""
    
    return 0
}

# @description Generate the .gitconfig file
# @return 0 on success, 1 on failure
# @example
#   generate_gitconfig
generate_gitconfig() {
    info "Generando archivo .gitconfig profesional..."
    
    local gitconfig_path="$HOME/.gitconfig"
    local backup_suffix=".backup-$(date +%Y%m%d_%H%M%S)"
    
    # Backup existing .gitconfig
    if [[ -f "$gitconfig_path" ]]; then
        warning "Se encontró un archivo .gitconfig existente"
        if ask_yes_no "¿Deseas hacer backup del .gitconfig actual antes de reemplazarlo?"; then
            cp "$gitconfig_path" "${gitconfig_path}${backup_suffix}"
            success "Backup creado: ${gitconfig_path}${backup_suffix}"
        fi
    fi
    
    # Determine credential helper
    local credential_helper="manager"
    local credential_helper_path=""
    local os_type
    os_type=$(uname -s)
    
    case $os_type in
        "Darwin")
            if ! command -v git-credential-manager &> /dev/null; then
                credential_helper="osxkeychain"
            else
                # Use full path to avoid duplicates when git-credential-manager configure runs
                credential_helper_path=$(command -v git-credential-manager)
            fi
            ;;
        "Linux")
            if ! command -v git-credential-manager &> /dev/null; then
                credential_helper="store"
            else
                # Use full path to avoid duplicates when git-credential-manager configure runs
                credential_helper_path=$(command -v git-credential-manager)
            fi
            ;;
    esac
    
    # Generate .gitconfig
    cat > "$gitconfig_path" << EOF
# ============================================================================
# Configuración Git Profesional
# Generado automáticamente el $(date)
# Usuario: $USER_NAME <$USER_EMAIL>
# ============================================================================

[user]
	name = $USER_NAME
	email = $USER_EMAIL$(if [[ -n "$GPG_KEY_ID" ]]; then echo "
	signingkey = $GPG_KEY_ID"; fi)

[commit]$(if [[ -n "$GPG_KEY_ID" ]]; then echo "
	gpgsign = true"; fi)
	template = ~/.gitmessage

[credential]$(if [[ -n "$credential_helper_path" ]]; then echo "
	helper = $credential_helper_path$(if [[ "$os_type" == "Linux" ]]; then echo "
	credentialStore = secretservice"; fi)"; else echo "
	helper = $credential_helper"; fi)

[init]
	defaultBranch = ${GIT_DEFAULT_BRANCH:-main}

[core]
	editor = nano
	autocrlf = false
	filemode = true
	ignorecase = false
	precomposeUnicode = true
	quotepath = false

[push]
	default = simple
	followTags = true
	autoSetupRemote = true

[pull]
	rebase = false
	ff = only

[fetch]
	prune = true
	pruneTags = true

[merge]
	tool = vimdiff
	conflictstyle = diff3

[diff]
	tool = vimdiff
	algorithm = histogram
	colorMoved = default

[status]
	showUntrackedFiles = all

[branch]
	autoSetupMerge = always
	autoSetupRebase = never

[rerere]
	enabled = true

[help]
	autoCorrect = 1

[color]
	ui = auto
	branch = auto
	diff = auto
	status = auto
	showBranch = auto

[color "branch"]
	current = yellow reverse
	local = yellow
	remote = green

[color "diff"]
	meta = yellow bold
	frag = magenta bold
	old = red bold
	new = green bold

[color "status"]
	added = yellow
	changed = green
	untracked = cyan

[alias]
	# Aliases básicos
	st = status -s
	co = checkout
	br = branch
	ci = commit
	df = diff
	dc = diff --cached
	lg = log --oneline --decorate --graph --all
	ls = log --pretty=format:"%C(yellow)%h%Cred%d\\\\ %Creset%s%Cblue\\\\ [%cn]" --decorate
	ll = log --pretty=format:"%C(yellow)%h%Cred%d\\\\ %Creset%s%Cblue\\\\ [%cn]" --decorate --numstat

	# Aliases avanzados
	unstage = reset HEAD --
	last = log -1 HEAD
	visual = !gitk
	type = cat-file -t
	dump = cat-file -p

	# Aliases para trabajo con ramas
	branches = branch -a
	remotes = remote -v
	tags = tag -l

	# Aliases para estadísticas
	stats = shortlog -sn
	contributors = shortlog -s -n

	# Aliases para GitHub
	hub = !gh
	pr = !gh pr
	issue = !gh issue

[url "git@github.com:"]
	insteadOf = https://github.com/

[github]
	user = $(echo "$USER_EMAIL" | cut -d'@' -f1)

# Configuración específica para diferentes repositorios
# Descomenta y modifica según necesites:
# [includeIf "gitdir:~/work/"]
#     path = ~/.gitconfig-work
# [includeIf "gitdir:~/personal/"]
#     path = ~/.gitconfig-personal
EOF
    
    success "Archivo .gitconfig generado exitosamente"
    
    # Create commit template
    create_commit_template
    
    return 0
}

# @description Create the commit message template
# @return 0 always
# @example
#   create_commit_template
create_commit_template() {
    local template_path="$HOME/.gitmessage"
    
    info "Creando plantilla de mensaje de commit..."
    
    cat > "$template_path" << 'EOF'
# <tipo>(<ámbito>): <asunto>
#
# <cuerpo del mensaje>
#
# <pie del mensaje>
#
# Tipos permitidos:
#   feat:     Nueva característica
#   fix:      Corrección de bug
#   docs:     Cambios en documentación
#   style:    Formato, espacios, etc (sin cambios de código)
#   refactor: Refactorización (sin cambios funcionales)
#   perf:     Mejoras de rendimiento
#   test:     Agregar o modificar tests
#   chore:    Cambios en build, dependencias, etc
#   ci:       Cambios en configuración CI/CD
#   revert:   Revertir un commit anterior
#
# Ámbito (opcional): Componente o módulo afectado
#
# Asunto: Descripción breve (máx 50 caracteres)
#   - Usa imperativo: "agrega" no "agregando" ni "agregó"
#   - Sin punto al final
#   - Primera letra en minúscula
#
# Cuerpo (opcional): Explicación detallada del cambio
#   - Wrap a 72 caracteres
#   - Explica QUÉ y POR QUÉ, no CÓMO
#
# Pie (opcional): Issues relacionados, breaking changes
#   - Refs: #123
#   - Closes: #456
#   - BREAKING CHANGE: descripción
#
# Ejemplo:
# feat(auth): agrega autenticación con OAuth2
#
# Implementa flujo OAuth2 para login con Google y GitHub.
# Mejora seguridad y experiencia de usuario.
#
# Refs: #123
# Closes: #456
EOF
    
    chmod 644 "$template_path"
    success "Plantilla de commit creada: $(c primary)$template_path$(cr)"
    
    return 0
}
