#!/usr/bin/env zsh
# Shared logging helpers for bootstrap scripts.
# Usage: source "$BOOTSTRAP_DIR/lib/log.sh"

# Disable color when NO_COLOR is set or stdout is not a tty
if [[ -n "$NO_COLOR" ]] || [[ ! -t 1 ]]; then
  _C_RESET="" _C_BOLD="" _C_BLUE="" _C_CYAN="" _C_GREEN="" _C_YELLOW="" _C_RED=""
else
  _C_RESET=$'\033[0m'
  _C_BOLD=$'\033[1m'
  _C_BLUE=$'\033[1;34m'
  _C_CYAN=$'\033[0;36m'
  _C_GREEN=$'\033[0;32m'
  _C_YELLOW=$'\033[0;33m'
  _C_RED=$'\033[0;31m'
fi

_log_header() { printf "\n${_C_BLUE}[%s]${_C_RESET}\n" "$1"; }
_log_run()    { printf "  ${_C_CYAN}->${_C_RESET} %s\n" "$1"; }
_log_ok()     { printf "  ${_C_GREEN}ok${_C_RESET} %s\n" "$1"; }
_log_warn()   { printf "  ${_C_YELLOW}!!${_C_RESET} %s\n" "$1"; }
_log_error()  { printf "  ${_C_RED}**${_C_RESET} %s\n" "$1"; }
_log_skip()   { printf "  ${_C_YELLOW}--${_C_RESET} %s\n" "$1"; }
