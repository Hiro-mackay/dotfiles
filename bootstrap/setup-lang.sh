#!/usr/bin/env zsh


# All runtimes, tools and services necessary for development will be managed using mise (https://github.com/jdx/mise).
# mise reads ${XDG_CONFIG_HOME}/mise/config.toml and configures the runtime environment.
# Rust is an exception because the community has a mature package manager called Cargo, which does not use rtx and installs directly

echo "--------------------------------"
echo "⏳ Setting up language..."
echo "--------------------------------"

# ----------------------
# Rust と Cargo のセットアップ
# ----------------------
echo "⏳ Setting up Rust and Cargo..."
# rustup がすでにインストールされているかチェック
if command -v rustup >/dev/null 2>&1; then
    echo "✅ rustup is already installed. "
else
    echo "⏳ Installing Rust..."
    # rustup をインストール
    if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh then
        echo "✅ Rust installed successfully."
        rustup default stable
    else
        echo "❌ Failed to install Rust. Exiting."
        exit 1
    fi
fi

# ----------------------
# mise
# ----------------------

echo "⏳ Setting up mise..."
if command -v mise >/dev/null 2>&1; then
    echo "✅ mise is already installed. Updating mise..."
    # インストール後に現在のシェルにパスを設定
    eval "$(~/.local/bin/mise activate zsh)"
    # mise を更新
    if mise update; then
        echo "✅ mise updated successfully."
    else
        echo "❌ Failed to update mise. Continuing..."
    fi
else
    echo "❌ mise is not installed. Exiting."
    exit 1
fi

# Python & uv
echo "⏳ Setting up Python and uv..."
mise use -g uv@latest python@latest  

# node
echo "⏳ Setting up node..."
mise use -g node@latest bun@latest pnpm@latest deno@latest ni@latest

# go
echo "⏳ Setting up go..."
mise use -g go@latest



echo "--------------------------------"
echo "✅ All language setup is complete!"
echo "--------------------------------"