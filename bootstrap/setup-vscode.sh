#!/usr/bin/env zsh
set -e

echo "--------------------------------"
echo "⏳ Setting up Visual Studio Code..."
echo "--------------------------------"

# VS Code の設定ディレクトリを定義。スペースを含むため、必ずクォートする
VSCODE_SETTING_DIR="$HOME/Library/Application Support/Code/User"
DOTFILES_VSCODE_DIR="${XDG_CONFIG_HOME}/vscode"
DOTFILES_SETTING_FILE="${DOTFILES_VSCODE_DIR}/settings.json"

# settings.json のリンク
if [[ ! -f "${DOTFILES_SETTING_FILE}" ]]; then
  echo "⚠️  settings.json not found at ${DOTFILES_SETTING_FILE}. Skipping."
else
  # VS Code 未起動でもディレクトリを作成
  mkdir -p "${VSCODE_SETTING_DIR}"

  # 既存のリンクまたはファイルを削除
  if [[ -L "${VSCODE_SETTING_DIR}/settings.json" ]] || [[ -f "${VSCODE_SETTING_DIR}/settings.json" ]]; then
    rm -f "${VSCODE_SETTING_DIR}/settings.json"
  fi

  # シンボリックリンクを作成
  if ln -s "${DOTFILES_SETTING_FILE}" "${VSCODE_SETTING_DIR}/settings.json"; then
    echo "✅ settings.json linked successfully."
  else
    echo "❌ Failed to link settings.json."
  fi
fi

echo "--------------------------------"
echo "✅ VS Code setup complete!"
echo "--------------------------------"
