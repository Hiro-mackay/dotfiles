#!/usr/bin/env zsh

INSTALL_DIR="$HOME/.dotfiles"
BOOTSTRAP_DIR="$INSTALL_DIR/bootstrap"

source "$BOOTSTRAP_DIR/env.sh"
source "$BOOTSTRAP_DIR/lib/log.sh"

# Request sudo upfront and keep the timestamp alive for the lifetime of this script (PID $$).
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Step execution tracker
typeset -a FAILED_STEPS=()

run_step() {
    local name="$1"
    local script="$2"
    local critical="${3:-false}"

    _log_header "$name"

    if "$script"; then
        _log_ok "$name done"
    else
        _log_error "$name failed"
        FAILED_STEPS+=("$name")
        if [[ "$critical" == "true" ]]; then
            _log_error "Critical step failed. Aborting."
            exit 1
        fi
    fi
}

# Critical steps (abort on failure — later steps depend on these)
run_step "setup-dir"  "$BOOTSTRAP_DIR/setup-dir.sh"  true
run_step "setup-link" "$BOOTSTRAP_DIR/setup-link.sh" true
run_step "setup-brew" "$BOOTSTRAP_DIR/setup-brew.sh" true

# Non-critical steps (continue on failure)
# Project the shared agents SSoT (config/agents) into Claude + Codex. Tool-neutral
# (only manipulates the dotfiles tree) so it runs even if an agent CLI is absent.
run_step "setup-agents" "$BOOTSTRAP_DIR/setup-agents.sh"
run_step "setup-lang"   "$BOOTSTRAP_DIR/setup-lang.sh"
run_step "setup-macos"  "$BOOTSTRAP_DIR/setup-macos.sh"
run_step "setup-vscode" "$BOOTSTRAP_DIR/setup-vscode.sh"
run_step "setup-claude" "$BOOTSTRAP_DIR/setup-claude.sh"
# setup-codex checks the Codex CLI, sets hook script perms, and verifies deps.
# (Skill/AGENTS.md projection is handled tool-neutrally by setup-agents above.)
run_step "setup-codex"  "$BOOTSTRAP_DIR/setup-codex.sh"

# Summary
_log_header "summary"
if [[ ${#FAILED_STEPS[@]} -eq 0 ]]; then
    _log_ok "All steps completed successfully."
else
    _log_warn "The following steps failed:"
    for step in "${FAILED_STEPS[@]}"; do
        _log_error "  $step"
    done
    exit 1
fi
