# Linux-only home-manager settings (non-NixOS dev servers and dev environments).
{ pkgs, ... }:
{
  targets.genericLinux = {
    enable = true;
    # Headless servers: skip the GPU driver setup and its sudo prompt.
    gpu.enable = false;
  };

  # No systemd user services are used here.
  systemd.user.enable = false;

  home.packages = with pkgs; [
    zsh
    lsof
  ];

  # install.sh links /etc/codex/config.toml here once with sudo; later changes need no root.
  home.file.".local/share/dotfiles/etc/codex/config.toml".source =
    ./programs/codex/system-config.toml;
}
