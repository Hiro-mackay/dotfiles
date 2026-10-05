# Codex CLI. The declared settings in ./config.toml are merged into ~/.codex/config.toml
# on every switch: keys Codex writes itself (trust, machine paths) are kept, and
# declared keys win.
{ pkgs, inputs, ... }:
{
  programs.codex = {
    enable = true;
    package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex;
    context = ../agents/AGENTS.md;
    skills = ../agents/skills;
    settings = builtins.fromTOML (builtins.readFile ./config.toml);
    mutableSettings = true;
  };
}
