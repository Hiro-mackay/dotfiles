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
# --no-upgrade (-nu) only applies: it still installs missing mise tools, but upgrades
# nothing.
dotup() {
  local upgrade=1
  case ${1:-} in --no-upgrade | -nu) upgrade= ;; esac
  git -C "$DOTFILES_DIR" pull --ff-only && nix run "$DOTFILES_DIR#switch" || return
  if [[ -n $upgrade ]] && command -v brew >/dev/null; then brew upgrade || return; fi
  # From $HOME, so only the global tools are handled, not those of the project dotup
  # was run from.
  (
    cd || exit
    mise install --yes && { [[ -z $upgrade ]] || mise upgrade --yes; }
  )
}
