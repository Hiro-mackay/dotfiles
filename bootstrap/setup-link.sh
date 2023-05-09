#!/usr/bin/env zsh

echo "Start link setup..."

ln -sfv "${DOTFILES_CONFIG_DIR}/" "$XDG_CONFIG_HOME"
ln -sfv "$XDG_CONFIG_HOME/zsh/.zshenv" "$HOME/.zshenv"

