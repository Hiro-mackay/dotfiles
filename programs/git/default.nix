# Git settings that hold on every machine. Accounts (identity, which directory uses
# which account) live only in the untracked ~/.gitconfig.local, copied from
# ./gitconfig.local.sample and included last so it can override anything here.
{ pkgs, ... }:
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

    includes = [
      { path = "~/.gitconfig.local"; }
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
        ];
  };

  home.packages = [ pkgs.git-secrets ];
}
