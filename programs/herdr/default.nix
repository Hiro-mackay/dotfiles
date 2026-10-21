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
  xdg.configFile."herdr/config.toml".text = builtins.replaceStrings [ "@bin@" ] [ "${scripts}/bin" ] (
    builtins.readFile ./config.toml
  );
}
