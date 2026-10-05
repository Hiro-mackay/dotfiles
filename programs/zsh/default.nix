# zsh: home-manager generates .zshenv/.zshrc; aliases and functions stay as plain
# files in rc.d/ and are sourced from the store. macOS-only files are included only
# in the macOS configuration.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
  rcFiles = [
    "_container"
    "aliases"
    "cheat"
    "dev"
    "docker"
    "functions"
    "git"
    "plugins"
  ]
  ++ lib.optionals isDarwin [
    "darwin"
    "warp-code"
  ];
in
{
  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";

    history = {
      path = "${config.xdg.stateHome}/zsh/history";
      size = 100000;
      save = 100000;
      share = true;
      ignoreSpace = true;
      ignoreAllDups = true;
      # Best effort: commands that look like they carry a credential are not written to
      # the history file. Case-insensitive via brackets (no extended_glob needed).
      ignorePatterns = [
        "*[Tt][Oo][Kk][Ee][Nn]*=*"
        "*[Ss][Ee][Cc][Rr][Ee][Tt]*"
        "*[Pp][Aa][Ss][Ss][Ww]*"
        "*[Aa][Pp][Ii]_[Kk][Ee][Yy]*"
        "*[Pp][Rr][Ii][Vv][Aa][Tt][Ee]_[Kk][Ee][Yy]*"
        "*[Aa][Cc][Cc][Ee][Ss][Ss]_[Kk][Ee][Yy]*"
        "*DATABASE_URL=*"
        "*[Aa]uthorization:*"
        "*[Bb]earer *"
        "*://*:*@*"
      ];
    };

    setOptions = [
      "AUTO_CD"
      "NO_BEEP"
      "AUTO_PUSHD"
      "PUSHD_IGNORE_DUPS"
      "HIST_NO_STORE"
      "HIST_REDUCE_BLANKS"
      "INC_APPEND_HISTORY"
      "HIST_VERIFY"
      "NO_NOMATCH"
    ];

    # Rebuild the completion cache at most once a day. The (#q...) glob qualifier
    # needs extended_glob, enabled only inside this function.
    completionInit = ''
      autoload -Uz compinit
      () {
        setopt local_options extended_glob
        if [[ -n ''${ZDOTDIR}/.zcompdump(#qN.mh+24) ]]; then
          compinit
        else
          compinit -C
        fi
      }
    '';

    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    initContent = lib.mkMerge [
      # Before compinit.
      (lib.mkOrder 550 ''
        if [[ -d "$HOME/.docker/completions" ]]; then
          fpath=($HOME/.docker/completions $fpath)
        fi
      '')
      # Homebrew (casks such as code and zed, and sbx) is appended so a cask binary never
      # shadows the Nix one, and before rc.d so its `code` checks see it.
      (lib.mkIf isDarwin (
        lib.mkOrder 900 ''
          path+=(/opt/homebrew/bin(N-/) /opt/homebrew/sbin(N-/))
        ''
      ))
      (lib.concatMapStringsSep "\n" (name: "source ${./rc.d}/${name}.zsh") rcFiles)
      ''
        if [[ -f "$ZDOTDIR/.zshrc.local" ]]; then
          source "$ZDOTDIR/.zshrc.local"
        fi
      ''
    ];
  };

  programs.zoxide.enable = true;
  programs.direnv.enable = true;

  # Shell integration is loaded by rc.d/plugins.zsh, which skips it inside Warp.
  programs.fzf = {
    enable = true;
    enableZshIntegration = false;
    defaultCommand = "fd --type f --hidden --exclude .git";
    defaultOptions = [
      "--height=40%"
      "--reverse"
      "--border"
      "--bind=ctrl-d:preview-half-page-down,ctrl-u:preview-half-page-up"
      "--preview-window=right:50%:wrap"
    ];
    historyWidget.options = [
      "--preview 'echo {}'"
      "--preview-window=up:3:wrap"
    ];
    fileWidget.options = [ "--preview 'bat --color=always --style=numbers --line-range=:300 {}'" ];
    changeDirWidget.options = [ "--preview 'eza --tree --level=2 --icons {}'" ];
  };
  programs.starship = {
    enable = true;
    enableZshIntegration = false;
  };
}
