# nix-darwin entry (macOS only). home-manager runs inside it with home.nix.
{
  pkgs,
  username,
  homeDirectory,
  ...
}:
{
  imports = [
    ./darwin/defaults.nix
    ./darwin/homebrew.nix
  ];

  # No option manuals (darwin-help, man pages): building them slows every switch.
  documentation.enable = false;
  # It bundles a second, default system with those manuals. When needed:
  # nix run nix-darwin#darwin-uninstaller
  system.tools.darwin-uninstaller.enable = false;

  # Determinate Nix collects garbage on its own, but every old generation keeps its
  # packages alive. Weekly, keep the current system generation and the two before
  # (enough to roll back; older configurations come back from git), then collect.
  # home-manager runs inside nix-darwin, so its configuration is part of each system
  # generation and has none of its own. Only generations go: direnv's gcroots stay.
  launchd.daemons.prune-generations = {
    script = ''
      /nix/var/nix/profiles/default/bin/nix-env -p /nix/var/nix/profiles/system --delete-generations +3
      /nix/var/nix/profiles/default/bin/nix store gc
    '';
    serviceConfig.StartCalendarInterval = [
      {
        Weekday = 1;
        Hour = 12;
        Minute = 0;
      }
    ];
  };

  nixpkgs.hostPlatform = "aarch64-darwin";
  system.stateVersion = 7;
  system.primaryUser = username;
  users.users.${username}.home = homeDirectory;

  # Determinate owns the Nix daemon and /etc/nix/nix.conf; extra settings go to nix.custom.conf.
  determinateNix = {
    enable = true;
    customSettings = {
      extra-substituters = [ "https://cache.numtide.com" ];
      extra-trusted-public-keys = [ "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=" ];
    };
  };

  time.timeZone = "Asia/Tokyo";
  security.pam.services.sudo_local.touchIdAuth = true;

  # Writes /etc/zshrc only. These defaults would clash with the home-manager zsh config.
  programs.zsh = {
    enable = true;
    promptInit = "";
    enableGlobalCompInit = false;
  };

  # macOS-only CLI tools.
  environment.systemPackages = with pkgs; [
    emacs-nox
    shellcheck
    watch
    terminal-notifier
    coreutils-prefixed # ghead for the cpb alias
  ];

  system.activationScripts.postActivation.text = ''
    nvram SystemAudioVolume=" " 2>/dev/null || true
  '';
}
