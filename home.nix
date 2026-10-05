# home-manager entry, shared by macOS (inside nix-darwin) and Linux (standalone).
# OS-wide differences live in darwin.nix / linux.nix; tool-level ones inside each
# programs/<tool>/default.nix.
{
  config,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    inputs.nix-index-database.homeModules.nix-index
    ./programs/zsh
    ./programs/git
    ./programs/gh
    ./programs/mise
    ./programs/claude
    ./programs/codex
    ./programs/vscode
    ./programs/hammerspoon
  ];

  home.stateVersion = "26.05";
  news.display = "silent";
  xdg.enable = true;

  assertions = [
    {
      assertion = config.home.username != "root";
      message = "Evaluated as root. Run `nix run .#switch` as your normal user.";
    }
  ];

  home.packages = with pkgs; [
    ghq
    ripgrep
    fd
    bat
    eza
    jq
    htmlq
    lazygit
    vim
  ];

  # comma (`, cmd`) and command-not-found with a prebuilt nix-index database.
  programs.nix-index.enable = true;
  programs.nix-index-database.comma.enable = true;

  home.sessionVariables = {
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    DOTFILES_DIR = "${config.home.homeDirectory}/.dotfiles";
    CARGO_HOME = "${config.xdg.dataHome}/.cargo";
    RUSTUP_HOME = "${config.xdg.dataHome}/.rustup";
    PNPM_HOME = "${config.xdg.dataHome}/pnpm";
    NI_CONFIG_FILE = "${config.xdg.configHome}/ni/nirc";
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
    "${config.xdg.dataHome}/.cargo/bin"
    "${config.xdg.dataHome}/pnpm"
  ];
}
