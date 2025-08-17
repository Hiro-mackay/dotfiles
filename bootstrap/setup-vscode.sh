#!/usr/bin/env zsh

echo "---"
echo "⏳ Setting up Visual Studio Code..."

# VS Code の設定ディレクトリを定義。スペースを含むため、必ずクォートする
VSCODE_SETTING_DIR="$HOME/Library/Application Support/Code/User"

# ----------------------
# settings.json のリンク
# ----------------------
echo "⏳ Linking settings.json..."
DOTFILES_VSCODE_DIR="${XDG_CONFIG_HOME}/vscode"
DOTFILES_SETTING_FILE="${DOTFILES_VSCODE_DIR}/settings.json"

# settings.json が存在するか確認
if [ ! -f "${DOTFILES_SETTING_FILE}" ]; then
  echo "❌ settings.json not found at ${DOTFILES_SETTING_FILE}. Skipping link."
else
  # 既存のリンクまたはファイルを削除
  if [ -L "${VSCODE_SETTING_DIR}/settings.json" ] || [ -f "${VSCODE_SETTING_DIR}/settings.json" ]; then
    rm -f "${VSCODE_SETTING_DIR}/settings.json"
    echo "✅ Removed existing settings.json."
  fi

  # シンボリックリンクを作成
  if ln -s "${DOTFILES_SETTING_FILE}" "${VSCODE_SETTING_DIR}/settings.json"; then
    echo "✅ settings.json linked successfully."
  else
    echo "❌ Failed to link settings.json. Check permissions."
  fi
fi

# ----------------------
# 拡張機能のインストール
# ----------------------
echo "---"
echo "⏳ Installing VS Code extensions..."
DOTFILES_EXTENSIONS_FILE="${DOTFILES_VSCODE_DIR}/extensions"

# 拡張機能リストファイルが存在するか確認
if [ ! -f "${DOTFILES_EXTENSIONS_FILE}" ]; then
  echo "❌ extensions file not found at ${DOTFILES_EXTENSIONS_FILE}. Skipping extension installation."
else
  # VS Code が実行可能か確認
  if ! command -v code &> /dev/null; then
    echo "❌ 'code' command not found. Please add VS Code to your PATH."
    echo "   (Open VS Code, press Cmd+Shift+P, and select 'Shell Command: Install 'code' command in PATH')."
  else
    # 拡張機能を1行ずつインストール
    cat "${DOTFILES_EXTENSIONS_FILE}" | while read -r line; do
      # 空行またはコメント行をスキップ
      if [[ -z "$line" || "$line" =~ ^#.* ]]; then
        continue
      fi
      # インストールコマンドを実行
      if code --install-extension "$line"; then
        echo "✅ Installed: $line"
      else
        echo "❌ Failed to install: $line"
      fi
    done
  fi
fi

echo "---"
echo "🎉 VS Code setup complete!"