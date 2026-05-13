#!/usr/bin/env zsh
set -e

BOOTSTRAP_DIR="${0:a:h}"
source "$BOOTSTRAP_DIR/lib/log.sh"

# ----------------------
# Codex CLI installation check
# ----------------------
if ! command -v codex &> /dev/null; then
    _log_error "codex CLI not found. Install via 'brew install --cask codex' or ensure setup-brew ran first."
    exit 1
fi

if ! codex --version &> /dev/null; then
    _log_warn "'codex' command found but not working properly. Skipping."
    exit 0
fi

_log_ok "Codex CLI $(codex --version 2>/dev/null) is installed."

# ----------------------
# Set script permissions (hooks called from config.toml)
# ----------------------
CODEX_CONFIG_DIR="${XDG_CONFIG_HOME:-${HOME}/.config}/codex"
CODEX_SCRIPT_DIR="${CODEX_CONFIG_DIR}/script"

if [[ -d "${CODEX_SCRIPT_DIR}" ]]; then
    _log_run "Setting script permissions..."
    chmod +x "${CODEX_SCRIPT_DIR}"/*.sh 2>/dev/null || true
    _log_ok "Script permissions set."
else
    _log_skip "Script directory not found at ${CODEX_SCRIPT_DIR}."
fi

# ----------------------
# Dependency checks (hooks rely on jq; notify.sh on terminal-notifier)
# ----------------------
if ! command -v jq &> /dev/null; then
    _log_warn "jq is not installed. Codex hooks (pre-tool-policy, permission-request, post-edit-check) parse JSON via jq and will fail without it."
    _log_skip "Install via 'brew install jq'."
fi

if ! command -v terminal-notifier &> /dev/null; then
    _log_warn "terminal-notifier is not installed. Codex desktop notifications via notify.sh will not appear."
    _log_skip "Install via 'brew install terminal-notifier'."
fi

# ----------------------
# Link shared agent skills into Codex skills/
# ----------------------
BOOTSTRAP_BRIDGE="${CODEX_SCRIPT_DIR}/bootstrap.sh"

if [[ -x "${BOOTSTRAP_BRIDGE}" ]]; then
    _log_run "Linking shared agent skills into Codex skills/..."
    if "${BOOTSTRAP_BRIDGE}"; then
        _log_ok "Skill bridge populated."
    else
        _log_error "Skill bridge failed."
        exit 1
    fi
else
    _log_skip "Bridge script not found at ${BOOTSTRAP_BRIDGE}."
fi

# ----------------------
# Auth status (informational)
# ----------------------
if [[ ! -f "${CODEX_CONFIG_DIR}/auth.json" ]]; then
    _log_warn "No Codex auth.json found. Run 'codex login' to authenticate."
fi
