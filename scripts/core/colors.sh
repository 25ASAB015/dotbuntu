#!/usr/bin/env bash
#==============================================================================
#                              COLORS
#==============================================================================
# @file colors.sh
# @brief Color output utilities for terminal display
# @description
#   Provides color helper functions for consistent terminal output.
#   Includes the c() function for color codes and cr() for reset.
#
# Globals:
#   COLORS    Associative array of color escape codes (from defaults.sh)
#
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#==============================================================================

# Prevent double sourcing
[[ -n "${_COLORS_SOURCED:-}" ]] && return 0
declare -r _COLORS_SOURCED=1

#==============================================================================
# COLOR HELPER FUNCTIONS
#==============================================================================

# @description Get color escape code by name
# @param $1 color_name - Name of the color (e.g., primary, success, error)
# @return Color escape code string
# @example
#   echo -e "$(c primary)Hello$(cr)"
c() {
    local color_name="${1:-text}"
    printf '%b' "${COLORS[$color_name]:-${COLORS[text]}}"
}

# @description Get reset escape code
# @return Reset escape code string
# @example
#   echo -e "$(c error)Error:$(cr) message"
cr() {
    printf '%b' "${COLORS[reset]}"
}

# @description Check if terminal supports Unicode
# @return 0 if Unicode supported, 1 otherwise
# @example
#   if check_unicode_support; then echo "✓"; else echo "[OK]"; fi
check_unicode_support() {
    local lang="${LANG:-}"
    local lc_all="${LC_ALL:-}"
    local term="${TERM:-}"
    
    # Check if locale supports UTF-8
    if [[ "$lang" == *"UTF-8"* ]] || [[ "$lang" == *"utf8"* ]] || \
       [[ "$lc_all" == *"UTF-8"* ]] || [[ "$lc_all" == *"utf8"* ]]; then
        # Additional check for terminal capability
        if [[ "$term" != "dumb" ]] && [[ -n "$term" ]]; then
            return 0
        fi
    fi
    
    return 1
}

# @description Get appropriate symbol based on Unicode support
# @param $1 unicode_symbol - Symbol to use if Unicode is supported
# @param $2 ascii_fallback - Fallback ASCII representation
# @return Appropriate symbol for terminal
# @example
#   echo "$(get_symbol '✓' '[OK]') Done"
get_symbol() {
    local unicode_symbol="$1"
    local ascii_fallback="$2"
    
    if check_unicode_support; then
        printf '%s' "$unicode_symbol"
    else
        printf '%s' "$ascii_fallback"
    fi
}
