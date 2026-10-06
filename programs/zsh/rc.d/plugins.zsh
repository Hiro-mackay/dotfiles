# -----------------
#  Plugins not wired by home-manager
# -----------------
# zoxide, direnv, mise, autosuggestions, syntax highlighting and command-not-found
# come from home-manager (programs/*/default.nix). fzf key bindings and starship stay
# here because Warp intercepts the bindings and renders its own prompt.

# fzf: key bindings (Ctrl+R/T, Alt+C) outside Warp only. fzf itself still works for
# all fzf-powered commands (glz, gfb, dexec, etc.).
if [[ "$TERM_PROGRAM" != "WarpTerminal" ]] && command -v fzf &>/dev/null; then
  source <(fzf --zsh)
fi

# starship: prompt outside Warp only.
if [[ "$TERM_PROGRAM" != "WarpTerminal" ]] && command -v starship &>/dev/null; then
  eval "$(starship init zsh)"
fi

# -----------------
#  lazygit
# -----------------
alias lg="lazygit"
