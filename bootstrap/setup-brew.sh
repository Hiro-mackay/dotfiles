#!/usr/bin/env zsh
set -e

BOOTSTRAP_DIR="${0:a:h}"
source "$BOOTSTRAP_DIR/lib/log.sh"

if command -v brew >/dev/null; then
    _log_ok "Homebrew is already installed."
else
    _log_run "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    if command -v brew >/dev/null; then
        _log_ok "Homebrew installed."
    else
        _log_error "Failed to install Homebrew."
        exit 1
    fi
fi

_log_run "Updating Homebrew..."
if brew update; then
    _log_ok "Homebrew updated."
else
    _log_error "Failed to update Homebrew."
    exit 1
fi

BREWFILE_PATH="${DOTFILES_CONFIG_DIR}/brew/Brewfile"
if [[ ! -f "${BREWFILE_PATH}" ]]; then
    _log_error "Brewfile not found at ${BREWFILE_PATH}."
    exit 1
fi

_log_run "Installing Homebrew bundle..."
if brew bundle --file="${BREWFILE_PATH}"; then
    _log_ok "Homebrew bundle installed."
else
    _log_error "Failed to install Homebrew bundle."
    exit 1
fi

_log_run "Cleaning up Homebrew cache..."
if brew cleanup -s; then
    _log_ok "Homebrew cache cleaned."
else
    _log_warn "Failed to clean Homebrew cache."
fi
