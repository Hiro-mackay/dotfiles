# Codex CLI. The declared settings in ./config.toml are merged into ~/.codex/config.toml
# on every switch: keys Codex writes itself (trust, machine paths) are kept, and
# declared keys win.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  guardrails = import ../agents/guardrails.nix;
in
{
  programs.codex = {
    enable = true;
    package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex;
    context = ../agents/AGENTS.md;
    skills =
      lib.mapAttrs (name: _: ../agents/skills + "/${name}") (builtins.readDir ../agents/skills)
      // {
        i-have-adhd = "${inputs.i-have-adhd}/skills/i-have-adhd";
      };
    # Plugin marketplaces come from the flake inputs (pinned, updated with flake.lock)
    # instead of Codex fetching them from git.
    rules.guardrails = lib.concatMapStrings (
      cmd: "prefix_rule(pattern = ${builtins.toJSON cmd}, decision = \"forbidden\")\n"
    ) guardrails.commands;
    settings = lib.recursiveUpdate (builtins.fromTOML (builtins.readFile ./config.toml)) {
      # The workspace sandbox, plus no reads of the guarded files.
      default_permissions = "guarded";
      permissions.guarded = {
        extends = ":workspace";
        filesystem = lib.genAttrs (map (path: "${config.home.homeDirectory}/${path}") guardrails.secrets) (
          _: "deny"
        );
      };
      # By absolute path: Codex.app started from the Dock has no mise shims on PATH.
      mcp_servers.codebase-memory-mcp.command = "${config.xdg.dataHome}/mise/shims/codebase-memory-mcp";
      marketplaces = {
        ponytail = {
          source_type = "local";
          source = "${inputs.ponytail}";
        };
        codex-warp = {
          source_type = "local";
          source = "${inputs.codex-warp}";
        };
      };
    };
    mutableSettings = true;
  };

  # Declared settings only (no keys Codex writes itself), for other environments such as
  # containers. Matches home-manager's merge input only while plugins, marketplaces and MCP
  # servers are written in `settings` directly above; moving them to the dedicated
  # programs.codex options would make home-manager add keys here that this file misses.
  home.file.".codex/declared/config.toml".source =
    (pkgs.formats.toml { }).generate "codex-declared-config.toml"
      config.programs.codex.settings;
}
