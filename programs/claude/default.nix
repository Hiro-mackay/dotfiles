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

  # Copies conversations and memory into the vault's .depth/, then syncs the vault and
  # runs the daily agents in a detached run (see vault-capture.py). git and claude come
  # from Nix so the hook does not depend on the PATH of whatever started Claude Code.
  capture = pkgs.writeShellScript "vault-capture" ''
    export VAULT_RCLONE=${pkgs.rclone}/bin/rclone VAULT_CLAUDE=${claude}/bin/claude
    export PATH="${pkgs.git}/bin:$PATH"
    exec ${pkgs.python3}/bin/python3 ${./vault-capture.py} "$@"
  '';
  hook = arg: [
    {
      hooks = [
        {
          type = "command";
          command = "${capture} ${arg}";
          # SessionEnd hooks share a 1.5 s budget unless an entry sets a longer timeout.
          timeout = 30;
        }
      ];
    }
  ];
in
{
  # The same rclone the capture hook runs, so `rclone config` sets up its remote.
  home.packages = lib.optional config.dotfiles.vault.enable pkgs.rclone;

  programs.claude-code = {
    enable = true;
    # A machine that installs Claude Code some other way sets this to null.
    package = lib.mkDefault claude;

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
      hooks = lib.mkIf config.dotfiles.vault.enable {
        SessionEnd = hook "end";
        SessionStart = hook "start";
      };
    };
  };
}
