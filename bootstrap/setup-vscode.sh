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

# Restore declared extensions. `code --install-extension` is idempotent: it
# skips anything already installed, so re-running is safe.
DOTFILES_EXTENSIONS_FILE="${DOTFILES_VSCODE_DIR}/extensions"
if ! command -v code >/dev/null 2>&1; then
    _log_skip "code CLI not found; skipping extension install."
elif [[ ! -f "${DOTFILES_EXTENSIONS_FILE}" ]]; then
    _log_skip "extensions list not found at ${DOTFILES_EXTENSIONS_FILE}."
else
    _log_run "Installing VS Code extensions..."
    while IFS= read -r ext; do
        [[ -z "${ext}" ]] && continue
        code --install-extension "${ext}" >/dev/null 2>&1
    done < "${DOTFILES_EXTENSIONS_FILE}"
    _log_ok "VS Code extensions installed."
fi
