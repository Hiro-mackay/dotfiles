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
  text = ''
    # The flake this command was built from (a worktree, a clone, or GitHub), so the
    # edits being applied are the ones the user is looking at. nh treats a bare store
    # path as a built configuration, hence the path: prefix.
    src="${flake}"

    # nh builds as the invoking user and elevates only the activation step, so this
    # works before darwin-rebuild exists. --impure lets the flake read USER and HOME.
    # --no-nom: nix-output-monitor cannot parse Determinate Nix's JSON log format.
    # --show-activation-logs: activation (Homebrew, defaults, home-manager) prints as
    # it goes instead of sitting silent after "Activating configuration".
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
        nh darwin switch --no-nom --show-activation-logs "path:$src" -H default -- --impure
      fi
    else
      nh home switch --no-nom --show-activation-logs "path:$src" -c "$(uname -m)-linux" -b backup -- --impure
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
