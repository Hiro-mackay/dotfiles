#!/bin/sh

if type brew >/dev/null; then
    echo "Homebrew is already installed."
else
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo "Updating Homebrew..."
brew update

echo "Installing Homebrew bundle..."
brew bundle --file="${DOTFILES_CONFIG_DIR}/brew/Brewfile" --no-lock

echo "Cleaning up Homebrew cache..."
brew cleanup -s