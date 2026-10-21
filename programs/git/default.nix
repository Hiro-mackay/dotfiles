# Git settings shared by every machine. The base GitHub account and identity come from
# options.dotfiles (options.nix).
# ~/.gitconfig.accounts, a writable file created from ./gitconfig.accounts on the first
# switch, holds which owners use which other account (gh-setup). It is included after
# the settings here, so an account there overrides the base account; an account declared
# in options.dotfiles.github.accounts comes after it and wins.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.dotfiles) github git repoRoot;
  # The URL forms a remote can name GitHub with, as in gh-setup.
  remoteUrls =
    owner:
    map (form: "${form}${owner}/**") [
      "https://github.com/"
      "git@github.com:"
      "ssh://git@github.com/"
    ];
  # A declared account (options.nix): its identity and login for its owners' remotes,
  # lowercase too, since git matches URLs case-sensitively and gh-wrapper.sh lowercases.
  accountIncludes = lib.concatLists (
    lib.mapAttrsToList (
      login: account:
      map
        (url: {
          condition = "hasconfig:remote.*.url:${url}";
          contents = {
            user = { inherit (account) name email; };
            github.login = login;
            credential."https://github.com".username = login;
          };
        })
        (
          lib.concatMap remoteUrls (
            lib.unique (
              lib.concatMap (o: [
                o
                (lib.toLower o)
              ]) ([ login ] ++ account.owners)
            )
          )
        )
    ) github.accounts
  );
  # This repository's owner, for its pre-commit hook below (not the base account).
  repoOwner = "Hiro-mackay";
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
      user = { inherit (git.user) name email; };
      init.defaultBranch = "main";
      fetch.prune = true;
      pull.rebase = true;
      push = {
        default = "current";
        autoSetupRemote = true;
      };
      ghq.root = repoRoot;

      # GitHub over HTTPS only, with gh's token for both git and gh (gh-wrapper.sh).
      url."https://github.com/".insteadOf = [
        "git@github.com:"
        "ssh://git@github.com/"
      ];
      github.login = github.login;
      credential."https://github.com" = {
        helper = [
          ""
          "${credentialHelper}/bin/git-credential-gh-account"
        ];
        username = github.login;
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
    ++ accountIncludes
    # This public repo, wherever it is cloned: run its pre-commit hook.
    ++
      map
        (url: {
          condition = "hasconfig:remote.*.url:${url}";
          contents.core.hooksPath = "programs/git/hooks";
        })
        [
          "https://github.com/${repoOwner}/dotfiles*"
          "git@github.com:${repoOwner}/dotfiles*"
          "ssh://git@github.com/${repoOwner}/dotfiles*"
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
