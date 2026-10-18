# herdr (terminal multiplexer for coding agents). The binary is a Homebrew formula
# (darwin/homebrew.nix); only the config is managed here.
{ ... }:
{
  xdg.configFile."herdr/config.toml".source = ./config.toml;
}
