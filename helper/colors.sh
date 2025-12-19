#!/usr/bin/env bash
# shellcheck shell=bash
#
# colors.sh - Color definitions and styling for terminal output
#
# This helper provides color and style variables for consistent terminal output
# across all dotbuntu scripts. Colors use tput for terminal capability detection
# and fallback gracefully to empty strings in non-tty environments.
#
# This is the CANONICAL color source for the project. The `scripts/core/colors.sh`
# provides `c()/cr()` function wrappers that delegate to these variables.
#
# @author: dotbuntu
# @version: 2.0.0

set -Eeuo pipefail

# Idempotent load guard
[[ -n "${_HELPER_COLORS_SOURCED:-}" ]] && return 0
declare -r _HELPER_COLORS_SOURCED=1

#######################################
# Color Variable Exports
#
# These variables contain ANSI escape codes for terminal coloring.
# Each uses tput for terminal capability detection and falls back
# to empty string if tput fails (non-tty environments like CI/CD).
#
# Globals (exported):
#   CRE - Red color (errors, failures)
#   CYE - Yellow color (warnings)
#   CGR - Green color (success)
#   CBL - Blue color (info, links)
#   BLD - Bold text style
#   CNC - Clear/reset all colors and styles
#
# Usage:
#   printf "%b\n" "${CGR}Success!${CNC}"
#   printf "%b\n" "${BLD}${CRE}Error!${CNC}"
#######################################

# Red - for errors, failures, critical issues
export CRE
CRE=$(tput setaf 1 2>/dev/null || echo '')

# Yellow - for warnings, cautions
export CYE
CYE=$(tput setaf 3 2>/dev/null || echo '')

# Green - for success, confirmations
export CGR
CGR=$(tput setaf 2 2>/dev/null || echo '')
  
# Blue - for info, links, highlights
export CBL
CBL=$(tput setaf 4 2>/dev/null || echo '')

# Bold - text emphasis
export BLD
BLD=$(tput bold 2>/dev/null || echo '')

# Clear/Reset - remove all formatting
export CNC
CNC=$(tput sgr0 2>/dev/null || echo '')
