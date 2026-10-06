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
    skills = ../agents/skills;
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
}
