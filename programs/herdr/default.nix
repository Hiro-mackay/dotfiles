# herdr (terminal multiplexer for coding agents). The binary is a Homebrew formula
# (darwin/homebrew.nix); the config and the scripts its keys run are managed here.
# The scripts are on PATH too: herdr-claude-sync is started outside herdr.
{ pkgs, ... }:
let
  scripts = pkgs.runCommandLocal "herdr-scripts" { } ''
    mkdir -p $out
    cp -r ${./bin} $out/bin
  '';
in
{
  home.packages = [ scripts ];
  xdg.configFile."herdr/config.toml" = {
    text = builtins.replaceStrings [ "@bin@" ] [ "${scripts}/bin" ] (builtins.readFile ./config.toml);
    # A running server keeps the config it started with, so its keys would go on running the
    # previous generation's scripts. Activation's PATH has no herdr: it is Homebrew's on the Mac
    # and the installer's in ~/.local/bin elsewhere. With no server running this fails, harmlessly.
    onChange = ''
      for herdr in "$HOME/.local/bin/herdr" /opt/homebrew/bin/herdr; do
        if [[ -x $herdr ]]; then
          run "$herdr" server reload-config >/dev/null 2>&1 || true
          break
        fi
      done
    '';
  };
}
