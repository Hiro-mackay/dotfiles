# `nix run .#switch [-- --force]`: the single entry point on both macOS and Linux.
# Applies the configuration with nh. mise tools are installed by the callers (install.sh,
# dotup), after GitHub sign-in, so they can use a token. On macOS an unchanged
# configuration is not activated again, so a routine run asks for no sudo password;
# --force (install.sh) always activates.
{ pkgs, flake }:
pkgs.writeShellApplication {
  name = "dotfiles-switch";
  runtimeInputs = [ pkgs.nh ];
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
    # ~/.gitconfig is read after the dotfiles' git settings and overrides them, accounts
    # included. Without it, `git config --global` fails on the read-only settings instead
    # of quietly writing there (e.g. an onboarding guide setting another email for every
    # repository). Checked on every run, activation or not: an empty one goes, one with
    # content is reported and left alone.
    if [ -f "$HOME/.gitconfig" ] && [ ! -L "$HOME/.gitconfig" ]; then
      if [ -s "$HOME/.gitconfig" ]; then
        echo "warning: ~/.gitconfig overrides the git settings from the dotfiles, accounts included; move what it needs to ~/.gitconfig.accounts, then remove it" >&2
      else
        rm "$HOME/.gitconfig"
      fi
    fi

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
  '';
}
