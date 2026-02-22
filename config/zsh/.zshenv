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
export HISTFILE="$XDG_STATE_HOME/zsh/history"
export HISTSIZE=100000
export SAVEHIST=100000

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
#  ni - use the right package manager
# -----------------
export NI_CONFIG_FILE="$XDG_CONFIG_HOME/ni/nirc"

# -----------------
#  fzf
# -----------------
export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
export FZF_DEFAULT_OPTS='
  --height=40%
  --reverse
  --border
  --bind=ctrl-d:preview-half-page-down,ctrl-u:preview-half-page-up
  --preview-window=right:50%:wrap'
export FZF_CTRL_R_OPTS='--preview "echo {}" --preview-window=up:3:wrap'
export FZF_CTRL_T_OPTS='--preview "bat --color=always --style=numbers --line-range=:300 {}"'
export FZF_ALT_C_OPTS='--preview "eza --tree --level=2 --icons {}"'

# -----------------
#  Google Cloud SDK
# -----------------
if [[ -f "$HOME/.google-cloud-sdk/path.zsh.inc" ]]; then
  . "$HOME/.google-cloud-sdk/path.zsh.inc"
fi

# -----------------
#  Cargo
# -----------------
if [[ -f "${CARGO_HOME:-$HOME/.cargo}/env" ]]; then
  . "${CARGO_HOME:-$HOME/.cargo}/env"
fi
