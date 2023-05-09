#!/usr/bin/env zsh

INSTALL_DIR=$HOME/.dotfiles
BOOTSTRAP_DIR=$INSTALL_DIR/bootstrap

if [ ! -d $INSTALL_DIR ]; then
    REPO_URL="https://github.com/Hiro-mackay/dotfiles/archive/main.tar.gz"
    mkdir -p $INSTALL_DIR
    curl -L $REPO_URL | tar xz --strip 1 -C $INSTALL_DIR
    chmod -R 755 $BOOTSTRAP_DIR
    ${BOOTSTRAP_DIR}/setup.sh
else
    echo "dotfiles already exists"
    exit 1
fi
