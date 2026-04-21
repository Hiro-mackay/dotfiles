#!/usr/bin/env zsh
set -e

BOOTSTRAP_DIR="${0:a:h}"
source "$BOOTSTRAP_DIR/lib/log.sh"

# ----------------------
# Claude Code installation check
# ----------------------
# Ensure ~/.local/bin is on PATH so a just-installed claude binary is visible
# within this setup session (shell rc files aren't re-sourced after install).
export PATH="$HOME/.local/bin:$PATH"

if ! command -v claude &> /dev/null; then
    _log_run "Installing Claude Code via official installer..."
    if ! curl -fsSL https://claude.ai/install.sh | bash; then
        _log_error "Claude Code installer failed."
        exit 1
    fi
    hash -r
fi

if ! claude --version &> /dev/null; then
    _log_warn "'claude' command found but not working properly. Skipping."
    exit 0
fi

_log_ok "Claude Code $(claude --version 2>/dev/null) is installed."

# ----------------------
# Set script permissions
# ----------------------
CLAUDE_SCRIPT_DIR="${XDG_CONFIG_HOME}/claude/script"

if [[ -d "${CLAUDE_SCRIPT_DIR}" ]]; then
    _log_run "Setting script permissions..."
    chmod +x "${CLAUDE_SCRIPT_DIR}"/*.sh 2>/dev/null || true
    chmod +x "${CLAUDE_SCRIPT_DIR}"/hooks/*.sh 2>/dev/null || true
    _log_ok "Script permissions set."
else
    _log_skip "Script directory not found at ${CLAUDE_SCRIPT_DIR}."
fi

# ----------------------
# Check terminal-notifier (notification hook dependency)
# ----------------------
if ! command -v terminal-notifier &> /dev/null; then
    _log_warn "terminal-notifier is not installed. Notification hooks will not work."
    _log_skip "Install via 'brew install terminal-notifier'."
fi
