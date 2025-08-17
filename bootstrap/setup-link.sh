#!/usr/bin/env zsh

echo "--------------------------------"
echo "⏳ Setting up link..."
echo "--------------------------------"

# Remove existing ~/.config directory if it exists (not a symlink)
if [ -d "$XDG_CONFIG_HOME" ] && [ ! -L "$XDG_CONFIG_HOME" ]; then
    echo "Removing existing ~/.config directory..."
    rm -rf "$XDG_CONFIG_HOME"
fi

# Remove existing ~/.zshenv if it exists
if [ -f "$HOME/.zshenv" ]; then
    echo "Removing existing ~/.zshenv..."
    rm "$HOME/.zshenv"
fi

# .config -> .dotfiles/config
echo "⏳ Linking .config -> .dotfiles/config..."
ln -sfv "$DOTFILES_CONFIG_DIR" "$XDG_CONFIG_HOME"

# .zshenv -> .dotfiles/config/zsh/.zshenv
echo "⏳ Linking .zshenv -> .dotfiles/config/zsh/.zshenv..."
ln -sfv "$XDG_CONFIG_HOME/zsh/.zshenv" "$HOME/.zshenv" 

echo "--------------------------------"
echo "✅ All link setup is complete!"
echo "--------------------------------"