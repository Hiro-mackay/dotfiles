#!/usr/bin/env zsh
set -e

echo "--------------------------------"
echo "⏳ Setting up link..."
echo "--------------------------------"

# Backup and replace existing ~/.config directory if it exists (not a symlink)
if [[ -d "$XDG_CONFIG_HOME" ]] && [[ ! -L "$XDG_CONFIG_HOME" ]]; then
    local backup_dir="$HOME/.config.backup.$(date +%Y%m%d%H%M%S)"
    echo "⚠️  Backing up existing ~/.config to $backup_dir ..."
    mv "$XDG_CONFIG_HOME" "$backup_dir"
fi

# Remove existing ~/.zshenv if it exists
if [[ -f "$HOME/.zshenv" ]] && [[ -L "$HOME/.zshenv" ]]; then
    echo "Removing existing ~/.zshenv symlink..."
    rm "$HOME/.zshenv"
fi

# .config -> .dotfiles/config
echo "⏳ Linking .config -> .dotfiles/config..."
ln -sfv "$HOME/.dotfiles/config" "$HOME/.config"

# .zshenv -> .dotfiles/config/zsh/.zshenv
echo "⏳ Linking .zshenv -> .dotfiles/config/zsh/.zshenv..."
ln -sfv "$HOME/.dotfiles/config/zsh/.zshenv" "$HOME/.zshenv"

# Backup and replace existing ~/.claude directory if it exists (not a symlink)
if [[ -d "$HOME/.claude" ]] && [[ ! -L "$HOME/.claude" ]]; then
    local backup_dir="$HOME/.claude.backup.$(date +%Y%m%d%H%M%S)"
    echo "⚠️  Backing up existing ~/.claude to $backup_dir ..."
    mv "$HOME/.claude" "$backup_dir"
fi

# .claude -> .config/claude
echo "⏳ Linking .claude -> .config/claude..."
ln -sfv "$HOME/.config/claude" "$HOME/.claude"

echo "--------------------------------"
echo "✅ All link setup is complete!"
echo "--------------------------------"
