#!/usr/bin/env zsh

echo "Start link setup..."

VSCODE_SETTING_DIR=~/Library/Application\ Support/Code/User

ln -sfv "$DOTFILES_CONFIG_DIR" "$XDG_CONFIG_HOME"
ln -sfv "$XDG_CONFIG_HOME/zsh/.zshenv" "$HOME/.zshenv"


# ----------------------
# VS code
# ----------------------
# link setting.json
rm "$VSCODE_SETTING_DIR/settings.json"
ln -s "$XDG_CONFIG_HOME/vscode/settings.json" "${VSCODE_SETTING_DIR}/settings.json"

# install extensions
cat "$XDG_CONFIG_HOME/vscode/extensions" | while read line
do
 code --install-extension $line
done
