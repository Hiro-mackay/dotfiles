# GUI apps stay on Homebrew casks: most are stale, unsigned or missing in nixpkgs.
{ lib, username, ... }:
let
  # Cask -> the app it installs in /Applications (null: no app, e.g. a CLI).
  casks = {
    hammerspoon = "Hammerspoon.app";
    warp = "Warp.app";
    docker-desktop = "Docker.app";
    bettertouchtool = "BetterTouchTool.app";
    visual-studio-code = "Visual Studio Code.app";
    google-chrome = "Google Chrome.app";
    obsidian = "Obsidian.app";
    appcleaner = "AppCleaner.app";
    chatgpt = "ChatGPT.app";
    claude = "Claude.app";
    codex-app = "Codex.app";
    "docker/tap/sbx" = null;
  };

  # An app already installed outside Homebrew (company MDM, a manual install) keeps its
  # installer as the single owner, so its cask is skipped instead of colliding. Read at
  # (impure) evaluation.
  installedElsewhere =
    cask: app:
    app != null
    && builtins.pathExists "/Applications/${app}"
    && !builtins.pathExists "/opt/homebrew/Caskroom/${baseNameOf cask}";
  managed = lib.attrNames (lib.filterAttrs (cask: app: !installedElsewhere cask app) casks);
in
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
      # "none" until the first switch is verified; then "zap" removes undeclared apps.
      cleanup = "none";
    };
    taps = [ "docker/tap" ];
    casks = managed;
    # Only when Homebrew owns VS Code, so its `code` is on PATH for brew bundle.
    # The list is written by the codeexport alias.
    vscode = lib.optionals (lib.elem "visual-studio-code" managed) (
      lib.filter (ext: ext != "") (lib.splitString "\n" (builtins.readFile ../programs/vscode/extensions))
    );
  };

  # brew bundle runs before home-manager in activation, so one failed cask
  # (network, a restricted Mac) would skip the whole home configuration. It only warns,
  # as the old setup-brew.sh did; read the switch output.
  system.activationScripts.homebrew.text = lib.mkMerge [
    # Before nix-homebrew's own mkBefore setup, so installing Homebrew itself is covered too.
    (lib.mkOrder 400 "set +e")
    (lib.mkAfter ''
      # The brew bundle block above is nix-darwin's, so its status is only available here.
      # shellcheck disable=SC2181
      [ $? -eq 0 ] || echo >&2 "warning: Homebrew bundle failed; continuing so the home configuration still applies"
      set -e
    '')
  ];
}
