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
# Pull this repo and apply it (Nix packages pinned in flake.lock; activation only when
# something changed), then upgrade Homebrew apps and install and upgrade mise tools.
dotup() {
  git -C "$DOTFILES_DIR" pull --ff-only && nix run "$DOTFILES_DIR#switch" || return
  if command -v brew >/dev/null; then brew upgrade || return; fi
  # mise reads GitHub releases; without a token it shares 60 requests an hour with
  # everyone behind the same IP. Use the base account's token. From $HOME, so only
  # the global tools are handled, not those of the project dotup was run from.
  (
    cd || exit
    if [[ -z ${MISE_GITHUB_TOKEN:-}${GITHUB_TOKEN:-} ]] &&
      token=$(gh auth token -h github.com -u "$(git config --global github.login)" 2>/dev/null); then
      export MISE_GITHUB_TOKEN=$token
    fi
    mise install --yes && mise upgrade --yes
  )
}
