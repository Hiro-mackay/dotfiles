#!/usr/bin/env zsh
set -e

BOOTSTRAP_DIR="${0:a:h}"
source "$BOOTSTRAP_DIR/lib/log.sh"

_log_run "Creating XDG directories..."
if mkdir -p \
    "$XDG_CONFIG_HOME" \
    "$XDG_DATA_HOME" \
    "$XDG_STATE_HOME" \
    "$XDG_STATE_HOME/zsh" \
    "$XDG_CACHE_HOME"; then
    _log_ok "XDG directories created."
else
    _log_error "Failed to create XDG directories."
    exit 1
fi

# SSH
SSH_DIR="$HOME/.ssh"
if [[ ! -d "$SSH_DIR" ]]; then
    _log_run "Creating SSH directory..."
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
    _log_ok "SSH directory created."
else
    _log_ok "SSH directory already exists."
fi

# Cargo / Rust
CARGO_HOME=${CARGO_HOME:-$HOME/.cargo}
RUSTUP_HOME=${RUSTUP_HOME:-$HOME/.rustup}

_log_run "Creating Cargo and Rust directories..."
if mkdir -p "$CARGO_HOME" "$RUSTUP_HOME"; then
    chmod 700 "$CARGO_HOME" "$RUSTUP_HOME"
    _log_ok "Cargo and Rust directories created."
else
    _log_error "Failed to create Cargo and Rust directories."
    exit 1
fi
