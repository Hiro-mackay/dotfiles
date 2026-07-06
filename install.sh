#!/usr/bin/env zsh

INSTALL_DIR="$HOME/.dotfiles"
BOOTSTRAP_DIR="$INSTALL_DIR/bootstrap"

if [ ! -d "$INSTALL_DIR" ]; then
    REPO_URL="https://github.com/Hiro-mackay/dotfiles/archive/main.tar.gz"
    echo "⏳ Creating dotfiles directory..."
    mkdir -p "$INSTALL_DIR"

    echo "⏳ Downloading and extracting dotfiles..."
    if curl -L "$REPO_URL" | tar xz --strip 1 -C "$INSTALL_DIR"; then
        echo "✅ Dotfiles downloaded and extracted successfully."

        if [ -d "$BOOTSTRAP_DIR" ]; then
            echo "⏳ Setting permissions..."
            chmod -R 755 "$BOOTSTRAP_DIR"

            echo "⏳ Running setup script..."
            "${BOOTSTRAP_DIR}/setup.sh"

            echo ""
            echo "================================="
            echo "  Next steps"
            echo "================================="
            echo "  1. Open a new terminal to apply shell settings"
            echo "  2. To enable git-based updates:"
            echo "     cd ~/.dotfiles"
            echo "     git init"
            echo "     git remote add origin https://github.com/Hiro-mackay/dotfiles.git"
            echo "     git fetch origin"
            echo "     git reset --mixed origin/main"
            echo ""
        else
            echo "❌ Bootstrap directory not found at $BOOTSTRAP_DIR"
            exit 1
        fi
    else
        echo "❌ Failed to download or extract dotfiles"
        exit 1
    fi
else
    echo "dotfiles already exists. Re-running setup..."
    "${BOOTSTRAP_DIR}/setup.sh"
fi
