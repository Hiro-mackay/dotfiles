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
