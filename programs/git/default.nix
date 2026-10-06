# Git settings shared by every machine. Accounts live in ~/.gitconfig.accounts, a
# writable file created from ./gitconfig.accounts on the first switch and edited per
# machine afterwards; it is included last, so it can override anything here.
{ lib, pkgs, ... }:
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
    };

    ignores = [
      ".DS_Store"
      "._*"
      "**/.claude/settings.local.json"
      "**/.claude/.cc-writes/"
    ];

    # The base account's key for GitHub, even while cloning. It comes before the
    # accounts file, so another account there (gh-account) overrides it.
    includes =
      map
        (url: {
          condition = "hasconfig:remote.*.url:${url}";
          contents.core.sshCommand = "ssh -i ~/.ssh/id_ed25519_github -o IdentitiesOnly=yes -o AddKeysToAgent=yes -o IgnoreUnknown=UseKeychain -o UseKeychain=yes";
        })
        [
          "git@github.com:*/**"
          "ssh://git@github.com/**"
        ]
      ++ [ { path = "~/.gitconfig.accounts"; } ]
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
