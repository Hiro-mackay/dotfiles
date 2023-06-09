#!/usr/bin/env zsh

set -x

INSTALL_DIR=$HOME/.dotfiles
BOOTSTRAP_DIR=$INSTALL_DIR/bootstrap


source $BOOTSTRAP_DIR/env.sh


$BOOTSTRAP_DIR/setup-dir.sh
$BOOTSTRAP_DIR/setup-link.sh
$BOOTSTRAP_DIR/setup-brew.sh
$BOOTSTRAP_DIR/setup-lang.sh
$BOOTSTRAP_DIR/setup-macos.sh
$BOOTSTRAP_DIR/setup-vscode.sh
