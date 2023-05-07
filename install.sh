#!/bin/sh

INSTALL_DIR=$HOME/test
BOOTSTRAP_DIR=$HOME/test/tmp

if [ ! -d $INSTALL_DIR ]; then
    REPO_URL="https://github.com/Hiro-mackay/dotfiles/archive/main.tar.gz"
    mkdir -p $INSTALL_DIR
    curl -L $REPO_URL | tar xz --strip 1 -C $INSTALL_DIR
    chmod -R 755 $BOOTSTRAP_DIR
    ${BOOTSTRAP_DIR}/run.sh
else
    echo "dotfiles already exists"
    exit 1
fi
