#!/usr/bin/env bash
#==============================================================================
#                              VALIDATION
#==============================================================================
# @file validation.sh
# @brief Input validation utilities
# @description
#   Provides validation functions for user input including email validation.
#
# Globals:
#   EMAIL_REGEX    Email validation pattern (from defaults.sh)
#
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#==============================================================================

# Prevent double sourcing
[[ -n "${_VALIDATION_SOURCED:-}" ]] && return 0
declare -r _VALIDATION_SOURCED=1

#==============================================================================
# VALIDATION FUNCTIONS
#==============================================================================

# @description Validate email address format
# @param $1 email - Email address to validate
# @return 0 if valid, 1 if invalid
# @example
#   if validate_email "user@example.com"; then
#       echo "Valid email"
#   fi
validate_email() {
    local email="$1"
    
    if [[ -z "$email" ]]; then
        return 1
    fi
    
    # Use the EMAIL_REGEX from defaults.sh
    if [[ "$email" =~ $EMAIL_REGEX ]]; then
        return 0
    else
        return 1
    fi
}

# @description Validate that a string is not empty
# @param $1 value - Value to check
# @return 0 if not empty, 1 if empty
# @example
#   if validate_not_empty "$name"; then
#       echo "Name provided"
#   fi
validate_not_empty() {
    local value="$1"
    [[ -n "${value// }" ]]
}

# @description Validate that a file exists
# @param $1 file_path - Path to file to check
# @return 0 if exists, 1 if not
# @example
#   if validate_file_exists "$HOME/.ssh/id_ed25519"; then
#       echo "SSH key exists"
#   fi
validate_file_exists() {
    local file_path="$1"
    [[ -f "$file_path" ]]
}

# @description Validate that a directory exists
# @param $1 dir_path - Path to directory to check
# @return 0 if exists, 1 if not
# @example
#   if validate_dir_exists "$HOME/.ssh"; then
#       echo "SSH directory exists"
#   fi
validate_dir_exists() {
    local dir_path="$1"
    [[ -d "$dir_path" ]]
}

# @description Validate that a command exists
# @param $1 cmd - Command to check
# @return 0 if exists, 1 if not
# @example
#   if validate_command_exists "git"; then
#       echo "Git is installed"
#   fi
validate_command_exists() {
    local cmd="$1"
    command -v "$cmd" &> /dev/null
}
