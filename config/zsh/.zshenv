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


# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/mackay/.google-cloud-sdk/path.zsh.inc' ]; then . '/Users/mackay/.google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/mackay/.google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/mackay/.google-cloud-sdk/completion.zsh.inc'; fi
. "/Users/mackay/.local/share/.cargo/env"
