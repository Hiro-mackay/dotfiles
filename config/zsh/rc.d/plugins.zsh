# -----------------
#  mise (runtime manager)
# -----------------
if command -v mise &>/dev/null; then
  eval "$(mise activate zsh)"
fi

# -----------------
#  fzf
# -----------------
# Keybindings (Ctrl+R/T, Alt+C) are intercepted by Warp.
# fzf itself still works for all fzf-powered commands (glz, gfb, dexec, etc.).
if command -v fzf &>/dev/null; then
  if [[ "$TERM_PROGRAM" != "WarpTerminal" ]]; then
    source <(fzf --zsh)
  fi
fi

# -----------------
#  zoxide (smart cd)
# -----------------
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
fi

# -----------------
#  direnv (per-directory env)
# -----------------
if command -v direnv &>/dev/null; then
  eval "$(direnv hook zsh)"
fi

# -----------------
#  lazygit / lazydocker
# -----------------
alias lg="lazygit"
alias lzd="lazydocker"

# -----------------
#  starship (prompt)
# -----------------
# Warp renders its own prompt (git branch, status, etc.).
# starship is activated only in non-Warp terminals.
if [[ "$TERM_PROGRAM" != "WarpTerminal" ]]; then
  if command -v starship &>/dev/null; then
    eval "$(starship init zsh)"
  fi
fi

# -----------------
#  zsh-autosuggestions
# -----------------
if [[ -f "$BREW_HOME/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  source "$BREW_HOME/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# -----------------
#  zsh-syntax-highlighting (must be last)
# -----------------
if [[ -f "$BREW_HOME/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "$BREW_HOME/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
