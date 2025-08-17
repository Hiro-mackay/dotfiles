#!/usr/bin/env zsh

echo "--------------------------------"
echo "⏳ Setting up Homebrew..."
echo "--------------------------------"
# Homebrewがインストールされているか確認
if command -v brew >/dev/null; then
    echo "✅ Homebrew is already installed."
else
    echo "⏳ Installing Homebrew..."
    # Homebrewのインストールスクリプトを実行
    # sudoで実行
    curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | sh

    # インストール後に設定を読み込む
    # これがないと、同じスクリプト内で`brew`コマンドが認識されない場合がある
    if [ -f "/opt/homebrew/bin/brew" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    if command -v brew >/dev/null; then
        echo "✅ Homebrew installed successfully."
    else
        echo "❌ Failed to install Homebrew. Exiting."
        exit 1
    fi
fi



# Homebrewの更新
echo "⏳ Updating Homebrew..."
if brew update; then
    echo "✅ Homebrew updated successfully."
else
    echo "❌ Failed to update Homebrew. Exiting."
    exit 1
fi

# Brewfileの存在確認
BREWFILE_PATH="${DOTFILES_CONFIG_DIR}/brew/Brewfile"
if [ ! -f "${BREWFILE_PATH}" ]; then
    echo "❌ Brewfile not found at ${BREWFILE_PATH}. Exiting."
    exit 1
fi

# Homebrew Bundleの実行
echo "⏳ Installing Homebrew bundle from ${BREWFILE_PATH}..."
if brew bundle --file="${BREWFILE_PATH}"; then
    echo "✅ Homebrew bundle installed successfully."
else
    echo "❌ Failed to install Homebrew bundle. Exiting."
    exit 1
fi

# Homebrewキャッシュのクリーンアップ
echo "⏳ Cleaning up Homebrew cache..."
if brew cleanup -s; then
    echo "✅ Homebrew cache cleaned up successfully."
else
    echo "❌ Failed to clean up Homebrew cache."
fi

echo "--------------------------------"
echo "✅ All brew setup is complete!"
echo "--------------------------------"