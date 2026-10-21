# Linux-only home-manager settings (non-NixOS dev servers and dev environments). Part of
# homeModules.default on every system, so it applies only on Linux.
{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
  targets.genericLinux = {
    enable = true;
    # Headless servers: skip the GPU driver setup and its sudo prompt.
    gpu.enable = false;
  };

  # No systemd user services are used here.
  systemd.user.enable = false;

  # bash stays the login shell until chsh; this gives it the same PATH and variables.
  programs.bash.enable = true;
  # A login shell started by a process that already read the session variables (a
  # multiplexer running its keys with sh -lc, say) inherits __HM_SESS_VARS_SOURCED, so
  # hm-session-vars.sh does nothing, and a /etc/profile that resets PATH (Debian's)
  # leaves it without them. Read them again when PATH lost them: ~/.local/bin is the
  # entry they add last (home.nix).
  programs.bash.profileExtra = ''
    case ":$PATH:" in
      *":${config.home.homeDirectory}/.local/bin:"*) ;;
      *)
        unset __HM_SESS_VARS_SOURCED
        . "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh"
        ;;
    esac
  '';

  home.packages = [ pkgs.lsof ];
}
