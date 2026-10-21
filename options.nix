# What a machine sets differently from this repo's defaults. The defaults are this repo's own
# machines; another flake that imports homeModules.default (another machine, say) sets these.
# Only values that feed several settings are options. A single setting a machine may change is
# set with lib.mkDefault where it is made, so a plain assignment overrides it.
{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.dotfiles = {
    github.login = mkOption {
      type = types.str;
      default = "Hiro-mackay";
      description = ''
        The base GitHub account: git and gh use its token unless ~/.gitconfig.accounts
        (gh-setup) names another account for a repository's owner.
      '';
    };

    github.accounts = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            name = mkOption {
              type = types.str;
              description = "git's user.name in its owners' repositories.";
            };
            email = mkOption {
              type = types.str;
              description = "git's user.email in its owners' repositories.";
            };
            owners = mkOption {
              type = types.listOf types.str;
              default = [ ];
              description = "Owners it serves besides its own login, as GitHub spells them.";
            };
          };
        }
      );
      default = { };
      example = lib.literalExpression ''
        { other-me = { name = "Me"; email = "me@example.com"; owners = [ "example-org" ]; }; }
      '';
      description = ''
        Additional GitHub accounts, by login: what gh-setup writes to ~/.gitconfig.<owner>,
        declared in Nix instead. Included after ~/.gitconfig.accounts, so a declared
        account wins for its owners. gh still needs to be signed in to it (gh-setup).
      '';
    };

    git.user = {
      name = mkOption {
        type = types.str;
        default = "mackay";
        description = "git's user.name outside the owners in ~/.gitconfig.accounts.";
      };
      email = mkOption {
        type = types.str;
        default = "43330841+Hiro-mackay@users.noreply.github.com";
        description = "git's user.email outside the owners in ~/.gitconfig.accounts.";
      };
    };

    repoRoot = mkOption {
      type = types.str;
      default = "~/Repository";
      description = "Where ghq puts repositories (<root>/github.com/<owner>/<repo>).";
    };

    vault.enable = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Claude Code's hooks that copy conversations and memory into the vault, and the
        rclone they sync with (programs/claude/vault-capture.py).
      '';
    };
  };
}
