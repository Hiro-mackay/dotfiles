# herdr (terminal multiplexer for coding agents). The binary comes from its own
# installer (`herdr update` rewrites it in place); only the config is managed here.
{ ... }:
{
  xdg.configFile."herdr/config.toml".source = ./config.toml;
}
