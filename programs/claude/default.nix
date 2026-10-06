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
in
{
  programs.claude-code = {
    enable = true;
    package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-code;

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
      ponytail = inputs.ponytail;
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
    };
  };
}
