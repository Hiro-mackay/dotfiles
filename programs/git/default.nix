# Git settings shared by every machine. Accounts live in ~/.gitconfig.accounts, a
# writable file created from ./gitconfig.accounts on the first switch and edited per
# machine afterwards; it is included last, so it can override anything here.
{ lib, pkgs, ... }:
let
  # The base GitHub account: git and gh use its token unless ~/.gitconfig.<owner>
  # (gh-setup) names another account for a repository's owner.
  baseLogin = "Hiro-mackay";
in
{
  programs.git = {
    enable = true;
    settings = {
      core = {
        editor = "vim";
        quotepath = false;
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
      credential."https://github.com".helper = [
        ""
        "!f() { test \"$1\" = get && echo username=${baseLogin} && echo password=$(gh auth token -h github.com -u ${baseLogin}); }; f"
      ];
    };

    ignores = [
      ".DS_Store"
      "._*"
      "**/.claude/settings.local.json"
      "**/.claude/.cc-writes/"
    ];

    # Included after the settings above, so another account there overrides them.
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
          "https://github.com/Hiro-mackay/dotfiles*"
          "git@github.com:Hiro-mackay/dotfiles*"
          "ssh://git@github.com/Hiro-mackay/dotfiles*"
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
