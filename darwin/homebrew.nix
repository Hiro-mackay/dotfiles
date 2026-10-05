# GUI apps stay on Homebrew casks: most are stale, unsigned or missing in nixpkgs.
{
  lib,
  username,
  full,
  ...
}:
{
  # Installs and pins Homebrew itself; nix-darwin's homebrew module does not.
  nix-homebrew = {
    enable = true;
    user = username;
    autoMigrate = true;
  };

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      # TRADEOFF: "none" until the first switch is verified; then "zap" removes undeclared apps.
      cleanup = "none";
    };
    taps = lib.optionals full [ "docker/tap" ];
    brews = lib.optionals full [ "docker/tap/sbx" ];
    casks = [
      "hammerspoon"
      "warp"
    ]
    ++ lib.optionals full [
      "docker-desktop"
      "bettertouchtool"
      "visual-studio-code"
      "zed"
      "google-chrome"
      "obsidian"
      "spotify"
      "appcleaner"
      "chatgpt"
      "claude"
      "codex-app"
    ];
    masApps = lib.optionalAttrs full { Kindle = 302584613; };
    # The list is written by the codeexport alias.
    vscode = lib.optionals full (
      lib.filter (ext: ext != "") (lib.splitString "\n" (builtins.readFile ../programs/vscode/extensions))
    );
  };
}
