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
      "docker/tap/sbx"
    ];
    masApps = lib.optionalAttrs full { Kindle = 302584613; };
    # The list is written by the codeexport alias.
    vscode = lib.optionals full (
      lib.filter (ext: ext != "") (lib.splitString "\n" (builtins.readFile ../programs/vscode/extensions))
    );
  };

  # TRADEOFF: brew bundle runs before home-manager in activation, so one failed cask
  # (restricted Mac, App Store signed out, network) would skip the whole home
  # configuration. It only warns, as the old setup-brew.sh did; read the switch output.
  system.activationScripts.homebrew.text = lib.mkMerge [
    # Before nix-homebrew's own mkBefore setup, so installing Homebrew itself is covered too.
    (lib.mkOrder 400 "set +e")
    (lib.mkAfter ''
      [ $? -eq 0 ] || echo >&2 "warning: Homebrew bundle failed; continuing so the home configuration still applies"
      set -e
    '')
  ];
}
