#!/usr/bin/env zsh
set -e

BOOTSTRAP_DIR="${0:a:h}"
source "$BOOTSTRAP_DIR/lib/log.sh"

# NOTE: VS Code symlinks are handled separately in setup-vscode.sh (non-critical step)
# because VS Code may not be installed yet at this point, and a failure there
# should not abort the entire setup.

# Backup and replace existing ~/.config directory if it exists (not a symlink)
if [[ -d "$XDG_CONFIG_HOME" ]] && [[ ! -L "$XDG_CONFIG_HOME" ]]; then
    backup_dir="$HOME/.config.backup.$(date +%Y%m%d%H%M%S)"
    _log_warn "Backing up existing ~/.config to $backup_dir"
    mv "$XDG_CONFIG_HOME" "$backup_dir"
fi

# Backup existing ~/.zshenv if it exists as a regular file (not a symlink).
# Existing symlinks are handled idempotently by `ln -sfnv` below.
if [[ -f "$HOME/.zshenv" ]] && [[ ! -L "$HOME/.zshenv" ]]; then
    backup_file="$HOME/.zshenv.backup.$(date +%Y%m%d%H%M%S)"
    _log_warn "Backing up existing ~/.zshenv to $backup_file"
    mv "$HOME/.zshenv" "$backup_file"
fi

# .config -> .dotfiles/config
_log_run "Linking .config -> .dotfiles/config"
ln -sfnv "$HOME/.dotfiles/config" "$HOME/.config"

# .zshenv -> .dotfiles/config/zsh/.zshenv
_log_run "Linking .zshenv -> .dotfiles/config/zsh/.zshenv"
ln -sfnv "$HOME/.dotfiles/config/zsh/.zshenv" "$HOME/.zshenv"

# Backup and replace existing ~/.claude directory if it exists (not a symlink)
if [[ -d "$HOME/.claude" ]] && [[ ! -L "$HOME/.claude" ]]; then
    backup_dir="$HOME/.claude.backup.$(date +%Y%m%d%H%M%S)"
    _log_warn "Backing up existing ~/.claude to $backup_dir"
    mv "$HOME/.claude" "$backup_dir"
fi

# .claude -> .config/claude
_log_run "Linking .claude -> .config/claude"
ln -sfnv "$HOME/.config/claude" "$HOME/.claude"

# .codex/AGENTS.md -> .dotfiles/config/codex/AGENTS.md
# Codex CLI auto-loads ~/.codex/AGENTS.md as global instructions, but .codex/
# itself is a runtime dir owned by Codex (auth.json, sessions/, etc), so we
# only symlink the single file rather than the whole directory.
_log_run "Linking .codex/AGENTS.md -> .dotfiles/config/codex/AGENTS.md"
mkdir -p "$HOME/.codex"
ln -sfnv "$HOME/.dotfiles/config/codex/AGENTS.md" "$HOME/.codex/AGENTS.md"

_log_ok "All links created."
