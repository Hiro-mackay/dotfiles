# Codex CLI. The declared settings in ./config.toml are merged into ~/.codex/config.toml
# on every switch: keys Codex writes itself (trust, machine paths) are kept, and
# declared keys win.
{
  lib,
  pkgs,
  inputs,
  ...
}:
{
  programs.codex = {
    enable = true;
    package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex;
    context = ../agents/AGENTS.md;
    skills = ../agents/skills;
    # Plugin marketplaces come from the flake inputs (pinned, updated with flake.lock)
    # instead of Codex fetching them from git.
    settings = lib.recursiveUpdate (builtins.fromTOML (builtins.readFile ./config.toml)) {
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
