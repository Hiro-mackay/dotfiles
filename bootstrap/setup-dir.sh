#!/usr/bin/env zsh

echo "--------------------------------"
echo "⏳ Creating XDG directories..."
echo "--------------------------------"
mkdir -p \
    "$XDG_CONFIG_HOME" \
    "$XDG_DATA_HOME" \
    "$XDG_STATE_HOME" \
    "$XDG_CACHE_HOME"

if [ $? -eq 0 ]; then
    echo "✅ XDG directories created successfully."
else
    echo "❌ Failed to create XDG directories. Exiting."
    exit 1
fi

# ----------------------
# SSHディレクトリの作成
# ----------------------
echo "--------------------------------"
echo "⏳ Setting up SSH directory..."
echo "--------------------------------"
SSH_DIR="$HOME/.ssh"
if [ ! -d "$SSH_DIR" ]; then
    mkdir -p "$SSH_DIR"
    chmod 700 "$SSH_DIR"
    echo "✅ SSH directory created and permissions set."
else
    echo "✅ SSH directory already exists."
fi

# ----------------------
# Cargo/Rustディレクトリの作成
# ----------------------
echo "--------------------------------"
echo "⏳ Setting up Cargo and Rust directories..."
echo "--------------------------------"
# 環境変数が設定されていない場合、デフォルト値を設定
CARGO_HOME=${CARGO_HOME:-$HOME/.cargo}
RUSTUP_HOME=${RUSTUP_HOME:-$HOME/.rustup}

mkdir -p "$CARGO_HOME" "$RUSTUP_HOME"

if [ $? -eq 0 ]; then
    echo "✅ Cargo and Rust directories created successfully."
else
    echo "❌ Failed to create Cargo and Rust directories. Exiting."
    exit 1
fi

echo "--------------------------------"
echo "✅ All directory setup is complete!"
echo "--------------------------------"