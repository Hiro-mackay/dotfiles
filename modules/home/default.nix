# Shared home-manager module (macOS via nix-darwin, Linux standalone).
#
# ~/.config is a symlink to ~/.dotfiles/config, so home-manager must never
# generate files under ~/.config: they would collide with the tracked files or
# land in the working tree. Config stays as plain files in config/; this module
# only installs packages, exports variables and creates links.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) isDarwin system;
  home = config.home.homeDirectory;
  dotfiles = "${home}/.dotfiles";
  gitExe = lib.getExe pkgs.git;

  enabledFiles = lib.filter (f: f.enable) (lib.attrValues config.home.file);
  underConfig =
    f: lib.hasPrefix ".config/" f.target || lib.hasPrefix "${config.xdg.configHome}/" f.target;
  filesUnderConfig = map (f: f.target) (lib.filter underConfig enabledFiles);
in
{
  imports = [ inputs.nix-index-database.homeModules.nix-index ];

  home.stateVersion = "26.05";
  news.display = "silent";

  assertions = [
    {
      assertion = config.home.username != "root";
      message = "Evaluated as root. Run `nix run .#switch` as your normal user.";
    }
    {
      assertion = filesUnderConfig == [ ];
      message =
        "home-manager would generate files under ~/.config (a symlink to the repo): "
        + lib.concatStringsSep ", " filesUnderConfig;
    }
  ];

  home.packages =
    with pkgs;
    [
      mise
      git
      gh
      ghq
      fzf
      ripgrep
      fd
      bat
      eza
      jq
      zoxide
      direnv
      lazygit
      starship
      vim
      git-secrets
      nh
      zsh-autosuggestions
      zsh-syntax-highlighting
      inputs.llm-agents.packages.${system}.codex
    ]
    ++ lib.optionals isDarwin [
      emacs-nox
      htmlq
      shellcheck
      watch
      terminal-notifier
      coreutils-prefixed
    ];

  programs.nix-index.enable = true;
  programs.nix-index-database.comma.enable = true;

  # Exported through hm-session-vars.sh, which config/zsh/.zshenv sources.
  home.sessionVariables = {
    NH_FLAKE = dotfiles;
    DOTFILES_ZSH_AUTOSUGGESTIONS = "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh";
    DOTFILES_ZSH_SYNTAX_HIGHLIGHTING = "${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh";
    DOTFILES_COMMAND_NOT_FOUND = "${config.programs.nix-index.package}/etc/profile.d/command-not-found.sh";
  };
  # Shims make mise tools visible to non-interactive shells and GUI-launched apps.
  home.sessionPath = [ "${home}/.local/share/mise/shims" ];

  home.file = lib.mkIf isDarwin {
    "Library/Application Support/Code/User/settings.json".source =
      config.lib.file.mkOutOfStoreSymlink "${dotfiles}/config/vscode/settings.json";
  };

  # Activation steps must stay offline and idempotent; network steps live in nix/switch.nix.
  home.activation = {
    # Entry links, same as the old setup-link.sh. Not home.file: that would collide with
    # anything generated under .config, and rolling back a generation would remove them.
    dotfilesLinks = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      dotfilesLink() {
        local target="$1" link="$2"
        if [ -L "$link" ]; then
          [ "$(readlink "$link")" = "$target" ] && return 0
          run rm "$link"
        elif [ -e "$link" ]; then
          run mv "$link" "$link.backup.$(date +%Y%m%d%H%M%S)"
        fi
        run ln -s "$target" "$link"
      }
      if [ -d "${dotfiles}/config" ]; then
        dotfilesLink "${dotfiles}/config" "${home}/.config"
        dotfilesLink "${dotfiles}/config/zsh/.zshenv" "${home}/.zshenv"
        dotfilesLink "${home}/.config/claude" "${home}/.claude"
        dotfilesLink "${home}/.config/codex" "${home}/.codex"
      else
        warnEcho "${dotfiles}/config not found; skipping dotfiles links"
      fi
    '';

    # Project the agents SSoT (config/agents) into Claude Code and Codex: one directory
    # symlink per skill, never the whole skills dir, which also holds tool-owned skills.
    agentSkills = lib.hm.dag.entryAfter [ "dotfilesLinks" ] ''
      agents="${dotfiles}/config/agents"
      if [ -d "$agents/skills" ]; then
        if [ -f "$agents/AGENTS.md" ] && ! cmp -s "$agents/AGENTS.md" "${dotfiles}/config/codex/AGENTS.md"; then
          run cp "$agents/AGENTS.md" "${dotfiles}/config/codex/AGENTS.md"
        fi
        for tool in claude codex; do
          dir="${dotfiles}/config/$tool/skills"
          run mkdir -p "$dir"
          for entry in "$dir"/*; do
            [ -L "$entry" ] && [ ! -e "$entry" ] || continue
            case "$(readlink "$entry")" in
              ../../agents/skills/*) run rm "$entry" ;;
            esac
          done
          for skill in "$agents/skills"/*/; do
            name="$(basename "$skill")"
            if [ -d "$dir/$name" ] && [ ! -L "$dir/$name" ]; then
              warnEcho "skip $dir/$name: a real directory with that name exists"
              continue
            fi
            run ln -sfn "../../agents/skills/$name" "$dir/$name"
          done
        done
      fi
    '';

    dotfilesGit = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ -d "${dotfiles}/.git" ]; then
        run ${gitExe} -C "${dotfiles}" config core.hooksPath config/git/hooks
        if ${gitExe} -C "${dotfiles}" config --get-regexp '^filter\.codex-config\.' >/dev/null 2>&1; then
          run ${gitExe} -C "${dotfiles}" config --remove-section filter.codex-config
        fi
        # Keep the machine-local identity (never tracked) out of this public repo.
        if [ -f "${home}/.gitconfig.local" ]; then
          for key in user.name user.email; do
            value="$(${gitExe} config -f "${home}/.gitconfig.local" "$key" || true)"
            [ -n "$value" ] || continue
            (
              cd "${dotfiles}"
              export PATH="${pkgs.git}/bin:$PATH"
              run ${pkgs.git-secrets}/bin/git-secrets --add --literal "$value"
            ) || true
          done
        fi
      fi
    '';

    xdgStateDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p "${config.xdg.stateHome}/zsh"
    '';
  };
}
