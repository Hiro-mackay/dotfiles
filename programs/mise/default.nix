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
      # A machine that leaves tools to each project's mise.toml sets this to { }.
      tools = lib.mkDefault (
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
      );
      settings = {
        idiomatic_version_file_enable_tools = [ "python" ];
        # Supply chain: ignore versions published in the last week (npm: dependencies too).
        minimum_release_age = "7d";
        # A GitHub token, so mise does not share the anonymous 60-an-hour limit and can
        # fetch an organization's private tools. mise asks for it itself; an exported
        # MISE_GITHUB_TOKEN would reach every installer it runs, npm scripts included.
        # Only for github.com: mise also asks for other GitHub hosts. The account is the
        # current repository's (programs/git), the base one elsewhere; host and account
        # are named, so neither GH_HOST nor gh's active account picks another token.
        github.credential_command = ''[ "$MISE_CREDENTIAL_HOST" = github.com ] && gh auth token -h github.com -u "$(git config github.login)"'';
      };
    };
  };

  # Shims make mise tools visible to shells home-manager sets up (zsh, and bash on Linux),
  # including non-interactive ones. Apps started by launchd (Dock) do not see them.
  home.sessionPath = [ "${config.xdg.dataHome}/mise/shims" ];
}
