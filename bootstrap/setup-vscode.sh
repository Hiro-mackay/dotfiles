#!/usr/bin/env zsh
set -e

BOOTSTRAP_DIR="${0:a:h}"
source "$BOOTSTRAP_DIR/lib/log.sh"

VSCODE_SETTING_DIR="$HOME/Library/Application Support/Code/User"
DOTFILES_VSCODE_DIR="${XDG_CONFIG_HOME}/vscode"
DOTFILES_SETTING_FILE="${DOTFILES_VSCODE_DIR}/settings.json"

if [[ ! -f "${DOTFILES_SETTING_FILE}" ]]; then
    _log_skip "settings.json not found at ${DOTFILES_SETTING_FILE}."
    exit 0
fi

mkdir -p "${VSCODE_SETTING_DIR}"

if [[ -L "${VSCODE_SETTING_DIR}/settings.json" ]] || [[ -f "${VSCODE_SETTING_DIR}/settings.json" ]]; then
    rm -f "${VSCODE_SETTING_DIR}/settings.json"
fi

_log_run "Linking VS Code settings.json..."
if ln -s "${DOTFILES_SETTING_FILE}" "${VSCODE_SETTING_DIR}/settings.json"; then
    _log_ok "VS Code settings.json linked."
else
    _log_error "Failed to link settings.json."
    exit 1
fi
