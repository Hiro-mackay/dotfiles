# `nix run .#switch`: the single entry point on both macOS and Linux.
# Applies the configuration with nh, then installs mise tools (a network step, kept
# out of activation).
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
    if [ "$(uname -s)" = Darwin ]; then
      nh darwin switch --no-nom "path:$src" -H default -- --impure
    else
      nh home switch --no-nom "path:$src" -c "$(uname -m)-linux" -b backup -- --impure
    fi

    # Unauthenticated GitHub API allows 60 requests/hour; mise cannot read gh's keychain token.
    if [ -z "''${MISE_GITHUB_TOKEN:-}" ] && [ -z "''${GITHUB_TOKEN:-}" ]; then
      if token="$(gh auth token 2>/dev/null)"; then
        export MISE_GITHUB_TOKEN="$token"
      fi
    fi
    # Last step: a failure leaves the applied configuration in place but fails the run.
    mise install --yes || { echo "error: mise install failed. Run 'gh auth login', then 'mise install'." >&2; exit 1; }
  '';
}
