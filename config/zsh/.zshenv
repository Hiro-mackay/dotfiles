#!/usr/bin/env zsh

# -----------------
#  LANG
# -----------------
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"


# -----------------
#  XDG
# -----------------
export XDG_CONFIG_HOME=$HOME/.config
export XDG_DATA_HOME=$HOME/.local/share
export XDG_STATE_HOME=$HOME/.local/state
export XDG_CACHE_HOME=$HOME/.cache



# -----------------
#  dotfiles
# -----------------
export DOTFILES_DIR="$HOME/.dotfiles"
export DOTFILES_CONFIG_DIR="$DOTFILES_DIR/config"


# -----------------
#  zsh
# -----------------
export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
export HISTFILE="$ZDOTDIR"/history


# -----------------
#  Homebrew
# ----------------- 
export BREW_HOME=/opt/homebrew


# -----------------
#  Rust
# -----------------
export CARGO_HOME="$XDG_DATA_HOME/.cargo"
export RUSTUP_HOME="$XDG_DATA_HOME/.rustup"


# -----------------
#  Volta
# -----------------
export VOLTA_HOME="$XDG_DATA_HOME/.volta"


# ----------------------
# Pyenv
# ----------------------
export PYENV_ROOT="$XDG_DATA_HOME/.pyenv"


# ----------------------
# Golang
# ----------------------
export GOPATH="$XDG_DATA_HOME/.go"
export GO111MODULE="on"


# -----------------
#  Deno
# -----------------
export DENO_INSTALL="$XDG_DATA_HOME/.deno"


# -----------------
#  PATH
# -----------------
typeset -U path
path=(
    ${BREW_HOME}/bin(N-/)
    ${CARGO_HOME}/bin(N-/)
    ${VOLTA_HOME}/bin(N-/)
    ${PYENV_ROOT}/bin(N-/)
    ${GOPATH}/bin(N-/)
    ${DENO_INSTALL}/bin(N-/)
    $path
)