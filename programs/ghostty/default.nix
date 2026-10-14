# Ghostty (the app itself is not installed from here). Machine-specific settings, such as what a
# new window runs, go in an optional work.conf next to this file that something
# outside this repo provides; the absolute path keeps the include from resolving
# against the store.
{ config, ... }:
{
  xdg.configFile."ghostty/config".text = builtins.readFile ./config + ''
    config-file = ?${config.xdg.configHome}/ghostty/work.conf
  '';
}
