#!/usr/bin/env bash
# shellcheck shell=bash
#
# colors.sh - Color definitions and styling for terminal output
#
# This helper provides color and style variables for consistent terminal output
# across all dotmarchy scripts. Colors use tput for terminal capability detection
# and fallback gracefully to empty strings in non-tty environments.
#
# @params
# Globals (exported):
#   ${CRE}: Red color
#   ${CYE}: Yellow color
#   ${CGR}: Green color
#   ${CBL}: Blue color
#   ${BLD}: Bold text
#   ${CNC}: Reset/clear all colors and styles
#
# Usage:
#   source "${mydir}/helper/colors.sh"
#   echo "${CGR}Success!${CNC}"
#   echo "${CRE}${BLD}Error!${CNC}"

set -Eeuo pipefail

# Color definitions (use tput for terminal capability detection)
# Fallback to empty string if tput fails (non-tty environments)
export CRE=$(tput setaf 1 2>/dev/null || echo '') # Red
export CYE=$(tput setaf 3 2>/dev/null || echo '') # Yellow
export CGR=$(tput setaf 2 2>/dev/null || echo '') # Green
export CBL=$(tput setaf 4 2>/dev/null || echo '') # Blue
export BLD=$(tput bold 2>/dev/null || echo '')    # Bold
export CNC=$(tput sgr0 2>/dev/null || echo '')    # Clear/reset

