#!/usr/bin/env zsh

# -----------------
#  zsh option
# -----------------
setopt auto_cd
setopt no_beep
setopt auto_pushd
setopt pushd_ignore_dups
setopt share_history
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_no_store
setopt hist_reduce_blanks
setopt inc_append_history      # save history immediately, not on exit
setopt hist_verify             # confirm before executing history expansion
setopt +o nomatch

# -----------------
#  history
# -----------------
# /etc/zshrc (macOS, nix-darwin) resets these after .zshenv, so set them here.
HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=100000
SAVEHIST=100000
HISTORY_IGNORE="(*DATABASE_URL=*|*PASSWORD=*|*SECRET=*|*TOKEN=*|*API_KEY=*)"

# -----------------
#  completion
# -----------------
if [[ -d "$HOME/.docker/completions" ]]; then
  fpath=($HOME/.docker/completions $fpath)
fi
autoload -Uz compinit
if [[ -n ${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# -----------------
#  PATH
# -----------------
# Nix profiles come from /etc/zshenv (nix-darwin) or the Nix installer and stay ahead
# of the system dirs. Homebrew (macOS casks such as code, zed, and sbx) goes last so
# a cask-installed binary never shadows the Nix one.
typeset -U path
path=(${path:#/opt/homebrew/*})
path=(
    $HOME/.local/bin(N-/)
    ${CARGO_HOME}/bin(N-/)
    ${PNPM_HOME}(N-/)
    $path
    /opt/homebrew/bin(N-/)
    /opt/homebrew/sbin(N-/)
)

# -----------------
#  load modules
# -----------------
for rc in "$ZDOTDIR"/rc.d/*.zsh(N); do
  source "$rc"
done

# -----------------
#  load local config
# -----------------
if [[ -f "$ZDOTDIR/.zshrc.local" ]]; then
  source "$ZDOTDIR/.zshrc.local"
fi