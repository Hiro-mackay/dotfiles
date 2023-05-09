# ----------------------
# VS code
# ----------------------
VSCODE_SETTING_DIR=~/Library/Application\ Support/Code/User
# link setting.json
rm "$VSCODE_SETTING_DIR/settings.json"
ln -s "$XDG_CONFIG_HOME/vscode/settings.json" "${VSCODE_SETTING_DIR}/settings.json"

# install extensions
cat "$XDG_CONFIG_HOME/vscode/extensions" | while read line
do
    code --install-extension $line
done
