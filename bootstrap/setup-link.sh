#!/usr/bin/env zsh
set -e

echo "--------------------------------"
echo "⏳ Setting up link..."
echo "--------------------------------"

# Remove existing ~/.config directory if it exists (not a symlink)
if [[ -d "$XDG_CONFIG_HOME" ]] && [[ ! -L "$XDG_CONFIG_HOME" ]]; then
    echo "Removing existing ~/.config directory..."
    rm -rf "$XDG_CONFIG_HOME"
fi

# Remove existing ~/.zshenv if it exists
if [[ -f "$HOME/.zshenv" ]] && [[ -L "$HOME/.zshenv" ]]; then
    echo "Removing existing ~/.zshenv..."
    rm "$HOME/.zshenv"
fi

# .config -> .dotfiles/config
echo "⏳ Linking .config -> .dotfiles/config..."
ln -sfv "$HOME/.dotfiles/config" "$HOME/.config"

# .zshenv -> .dotfiles/config/zsh/.zshenv
echo "⏳ Linking .zshenv -> .dotfiles/config/zsh/.zshenv..."
ln -sfv "$HOME/.dotfiles/config/zsh/.zshenv" "$HOME/.zshenv"

# Remove existing ~/.claude directory if it exists (not a symlink)
if [[ -d "$HOME/.claude" ]] && [[ ! -L "$HOME/.claude" ]]; then
    echo "Removing existing ~/.claude directory..."
    rm -rf "$HOME/.claude"
fi

# .claude -> .config/claude
echo "⏳ Linking .claude -> .config/claude..."
ln -sfv "$HOME/.config/claude" "$HOME/.claude"

echo "--------------------------------"
echo "✅ All link setup is complete!"
echo "--------------------------------"
