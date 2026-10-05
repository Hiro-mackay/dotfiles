# `nix run .#switch`: the single entry point on both macOS and Linux.
# Applies the configuration with nh, then installs what Nix does not manage:
# mise tools, and VS Code extensions on macOS (network steps, kept out of activation).
{ pkgs, flake }:
pkgs.writeShellApplication {
  name = "dotfiles-switch";
  runtimeInputs = with pkgs; [
    nh
    mise
    gh
    coreutils
    gnugrep
  ];
  text = ''
    # The flake this command was built from (a worktree, a clone, or GitHub), so the
    # edits being applied are the ones the user is looking at. nh treats a bare store
    # path as a built configuration, hence the path: prefix.
    src="${flake}"
    state="''${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
    warn() { printf 'warning: %s\n' "$*" >&2; }

    # nh builds as the invoking user and elevates only the activation step, so this
    # works before darwin-rebuild exists and never evaluates as root. --impure lets the
    # flake read USER and HOME. --no-nom: nix-output-monitor cannot parse Determinate
    # Nix's JSON log format and floods the output with errors.
    case "$(uname -s)" in
      Darwin)
        # DOTFILES_HOST (default or minimal) is remembered for later runs.
        mkdir -p "$state"
        if [ -n "''${DOTFILES_HOST:-}" ]; then
          printf '%s\n' "$DOTFILES_HOST" >"$state/host"
        fi
        host="$(cat "$state/host" 2>/dev/null || echo default)"
        nh darwin switch --no-nom "path:$src" -H "$host" -- --impure
        hm_vars="/etc/profiles/per-user/$USER/etc/profile.d/hm-session-vars.sh"
        ;;
      Linux)
        nh home switch --no-nom "path:$src" -c "$(uname -m)-linux" -b backup -- --impure
        hm_vars="$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
        ;;
      *)
        echo "unsupported OS: $(uname -s)" >&2
        exit 1
        ;;
    esac

    # Load the variables just applied (CARGO_HOME, RUSTUP_HOME, ...) so the first run
    # from install.sh puts tools where later shells look for them.
    if [ -r "$hm_vars" ]; then
      set +u
      # shellcheck disable=SC1090
      . "$hm_vars" || warn "could not load $hm_vars"
      set -u
    fi

    # Unauthenticated GitHub API allows 60 requests/hour; mise needs more on a fresh machine.
    if [ -z "''${MISE_GITHUB_TOKEN:-}" ] && [ -z "''${GITHUB_TOKEN:-}" ]; then
      if token="$(gh auth token 2>/dev/null)"; then
        export MISE_GITHUB_TOKEN="$token"
      fi
    fi
    mise install --yes || warn "mise install failed; rerun 'mise install'"

    # VS Code extensions (macOS): install what the tracked list has and the machine lacks.
    if [ "$(uname -s)" = Darwin ]; then
      PATH="$PATH:/opt/homebrew/bin"
      extensions="$src/programs/vscode/extensions"
      if command -v code >/dev/null 2>&1 && [ -f "$extensions" ]; then
        installed="$(code --list-extensions 2>/dev/null || true)"
        while IFS= read -r ext; do
          [ -n "$ext" ] || continue
          printf '%s\n' "$installed" | grep -qixF -- "$ext" && continue
          code --install-extension "$ext" >/dev/null || warn "could not install VS Code extension $ext"
        done <"$extensions"
      fi
    fi
  '';
}
