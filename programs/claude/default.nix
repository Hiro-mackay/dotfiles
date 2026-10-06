# Claude Code: package, settings, CLAUDE.md, skills, plugins and MCP all come from Nix.
# settings.json is read-only, so /model, /config and /plugin changes last only for the
# session; edit settings.json here and switch to keep them. The deny rules guard
# against accidents, not against a determined agent: the file is a symlink in the
# user's home that a plain rm can replace.
{
  lib,
  pkgs,
  inputs,
  ...
}:
let
  skills = ../agents/skills;
in
{
  programs.claude-code = {
    enable = true;
    package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-code;

    # Shared rules (agents/AGENTS.md) plus the Claude-only section.
    context = builtins.readFile ../agents/AGENTS.md + "\n" + builtins.readFile ./CLAUDE.md;

    # One directory link per skill (an attrset, not a path) so tool-owned entries such
    # as skills/synced keep living next to them. critique is for Codex only.
    skills = lib.mapAttrs (name: _: skills + "/${name}") (
      removeAttrs (builtins.readDir skills) [ "critique" ]
    );

    # Marketplace plugins pinned through flake inputs, loaded as personal plugins.
    plugins = {
      ponytail = inputs.ponytail;
      codex = "${inputs.codex-plugin-cc}/plugins/codex";
    };

    mcpServers.codebase-memory-mcp.command = "codebase-memory-mcp";

    settings = builtins.fromJSON (builtins.readFile ./settings.json) // {
      statusLine = {
        type = "command";
        command = "${./statusline.sh}";
      };
    };
  };
}
