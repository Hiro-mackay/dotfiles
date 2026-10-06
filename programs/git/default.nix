# Git settings and the base account, the same on every machine. An untracked
# ~/.gitconfig.local, where it exists, adds machine-specific accounts and settings;
# it is included last, so it can override anything here. See ./gitconfig.local.sample.
{ pkgs, ... }:
{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "mackay";
        email = "43330841+Hiro-mackay@users.noreply.github.com";
      };
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
          "ssh://git@github.com/Hiro-mackay/dotfiles*"
        ];
  };

  home.packages = [ pkgs.git-secrets ];
}
