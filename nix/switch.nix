# `nix run .#switch`: the single entry point on both macOS and Linux.
# Applies the configuration with nh, then runs the steps that need the network
# (kept out of activation so activation also works offline).
{ pkgs }:
pkgs.writeShellApplication {
  name = "dotfiles-switch";
  runtimeInputs = with pkgs; [
    nh
    mise
    gh
    curl
    bash
    coreutils
    gnugrep
  ];
  text = ''
    flake="''${NH_FLAKE:-$HOME/.dotfiles}"
    warn() { printf 'warning: %s\n' "$*" >&2; }

    # nh builds as the invoking user and elevates only the activation step, so
    # this works before darwin-rebuild exists and never evaluates as root.
    # --impure lets the flake read USER and HOME. --no-nom: nix-output-monitor cannot
    # parse Determinate Nix's JSON log format and floods the output with errors.
    case "$(uname -s)" in
      Darwin) nh darwin switch --no-nom "$flake" -H "''${DOTFILES_HOST:-default}" -- --impure ;;
      Linux) nh home switch --no-nom "$flake" -c "$(uname -m)-linux" -b backup -- --impure ;;
      *)
        echo "unsupported OS: $(uname -s)" >&2
        exit 1
        ;;
    esac

    claude="$HOME/.local/bin/claude"
    if [ ! -x "$claude" ]; then
      curl -fsSL https://claude.ai/install.sh | bash || warn "Claude Code install failed; rerun switch later"
    fi
    if [ -x "$claude" ] && ! "$claude" mcp get codebase-memory-mcp >/dev/null 2>&1; then
      "$claude" mcp add -s user codebase-memory-mcp -- codebase-memory-mcp >/dev/null \
        || warn "could not register codebase-memory-mcp with Claude Code"
    fi

    # Unauthenticated GitHub API allows 60 requests/hour; mise needs more on a fresh machine.
    if [ -z "''${MISE_GITHUB_TOKEN:-}" ] && [ -z "''${GITHUB_TOKEN:-}" ]; then
      if token="$(gh auth token 2>/dev/null)"; then
        export MISE_GITHUB_TOKEN="$token"
      fi
    fi
    mise install --yes || warn "mise install failed; rerun 'mise install'"

    # VS Code extensions: install what the tracked list has and the machine lacks.
    PATH="$PATH:/opt/homebrew/bin"
    extensions="$flake/config/vscode/extensions"
    if command -v code >/dev/null 2>&1 && [ -f "$extensions" ]; then
      installed="$(code --list-extensions 2>/dev/null || true)"
      while IFS= read -r ext; do
        [ -n "$ext" ] || continue
        printf '%s\n' "$installed" | grep -qixF -- "$ext" && continue
        code --install-extension "$ext" >/dev/null || warn "could not install VS Code extension $ext"
      done <"$extensions"
    fi
  '';
}
