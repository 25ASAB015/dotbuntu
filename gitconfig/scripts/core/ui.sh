#!/usr/bin/env bash
#==============================================================================
#                              UI
#==============================================================================
# @file ui.sh
# @brief User interface utilities
# @description
#   Provides UI functions including logo display, spinners, progress bars,
#   and user prompts.
#
# Globals:
#   INTERACTIVE_MODE    Whether running in interactive mode (from defaults.sh)
#   COLORS              Color definitions (from defaults.sh)
#   WORKFLOW_STEPS      Step descriptions (from defaults.sh)
#
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#==============================================================================

# Prevent double sourcing
[[ -n "${_UI_SOURCED:-}" ]] && return 0
declare -r _UI_SOURCED=1

#==============================================================================
# LOGO AND BRANDING
#==============================================================================

# @description Display the Crixus ASCII art logo
# @example
#   logo
logo() {
    echo ""
    printf "%b\n" "$(c primary)   ██████╗██████╗ ██╗██╗  ██╗██╗   ██╗███████╗$(cr)"
    printf "%b\n" "$(c primary)  ██╔════╝██╔══██╗██║╚██╗██╔╝██║   ██║██╔════╝$(cr)"
    printf "%b\n" "$(c primary)  ██║     ██████╔╝██║ ╚███╔╝ ██║   ██║███████╗$(cr)"
    printf "%b\n" "$(c primary)  ██║     ██╔══██╗██║ ██╔██╗ ██║   ██║╚════██║$(cr)"
    printf "%b\n" "$(c primary)  ╚██████╗██║  ██║██║██╔╝ ██╗╚██████╔╝███████║$(cr)"
    printf "%b\n" "$(c primary)   ╚═════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝$(cr)"
    echo ""
    printf "%b\n" "$(c accent)  🔧 Configuración Profesional de Git & GitHub$(cr)"
    printf "%b\n" "$(c muted)     Automatiza tu entorno de desarrollo$(cr)"
    echo ""
}

#==============================================================================
# PROGRESS INDICATORS
#==============================================================================

# @description Display a spinner animation while a process runs
# @param $1 pid - Process ID to wait for
# @param $2 message - Message to display with spinner
# @example
#   long_command &
#   show_spinner $! "Processing..."
show_spinner() {
    local pid=$1
    local message="${2:-Procesando...}"
    local spin_chars='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    
    # Only show spinner in interactive mode with a terminal
    if [[ ! -t 1 ]] || [[ "$INTERACTIVE_MODE" != "true" ]]; then
        wait "$pid"
        return $?
    fi
    
    printf "  "
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r  $(c primary)${spin_chars:$i:1}$(cr) %s" "$message"
        i=$(( (i + 1) % ${#spin_chars} ))
        sleep 0.1
    done
    printf "\r  $(c success)✓$(cr) %s\n" "$message"
    
    wait "$pid"
    return $?
}

# @description Display a progress bar
# @param $1 current - Current step number
# @param $2 total - Total number of steps
# @param $3 message - Optional message to display
# @example
#   show_progress_bar 3 10 "Installing dependencies"
show_progress_bar() {
    local current=$1
    local total=$2
    local message="${3:-}"
    local width=50
    
    # Calculate filled blocks directly from current/total ratio with proper rounding
    # Formula: (current * width + total/2) / total
    # This rounds to the nearest integer
    local filled=$(( (current * width + total / 2) / total ))
    
    # Ensure filled is within valid range
    if [[ $filled -gt $width ]]; then
        filled=$width
    fi
    if [[ $filled -lt 0 ]]; then
        filled=0
    fi
    
    # Calculate percentage based on filled blocks to ensure exact visual match
    # This ensures the percentage shown matches the visual bar exactly
    # Formula: (filled * 100 + width/2) / width
    local percentage=$(( (filled * 100 + width / 2) / width ))
    
    # Ensure percentage is within valid range
    if [[ $percentage -gt 100 ]]; then
        percentage=100
    fi
    if [[ $percentage -lt 0 ]]; then
        percentage=0
    fi
    
    local empty=$((width - filled))
    
    # Build progress bar
    local bar=""
    for ((i = 0; i < filled; i++)); do
        bar+="█"
    done
    for ((i = 0; i < empty; i++)); do
        bar+="░"
    done
    
    # Display progress bar with message on same line, then newline
    if [[ -n "$message" ]]; then
        printf "$(c primary)[%s]$(cr) $(c bold)%3d%%$(cr) $(c muted)%s$(cr)\n" "$bar" "$percentage" "$message"
    else
        printf "$(c primary)[%s]$(cr) $(c bold)%3d%%$(cr)\n" "$bar" "$percentage"
    fi
}

#==============================================================================
# USER PROMPTS
#==============================================================================

# @description Ask a yes/no question and return the response
# @param $1 prompt - Question to ask
# @param $2 default - Default answer (y/n), defaults to 'y'
# @param $3 exit_on_no - If "true", exit script when user says no
# @return 0 if yes, 1 if no
# @example
#   if ask_yes_no "Continue?" "y"; then
#       echo "User said yes"
#   fi
#   ask_yes_no "Continue?" "n" "true"  # exits if user says no
ask_yes_no() {
    local prompt="$1"
    local default="${2:-y}"
    local exit_on_no="${3:-false}"
    local response
    
    # In non-interactive mode, use default
    if [[ "$INTERACTIVE_MODE" != "true" ]]; then
        local answer="$default"
        log "AUTO-ANSWER: $prompt -> $answer"
        
        # Check if answer is yes
        if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
            return 0
        else
            # Answer is no - check if we should exit
            if [[ "$exit_on_no" == "true" ]]; then
                printf "\n%b\n" "$(c bold)$(c warning)Operación cancelada$(cr)"
                exit 0
            else
                return 1
            fi
        fi
    fi
    
    # Format prompt with default indicator
    local prompt_indicator
    if [[ "$default" == "y" || "$default" == "Y" ]]; then
        prompt_indicator="[Y/n]"
    else
        prompt_indicator="[y/N]"
    fi
    
    # Keep asking until we get a valid response
    while true; do
        printf " %b " "$(c bold)$(c success)$prompt$(cr) $prompt_indicator:"
        read -r response
        
        # Use default if empty response
        if [[ -z "$response" ]]; then
            response="$default"
        fi
        
        case "$response" in
            [yY]|[yY][eE][sS]|[sS]|[sS][iI])
                return 0
                ;;
            [nN]|[nN][oO])
                if [[ "$exit_on_no" == "true" ]]; then
                    printf "\n%b\n" "$(c bold)$(c warning)Operación cancelada$(cr)"
                    exit 0
                else
                    return 1
                fi
                ;;
            *)
                printf "\n%b\n\n" "$(c bold)$(c error)Error:$(cr) Solo escribe '$(c bold)$(c warning)s$(cr)', '$(c bold)$(c warning)n$(cr)', '$(c bold)$(c warning)y$(cr)' o '$(c bold)$(c warning)N$(cr)'"
                ;;
        esac
    done
}

# @description Read user input with a prompt
# @param $1 prompt - Prompt to display
# @param $2 default - Default value (optional)
# @param $3 var_name - Variable name to store result in
# @example
#   read_input "Enter your name:" "John Doe" user_name
read_input() {
    local prompt="$1"
    local default="${2:-}"
    local var_name="$3"
    local input
    
    if [[ -n "$default" ]]; then
        printf "%b " "$(c accent)$prompt$(cr) $(c muted)[$default]$(cr):"
    else
        printf "%b " "$(c accent)$prompt$(cr):"
    fi
    
    read -r input
    
    # Use default if empty
    if [[ -z "$input" ]] && [[ -n "$default" ]]; then
        input="$default"
    fi
    
    # Set the variable
    eval "$var_name=\"\$input\""
}

#==============================================================================
# HELP AND WELCOME
#==============================================================================

# @description Display help information
# @example
#   show_help
show_help() {
    logo
    show_separator
    printf "%b\n" "$(c bold)$(c text)USO:$(cr)"
    printf "%b\n" "  $(c primary)./gitconfig.sh$(cr) $(c muted)[opciones]$(cr)"
    echo ""
    printf "%b\n" "$(c bold)$(c text)OPCIONES:$(cr)"
    printf "%b\n" "  $(c primary)-h, --help$(cr)          Mostrar esta ayuda"
    printf "%b\n" "  $(c primary)--non-interactive$(cr)   Modo no-interactivo (requiere USER_EMAIL y USER_NAME)"
    printf "%b\n" "  $(c primary)--auto-upload$(cr)       Subir llaves a GitHub usando gh CLI (requiere autenticación previa)"
    echo ""
    printf "%b\n" "$(c bold)$(c text)VARIABLES DE ENTORNO:$(cr)"
    printf "%b\n" "  $(c primary)INTERACTIVE_MODE$(cr)    $(c muted)true|false (default: true) - Controla si el script espera entrada del usuario$(cr)"
    printf "%b\n" "  $(c primary)USER_EMAIL$(cr)          $(c muted)(requerido en modo no-interactivo) - Email de GitHub para configurar Git$(cr)"
    printf "%b\n" "  $(c primary)USER_NAME$(cr)           $(c muted)(requerido en modo no-interactivo) - Nombre completo para configurar Git$(cr)"
    echo ""
    printf "%b\n" "$(c bold)$(c text)EJEMPLOS:$(cr)"
    printf "%b\n" "  $(c muted)# Interactivo:$(cr)"
    printf "%b\n" "  $(c primary)./gitconfig.sh$(cr)"
    echo ""
    printf "%b\n" "  $(c muted)# No-interactivo (requiere variables):$(cr)"
    printf "%b\n" "  $(c primary)USER_EMAIL=\"tu@email.com\" USER_NAME=\"Tu Nombre\" ./gitconfig.sh --non-interactive$(cr)"
    echo ""
    printf "%b\n" "  $(c muted)# No-interactivo + auto-upload:$(cr)"
    printf "%b\n" "  $(c primary)USER_EMAIL=\"tu@email.com\" USER_NAME=\"Tu Nombre\" ./gitconfig.sh --non-interactive --auto-upload$(cr)"
    echo ""
    printf "%b\n" "$(c bold)$(c warning)NOTAS IMPORTANTES:$(cr)"
    printf "%b\n" "  $(c warning)•$(cr) En modo no-interactivo, $(c primary)USER_EMAIL$(cr) y $(c primary)USER_NAME$(cr) son $(c bold)OBLIGATORIOS$(cr)"
    printf "%b\n" "  $(c warning)•$(cr) Las preguntas sí/no usan sus valores por defecto (no existe auto-confirmación de 'sí')"
    printf "%b\n" "  $(c warning)•$(cr) Las respuestas automáticas se registran en el archivo de log"
    printf "%b\n" "  $(c warning)•$(cr) El modo interactivo es el comportamiento por defecto"
    printf "%b\n" "  $(c warning)•$(cr) Archivo de log: $(c primary)~/.github-keys-setup/setup.log$(cr)"
    show_separator
    printf "%b\n" "$(c muted)AUTOR: 25asab015 <25asab015@ujmd.edu.sv>  │  LICENCIA: GPL-3.0$(cr)"
}

# @description Display welcome message
# @example
#   welcome
welcome() {
    # Only clear screen in interactive mode with a terminal
    if [[ "$INTERACTIVE_MODE" == "true" ]] && [[ -t 1 ]]; then
        clear
    fi
    
    # Display logo
    logo
    
    # Display separator
    show_separator
    
    # Welcome message
    printf "%b\n" "$(c bold)$(c text)Bienvenido al configurador de Git$(cr)"
    printf "%b\n" "$(c muted)Este script configurará:$(cr)"
    printf "%b\n" "  $(c bold)$(c success)•$(cr) $(c bold)Llaves SSH para autenticación con GitHub$(cr)"
    printf "%b\n" "  $(c bold)$(c success)•$(cr) $(c bold)Llaves GPG para firmar commits (opcional)$(cr)"
    printf "%b\n" "  $(c bold)$(c success)•$(cr) $(c bold)Configurar tu archivo $(c primary).gitconfig$(cr) con nombre, email y preferencias recomendadas$(cr)"
    printf "%b\n" "  $(c bold)$(c success)•$(cr) $(c bold)Git Credential Manager$(cr)"
    printf "%b\n" "  $(c bold)$(c success)•$(cr) $(c bold)GitHub CLI (gh)$(cr)"
    
    # Display separator
    show_separator
    echo ""
    
    # Safety notice
    printf "%b\n" "$(c warning)!$(cr) $(c muted)Este script NO realiza cambios peligrosos en tu sistema$(cr)"
    printf "%b\n" "$(c warning)!$(cr) $(c muted)Solo edita configuraciones relacionadas a Git y GitHub en tu usuario$(cr)"
    echo ""
    
    # Show non-interactive mode info if active
    if [[ "$INTERACTIVE_MODE" == "false" ]]; then
        printf "%b\n" "$(c bold)$(c accent)ℹ️  MODO NO-INTERACTIVO ACTIVO$(cr)"
        if [[ -n "${USER_EMAIL:-}" ]] && [[ -n "${USER_NAME:-}" ]]; then
            printf "%b\n" "$(c muted)   Usando: $(c primary)USER_EMAIL=${USER_EMAIL}$(c muted), $(c primary)USER_NAME=${USER_NAME}$(cr)"
        else
            printf "%b\n" "$(c warning)   ⚠️  ADVERTENCIA: USER_EMAIL y USER_NAME deben estar definidos$(cr)"
            printf "%b\n" "$(c muted)   Ejemplo: $(c primary)USER_EMAIL=\"tu@email.com\" USER_NAME=\"Tu Nombre\" ./gitconfig.sh --non-interactive$(cr)"
            echo ""
            error "No se puede continuar sin USER_EMAIL y USER_NAME en modo no-interactivo"
            exit 1
        fi
        echo ""
        # In non-interactive mode, just continue (ask_yes_no will use default)
    fi
    
    # Ask for confirmation (exits if user says no)
    if ! ask_yes_no "¿Deseas continuar?" "y" "true"; then
        # This should not happen if default is "y", but handle it anyway
        exit 0
    fi
    
    # Add blank line after confirmation
    echo ""
}
