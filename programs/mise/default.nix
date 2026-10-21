# mise manages languages and project-pinnable dev tools.
# Declared tools go to conf.d (read-only); `mise use -g` still writes the mutable
# ~/.config/mise/config.toml, which is not tracked.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
in
{
  programs.mise = {
    enable = true;
    enableMutableConfig = true;
    globalConfig = {
      tools = lib.mkMerge [
        # A machine that leaves tools to each project's mise.toml sets this to { }.
        (lib.mkDefault (
          {
            node = "latest";
            python = "latest";
            uv = "latest";
            go = "latest";
            pnpm = "latest";
            terraform = "latest";
            kubectl = "latest";
            kind = "latest";
            skaffold = "latest";
            golangci-lint = "latest";
            sqlc = "latest";
            buf = "latest";
            task = "latest";
            lefthook = "latest";
            "aqua:golang-migrate/migrate" = "latest";
            "go:golang.org/x/tools/gopls" = "latest";
          }
          // lib.optionalAttrs isDarwin {
            bun = "latest";
            deno = "latest";
            ni = "latest";
            rust = "latest";
            sops = "3.12.2";
          }
        ))
        # The MCP server Claude Code and Codex run (programs/claude, programs/codex): kept
        # when the tools above are cleared. allow_builds runs only its postinstall, which
        # fetches its binary.
        {
          "npm:codebase-memory-mcp" = {
            version = "latest";
            allow_builds = [ "codebase-memory-mcp" ];
          };
        }
      ];
      settings = {
        idiomatic_version_file_enable_tools = [ "python" ];
        # Supply chain: ignore versions published in the last week (npm: dependencies too).
        minimum_release_age = "7d";
      };
    };
  };

  # Shims make mise tools visible to shells home-manager sets up (zsh, and bash on Linux),
  # including non-interactive ones. Apps started by launchd (Dock) do not see them.
  home.sessionPath = [ "${config.xdg.dataHome}/mise/shims" ];
}
