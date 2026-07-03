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

# Backup and replace existing ~/.codex directory if it exists (not a symlink)
if [[ -d "$HOME/.codex" ]] && [[ ! -L "$HOME/.codex" ]]; then
    backup_dir="$HOME/.codex.backup.$(date +%Y%m%d%H%M%S)"
    _log_warn "Backing up existing ~/.codex to $backup_dir"
    mv "$HOME/.codex" "$backup_dir"
fi

# .codex -> .config/codex
_log_run "Linking .codex -> .config/codex"
ln -sfnv "$HOME/.config/codex" "$HOME/.codex"

# Point this repo's git at the tracked hooks directory so the pre-commit
# sanitizer for Codex's config.toml runs without per-machine setup.
DOTFILES_DIR="${HOME}/.dotfiles"
if [[ -d "${DOTFILES_DIR}/.git" ]]; then
    _log_run "Setting core.hooksPath -> config/git/hooks (repo-local)"
    git -C "${DOTFILES_DIR}" config core.hooksPath config/git/hooks

    # Register the machine-local private identity as a git-secrets prohibited
    # pattern so it can never be committed to this public repo. The value is
    # read from ~/.gitconfig.local (untracked) — nothing private is hardcoded
    # here. Skipped silently when git-secrets or the local config is absent.
    GITCONFIG_LOCAL="${HOME}/.gitconfig.local"
    if command -v git-secrets >/dev/null 2>&1 && [[ -f "${GITCONFIG_LOCAL}" ]]; then
        _log_run "Registering git-secrets patterns from ~/.gitconfig.local"
        existing="$(git -C "${DOTFILES_DIR}" config --get-all secrets.patterns 2>/dev/null || true)"
        for key in user.name user.email; do
            value="$(git config -f "${GITCONFIG_LOCAL}" "${key}" 2>/dev/null || true)"
            [[ -z "${value}" ]] && continue
            if ! print -r -- "${existing}" | grep -qxF -- "${value}"; then
                git -C "${DOTFILES_DIR}" secrets --add "${value}"
            fi
        done
    fi
fi

_log_ok "All links created."
