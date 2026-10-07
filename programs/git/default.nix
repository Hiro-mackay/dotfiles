# Git settings shared by every machine, the base GitHub account included.
# ~/.gitconfig.accounts, a writable file created from ./gitconfig.accounts on the first
# switch, holds which owners use which other account (gh-setup). It is included after
# the settings here, so an account there overrides the base account.
{ lib, pkgs, ... }:
let
  # The base GitHub account: git and gh use its token unless ~/.gitconfig.<owner>
  # (gh-setup) names another account for a repository's owner.
  baseLogin = "Hiro-mackay";
  # git's credential helper for github.com: the token of the account in
  # credential.username, which ~/.gitconfig.<owner> sets for its owners' repositories.
  credentialHelper = pkgs.writeShellApplication {
    name = "git-credential-gh-account";
    text = ''
      [ "''${1:-}" = get ] || exit 0
      user=""
      while IFS="=" read -r key value && [ -n "$key" ]; do
        [ "$key" != username ] || user=$value
      done
      [ -n "$user" ] || exit 0
      if ! token=$(${pkgs.gh}/bin/gh auth token -h github.com -u "$user"); then
        echo "git: gh is not signed in as $user; run gh-setup" >&2
        exit 1
      fi
      printf 'username=%s\npassword=%s\n' "$user" "$token"
    '';
  };
in
{
  programs.git = {
    enable = true;
    settings = {
      core = {
        editor = "vim";
        quotepath = false;
      };
      user = {
        name = "mackay";
        email = "43330841+${baseLogin}@users.noreply.github.com";
      };
      init.defaultBranch = "main";
      fetch.prune = true;
      pull.rebase = true;
      push = {
        default = "current";
        autoSetupRemote = true;
      };
      ghq.root = "~/Repository";

      # GitHub over HTTPS only, with gh's token for both git and gh (gh-wrapper.sh).
      url."https://github.com/".insteadOf = [
        "git@github.com:"
        "ssh://git@github.com/"
      ];
      github.login = baseLogin;
      credential."https://github.com" = {
        helper = [
          ""
          "${credentialHelper}/bin/git-credential-gh-account"
        ];
        username = baseLogin;
      };
    };

    ignores = [
      ".DS_Store"
      "._*"
      "**/.claude/settings.local.json"
      "**/.claude/.cc-writes/"
    ];

    # After the settings above, so another account there overrides them.
    includes = [
      { path = "~/.gitconfig.accounts"; }
    ]
    # This public repo, wherever it is cloned: run its pre-commit hook.
    ++
      map
        (url: {
          condition = "hasconfig:remote.*.url:${url}";
          contents.core.hooksPath = "programs/git/hooks";
        })
        [
          "https://github.com/${baseLogin}/dotfiles*"
          "git@github.com:${baseLogin}/dotfiles*"
          "ssh://git@github.com/${baseLogin}/dotfiles*"
        ];
  };

  home.packages = [ pkgs.git-secrets ];

  # Created only when missing, so edits survive later switches.
  home.activation.gitconfigAccounts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -e "$HOME/.gitconfig.accounts" ]; then
      run install -m 644 ${./gitconfig.accounts} "$HOME/.gitconfig.accounts"
    fi
  '';
}
