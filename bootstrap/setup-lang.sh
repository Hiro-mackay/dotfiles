#!/usr/bin/env zsh
set -e

BOOTSTRAP_DIR="${0:a:h}"
source "$BOOTSTRAP_DIR/lib/log.sh"

# Ensure brew is on PATH (works for both Apple Silicon and Intel)
if command -v brew >/dev/null; then
    eval "$(brew shellenv)"
    hash -r
fi

if command -v mise >/dev/null 2>&1; then
    _log_ok "mise is already installed."
    _log_run "Installing tools from config.toml (this may take a while)..."
    mise install
    _log_ok "Tools installed."
else
    _log_warn "mise is not installed. Skipping language setup."
    _log_skip "Install mise via Homebrew and re-run this script."
    exit 0
fi
