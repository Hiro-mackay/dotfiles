#!/usr/bin/env zsh
set -e

BOOTSTRAP_DIR="${0:a:h}"
source "$BOOTSTRAP_DIR/lib/log.sh"

if ! command -v codex &> /dev/null; then
    _log_error "codex CLI not found. Install via 'brew install --cask codex' or ensure setup-brew ran first."
    exit 1
fi

if ! codex_version="$(codex --version 2>/dev/null)"; then
    _log_warn "'codex' command found but not working properly. Skipping."
    exit 0
fi

_log_ok "${codex_version} is installed."
CODEX_CONFIG_DIR="${CODEX_HOME:-${XDG_CONFIG_HOME:-${HOME}/.config}/codex}"
if [[ ! -f "${CODEX_CONFIG_DIR}/auth.json" ]]; then
    _log_warn "No Codex auth.json found. Run 'codex login' to authenticate."
fi

if command -v codebase-memory-mcp &> /dev/null; then
    if codex mcp get codebase-memory-mcp &> /dev/null; then
        _log_ok "codebase-memory-mcp is already registered."
    else
        _log_run "Registering codebase-memory-mcp..."
        codex mcp add codebase-memory-mcp -- "$(command -v codebase-memory-mcp)"
        _log_ok "codebase-memory-mcp registered."
    fi
else
    _log_warn "codebase-memory-mcp not found on PATH."
fi
