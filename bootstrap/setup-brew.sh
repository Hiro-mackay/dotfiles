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

_log_run "Installing Homebrew bundle (CLI)..."
if brew bundle --file="${BREWFILE_PATH}"; then
    _log_ok "Homebrew bundle installed."
else
    _log_error "Failed to install Homebrew bundle."
    exit 1
fi

# GUI casks are optional and non-critical: skip entirely on headless/CI machines
# with DOTFILES_SKIP_CASKS=1, and a single unavailable cask never aborts setup.
CASKFILE_PATH="${DOTFILES_CONFIG_DIR}/brew/Brewfile.cask"
if [[ "${DOTFILES_SKIP_CASKS}" == "1" ]]; then
    _log_warn "DOTFILES_SKIP_CASKS=1 set; skipping Homebrew casks."
elif [[ -f "${CASKFILE_PATH}" ]]; then
    _log_run "Installing Homebrew casks (non-fatal)..."
    if brew bundle --file="${CASKFILE_PATH}"; then
        _log_ok "Homebrew casks installed."
    else
        _log_warn "Some casks failed to install; continuing."
    fi
fi

_log_run "Cleaning up Homebrew cache..."
if brew cleanup -s; then
    _log_ok "Homebrew cache cleaned."
else
    _log_warn "Failed to clean Homebrew cache."
fi
