#!/usr/bin/env zsh
set -e

BOOTSTRAP_DIR="${0:a:h}"
source "$BOOTSTRAP_DIR/lib/log.sh"

export PATH="$HOME/.local/bin:$PATH"

if ! command -v claude &> /dev/null; then
    _log_run "Installing Claude Code via official installer..."
    if ! curl -fsSL https://claude.ai/install.sh | bash; then
        _log_error "Claude Code installer failed."
        exit 1
    fi
    hash -r
fi

if ! CLAUDE_VERSION=$(claude --version 2>/dev/null); then
    _log_warn "'claude' command found but not working properly. Skipping."
    exit 0
fi

_log_ok "Claude Code ${CLAUDE_VERSION} is installed."

CLAUDE_STATUSLINE="${XDG_CONFIG_HOME:-$HOME/.config}/claude/script/statusline.sh"

if [[ -f "$CLAUDE_STATUSLINE" ]]; then
    chmod +x "$CLAUDE_STATUSLINE"
    _log_ok "Status line script permissions set."
else
    _log_skip "Status line script not found at ${CLAUDE_STATUSLINE}."
fi

# User-scoped MCP registration lives outside dotfiles in ~/.claude.json.
if command -v codebase-memory-mcp &> /dev/null; then
    if claude mcp get codebase-memory-mcp &> /dev/null; then
        _log_ok "codebase-memory-mcp is already registered."
    else
        _log_run "Registering codebase-memory-mcp (user scope)..."
        claude mcp add -s user codebase-memory-mcp -- "$(command -v codebase-memory-mcp)"
        _log_ok "codebase-memory-mcp registered."
    fi
else
    _log_warn "codebase-memory-mcp not found on PATH. Install it, then re-run setup."
fi
