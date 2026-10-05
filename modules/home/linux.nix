# Standalone home-manager on non-NixOS Linux (dev servers and dev environments).
{
  config,
  pkgs,
  ...
}:
let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
  outOfStore = config.lib.file.mkOutOfStoreSymlink;
in
{
  targets.genericLinux = {
    enable = true;
    # Headless servers: skip the GPU driver setup and its sudo prompt.
    gpu.enable = false;
  };

  # No systemd user services are used. Disabling the module keeps home-manager from
  # generating ~/.config/systemd and ~/.config/environment.d (genericLinux and i18n
  # set session variables there), which would land in the repo through ~/.config.
  systemd.user.enable = false;

  home.packages = with pkgs; [
    zsh
    lsof
  ];

  # install.sh links /etc/codex/config.toml and the Claude Code managed settings
  # to these files once with sudo; later edits need no root.
  home.file = {
    ".local/share/dotfiles/etc/codex/config.toml".source =
      outOfStore "${dotfiles}/config/codex/system-config.toml";
    ".local/share/dotfiles/etc/claude-code/10-nix.json".source =
      outOfStore "${dotfiles}/config/claude/managed-settings.json";
  };
}
