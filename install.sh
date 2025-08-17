#!/usr/bin/env zsh

INSTALL_DIR=$HOME/.dotfiles
BOOTSTRAP_DIR=$INSTALL_DIR/bootstrap

if [ ! -d $INSTALL_DIR ]; then
    REPO_URL="https://github.com/Hiro-mackay/dotfiles/archive/main.tar.gz"
    echo "⏳ Creating dotfiles directory..."
    mkdir -p $INSTALL_DIR
    
    echo "⏳ Downloading and extracting dotfiles..."
    if curl -L $REPO_URL | tar xz --strip 1 -C $INSTALL_DIR; then
        echo "✅ Dotfiles downloaded and extracted successfully."
        
        if [ -d $BOOTSTRAP_DIR ]; then
            echo "⏳ Setting permissions..."
            chmod -R 755 $BOOTSTRAP_DIR
            
            echo "⏳ Running setup script..."
            ${BOOTSTRAP_DIR}/setup.sh
        else
            echo "❌ Bootstrap directory not found at $BOOTSTRAP_DIR"
            exit 1
        fi
    else
        echo "❌ Failed to download or extract dotfiles"
        exit 1
    fi
else
    echo "dotfiles already exists"
    exit 1
fi
