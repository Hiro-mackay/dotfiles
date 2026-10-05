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

  # bash stays the login shell until chsh; this gives it the same PATH and variables.
  programs.bash.enable = true;

  home.packages = [ pkgs.lsof ];
}
