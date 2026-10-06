# -----------------
#  Python (uv)
# -----------------
alias pyrun="uv run"
alias pyadd="uv add"
alias pyinit="uv init"
alias pyin="uv sync"
alias pyshell="uv shell"
alias pyrm="rm -rf .venv"
alias pyfreeze="uv pip freeze > requirements.txt"

# -----------------
#  Kubernetes
# -----------------
alias k="kubectl"

# -----------------
#  ni
# -----------------
export NI_DEFAULT_AGENT="pnpm"
export NI_GLOBAL_AGENT="pnpm"

# -----------------
#  VS Code
# -----------------
# Snapshot installed extensions into dotfiles (run after adding/removing one).
(( $+commands[code] )) && alias codeexport="code --list-extensions | sort > $DOTFILES_DIR/programs/vscode/extensions"

# -----------------
#  Dotfiles
# -----------------
# Pull this repo and apply it (Nix packages pinned in flake.lock, Homebrew), then upgrade mise tools.
dotup() {
  git -C "$DOTFILES_DIR" pull --ff-only && nix run "$DOTFILES_DIR#switch" && mise upgrade --yes
}
