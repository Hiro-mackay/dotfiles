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

# Essential casks: always attempted, non-fatal. Not gated by DOTFILES_SKIP_CASKS
# so a required tool (e.g. Hammerspoon for 英数/かな) is still installed on
# restricted machines; failure only warns, leaving it to a manual install.
ESSENTIAL_CASKFILE="${DOTFILES_CONFIG_DIR}/brew/Brewfile.cask"
if [[ -f "${ESSENTIAL_CASKFILE}" ]]; then
    _log_run "Installing essential casks (non-fatal)..."
    if brew bundle --file="${ESSENTIAL_CASKFILE}"; then
        _log_ok "Essential casks installed."
    else
        _log_warn "Some essential casks failed; install them manually."
    fi
fi

# Optional GUI casks: skip entirely with DOTFILES_SKIP_CASKS=1 (headless/CI or
# restricted machines), and a single unavailable cask never aborts setup.
OPTIONAL_CASKFILE="${DOTFILES_CONFIG_DIR}/brew/Brewfile.cask.optional"
if [[ "${DOTFILES_SKIP_CASKS}" == "1" ]]; then
    _log_warn "DOTFILES_SKIP_CASKS=1 set; skipping optional casks."
elif [[ -f "${OPTIONAL_CASKFILE}" ]]; then
    _log_run "Installing optional casks (non-fatal)..."
    if brew bundle --file="${OPTIONAL_CASKFILE}"; then
        _log_ok "Optional casks installed."
    else
        _log_warn "Some optional casks failed to install; continuing."
    fi
fi

_log_run "Cleaning up Homebrew cache..."
if brew cleanup -s; then
    _log_ok "Homebrew cache cleaned."
else
    _log_warn "Failed to clean Homebrew cache."
fi
