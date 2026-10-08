# Claude Code: package, settings, CLAUDE.md, skills, plugins and MCP all come from Nix.
# settings.json is read-only, so /model, /config and /plugin changes last only for the
# session; edit settings.json here and switch to keep them. The deny rules guard
# against accidents, not against a determined agent: the file is a symlink in the
# user's home that a plain rm can replace.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  skills = ../agents/skills;
  guardrails = import ../agents/guardrails.nix;
  settings = builtins.fromJSON (builtins.readFile ./settings.json);
  claude = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-code;

  # Copies conversations and memory into the vault's .depth/ (see vault-capture.py).
  capture = pkgs.writeShellScript "vault-capture" ''
    export VAULT_RCLONE=${pkgs.rclone}/bin/rclone
    exec ${pkgs.python3}/bin/python3 ${./vault-capture.py} "$@"
  '';
  hook = arg: [
    {
      hooks = [
        {
          type = "command";
          command = "${capture} ${arg}";
        }
      ];
    }
  ];

  # Runs the vault's observer agent over yesterday's conversations. Only on a Mac
  # that has the marker file: on the work Mac, Claude Code may run only in its
  # sandbox, never on the host.
  observe = pkgs.writeShellScript "vault-observe" ''
    vault="''${VAULT_DIR:-$HOME/Repository/github.com/Hiro-mackay/vault}"
    [ -f "${config.xdg.configHome}/vault/observer" ] && [ -d "$vault/.depth/conversations" ] || exit 0
    state="${config.xdg.stateHome}/vault-capture"
    mkdir -p "$state" "$HOME/.claude/agent-memory"
    day=$(/bin/date -v-1d +%Y/%m/%d)
    cd "$vault" || exit 0
    ${claude}/bin/claude -p --agent observer --permission-mode acceptEdits \
      --add-dir "$HOME/.claude/agent-memory" \
      "Read .depth/conversations/''${day}_*.jsonl and update your memory." \
      >>"$state/observer.log" 2>&1 ||
      echo "$(/bin/date +%FT%T) observer exited with $?" >>"$state/errors.log"
  '';
in
{
  # The same rclone the capture hook runs, so `rclone config` sets up its remote.
  home.packages = [ pkgs.rclone ];

  launchd.agents.vault-observe = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    enable = true;
    config = {
      ProgramArguments = [ "${observe}" ];
      StartCalendarInterval = [
        {
          Hour = 5;
          Minute = 0;
        }
      ];
    };
  };

  programs.claude-code = {
    enable = true;
    package = claude;

    # Shared rules (agents/AGENTS.md) plus the Claude-only section.
    context = builtins.readFile ../agents/AGENTS.md + "\n" + builtins.readFile ./CLAUDE.md;

    # One directory link per skill (an attrset, not a path) so tool-owned entries such
    # as skills/synced keep living next to them. critique is for Codex only.
    skills =
      lib.mapAttrs (name: _: skills + "/${name}") (removeAttrs (builtins.readDir skills) [ "critique" ])
      // {
        i-have-adhd = "${inputs.i-have-adhd}/skills/i-have-adhd";
      };

    # Marketplace plugins pinned through flake inputs, loaded as personal plugins.
    plugins = {
      # home-manager's mkPluginEntry symlinks each top-level source entry into the
      # plugin store path individually, so hooks/ stays a symlink to the flake
      # input's own store path. ponytail's manifest points "hooks" at an explicit
      # file (./hooks/claude-codex-hooks.json); Claude Code resolves that through
      # the symlink and rejects it as outside the plugin directory. codex and warp
      # don't hit this because they rely on the default hooks/hooks.json location
      # instead of naming a path. Copy the source and rename the hooks file to the
      # default so ponytail resolves the same way.
      ponytail = pkgs.runCommand "ponytail-plugin" { nativeBuildInputs = [ pkgs.jq ]; } ''
        cp -r ${inputs.ponytail} $out
        chmod -R u+w $out
        mv $out/hooks/claude-codex-hooks.json $out/hooks/hooks.json
        jq 'del(.hooks)' ${inputs.ponytail}/.claude-plugin/plugin.json > $out/.claude-plugin/plugin.json
      '';
      codex = "${inputs.codex-plugin-cc}/plugins/codex";
      # Notifications go through Warp (OSC 777, also over SSH); preferredNotifChannel is off.
      warp = "${inputs.claude-code-warp}/plugins/warp";
    };

    # By absolute path, as in programs/codex: apps started by launchd lack the mise shims.
    mcpServers.codebase-memory-mcp.command = "${config.xdg.dataHome}/mise/shims/codebase-memory-mcp";

    settings = settings // {
      permissions = settings.permissions // {
        deny =
          settings.permissions.deny
          ++ map (cmd: "Bash(${lib.concatStringsSep " " cmd}:*)") guardrails.commands
          ++ lib.concatMap (path: [
            "Read(~/${path})"
            "Read(~/${path}/**)"
          ]) guardrails.secrets;
      };
      statusLine = {
        type = "command";
        command = "${./statusline.sh}";
      };
      hooks = {
        SessionEnd = hook "end";
        SessionStart = hook "start";
      };
    };
  };
}
