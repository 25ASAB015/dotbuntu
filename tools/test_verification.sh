#!/usr/bin/env bash
#==============================================================================
# Script temporal para probar funciones del proyecto
#==============================================================================
# @description
#   Permite probar cualquier función del proyecto cargando todos los módulos
#   necesarios y ejecutando la función especificada.
#
# @usage
#   ./test_verification.sh [--auto] [--help] [function_name]
#
# @examples
#   ./test_verification.sh run_verification_suite
#   ./test_verification.sh --auto check_optional_dependencies
#   ./test_verification.sh --auto test_github_connection
#   ./test_verification.sh --help
#
# @note
#   Si no se especifica función, por defecto ejecuta run_verification_suite
#==============================================================================

set -euo pipefail

# Determinar directorio del script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

#==============================================================================
# CARGAR TODOS LOS MÓDULOS
#==============================================================================

# Source configuration defaults
source "${SCRIPT_DIR}/config/defaults.sh"

# Source core modules
source "${SCRIPT_DIR}/scripts/core/colors.sh"
source "${SCRIPT_DIR}/scripts/core/logger.sh"
source "${SCRIPT_DIR}/scripts/core/validation.sh"
source "${SCRIPT_DIR}/scripts/core/ui.sh"
source "${SCRIPT_DIR}/scripts/core/common.sh"

# Source feature modules
source "${SCRIPT_DIR}/scripts/dependencies.sh"
source "${SCRIPT_DIR}/scripts/ssh.sh"
source "${SCRIPT_DIR}/scripts/gpg.sh"
source "${SCRIPT_DIR}/scripts/git-config.sh"
source "${SCRIPT_DIR}/scripts/github.sh"
source "${SCRIPT_DIR}/scripts/finalize.sh"

#==============================================================================
# CONFIGURACIÓN
#==============================================================================

# Configurar variables necesarias si no están definidas
export USER_NAME="${USER_NAME:-Test User}"
export USER_EMAIL="${USER_EMAIL:-test@example.com}"
export GPG_KEY_ID="${GPG_KEY_ID:-}"
export LOG_FILE="${LOG_FILE:-/tmp/test_verification.log}"

# Crear directorio de log si no existe
mkdir -p "$(dirname "$LOG_FILE")"

#==============================================================================
# FUNCIONES AUXILIARES
#==============================================================================

# @description Muestra ayuda del script
show_help() {
    cat << EOF
$(c bold)$(c primary)Script de Prueba de Funciones$(cr)

$(c bold)USO:$(cr)
  ./test_verification.sh [--auto] [--help] [function_name]

$(c bold)OPCIONES:$(cr)
  $(c primary)--auto$(cr)              Ejecutar sin esperar confirmación
  $(c primary)--help, -h$(cr)           Mostrar esta ayuda
  $(c primary)function_name$(cr)        Nombre de la función a probar

$(c bold)EJEMPLOS:$(cr)
  $(c muted)# Probar verificación post-instalación (por defecto)$(cr)
  ./test_verification.sh

  $(c muted)# Probar verificación sin esperar$(cr)
  ./test_verification.sh --auto

  $(c muted)# Probar función específica$(cr)
  ./test_verification.sh check_optional_dependencies
  ./test_verification.sh --auto test_github_connection
  ./test_verification.sh --auto check_dependencies

$(c bold)FUNCIONES DISPONIBLES:$(cr)
  $(c success)Verificación:$(cr)
    - run_verification_suite
    - check_dependencies
    - check_optional_dependencies
    - test_github_connection

  $(c success)Configuración:$(cr)
    - collect_user_info
    - configure_git
    - generate_gitconfig

  $(c success)SSH:$(cr)
    - generate_ssh_key
    - start_ssh_agent

  $(c success)GPG:$(cr)
    - generate_gpg_key
    - setup_gpg_environment

  $(c success)GitHub:$(cr)
    - ensure_github_cli_ready
    - upload_ssh_key_to_github
    - upload_gpg_key_to_github
    - maybe_upload_keys

  $(c success)UI:$(cr)
    - logo
    - welcome
    - show_help
    - display_keys
    - show_final_instructions

$(c bold)NOTAS:$(cr)
  - Si no se especifica función, se ejecuta $(c primary)run_verification_suite$(cr) por defecto
  - Todas las funciones del proyecto están disponibles
  - Usa $(c primary)--auto$(cr) para ejecutar sin confirmación

EOF
}

# @description Verifica si una función existe
# @param $1 Nombre de la función
# @return 0 si existe, 1 si no existe
function_exists() {
    local func_name="$1"
    if declare -f "$func_name" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# @description Lista todas las funciones disponibles
list_functions() {
    echo "$(c bold)$(c info)Funciones disponibles:$(cr)"
    echo ""
    
    # Obtener todas las funciones definidas
    local functions
    functions=$(declare -F | awk '{print $3}' | grep -E '^[a-z_][a-z0-9_]*$' | sort)
    
    local count=0
    while IFS= read -r func; do
        printf "  $(c primary)%s$(cr)\n" "$func"
        count=$((count + 1))
    done <<< "$functions"
    
    echo ""
    echo "$(c muted)Total: $count funciones$(cr)"
}

#==============================================================================
# PROCESAMIENTO DE ARGUMENTOS
#==============================================================================

AUTO_MODE=false
FUNCTION_NAME=""
SHOW_HELP=false
LIST_FUNCTIONS=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --auto)
            AUTO_MODE=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        --list|-l)
            list_functions
            exit 0
            ;;
        -*)
            error "Opción desconocida: $1"
            echo ""
            show_help
            exit 1
            ;;
        *)
            if [[ -z "$FUNCTION_NAME" ]]; then
                FUNCTION_NAME="$1"
            else
                error "Solo se puede especificar una función a la vez"
                exit 1
            fi
            shift
            ;;
    esac
done

# Si no se especificó función, usar run_verification_suite por defecto
if [[ -z "$FUNCTION_NAME" ]]; then
    FUNCTION_NAME="run_verification_suite"
fi

#==============================================================================
# VALIDACIÓN
#==============================================================================

# Verificar que la función existe
if ! function_exists "$FUNCTION_NAME"; then
    error "La función '$FUNCTION_NAME' no existe"
    echo ""
    echo "$(c info)Usa $(c primary)--list$(cr) o $(c primary)--help$(cr) para ver funciones disponibles"
    exit 1
fi

#==============================================================================
# EJECUCIÓN
#==============================================================================

echo "=== PRUEBA DE FUNCIÓN ==="
echo ""
echo "$(c bold)Configuración:$(cr)"
echo "  Función: $(c primary)$FUNCTION_NAME$(cr)"
echo "  USER_NAME: ${USER_NAME}"
echo "  USER_EMAIL: ${USER_EMAIL}"
echo "  GPG_KEY_ID: ${GPG_KEY_ID:-no definido}"
echo "  LOG_FILE: ${LOG_FILE}"
echo ""

# Si no está en modo auto, esperar confirmación
if [[ "$AUTO_MODE" != "true" ]]; then
    echo "$(c muted)Presiona ENTER para ejecutar (o usa --auto para ejecutar sin esperar)...$(cr)"
    read -r
fi

echo ""
echo "$(c bold)Ejecutando función: $(c primary)$FUNCTION_NAME$(cr)..."
echo ""

# Ejecutar la función
# Nota: Algunas funciones retornan 1 en casos normales (ej: run_verification_suite)
# Usamos set +e temporalmente para que el script no se detenga y muestre todos los resultados
set +e
"$FUNCTION_NAME"
function_exit_code=$?
set -e

echo ""
echo "=== FIN DE PRUEBA ==="
echo ""
echo "$(c bold)Resultado:$(cr)"
if [[ $function_exit_code -eq 0 ]]; then
    success "Función ejecutada exitosamente (código: $function_exit_code)"
else
    warning "Función retornó código: $function_exit_code"
    echo "$(c muted)(Nota: Algunas funciones retornan códigos distintos de 0 en casos normales)$(cr)"
fi

# Salir con el código de salida de la función
exit $function_exit_code
