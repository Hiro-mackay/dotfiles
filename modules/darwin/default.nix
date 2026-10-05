# nix-darwin system module (macOS only).
{
  username,
  homeDirectory,
  ...
}:
{
  imports = [
    ./defaults.nix
    ./homebrew.nix
  ];

  assertions = [
    {
      assertion = username != "root";
      message = "Evaluated as root. Run `nix run .#switch` as your normal user; nh elevates only the activation.";
    }
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

  # Writes /etc/zshrc only. The defaults below would clash with config/zsh/.zshrc.
  programs.zsh = {
    enable = true;
    promptInit = "";
    enableGlobalCompInit = false;
  };

  # Codex reads /etc/codex/config.toml as its lowest-precedence layer and never writes it.
  environment.etc."codex/config.toml".source = ../../config/codex/system-config.toml;

  # /Library is outside environment.etc. Removing this does not delete the file.
  system.activationScripts.postActivation.text = ''
    managed="/Library/Application Support/ClaudeCode/managed-settings.d"
    mkdir -p "$managed"
    install -m 0644 ${../../config/claude/managed-settings.json} "$managed/10-nix.json"
    nvram SystemAudioVolume=" " 2>/dev/null || true
  '';
}
