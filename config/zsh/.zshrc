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

if [[ -f "$HOME/.google-cloud-sdk/completion.zsh.inc" ]]; then
  source "$HOME/.google-cloud-sdk/completion.zsh.inc"
fi

# -----------------
#  load modules
# -----------------
for rc in "$ZDOTDIR"/rc.d/*.zsh(N); do
  source "$rc"
done
