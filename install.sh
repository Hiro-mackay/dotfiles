#!/bin/sh

INSTALL_DIR="${INSTALL_DIR:-$HOME/test}"

if [ ! -d ${DOT_DIR} ]; then
    REPO_URL="https://github.com/Hiro-mackay/dotfiles/archive/main.tar.gz"
    mkdir -p ${INSTALL_DIR}
    curl -L REPO_URL | tar xz --strip 1 -C $INSTALL_DIR
    $INSTALL_DIR/env.sh
else
    echo "dotfiles already exists"
    exit 1
fi
