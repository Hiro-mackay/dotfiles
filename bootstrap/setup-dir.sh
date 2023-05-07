#!/bin/sh

echo "Start directory setup..."

# ----------------------
# XDG
# ----------------------
mkdir -p \
    $XDG_CONFIG_HOME \
    $XDG_CACHE_HOME \
    $XDG_DATA_HOME \
    $XDG_RUNTIME_DIR \


# ----------------------
# SSH
# ----------------------
if [ ! -d "$HOME/.ssh" ]; then
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
fi


# ----------------------
# language
# ----------------------
mkdir -p $CARGO_HOME
mkdir -p $RUSTUP_HOME
mkdir -p $VOLTA_HOME
mkdir -p $PYENV_ROOT
mkdir -p $GOPATH
mkdir -p $DENO_INSTALL

