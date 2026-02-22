#!/usr/bin/env zsh
set -e

echo "--------------------------------"
echo "⏳ Setting up Claude Code..."
echo "--------------------------------"

# brew bundle 直後でも claude を検出できるよう PATH を更新
if [[ -f "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# ----------------------
# Claude Code のインストール確認
# ----------------------
if ! command -v claude &> /dev/null; then
    echo "⚠️  'claude' command not found. Install via 'brew install --cask claude-code'."
    echo "   Skipping Claude Code setup."
    exit 0
fi

# 動作確認
if ! claude --version &> /dev/null; then
    echo "⚠️  'claude' command found but not working properly. Skipping."
    exit 0
fi

echo "✅ Claude Code $(claude --version 2>/dev/null) is installed."

# ----------------------
# notify.sh の実行権限を付与
# ----------------------
CLAUDE_SCRIPT_DIR="${XDG_CONFIG_HOME}/claude/script"

if [[ -d "${CLAUDE_SCRIPT_DIR}" ]]; then
    echo "⏳ Setting script permissions..."
    chmod +x "${CLAUDE_SCRIPT_DIR}"/*.sh 2>/dev/null || true
    echo "✅ Script permissions set."
else
    echo "⚠️  Script directory not found at ${CLAUDE_SCRIPT_DIR}. Skipping."
fi

# ----------------------
# terminal-notifier の確認（通知フックの依存）
# ----------------------
if ! command -v terminal-notifier &> /dev/null; then
    echo "⚠️  terminal-notifier is not installed. Notification hooks will not work."
    echo "   Install via 'brew install terminal-notifier'."
fi

echo "--------------------------------"
echo "✅ Claude Code setup complete!"
echo "--------------------------------"
