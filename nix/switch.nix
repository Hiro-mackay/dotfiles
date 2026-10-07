# `nix run .#switch [-- --force]`: the single entry point on both macOS and Linux.
# Applies the configuration with nh, then installs mise tools (a network step, kept
# out of activation). On macOS an unchanged configuration is not activated again, so a
# routine run asks for no sudo password; --force (install.sh) always activates.
{ pkgs, flake }:
pkgs.writeShellApplication {
  name = "dotfiles-switch";
  runtimeInputs = with pkgs; [
    nh
    mise
    gh
  ];
  text = builtins.readFile ./log-window.sh + ''
    # The flake this command was built from (a worktree, a clone, or GitHub), so the
    # edits being applied are the ones the user is looking at. nh treats a bare store
    # path as a built configuration, hence the path: prefix.
    src="${flake}"

    # nh builds as the invoking user and elevates only the activation step, so this
    # works before darwin-rebuild exists. --impure lets the flake read USER and HOME.
    # --no-nom: nix-output-monitor cannot parse Determinate Nix's JSON log format.
    # --show-activation-logs: activation (Homebrew, defaults, home-manager) prints as
    # it goes; log_window scrolls it in a few lines and keeps the full text in $log.
    log=$(mktemp -t dotfiles-switch.XXXXXX)
    failed() {
      echo "error: applying the configuration failed; its last lines:" >&2
      tail -n 30 "$log" >&2
      echo "Full log: $log" >&2
      exit 1
    }
    if [ "$(uname -s)" = Darwin ]; then
      # Unchanged: the system built from this flake is the running one and every
      # declared cask is installed (one that failed before still gets retried).
      built=""
      if [ "''${1:-}" != --force ]; then
        built=$(nix build --impure --no-link --print-out-paths "path:$src#darwinConfigurations.default.system")
        brewfile=$(grep -oE '/nix/store/[a-z0-9]{32}-Brewfile' "$built/activate" | head -n 1 || true)
        if [ "$built" != "$(readlink /run/current-system 2>/dev/null)" ] ||
          { [ -n "$brewfile" ] && ! HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --no-upgrade --file="$brewfile" >/dev/null 2>&1; }; then
          built=""
        fi
      fi
      if [ -n "$built" ]; then
        echo "The configuration is unchanged; nothing to activate."
      else
        nh darwin switch --no-nom --show-activation-logs "path:$src" -H default -- --impure 2>&1 | log_window "$log" || failed
      fi
    else
      nh home switch --no-nom --show-activation-logs "path:$src" -c "$(uname -m)-linux" -b backup -- --impure 2>&1 | log_window "$log" || failed
    fi

    # VS Code extensions: after activation, as this user, missing ones only, with a time
    # limit. Run from activation (root, then sudo -u) the Electron CLI can wait forever
    # for a GUI session, holding up the whole switch.
    if [ "$(uname -s)" = Darwin ] && command -v code >/dev/null; then
      missing=$(comm -23 \
        <(grep -v '^$' "$src/programs/vscode/extensions" | tr '[:upper:]' '[:lower:]' | sort -u) \
        <(${pkgs.coreutils}/bin/timeout 60 code --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]' | sort -u))
      if [ -n "$missing" ]; then
        args=()
        for ext in $missing; do args+=(--install-extension "$ext"); done
        echo "Installing $(echo "$missing" | wc -l | tr -d ' ') VS Code extensions..."
        ${pkgs.coreutils}/bin/timeout 600 code "''${args[@]}" >/dev/null ||
          echo "warning: VS Code extensions were not installed (code failed or took over 10 minutes); open VS Code once, then run dotup" >&2
      fi
    fi

    # Unauthenticated GitHub API allows 60 requests/hour; mise cannot read gh's keychain token.
    if [ -z "''${MISE_GITHUB_TOKEN:-}" ] && [ -z "''${GITHUB_TOKEN:-}" ]; then
      if token="$(gh auth token 2>/dev/null)"; then
        export MISE_GITHUB_TOKEN="$token"
      fi
    fi
    # Last step: a failure leaves the applied configuration in place but fails the run.
    mise install --yes || { echo "error: mise install failed (see above); fix it, then run 'mise install'. A GitHub API rate limit is fixed by 'gh auth login'." >&2; exit 1; }
  '';
}
