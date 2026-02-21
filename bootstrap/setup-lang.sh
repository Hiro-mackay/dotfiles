#!/usr/bin/env zsh
set -e

# All runtimes and tools are managed using mise (https://github.com/jdx/mise).
# mise reads ${XDG_CONFIG_HOME}/mise/config.toml and configures the runtime environment.

echo "--------------------------------"
echo "⏳ Setting up language..."
echo "--------------------------------"

# brew bundle 直後でも mise を検出できるよう PATH を更新
eval "$(/opt/homebrew/bin/brew shellenv)"
hash -r

echo "⏳ Setting up mise..."
if command -v mise >/dev/null 2>&1; then
    echo "✅ mise is already installed."

    # config.toml に定義されたツールを一括インストール
    echo "⏳ Installing tools from config.toml (this may take a while)..."
    mise install
else
    echo "⚠️  mise is not installed. Skipping language setup via mise."
    echo "   Install mise via Homebrew and re-run this script."
    exit 0
fi

echo "--------------------------------"
echo "✅ All language setup is complete!"
echo "--------------------------------"
