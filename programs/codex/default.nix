# Codex CLI. config.toml is left to Codex (it writes trust and machine paths there);
# shared settings live in system-config.toml and are deployed to /etc/codex/config.toml
# (darwin.nix on macOS, install.sh + linux.nix on Linux).
{ pkgs, inputs, ... }:
{
  programs.codex = {
    enable = true;
    package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.codex;
    context = ../agents/AGENTS.md;
    skills = ../agents/skills;
  };
}
